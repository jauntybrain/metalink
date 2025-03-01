// lib/src/core/metadata_extractor.dart

import 'dart:async';
import 'dart:developer';

import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:metalink/metalink.dart';

import '../utils/domain_patterns.dart';
import '../utils/html_parser.dart';

/// The main metadata extraction engine
class MetadataExtractor {
  /// Creates a new instance of [MetadataExtractor]
  MetadataExtractor({
    http.Client? client,
    UrlOptimizer? urlOptimizer,
    ImageUrlAnalyzer? imageAnalyzer,
    MetadataCache? cache,
    this.timeout = const Duration(seconds: 10),
    this.userAgent,
    this.cacheEnabled = true,
    this.cacheDuration = const Duration(hours: 4),
    this.followRedirects = true,
    this.optimizeUrls = true,
    this.maxRedirects = 5,
    this.analyzeImages = true,
    this.extractStructuredData = true,
    this.extractSocialMetrics = false,
    this.analyzeContent = false,
    this.proxyUrl,
  })  : _client = client ?? http.Client(),
        _urlOptimizer = urlOptimizer ??
            UrlOptimizer(
              client: client,
              followRedirects: followRedirects,
              maxRedirects: maxRedirects,
              timeout: timeout,
              userAgent: userAgent,
              proxyUrl: proxyUrl,
            ),
        _imageAnalyzer = imageAnalyzer ??
            ImageUrlAnalyzer(
              client: client,
              timeout: timeout,
              userAgent: userAgent,
              followRedirects: followRedirects,
              maxRedirects: maxRedirects,
              proxyUrl: proxyUrl,
            ),
        _cache = cache;

  /// HTTP client for making network requests
  final http.Client _client;

  /// URL optimizer for handling redirects
  final UrlOptimizer _urlOptimizer;

  /// Image URL analyzer for processing images
  final ImageUrlAnalyzer _imageAnalyzer;

  /// Metadata cache for storing results
  final MetadataCache? _cache;

  /// Timeout duration for HTTP requests
  final Duration timeout;

  /// Custom user agent to use for HTTP requests
  final String? userAgent;

  /// Whether to use the cache
  final bool cacheEnabled;

  /// How long to cache results
  final Duration cacheDuration;

  /// Whether to follow redirects
  final bool followRedirects;

  /// Whether to optimize URLs
  final bool optimizeUrls;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  /// Whether to analyze images
  final bool analyzeImages;

  /// Whether to extract structured data
  final bool extractStructuredData;

  /// Whether to extract social engagement metrics
  final bool extractSocialMetrics;

  /// Whether to analyze content
  final bool analyzeContent;

  /// Optional proxy URL to use for requests (helps with CORS on web)
  final String? proxyUrl;

  /// Applies the proxy URL to the target URL if a proxy is configured
  String _applyProxyUrl(String targetUrl) {
    if (proxyUrl == null) return targetUrl;

    // Ensure the targetUrl is correctly encoded if it contains special characters
    final encodedTargetUrl = Uri.encodeFull(targetUrl);

    // Handle different proxy URL formats
    if (proxyUrl!.endsWith('?')) {
      // Format: https://corsproxy.io/?https://example.com
      return '$proxyUrl$encodedTargetUrl';
    } else if (proxyUrl!.contains('=') && proxyUrl!.contains('?')) {
      // Format: https://some-proxy.com/fetch?url=https://example.com
      return '$proxyUrl$encodedTargetUrl';
    } else if (proxyUrl!.contains('{url}')) {
      // Format with placeholder: https://proxy.com/fetch?url={url}&param=value
      return proxyUrl!.replaceAll('{url}', Uri.encodeComponent(targetUrl));
    } else {
      // Default: just append the URL
      return '$proxyUrl$encodedTargetUrl';
    }
  }

  /// Extracts metadata from the given URL
  ///
  /// Parameters:
  /// - [url]: The URL to extract metadata from
  /// - [skipCache]: Whether to skip the cache and extract fresh metadata
  Future<LinkMetadata> extract(String url, {bool skipCache = false}) async {
    // Start timing
    final stopwatch = Stopwatch()..start();

    // Check cache first if enabled
    if (cacheEnabled && !skipCache && _cache != null) {
      final cachedMetadata = await _cache?.get(url);
      if (cachedMetadata != null && cachedMetadata.isValid) {
        return cachedMetadata;
      }
    }

    final originalUrl = url;
    var finalUrl = url;

    try {
      // Optimize URL if enabled
      if (optimizeUrls) {
        final optimizationResult = await _urlOptimizer.optimize(url);
        finalUrl = optimizationResult.finalUrl;
      }

      // The actualFetchUrl includes the proxy if needed, but we don't expose this in metadata
      final actualFetchUrl = _applyProxyUrl(finalUrl);

      // Fetch content using the proxy URL if available
      final response = await _fetchContent(actualFetchUrl);

      // Parse HTML
      final document = HtmlParser.parse(response.body);

      // Get domain-specific pattern
      final domain = Uri.parse(finalUrl).host;
      final pattern = DomainPatterns.getPatternForDomain(domain);

      // Extract basic metadata
      final title = await _extractTitle(document, pattern);
      final description = await _extractDescription(document, pattern);
      final imageUrl = await _extractImageUrl(document, pattern, finalUrl);
      final favicon = await _extractFavicon(document, finalUrl);
      final siteName = await _extractSiteName(document, pattern, finalUrl);
      final keywords = await _extractKeywords(document, pattern);
      final author = await _extractAuthor(document, pattern);
      final publishedTime = await _extractPublishedTime(document, pattern);
      final modifiedTime = await _extractModifiedTime(document, pattern);
      final locale = await _extractLocale(document, pattern);
      final videoUrl = await _extractVideoUrl(document, pattern);
      final audioUrl = await _extractAudioUrl(document, pattern);

      // Extract advanced metadata if enabled
      Map<String, dynamic>? structuredData;
      if (extractStructuredData) {
        structuredData = await _extractStructuredData(document);
      }

      SocialEngagement? socialEngagement;
      if (extractSocialMetrics) {
        socialEngagement =
            await _extractSocialEngagement(finalUrl, structuredData);
      }

      ContentAnalysis? contentAnalysis;
      if (analyzeContent) {
        contentAnalysis = await _analyzeContent(document, finalUrl);
      }

      // Analyze image if enabled and available
      ImageMetadata? imageMetadata;
      if (analyzeImages && imageUrl != null) {
        imageMetadata = await _imageAnalyzer.analyze(
          imageUrl,
          sourceDomain: domain,
        );
      }

      // Create metadata object
      final metadata = LinkMetadata(
        title: title,
        description: description,
        imageMetadata: imageMetadata,
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        siteName: siteName,
        originalUrl: originalUrl,
        finalUrl: finalUrl, // Note: using the actual URL, not the proxy URL
        favicon: favicon,
        keywords: keywords,
        author: author,
        publishedTime: publishedTime,
        modifiedTime: modifiedTime,
        contentType: _determineContentType(document, finalUrl, structuredData),
        locale: locale,
        structuredData: structuredData,
        socialEngagement: socialEngagement,
        contentAnalysis: contentAnalysis,
        extractionDurationMs: stopwatch.elapsedMilliseconds,
        proxyUrl: proxyUrl,
      );

      // Cache result if enabled
      if (cacheEnabled && _cache != null) {
        await _cache?.put(
          url,
          metadata,
          ttlMs: cacheDuration.inMilliseconds,
        );
      }

      return metadata;
    } catch (e, s) {
      log('error extracting metadata for $url', error: e, stackTrace: s);
      // If an error occurs, return a basic metadata object with the error
      return LinkMetadata(
        originalUrl: originalUrl,
        finalUrl: finalUrl,
        extractionDurationMs: stopwatch.elapsedMilliseconds,
        proxyUrl: proxyUrl,
      );
    } finally {
      stopwatch.stop();
    }
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
  }) async {
    if (urls.isEmpty) {
      return [];
    }

    // Use a pool to limit concurrent requests
    final results = <LinkMetadata>[];

    // Process in batches to limit concurrent requests
    for (var i = 0; i < urls.length; i += concurrentRequests) {
      final end = (i + concurrentRequests < urls.length)
          ? i + concurrentRequests
          : urls.length;
      final batch = urls.sublist(i, end);

      // Process batch in parallel
      final batchResults = await Future.wait(
        batch.map((url) => extract(url, skipCache: skipCache)),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  /// Fetches the content at the given URL
  Future<http.Response> _fetchContent(String url) async {
    // The URL passed here should already have the proxy applied if needed
    final request = http.Request('GET', Uri.parse(url));

    // Add user agent if specified
    if (userAgent != null) {
      request.headers['User-Agent'] = userAgent!;
    } else {
      // Default to a modern browser user agent
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    }

    // Send the request with the configured client
    final streamedResponse = await _client.send(request).timeout(timeout);
    return http.Response.fromStream(streamedResponse);
  }

  /// Extracts the title from the document
  Future<String?> _extractTitle(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractTitle(document);
  }

  /// Extracts the description from the document
  Future<String?> _extractDescription(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractDescription(document);
  }

  /// Extracts the primary image URL from the document
  Future<String?> _extractImageUrl(
    Document document,
    DomainMetadataPattern pattern,
    String baseUrl,
  ) async {
    return HtmlParser.extractImageUrl(document, baseUrl);
  }

  /// Extracts the favicon URL from the document
  Future<String?> _extractFavicon(Document document, String baseUrl) async {
    return HtmlParser.extractFavicon(document, baseUrl);
  }

  /// Extracts the site name from the document
  Future<String?> _extractSiteName(
    Document document,
    DomainMetadataPattern pattern,
    String baseUrl,
  ) async {
    return HtmlParser.extractSiteName(document, baseUrl);
  }

  /// Extracts keywords from the document
  Future<List<String>> _extractKeywords(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractKeywords(document);
  }

  /// Extracts the author from the document
  Future<String?> _extractAuthor(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractAuthor(document);
  }

  /// Extracts the published time from the document
  Future<DateTime?> _extractPublishedTime(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractPublishedDate(document);
  }

  /// Extracts the modified time from the document
  Future<DateTime?> _extractModifiedTime(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractModifiedDate(document);
  }

  /// Extracts the locale from the document
  Future<String?> _extractLocale(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractLocale(document);
  }

  /// Extracts the video URL from the document
  Future<String?> _extractVideoUrl(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractVideoUrl(document);
  }

  /// Extracts the audio URL from the document
  Future<String?> _extractAudioUrl(
      Document document, DomainMetadataPattern pattern) async {
    return HtmlParser.extractAudioUrl(document);
  }

  /// Extracts structured data from the document
  Future<Map<String, dynamic>?> _extractStructuredData(
      Document document) async {
    return HtmlParser.extractStructuredData(document);
  }

  /// Extracts social engagement metrics for the URL
  Future<SocialEngagement?> _extractSocialEngagement(
    String url,
    Map<String, dynamic>? structuredData,
  ) async {
    // This is a placeholder - in a real implementation, you'd use a
    // service to get social metrics or extract them from the page
    return null;
  }

  /// Analyzes the content of the document
  Future<ContentAnalysis?> _analyzeContent(
      Document document, String url) async {
    // Extract main content
    final articleContent = _extractMainContent(document);

    // Calculate reading time
    final readingTimeSeconds = _calculateReadingTime(articleContent);

    // Count words
    final wordCount = _countWords(articleContent);

    // Detect language
    final language = _detectLanguage(document, articleContent);

    return ContentAnalysis(
      readingTimeSeconds: readingTimeSeconds,
      wordCount: wordCount,
      language: language,
      contentType: _determineContentTypeEnum(document, url),
    );
  }

  /// Extracts the main content from the document
  String _extractMainContent(Document document) {
    // Look for main content elements in order of likelihood
    final selectors = [
      'article',
      '[role="main"]',
      'main',
      '.post-content',
      '.article-content',
      '.entry-content',
      '.content',
      '#content',
      '.post',
      '.article',
    ];

    for (final selector in selectors) {
      final elements = document.querySelectorAll(selector);
      if (elements.isNotEmpty) {
        return elements.first.text;
      }
    }

    // If no main content element is found, use body
    final body = document.querySelector('body');
    if (body != null) {
      return body.text;
    }

    return '';
  }

  /// Calculates the reading time in seconds for the given content
  int _calculateReadingTime(String content) {
    // Average reading speed is about 200-250 words per minute
    // We'll use 225 words per minute
    final wordCount = _countWords(content);
    final readingTimeMinutes = wordCount / 225;
    return (readingTimeMinutes * 60).round();
  }

  /// Counts the number of words in the given content
  int _countWords(String content) {
    if (content.isEmpty) {
      return 0;
    }

    // Split by whitespace and filter out empty strings
    final words =
        content.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

    return words;
  }

  /// Detects the language of the given content
  String? _detectLanguage(Document document, String content) {
    // First check the HTML lang attribute
    final htmlElement = document.querySelector('html');
    if (htmlElement != null) {
      final lang = htmlElement.attributes['lang'];
      if (lang != null && lang.isNotEmpty) {
        return lang;
      }
    }

    // If no language attribute, check content-language meta tag
    final contentLanguage = HtmlParser.extractMetaContent(
        document, 'meta[http-equiv="content-language"]');
    if (contentLanguage != null && contentLanguage.isNotEmpty) {
      return contentLanguage;
    }

    // If no meta tag, check OpenGraph locale
    final ogLocale =
        HtmlParser.extractMetaContent(document, 'meta[property="og:locale"]');
    if (ogLocale != null && ogLocale.isNotEmpty) {
      return ogLocale;
    }

    // If nothing found, return null
    return null;
  }

  /// Determines the content type enum based on document characteristics
  ContentType _determineContentTypeEnum(Document document, String url) {
    final uri = Uri.parse(url);

    // Check URL for obvious patterns
    if (url.contains('product') || url.contains('/p/')) {
      return ContentType.product;
    }

    if (url.contains('video') ||
        url.contains('youtube.com/watch') ||
        url.contains('vimeo.com/')) {
      return ContentType.video;
    }

    if (url.contains('audio') ||
        url.contains('podcast') ||
        url.contains('soundcloud.com')) {
      return ContentType.audio;
    }

    if (url.contains('gallery') || url.contains('photos')) {
      return ContentType.gallery;
    }

    if (url.contains('profile') ||
        url.contains('user') ||
        url.contains('/u/')) {
      return ContentType.profile;
    }

    if (url.contains('event')) {
      return ContentType.event;
    }

    if (uri.path == '' || uri.path == '/') {
      return ContentType.homepage;
    }

    if (url.contains('search') || uri.queryParameters.containsKey('q')) {
      return ContentType.search;
    }

    // Check meta tags and structured data for clues
    final ogType =
        HtmlParser.extractMetaContent(document, 'meta[property="og:type"]');
    if (ogType != null) {
      if (ogType == 'article') return ContentType.article;
      if (ogType == 'product') return ContentType.product;
      if (ogType == 'video') return ContentType.video;
      if (ogType == 'profile') return ContentType.profile;
    }

    // Check for common elements
    if (document.querySelector('article') != null) {
      return ContentType.article;
    }

    if (document.querySelector('video') != null) {
      return ContentType.video;
    }

    if (document.querySelector('audio') != null) {
      return ContentType.audio;
    }

    // Default to article as most content on the web is article-like
    return ContentType.article;
  }

  /// Determines the content type string based on document characteristics
  String? _determineContentType(
    Document document,
    String url,
    Map<String, dynamic>? structuredData,
  ) {
    // First, check OpenGraph type
    final ogType =
        HtmlParser.extractMetaContent(document, 'meta[property="og:type"]');
    if (ogType != null && ogType.isNotEmpty) {
      return ogType;
    }

    // Check structured data for type
    if (structuredData != null) {
      final type = structuredData['@type'];
      if (type != null) {
        if (type is String) {
          return type;
        } else if (type is List && type.isNotEmpty) {
          return type.first.toString();
        }
      }
    }

    // Map content type enum to string
    final contentTypeEnum = _determineContentTypeEnum(document, url);
    return contentTypeEnum.name;
  }

  /// Creates an instance with a shared cache
  static Future<MetadataExtractor> withSharedCache({
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
    Future<MetadataCache>? Function()? customCache,
    String? proxyUrl,
  }) async {
    final cache = customCache != null
        ? await customCache()
        : await MetadataCacheFactory.getSharedInstance();

    return MetadataExtractor(
      client: client,
      cache: cache,
      timeout: timeout,
      userAgent: userAgent,
      cacheEnabled: true,
      followRedirects: followRedirects,
      optimizeUrls: optimizeUrls,
      maxRedirects: maxRedirects,
      analyzeImages: analyzeImages,
      extractStructuredData: extractStructuredData,
      extractSocialMetrics: extractSocialMetrics,
      analyzeContent: analyzeContent,
      proxyUrl: proxyUrl,
    );
  }

  /// Closes the HTTP client and other resources
  void dispose() {
    _client.close();
    _urlOptimizer.dispose();
    _imageAnalyzer.dispose();
  }
}
