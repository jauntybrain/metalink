// lib/src/core/metadata_cache.dart

import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:hive_ce/hive.dart';

import '../models/link_metadata.dart';

/// A cache for storing and retrieving extracted metadata
class MetadataCache {
  /// Creates a new instance of [MetadataCache]
  ///
  /// Parameters:
  /// - [box]: Optional Hive box instance for persistent storage
  /// - [keyPrefix]: Prefix for cache keys in the Hive box
  /// - [defaultTtlMs]: Default TTL for cached items in milliseconds
  MetadataCache({
    Box<String>? box,
    String keyPrefix = 'metalink_cache_',
    int defaultTtlMs = 14400000,
  })  : _box = box,
        _keyPrefix = keyPrefix,
        _defaultTtlMs = defaultTtlMs;

  /// Hive box for persistent storage
  final Box<String>? _box;

  /// In-memory cache for faster access
  final Map<String, LinkMetadata> _memoryCache = {};

  /// Prefix for cache keys in Hive box
  final String _keyPrefix;

  /// Default TTL for cached items in milliseconds
  final int _defaultTtlMs;

  /// Gets metadata from the cache for the given URL
  ///
  /// Returns null if the URL is not in the cache or if the cached item has expired
  Future<LinkMetadata?> get(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    final cacheKey = _getCacheKey(normalizedUrl);

    // Check memory cache first
    if (_memoryCache.containsKey(normalizedUrl)) {
      final metadata = _memoryCache[normalizedUrl];
      if (metadata != null && metadata.isValid && !_isExpired(metadata)) {
        return metadata;
      } else {
        // Remove expired item from memory cache
        _memoryCache.remove(normalizedUrl);
      }
    }

    // If we have persistent storage, check there
    if (_box != null && _box!.isOpen) {
      final jsonString = _box!.get(cacheKey);
      if (jsonString != null) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;

          // Check cache timestamp
          final timestamp = json['timestamp'] as int?;
          if (timestamp != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            if (now - timestamp <= _defaultTtlMs) {
              // Not expired, create metadata object
              final metadata = LinkMetadata.fromJson(
                  json['metadata'] as Map<String, dynamic>);

              if (metadata.isValid) {
                // Add to memory cache for faster access next time
                _memoryCache[normalizedUrl] = metadata;

                return metadata;
              }
            }
          }

          // Item has expired, remove it
          await _box!.delete(cacheKey);
        } catch (e) {
          // If there's an error parsing the cached data, remove it
          await _box!.delete(cacheKey);
        }
      }
    }

    return null;
  }

  /// Puts metadata in the cache for the given URL
  ///
  /// Parameters:
  /// - [url]: The URL to cache
  /// - [metadata]: The metadata to cache
  /// - [ttlMs]: Optional TTL in milliseconds, defaults to the cache-wide default
  Future<void> put(String url, LinkMetadata metadata, {int? ttlMs}) async {
    final normalizedUrl = _normalizeUrl(url);
    final cacheKey = _getCacheKey(normalizedUrl);

    // Add to memory cache
    _memoryCache[normalizedUrl] = metadata;

    // If we have persistent storage, save there too
    if (_box != null && _box!.isOpen) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheData = {
        'timestamp': now,
        'ttl': ttlMs ?? _defaultTtlMs,
        'metadata': metadata.toJson(),
      };

      await _box!.put(cacheKey, jsonEncode(cacheData));
    }
  }

  /// Removes metadata from the cache for the given URL
  ///
  /// Returns true if the item was in the cache and was removed
  Future<bool> remove(String url) async {
    final normalizedUrl = _normalizeUrl(url);
    final cacheKey = _getCacheKey(normalizedUrl);

    final wasInMemory = _memoryCache.remove(normalizedUrl) != null;
    var wasInBox = false;

    if (_box != null && _box!.isOpen) {
      wasInBox = _box!.containsKey(cacheKey);
      if (wasInBox) {
        await _box!.delete(cacheKey);
      }
    }

    return wasInMemory || wasInBox;
  }

  /// Clears all cached metadata
  Future<void> clear() async {
    try {
      _memoryCache.clear();
      if (_box != null && _box!.isOpen) {
        final allKeys = _box!.keys.toList();
        for (final key in allKeys) {
          if (key is String && key.startsWith(_keyPrefix)) {
            await _box!.delete(key);
          }
        }
      }
    } catch (_) {}
  }

  /// Removes all expired items from the cache
  Future<int> removeExpired() async {
    var count = 0;

    // Check memory cache
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredUrls = <String>[];

    for (final entry in _memoryCache.entries) {
      if (_isExpired(entry.value)) {
        expiredUrls.add(entry.key);
        count++;
      }
    }

    // Remove expired items from memory cache
    for (final url in expiredUrls) {
      _memoryCache.remove(url);
    }

    // Check persistent storage
    if (_box != null && _box!.isOpen) {
      final allKeys = _box!.keys.toList();
      for (final key in allKeys) {
        if (key is String && key.startsWith(_keyPrefix)) {
          final jsonString = _box!.get(key);
          if (jsonString != null) {
            try {
              final json = jsonDecode(jsonString) as Map<String, dynamic>;
              final timestamp = json['timestamp'] as int?;
              final ttl = json['ttl'] as int? ?? _defaultTtlMs;

              if (timestamp != null && now - timestamp > ttl) {
                await _box!.delete(key);
                count++;
              }
            } catch (e) {
              // If there's an error parsing the cached data, remove it
              await _box!.delete(key);
              count++;
            }
          }
        }
      }
    }

    return count;
  }

  /// Checks if the given metadata has expired
  bool _isExpired(LinkMetadata metadata) {
    // We'll use the extraction duration field to store our timestamp
    // This is a bit of a hack, but it works and doesn't require modifying the model
    if (metadata.extractionDurationMs != null) {
      final timestamp = metadata.extractionDurationMs!;
      final now = DateTime.now().millisecondsSinceEpoch;
      return now - timestamp > _defaultTtlMs;
    }
    return true;
  }

  /// Gets the cache key for the given URL
  String _getCacheKey(String url) {
    return '$_keyPrefix${_hash(url)}';
  }

  /// Normalizes the given URL for consistent caching
  String _normalizeUrl(String url) {
    // Simple normalization for caching - remove protocol and trailing slash
    return url
        .replaceFirst(RegExp('^https?://'), '')
        .replaceFirst(RegExp(r'/$'), '');
  }

  /// Generates a simple hash of the given string
  String _hash(String input) {
    // Simple implementation of djb2 hash algorithm
    var hash = 5381;
    for (var i = 0; i < input.length; i++) {
      hash = ((hash * 33) ^ input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.toString();
  }
}

/// Factory for creating metadata cache instances
class MetadataCacheFactory {
  /// Shared instance of the cache
  static MetadataCache? _sharedInstance;

  /// The name of the Hive box used for caching
  static const String _boxName = 'metalink_cache';

  /// Gets a shared instance of the metadata cache
  ///
  /// The shared instance uses persistent storage if available
  static Future<MetadataCache> getSharedInstance() async {
    if (_sharedInstance != null) {
      return _sharedInstance!;
    }

    // Try to get or create Hive box
    Box<String>? box;
    try {
      // Try to initialize Hive - will throw if already initialized
      try {
        Hive.init('.');
      } catch (_) {
        // Hive is already initialized, which is fine
      }

      // Open the box
      box = await Hive.openBox<String>(_boxName);
    } catch (e) {
      // If we can't open the box, we'll use memory-only cache
      log('Error opening Hive box: $e');
    }

    _sharedInstance = MetadataCache(box: box);
    return _sharedInstance!;
  }

  /// Creates a new memory-only cache instance
  static MetadataCache createMemoryCache({
    String keyPrefix = 'metalink_cache_',
    int defaultTtlMs = 14400000, // 4 hours by default
  }) {
    return MetadataCache(
      box: null,
      keyPrefix: keyPrefix,
      defaultTtlMs: defaultTtlMs,
    );
  }

  /// Creates a new cache instance with a custom box
  static Future<MetadataCache> createWithBox({
    required String boxName,
    String keyPrefix = 'metalink_cache_',
    int defaultTtlMs = 14400000, // 4 hours by default
    String? directory,
  }) async {
    // Try to initialize Hive - will throw if already initialized
    try {
      Hive.init(directory ?? '.');
    } catch (_) {
      // Hive is already initialized, which is fine
    }

    // Check if box exists and open it
    final box = await Hive.openBox<String>(boxName);

    return MetadataCache(
      box: box,
      keyPrefix: keyPrefix,
      defaultTtlMs: defaultTtlMs,
    );
  }
}
