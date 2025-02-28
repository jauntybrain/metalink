// lib/src/utils/cdn_detector.dart

import '../models/image_metadata.dart';

/// A utility class for detecting and analyzing CDN patterns in image URLs
class CdnDetector {
  /// Map of CDN types to their regex patterns
  static final Map<CdnType, RegExp> cdnPatterns = {
    CdnType.cloudinary: RegExp(r'res\.cloudinary\.com|cloudinary\.com'),
    CdnType.imgix: RegExp(r'\.imgix\.net'),
    CdnType.wordpress:
        RegExp(r'\.wp\.com|\.wordpress\.com|wp-content\/uploads'),
    CdnType.medium: RegExp(r'miro\.medium\.com'),
    CdnType.youtube: RegExp(r'i\.ytimg\.com|img\.youtube\.com'),
    CdnType.vimeo: RegExp(r'i\.vimeocdn\.com|vimeo\.com'),
    CdnType.twitter: RegExp(r'pbs\.twimg\.com|twitter\.com'),
    CdnType.facebook:
        RegExp(r'fbcdn\.net|facebook\.com|scontent.*\.fbcdn\.net'),
    CdnType.instagram: RegExp(
        r'cdninstagram\.com|instagram\.com|scontent.*\.cdninstagram\.com'),
    CdnType.github: RegExp(r'githubusercontent\.com|github\.com'),
    CdnType.pinterest: RegExp(r'pinimg\.com|pinterest\.com'),
    CdnType.unsplash: RegExp(r'images\.unsplash\.com'),
    CdnType.shopify: RegExp(r'cdn\.shopify\.com'),
    CdnType.pexels: RegExp(r'images\.pexels\.com'),
    CdnType.googleUserContent: RegExp(r'googleusercontent\.com|ggpht\.com'),
    CdnType.cloudfront: RegExp(r'\.cloudfront\.net'),
    CdnType.akamai: RegExp(r'\.akamaized\.net|\.akamai\.net'),
    CdnType.fastly: RegExp(r'\.fastly\.net|\.fastlylb\.net'),
  };

  /// Map of CDN types to their manipulation capabilities
  static final Map<CdnType, ImageManipulationCapabilities> cdnCapabilities = {
    CdnType.cloudinary: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: true,
      canAdjustQuality: true,
      widthParameterName: 'w',
      heightParameterName: 'h',
      qualityParameterName: 'q',
      maxWidth: 5000,
      maxHeight: 5000,
      maxQuality: 100,
      minQuality: 1,
      cdnType: CdnType.cloudinary,
      manipulationStrategy: ImageManipulationStrategy.cdnSpecific,
    ),
    CdnType.imgix: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: true,
      canAdjustQuality: true,
      widthParameterName: 'w',
      heightParameterName: 'h',
      qualityParameterName: 'q',
      maxWidth: 8192,
      maxHeight: 8192,
      maxQuality: 100,
      minQuality: 0,
      cdnType: CdnType.imgix,
      manipulationStrategy: ImageManipulationStrategy.queryParameters,
    ),
    CdnType.wordpress: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: true,
      canAdjustQuality: false,
      widthParameterName: 'w',
      heightParameterName: 'h',
      maxWidth: 2000,
      maxHeight: 2000,
      cdnType: CdnType.wordpress,
      manipulationStrategy: ImageManipulationStrategy.queryParameters,
    ),
    CdnType.youtube: const ImageManipulationCapabilities(
      canAdjustWidth: false,
      canAdjustHeight: false,
      canAdjustQuality: false,
      cdnType: CdnType.youtube,
      manipulationStrategy: ImageManipulationStrategy.none,
    ),
    CdnType.unsplash: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: true,
      canAdjustQuality: true,
      widthParameterName: 'w',
      heightParameterName: 'h',
      qualityParameterName: 'q',
      maxWidth: 5000,
      maxHeight: 5000,
      maxQuality: 100,
      minQuality: 0,
      cdnType: CdnType.unsplash,
      manipulationStrategy: ImageManipulationStrategy.queryParameters,
    ),
    CdnType.shopify: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: false,
      canAdjustQuality: false,
      widthParameterName: 'width',
      maxWidth: 5760,
      cdnType: CdnType.shopify,
      manipulationStrategy: ImageManipulationStrategy.queryParameters,
    ),
    CdnType.medium: const ImageManipulationCapabilities(
      canAdjustWidth: true,
      canAdjustHeight: false,
      canAdjustQuality: false,
      widthParameterName: 'max',
      maxWidth: 2000,
      cdnType: CdnType.medium,
      manipulationStrategy: ImageManipulationStrategy.queryParameters,
    ),
    // Default capabilities for CDNs that don't have specific manipulation patterns
    CdnType.twitter: const ImageManipulationCapabilities(
      canAdjustWidth: false,
      canAdjustHeight: false,
      canAdjustQuality: false,
      cdnType: CdnType.twitter,
      manipulationStrategy: ImageManipulationStrategy.none,
    ),
    // Additional CDN capabilities can be added as needed
  };

  /// Detects the CDN type from the given URL
  ///
  /// Returns [CdnType.none] if no known CDN is detected
  static CdnType detectCdnType(String url) {
    final normalizedUrl = url.toLowerCase();

    for (final entry in cdnPatterns.entries) {
      if (entry.value.hasMatch(normalizedUrl)) {
        return entry.key;
      }
    }

    return CdnType.none;
  }

  /// Gets the default capabilities for the given CDN type
  ///
  /// Returns default capabilities with no manipulation if the CDN type
  /// is not supported or is [CdnType.none]
  static ImageManipulationCapabilities getCapabilitiesForCdnType(
      CdnType cdnType) {
    return cdnCapabilities[cdnType] ??
        ImageManipulationCapabilities(
          cdnType: cdnType,
          manipulationStrategy: ImageManipulationStrategy.none,
        );
  }

  /// Analyzes a URL to determine if it contains query parameters for image manipulation
  ///
  /// Returns a map of parameter types to their information
  static Map<String, ParameterInfo> analyzeQueryParameters(Uri uri) {
    final result = <String, ParameterInfo>{};

    // Common dimension parameter names
    final widthParams = [
      'w',
      'width',
      'wd',
      'wid',
      'maxwidth',
      'max-width',
      'size'
    ];
    final heightParams = [
      'h',
      'height',
      'ht',
      'hgt',
      'maxheight',
      'max-height'
    ];
    final qualityParams = ['q', 'quality', 'qual', 'qlt'];

    for (final entry in uri.queryParameters.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      // Try to convert to integer
      final intValue = int.tryParse(value);
      if (intValue != null) {
        if (widthParams.contains(key)) {
          result[key] = ParameterInfo(
            type: ParameterType.width,
            intValue: intValue,
            originalValue: value,
          );
        } else if (heightParams.contains(key)) {
          result[key] = ParameterInfo(
            type: ParameterType.height,
            intValue: intValue,
            originalValue: value,
          );
        } else if (qualityParams.contains(key)) {
          result[key] = ParameterInfo(
            type: ParameterType.quality,
            intValue: intValue,
            originalValue: value,
          );
        }
      }
    }

    return result;
  }

  /// Analyzes path segments to detect dimension patterns
  ///
  /// Returns dimension information if a pattern is found, or null if no pattern is detected
  static DimensionInfo? analyzePathSegments(List<String> segments) {
    // Look for common dimension patterns in path segments

    // Example: /100x100/image.jpg
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final dimensionMatch = RegExp(r'^(\d+)x(\d+)$').firstMatch(segment);
      if (dimensionMatch != null) {
        return DimensionInfo(
          width: int.parse(dimensionMatch.group(1)!),
          height: int.parse(dimensionMatch.group(2)!),
          segmentIndex: i,
          pattern: DimensionPattern.widthByHeight,
        );
      }
    }

    // Example: /w100/image.jpg or /h100/image.jpg
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];

      final widthMatch = RegExp(r'^w(\d+)$').firstMatch(segment);
      if (widthMatch != null) {
        return DimensionInfo(
          width: int.parse(widthMatch.group(1)!),
          segmentIndex: i,
          pattern: DimensionPattern.widthOnly,
        );
      }

      final heightMatch = RegExp(r'^h(\d+)$').firstMatch(segment);
      if (heightMatch != null) {
        return DimensionInfo(
          height: int.parse(heightMatch.group(1)!),
          segmentIndex: i,
          pattern: DimensionPattern.heightOnly,
        );
      }
    }

    // Example: /size_100x100/image.jpg
    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sizeMatch = RegExp(r'^size[-_](\d+)x(\d+)$').firstMatch(segment);
      if (sizeMatch != null) {
        return DimensionInfo(
          width: int.parse(sizeMatch.group(1)!),
          height: int.parse(sizeMatch.group(2)!),
          segmentIndex: i,
          pattern: DimensionPattern.sizePrefix,
        );
      }
    }

    // WordPress pattern: /2023/01/image-100x100.jpg
    for (var i = 0; i < segments.length; i++) {
      if (i == segments.length - 1) {
        final segment = segments[i];
        final wpMatch =
            RegExp(r'^(.+)-(\d+)x(\d+)\.([a-zA-Z0-9]+)$').firstMatch(segment);
        if (wpMatch != null) {
          return DimensionInfo(
            width: int.parse(wpMatch.group(2)!),
            height: int.parse(wpMatch.group(3)!),
            segmentIndex: i,
            pattern: DimensionPattern.wordpressSuffix,
            originalFilename: '${wpMatch.group(1)!}.${wpMatch.group(4)!}',
          );
        }
      }
    }

    return null;
  }

  /// Analyzes an image URL to determine its manipulation capabilities
  ///
  /// Returns the detected capabilities
  static ImageManipulationCapabilities analyzeImageUrl(String imageUrl) {
    final uri = Uri.parse(imageUrl);
    final cdnType = detectCdnType(imageUrl);

    // If the CDN type is known, use its default capabilities
    if (cdnType != CdnType.none) {
      final capabilities = getCapabilitiesForCdnType(cdnType);

      // If the CDN has specific handling, return its capabilities
      if (capabilities.manipulationStrategy ==
          ImageManipulationStrategy.cdnSpecific) {
        return capabilities;
      }
    }

    // Check for query parameter patterns
    final queryParams = analyzeQueryParameters(uri);
    if (queryParams.isNotEmpty) {
      String? widthParam;
      String? heightParam;
      String? qualityParam;

      for (final entry in queryParams.entries) {
        if (entry.value.type == ParameterType.width) {
          widthParam = entry.key;
        } else if (entry.value.type == ParameterType.height) {
          heightParam = entry.key;
        } else if (entry.value.type == ParameterType.quality) {
          qualityParam = entry.key;
        }
      }

      return ImageManipulationCapabilities(
        canAdjustWidth: widthParam != null,
        canAdjustHeight: heightParam != null,
        canAdjustQuality: qualityParam != null,
        widthParameterName: widthParam,
        heightParameterName: heightParam,
        qualityParameterName: qualityParam,
        cdnType: cdnType,
        manipulationStrategy: ImageManipulationStrategy.queryParameters,
      );
    }

    // Check for path segment patterns
    final pathSegmentInfo = analyzePathSegments(uri.pathSegments);
    if (pathSegmentInfo != null) {
      return ImageManipulationCapabilities(
        canAdjustWidth: pathSegmentInfo.width != null,
        canAdjustHeight: pathSegmentInfo.height != null,
        canAdjustQuality: false,
        cdnType: cdnType,
        manipulationStrategy: ImageManipulationStrategy.pathSegments,
      );
    }

    // No manipulation capabilities detected
    return ImageManipulationCapabilities(
      cdnType: cdnType,
      manipulationStrategy: ImageManipulationStrategy.none,
    );
  }
}

/// Type of parameter in a URL
enum ParameterType {
  /// Width parameter
  width,

  /// Height parameter
  height,

  /// Quality parameter
  quality,

  /// Other parameter type
  other,
}

/// Information about a parameter in a URL
class ParameterInfo {
  /// Creates a new instance of [ParameterInfo]
  ParameterInfo({
    required this.type,
    required this.originalValue,
    this.intValue,
  });

  /// The type of parameter
  final ParameterType type;

  /// The integer value of the parameter, if available
  final int? intValue;

  /// The original value of the parameter as a string
  final String originalValue;
}

/// Pattern of dimension specification in path segments
enum DimensionPattern {
  /// Width by height (e.g., "100x100")
  widthByHeight,

  /// Width only (e.g., "w100")
  widthOnly,

  /// Height only (e.g., "h100")
  heightOnly,

  /// Size prefix (e.g., "size_100x100")
  sizePrefix,

  /// WordPress suffix (e.g., "image-100x100.jpg")
  wordpressSuffix,
}

/// Information about dimensions detected in a URL path segment
class DimensionInfo {
  /// Creates a new instance of [DimensionInfo]
  DimensionInfo({
    required this.segmentIndex,
    required this.pattern,
    this.width,
    this.height,
    this.originalFilename,
  });

  /// The width value, if available
  final int? width;

  /// The height value, if available
  final int? height;

  /// The index of the segment in the path that contains the dimension information
  final int segmentIndex;

  /// The pattern used to specify the dimensions
  final DimensionPattern pattern;

  /// The original filename, for patterns that modify the filename
  final String? originalFilename;
}
