// lib/src/core/image_url_analyzer.dart

import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/image_metadata.dart';
import '../utils/cdn_detector.dart';

/// A utility class for analyzing and manipulating image URLs
class ImageUrlAnalyzer {
  /// Creates a new instance of [ImageUrlAnalyzer]
  ImageUrlAnalyzer({
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
    this.userAgent,
    this.followRedirects = true,
    this.maxRedirects = 3,
    this.checkDimensions = true,
    this.proxyUrl,
  }) : _client = client ?? http.Client();

  /// HTTP client for making network requests
  final http.Client _client;

  /// Timeout duration for HTTP requests
  final Duration timeout;

  /// Custom user agent to use for HTTP requests
  final String? userAgent;

  /// Whether to follow redirects when analyzing images
  final bool followRedirects;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  /// Whether to check image dimensions when possible
  final bool checkDimensions;

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

  /// Analyzes an image URL and returns detailed metadata
  ///
  /// Parameters:
  /// - [url]: The URL of the image to analyze
  /// - [sourceDomain]: The domain of the page where the image was found
  /// - [fetchHeaders]: Whether to fetch the image headers (helps determine dimensions, etc.)
  Future<ImageMetadata> analyze(
    String imageUrl, {
    String? sourceDomain,
    bool fetchHeaders = true,
  }) async {
    var url = imageUrl;
    // Normalize the URL
    url = _normalizeImageUrl(url);

    // Detect CDN type and manipulation capabilities
    final capabilities = CdnDetector.analyzeImageUrl(url);

    // Initialize metadata
    final metadata = ImageMetadata(
      imageUrl: url,
      manipulationCapabilities: capabilities,
    );

    // If we shouldn't fetch headers, return early
    if (!fetchHeaders) {
      return metadata;
    }

    // Fetch image headers to get more information
    try {
      // If a proxy URL is provided, use it
      final fetchUrl = _applyProxyUrl(url);

      final request = http.Request('HEAD', Uri.parse(fetchUrl));

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
      final response = await http.Response.fromStream(streamedResponse);

      // Extract image information from headers
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        final contentLength = response.headers['content-length'];

        // Update metadata with extracted information
        return metadata.copyWith(
          mimeType: contentType,
          fileSize: contentLength != null ? int.tryParse(contentLength) : null,
        );
      }
    } catch (e) {
      // Ignore errors when fetching headers
    }

    return metadata;
  }

  /// Analyzes multiple image URLs and returns detailed metadata for each
  ///
  /// Parameters:
  /// - [imageUrls]: A list of image URLs to analyze
  /// - [sourceDomain]: The domain of the page where the images were found
  /// - [fetchHeaders]: Whether to fetch the image headers (helps determine dimensions, etc.)
  /// - [concurrentRequests]: Maximum number of concurrent requests to make
  Future<List<ImageMetadata>> analyzeMultiple(
    List<String> imageUrls, {
    String? sourceDomain,
    bool fetchHeaders = true,
    int concurrentRequests = 3,
  }) async {
    if (imageUrls.isEmpty) {
      return [];
    }

    // Use a pool to limit concurrent requests
    final results = <ImageMetadata>[];

    // Process in batches to limit concurrent requests
    for (var i = 0; i < imageUrls.length; i += concurrentRequests) {
      final end = (i + concurrentRequests < imageUrls.length)
          ? i + concurrentRequests
          : imageUrls.length;
      final batch = imageUrls.sublist(i, end);

      // Process batch in parallel
      final batchResults = await Future.wait(
        batch.map((url) => analyze(
              url,
              sourceDomain: sourceDomain,
              fetchHeaders: fetchHeaders,
            )),
      );

      results.addAll(batchResults);
    }

    return results;
  }

  /// Detects image dimensions from the URL if possible
  ///
  /// For example, many image URLs include dimensions in the path or query parameters
  Map<String, int?> detectDimensionsFromUrl(String imageUrl) {
    final uri = Uri.parse(imageUrl);

    // Check query parameters for dimensions
    final queryParams = CdnDetector.analyzeQueryParameters(uri);
    int? width;
    int? height;

    for (final entry in queryParams.entries) {
      if (entry.value.type == ParameterType.width) {
        width = entry.value.intValue;
      } else if (entry.value.type == ParameterType.height) {
        height = entry.value.intValue;
      }
    }

    // If dimensions weren't found in query parameters, check path segments
    if (width == null || height == null) {
      final dimensionInfo = CdnDetector.analyzePathSegments(uri.pathSegments);
      if (dimensionInfo != null) {
        width = dimensionInfo.width ?? width;
        height = dimensionInfo.height ?? height;
      }
    }

    return {
      'width': width,
      'height': height,
    };
  }

  /// Normalizes an image URL
  ///
  /// This method:
  /// - Ensures the URL has a scheme
  /// - Removes unnecessary query parameters
  /// - Adds protocol to protocol-relative URLs
  String _normalizeImageUrl(String u) {
    var url = u;

    // Handle protocol-relative URLs
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Ensure the URL has a scheme
    if (!url.contains('://')) {
      url = 'https://$url';
    }

    // Parse the URL to work with its components
    Uri uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      // If parsing fails, return the original URL
      return url;
    }

    // Remove fragment identifier (the part after #)
    if (uri.hasFragment) {
      uri = uri.removeFragment();
    }

    return uri.toString();
  }

  /// Generates manipulated versions of an image URL based on the provided metadata
  ///
  /// Parameters:
  /// - [metadata]: The image metadata with manipulation capabilities
  /// - [sizes]: List of desired sizes for the image
  ///
  /// Returns a list of URLs for different sizes
  List<String> generateResponsiveImageUrls(
    ImageMetadata metadata, {
    List<Map<String, int>> sizes = const [
      {'width': 320},
      {'width': 640},
      {'width': 1024},
      {'width': 1600},
    ],
  }) {
    if (!metadata.canResizeWidth && !metadata.canResizeHeight) {
      return [metadata.imageUrl];
    }

    final urls = <String>[];

    for (final size in sizes) {
      final width = size['width'];
      final height = size['height'];

      if (width != null || height != null) {
        final url = metadata.generateUrl(
          width: width,
          height: height,
        );

        if (url != metadata.imageUrl && !urls.contains(url)) {
          urls.add(url);
        }
      }
    }

    return urls;
  }

  /// Closes the HTTP client
  void dispose() {
    _client.close();
  }
}
