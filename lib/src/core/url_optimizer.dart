// lib/src/core/url_optimizer.dart

import 'dart:async';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:http/http.dart' as http;

/// A utility class for optimizing and following URL redirects
class UrlOptimizer {
  /// Creates a new instance of [UrlOptimizer]
  UrlOptimizer({
    http.Client? client,
    this.followRedirects = true,
    this.maxRedirects = 5,
    this.timeout = const Duration(seconds: 10),
    this.userAgent,
  }) : _client = client ?? http.Client();

  /// HTTP client for making network requests
  final http.Client _client;

  /// Whether to follow redirects
  final bool followRedirects;

  /// Maximum number of redirects to follow
  final int maxRedirects;

  /// Timeout duration for HTTP requests
  final Duration timeout;

  /// Custom user agent to use for HTTP requests
  final String? userAgent;

  /// Optimizes the given URL and follows redirects if enabled
  ///
  /// Returns the optimized URL and the HTTP response
  Future<UrlOptimizationResult> optimize(String url) async {
    // Normalize the URL
    final normalizedUrl = _normalizeUrl(url);

    // If redirects are not enabled, just return the normalized URL
    if (!followRedirects) {
      return UrlOptimizationResult(
        originalUrl: url,
        finalUrl: normalizedUrl.toUri.toString(),
        response: null,
        redirectCount: 0,
        optimizationDuration: 0,
      );
    }

    // Follow redirects
    final stopwatch = Stopwatch()..start();
    var finalUrl = normalizedUrl;
    http.Response? finalResponse;
    var redirectCount = 0;
    var hasCookieWall = false;

    try {
      // Create a custom request with specified headers
      final request = http.Request('HEAD', Uri.parse(normalizedUrl));

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

      // Check if we've reached our max redirects
      if (redirectCount >= maxRedirects) {
        finalResponse = response;
        return UrlOptimizationResult(
          originalUrl: url,
          finalUrl: finalUrl.toUri.toString(),
          response: finalResponse,
          redirectCount: redirectCount,
          optimizationDuration: stopwatch.elapsedMilliseconds,
          hasCookieWall: hasCookieWall,
          notes: 'Maximum redirect count reached',
        );
      }

      // Check for redirect status codes
      if (response.statusCode >= 300 && response.statusCode < 400) {
        final location = response.headers['location'];
        if (location != null && location.isNotEmpty) {
          redirectCount++;

          // Resolve relative URLs
          var nextUrl = location;
          if (location.startsWith('/')) {
            final uri = Uri.parse(finalUrl);
            nextUrl = '${uri.scheme}://${uri.host}$location';
          } else if (!location.startsWith('http')) {
            final baseUri = Uri.parse(finalUrl);
            final baseUrlWithPath = baseUri.resolve('.').toString();
            nextUrl = Uri.parse(baseUrlWithPath).resolve(location).toString();
          }

          // Handle protocol-relative URLs
          if (nextUrl.startsWith('//')) {
            final uri = Uri.parse(finalUrl);
            nextUrl = '${uri.scheme}:$nextUrl';
          }

          // Recursively follow redirects
          final redirectResult = await optimize(nextUrl);
          return UrlOptimizationResult(
            originalUrl: url,
            finalUrl: redirectResult.finalUrl.toUri.toString(),
            response: redirectResult.response,
            redirectCount: redirectCount + redirectResult.redirectCount,
            optimizationDuration: stopwatch.elapsedMilliseconds,
            hasCookieWall: redirectResult.hasCookieWall,
            notes: redirectResult.notes,
          );
        }
      }

      // Check for cookie walls or consent pages
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.contains('text/html')) {
          // Sometimes a 200 response might be a consent page or cookie wall
          // We'd need to examine the content to know for sure
          // For now, just note this possibility
          if (response.body.toLowerCase().contains('cookie') &&
              (response.body.toLowerCase().contains('consent') ||
                  response.body.toLowerCase().contains('accept'))) {
            hasCookieWall = true;
          }
        }
      }

      finalResponse = response;
      finalUrl = response.request?.url.toString() ?? finalUrl;
    } catch (e) {
      return UrlOptimizationResult(
        originalUrl: url,
        finalUrl: normalizedUrl.toUri.toString(),
        response: null,
        redirectCount: redirectCount,
        optimizationDuration: stopwatch.elapsedMilliseconds,
        error: e.toString(),
      );
    } finally {
      stopwatch.stop();
    }

    return UrlOptimizationResult(
      originalUrl: url,
      finalUrl: finalUrl.toUri.toString(),
      response: finalResponse,
      redirectCount: redirectCount,
      optimizationDuration: stopwatch.elapsedMilliseconds,
      hasCookieWall: hasCookieWall,
    );
  }

  /// Normalizes the given URL
  ///
  /// This method:
  /// - Ensures the URL has a scheme
  /// - Removes unnecessary query parameters
  /// - Removes fragment identifiers
  /// - Removes tracking parameters
  /// - Removes UTM parameters
  String _normalizeUrl(String u) {
    var url = u;
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
    uri = uri.removeFragment();

    // Filter out tracking and analytics parameters
    final filteredParams = Map<String, String>.from(uri.queryParameters);

    // Remove common tracking parameters
    _removeTrackingParameters(filteredParams);

    // Rebuild the URI with filtered parameters
    if (filteredParams.isEmpty) {
      // If all parameters were removed, return the URL without query parameters
      return uri.replace(queryParameters: {}).toString();
    } else if (filteredParams.length != uri.queryParameters.length) {
      // If some parameters were removed, return the URL with filtered parameters
      return uri.replace(queryParameters: filteredParams).toString();
    }

    // No parameters were removed, return the URL as is (without the fragment)
    return uri.toString();
  }

  /// Removes common tracking parameters from the query parameters map
  void _removeTrackingParameters(Map<String, String> params) {
    // UTM parameters (Google Analytics)
    final utmParams = [
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_term',
      'utm_content',
      'utm_cid',
      'utm_reader',
      'utm_name',
      'utm_social',
      'utm_social-type',
    ];

    // Facebook tracking parameters
    final fbParams = [
      'fbclid',
      'fb_action_ids',
      'fb_action_types',
      'fb_source',
      'fb_ref',
    ];

    // Google tracking parameters
    final googleParams = [
      'gclid',
      'gclsrc',
      'dclid',
      'gdftrk',
      'gdffi',
    ];

    // Other common tracking parameters
    final otherParams = [
      'referrer',
      'ref',
      'source',
      'origin',
      'mc_cid',
      'mc_eid',
      '_hsenc',
      '_hsmi',
      'ICID',
      'icid',
      'ito',
      'yclid',
      '_openstat',
      'mkt_tok',
      'ga_source',
      'ga_medium',
      'ga_term',
      'ga_content',
      'ga_campaign',
    ];

    // Combined list of parameters to remove
    final parametersToRemove = [
      ...utmParams,
      ...fbParams,
      ...googleParams,
      ...otherParams,
    ];

    // Remove all parameters from the list
    for (final param in parametersToRemove) {
      params.remove(param);
    }

    // Also remove any parameter that starts with utm_, fb_, ga_, or _
    params.removeWhere((key, _) =>
        key.startsWith('utm_') ||
        key.startsWith('fb_') ||
        key.startsWith('ga_') ||
        key.startsWith('_'));
  }

  /// Closes the HTTP client
  void dispose() {
    _client.close();
  }
}

/// Result of a URL optimization operation
class UrlOptimizationResult {
  /// Creates a new instance of [UrlOptimizationResult]
  UrlOptimizationResult({
    required this.originalUrl,
    required this.finalUrl,
    required this.response,
    required this.redirectCount,
    required this.optimizationDuration,
    this.error,
    this.hasCookieWall = false,
    this.notes,
  });

  /// The original URL that was provided
  final String originalUrl;

  /// The final URL after optimization and redirection
  final String finalUrl;

  /// The HTTP response from the final URL, if available
  final http.Response? response;

  /// The number of redirects that were followed
  final int redirectCount;

  /// The duration of the optimization process in milliseconds
  final int optimizationDuration;

  /// Error message, if an error occurred
  final String? error;

  /// Whether the URL appears to have a cookie wall
  final bool hasCookieWall;

  /// Additional notes about the optimization process
  final String? notes;

  /// Returns true if the URL was redirected
  bool get wasRedirected => originalUrl != finalUrl;

  /// Returns true if the optimization was successful
  bool get isSuccessful =>
      error == null &&
      (response?.statusCode == 200 || response?.statusCode == null);

  /// Returns true if the URL is reachable
  bool get isReachable => error == null && response != null;

  @override
  String toString() {
    return 'UrlOptimizationResult(originalUrl: $originalUrl, finalUrl: $finalUrl, '
        'redirectCount: $redirectCount, successful: $isSuccessful)';
  }
}
