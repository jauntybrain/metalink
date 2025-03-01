// lib/metalink.dart
///
library;

import 'dart:async';

import 'package:http/http.dart' as http;

import 'src/core/image_url_analyzer.dart';
import 'src/core/metadata_cache.dart';
import 'src/core/metadata_extractor.dart';
import 'src/core/url_optimizer.dart';
import 'src/models/image_metadata.dart';
import 'src/models/link_metadata.dart';

export 'src/core/image_url_analyzer.dart';
export 'src/core/metadata_cache.dart';
// Export core functionality
export 'src/core/metadata_extractor.dart';
export 'src/core/url_optimizer.dart';
export 'src/models/content_analysis.dart';
export 'src/models/image_metadata.dart'; // Export models
export 'src/models/link_metadata.dart';
export 'src/models/social_engagement.dart';

/// Main entry point for using the MetaLink package
class MetaLink {
  /// Creates a new instance of [MetaLink]
  MetaLink._({
    required MetadataExtractor extractor,
  }) : _extractor = extractor;

  /// Creates a new instance of [MetaLink] with default configuration
  ///
  /// This method creates a non-cached instance that is suitable for one-time use
  factory MetaLink.create({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    String? userAgent,
    bool followRedirects = true,
    bool optimizeUrls = true,
    int maxRedirects = 5,
    bool analyzeImages = true,
    bool extractStructuredData = true,
    bool extractSocialMetrics = false,
    bool analyzeContent = false,
    String? proxyUrl,
  }) {
    final extractor = MetadataExtractor(
      client: client,
      timeout: timeout,
      userAgent: userAgent,
      cacheEnabled: false,
      followRedirects: followRedirects,
      optimizeUrls: optimizeUrls,
      maxRedirects: maxRedirects,
      analyzeImages: analyzeImages,
      extractStructuredData: extractStructuredData,
      extractSocialMetrics: extractSocialMetrics,
      analyzeContent: analyzeContent,
      proxyUrl: proxyUrl,
    );

    return MetaLink._(extractor: extractor);
  }

  /// The metadata extractor instance
  final MetadataExtractor _extractor;

  /// Creates a new instance of [MetaLink] with caching enabled
  ///
  /// This method creates a cached instance that is suitable for multiple uses
  static Future<MetaLink> createWithCache({
    http.Client? client,
    Duration timeout = const Duration(seconds: 10),
    String? userAgent,
    Duration cacheDuration = const Duration(hours: 4),
    bool followRedirects = true,
    bool optimizeUrls = true,
    int maxRedirects = 5,
    bool analyzeImages = true,
    bool extractStructuredData = true,
    bool extractSocialMetrics = false,
    bool analyzeContent = false,
    Future<MetadataCache>? Function()? customCache,
    String? proxyUrl,
  }) async {
    final cache = customCache != null
        ? await customCache()
        : await MetadataCacheFactory.getSharedInstance();

    final extractor = MetadataExtractor(
      client: client,
      cache: cache,
      timeout: timeout,
      userAgent: userAgent,
      cacheEnabled: true,
      cacheDuration: cacheDuration,
      followRedirects: followRedirects,
      optimizeUrls: optimizeUrls,
      maxRedirects: maxRedirects,
      analyzeImages: analyzeImages,
      extractStructuredData: extractStructuredData,
      extractSocialMetrics: extractSocialMetrics,
      analyzeContent: analyzeContent,
      proxyUrl: proxyUrl,
    );

    return MetaLink._(extractor: extractor);
  }

  /// Extracts metadata from the given URL
  ///
  /// Parameters:
  /// - [url]: The URL to extract metadata from
  /// - [skipCache]: Whether to skip the cache and extract fresh metadata
  Future<LinkMetadata> extract(String url, {bool skipCache = false}) {
    return _extractor.extract(url, skipCache: skipCache);
  }

  /// Extracts metadata for multiple URLs in parallel
  ///
  /// Parameters:
  /// - [urls]: List of URLs to extract metadata from
  /// - [skipCache]: Whether to skip the cache and extract fresh metadata
  /// - [concurrentRequests]: Maximum number of concurrent requests to make
  Future<List<LinkMetadata>> extractMultiple(
    List<String> urls, {
    bool skipCache = false,
    int concurrentRequests = 3,
  }) {
    return _extractor.extractMultiple(
      urls,
      skipCache: skipCache,
      concurrentRequests: concurrentRequests,
    );
  }

  /// Analyzes an image URL and returns detailed metadata
  ///
  /// Parameters:
  /// - [imageUrl]: The URL of the image to analyze
  /// - [sourceDomain]: The domain of the page where the image was found
  Future<ImageMetadata> analyzeImage(
    String imageUrl, {
    String? sourceDomain,
  }) {
    final analyzer = ImageUrlAnalyzer(
      client: http.Client(),
      timeout: _extractor.timeout,
      userAgent: _extractor.userAgent,
      followRedirects: _extractor.followRedirects,
      maxRedirects: _extractor.maxRedirects,
      proxyUrl: _extractor.proxyUrl,
    );

    try {
      return analyzer.analyze(
        imageUrl,
        sourceDomain: sourceDomain,
      );
    } finally {
      analyzer.dispose();
    }
  }

  /// Optimizes the given URL and follows redirects if enabled
  ///
  /// Parameters:
  /// - [url]: The URL to optimize
  Future<UrlOptimizationResult> optimizeUrl(String url) {
    final optimizer = UrlOptimizer(
      client: http.Client(),
      followRedirects: _extractor.followRedirects,
      maxRedirects: _extractor.maxRedirects,
      timeout: _extractor.timeout,
      userAgent: _extractor.userAgent,
      proxyUrl: _extractor.proxyUrl,
    );

    try {
      return optimizer.optimize(url);
    } finally {
      optimizer.dispose();
    }
  }

  /// Closes all resources used by this instance
  void dispose() {
    _extractor.dispose();
  }
}

/// A simplified interface for quick, one-off metadata extraction
class SimpleMetaLink {
  /// Extracts metadata from the given URL
  ///
  /// This is a convenience method for one-time extraction
  static Future<LinkMetadata> extract(String url, {String? proxyUrl}) async {
    final metalink = MetaLink.create(proxyUrl: proxyUrl);
    try {
      return await metalink.extract(url);
    } finally {
      metalink.dispose();
    }
  }

  /// Analyzes an image URL and returns detailed metadata
  ///
  /// This is a convenience method for one-time image analysis
  static Future<ImageMetadata> analyzeImage(String imageUrl,
      {String? proxyUrl}) async {
    final analyzer = ImageUrlAnalyzer(proxyUrl: proxyUrl);
    try {
      return await analyzer.analyze(imageUrl);
    } finally {
      analyzer.dispose();
    }
  }

  /// Optimizes the given URL and follows redirects
  ///
  /// This is a convenience method for one-time URL optimization
  static Future<UrlOptimizationResult> optimizeUrl(String url,
      {String? proxyUrl}) async {
    final optimizer = UrlOptimizer(proxyUrl: proxyUrl);
    try {
      return await optimizer.optimize(url);
    } finally {
      optimizer.dispose();
    }
  }
}
