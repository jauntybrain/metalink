// lib/src/models/image_metadata.dart

/// Defines the strategy used for image URL manipulation
enum ImageManipulationStrategy {
  /// No manipulation is possible
  none,

  /// Manipulation via query parameters
  queryParameters,

  /// Manipulation via path segments
  pathSegments,

  /// CDN-specific manipulation rules
  cdnSpecific,

  /// Custom manipulation logic
  custom,
}

/// Known CDN types for optimized handling
enum CdnType {
  /// none
  none,

  /// cloudinary
  cloudinary,

  /// imgix
  imgix,

  /// cloudfront
  cloudfront,

  /// akamai
  akamai,

  /// fastly
  fastly,

  /// googleUserContent
  googleUserContent,

  /// wordpress
  wordpress,

  /// shopify
  shopify,

  /// medium
  medium,

  /// youtube
  youtube,

  /// vimeo
  vimeo,

  /// twitter
  twitter,

  /// facebook
  facebook,

  /// instagram
  instagram,

  /// linkedin
  linkedin,

  /// github
  github,

  /// pinterest
  pinterest,

  /// unsplash
  unsplash,

  /// pexels
  pexels,
}

/// Represents the capabilities for manipulating an image URL
class ImageManipulationCapabilities {
  /// Creates a new instance of [ImageManipulationCapabilities]
  const ImageManipulationCapabilities({
    this.canAdjustWidth = false,
    this.canAdjustHeight = false,
    this.canAdjustQuality = false,
    this.widthParameterName,
    this.heightParameterName,
    this.qualityParameterName,
    this.maxWidth,
    this.maxHeight,
    this.maxQuality,
    this.minQuality,
    this.cdnType,
    this.manipulationStrategy = ImageManipulationStrategy.none,
  });

  /// Creates an instance from a JSON map
  factory ImageManipulationCapabilities.fromJson(Map<String, dynamic> json) {
    return ImageManipulationCapabilities(
      canAdjustWidth: json['canAdjustWidth'] as bool? ?? false,
      canAdjustHeight: json['canAdjustHeight'] as bool? ?? false,
      canAdjustQuality: json['canAdjustQuality'] as bool? ?? false,
      widthParameterName: json['widthParameterName'] as String?,
      heightParameterName: json['heightParameterName'] as String?,
      qualityParameterName: json['qualityParameterName'] as String?,
      maxWidth: json['maxWidth'] as int?,
      maxHeight: json['maxHeight'] as int?,
      maxQuality: json['maxQuality'] as int?,
      minQuality: json['minQuality'] as int?,
      cdnType: json['cdnType'] != null
          ? CdnType.values.firstWhere(
              (e) => e.name == json['cdnType'],
              orElse: () => CdnType.none,
            )
          : null,
      manipulationStrategy: json['manipulationStrategy'] != null
          ? ImageManipulationStrategy.values.firstWhere(
              (e) => e.name == json['manipulationStrategy'],
              orElse: () => ImageManipulationStrategy.none,
            )
          : ImageManipulationStrategy.none,
    );
  }

  /// Whether the width can be adjusted
  final bool canAdjustWidth;

  /// Whether the height can be adjusted
  final bool canAdjustHeight;

  /// Whether the quality can be adjusted
  final bool canAdjustQuality;

  /// Parameter name for width adjustment
  final String? widthParameterName;

  /// Parameter name for height adjustment
  final String? heightParameterName;

  /// Parameter name for quality adjustment
  final String? qualityParameterName;

  /// Maximum allowed width
  final int? maxWidth;

  /// Maximum allowed height
  final int? maxHeight;

  /// Maximum allowed quality (usually 100)
  final int? maxQuality;

  /// Minimum allowed quality
  final int? minQuality;

  /// The detected CDN type
  final CdnType? cdnType;

  /// Strategy used for image manipulation
  final ImageManipulationStrategy manipulationStrategy;

  /// Creates a copy of this instance with the specified attributes
  ImageManipulationCapabilities copyWith({
    bool? canAdjustWidth,
    bool? canAdjustHeight,
    bool? canAdjustQuality,
    String? widthParameterName,
    String? heightParameterName,
    String? qualityParameterName,
    int? maxWidth,
    int? maxHeight,
    int? maxQuality,
    int? minQuality,
    CdnType? cdnType,
    ImageManipulationStrategy? manipulationStrategy,
  }) {
    return ImageManipulationCapabilities(
      canAdjustWidth: canAdjustWidth ?? this.canAdjustWidth,
      canAdjustHeight: canAdjustHeight ?? this.canAdjustHeight,
      canAdjustQuality: canAdjustQuality ?? this.canAdjustQuality,
      widthParameterName: widthParameterName ?? this.widthParameterName,
      heightParameterName: heightParameterName ?? this.heightParameterName,
      qualityParameterName: qualityParameterName ?? this.qualityParameterName,
      maxWidth: maxWidth ?? this.maxWidth,
      maxHeight: maxHeight ?? this.maxHeight,
      maxQuality: maxQuality ?? this.maxQuality,
      minQuality: minQuality ?? this.minQuality,
      cdnType: cdnType ?? this.cdnType,
      manipulationStrategy: manipulationStrategy ?? this.manipulationStrategy,
    );
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'canAdjustWidth': canAdjustWidth,
      'canAdjustHeight': canAdjustHeight,
      'canAdjustQuality': canAdjustQuality,
      'widthParameterName': widthParameterName,
      'heightParameterName': heightParameterName,
      'qualityParameterName': qualityParameterName,
      'maxWidth': maxWidth,
      'maxHeight': maxHeight,
      'maxQuality': maxQuality,
      'minQuality': minQuality,
      'cdnType': cdnType?.name,
      'manipulationStrategy': manipulationStrategy.name,
    };
  }
}

/// Represents metadata for an image URL with manipulation capabilities
class ImageMetadata {
  /// Creates a new instance of [ImageMetadata]
  ImageMetadata({
    required this.imageUrl,
    this.width,
    this.height,
    double? aspectRatio,
    this.manipulationCapabilities = const ImageManipulationCapabilities(),
    this.dominantColor,
    this.alternativeUrls = const [],
    this.fileSize,
    this.mimeType,
  }) : aspectRatio = aspectRatio ??
            (width != null && height != null && height > 0
                ? width / height
                : null);

  /// Creates an instance from a JSON map
  factory ImageMetadata.fromJson(Map<String, dynamic> json) {
    return ImageMetadata(
      imageUrl: json['imageUrl'] as String,
      width: json['width'] as int?,
      height: json['height'] as int?,
      aspectRatio: json['aspectRatio'] as double?,
      manipulationCapabilities: json['manipulationCapabilities'] != null
          ? ImageManipulationCapabilities.fromJson(
              json['manipulationCapabilities'] as Map<String, dynamic>)
          : const ImageManipulationCapabilities(),
      dominantColor: json['dominantColor'] as String?,
      alternativeUrls: (json['alternativeUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
    );
  }

  /// The original image URL
  final String imageUrl;

  /// The image width if available
  final int? width;

  /// The image height if available
  final int? height;

  /// The image aspect ratio (width/height) if dimensions are available
  final double? aspectRatio;

  /// The capabilities for manipulating this image URL
  final ImageManipulationCapabilities manipulationCapabilities;

  /// The dominant color of the image, if detected
  final String? dominantColor;

  /// Alternative URLs for the same image (different sizes, etc.)
  final List<String> alternativeUrls;

  /// File size in bytes, if available
  final int? fileSize;

  /// MIME type of the image, if detected
  final String? mimeType;

  /// Creates a copy of this instance with the specified attributes
  ImageMetadata copyWith({
    String? imageUrl,
    int? width,
    int? height,
    double? aspectRatio,
    ImageManipulationCapabilities? manipulationCapabilities,
    String? dominantColor,
    List<String>? alternativeUrls,
    int? fileSize,
    String? mimeType,
  }) {
    return ImageMetadata(
      imageUrl: imageUrl ?? this.imageUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      manipulationCapabilities:
          manipulationCapabilities ?? this.manipulationCapabilities,
      dominantColor: dominantColor ?? this.dominantColor,
      alternativeUrls: alternativeUrls ?? this.alternativeUrls,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  /// Returns true if the image width can be adjusted
  bool get canResizeWidth => manipulationCapabilities.canAdjustWidth;

  /// Returns true if the image height can be adjusted
  bool get canResizeHeight => manipulationCapabilities.canAdjustHeight;

  /// Returns true if the image quality can be adjusted
  bool get canAdjustQuality => manipulationCapabilities.canAdjustQuality;

  /// Returns true if the image can be resized (both width and height)
  bool get canResize => canResizeWidth && canResizeHeight;

  /// Generates a manipulated version of the image URL
  ///
  /// Parameters:
  /// - [width]: The desired width of the image
  /// - [height]: The desired height of the image
  /// - [quality]: The desired quality of the image (0-100)
  String generateUrl({int? width, int? height, int? quality}) {
    if (manipulationCapabilities.manipulationStrategy ==
        ImageManipulationStrategy.none) {
      return imageUrl;
    }

    final uri = Uri.parse(imageUrl);

    return switch (manipulationCapabilities.manipulationStrategy) {
      ImageManipulationStrategy.queryParameters =>
        _generateUrlWithQueryParameters(uri, width, height, quality),
      ImageManipulationStrategy.pathSegments =>
        _generateUrlWithPathSegments(uri, width, height, quality),
      ImageManipulationStrategy.cdnSpecific =>
        _generateUrlWithCdnSpecific(uri, width, height, quality),
      _ => imageUrl,
    };
  }

  /// Generates a URL with manipulated query parameters
  String _generateUrlWithQueryParameters(
      Uri uri, int? width, int? height, int? quality) {
    final queryParams = Map<String, String>.from(uri.queryParameters);

    // Apply width if specified and supported
    if (width != null &&
        manipulationCapabilities.canAdjustWidth &&
        manipulationCapabilities.widthParameterName != null) {
      // Apply max width restriction if specified
      final effectiveWidth = manipulationCapabilities.maxWidth != null
          ? width.clamp(1, manipulationCapabilities.maxWidth!)
          : width;

      queryParams[manipulationCapabilities.widthParameterName!] =
          effectiveWidth.toString();
    }

    // Apply height if specified and supported
    if (height != null &&
        manipulationCapabilities.canAdjustHeight &&
        manipulationCapabilities.heightParameterName != null) {
      // Apply max height restriction if specified
      final effectiveHeight = manipulationCapabilities.maxHeight != null
          ? height.clamp(1, manipulationCapabilities.maxHeight!)
          : height;

      queryParams[manipulationCapabilities.heightParameterName!] =
          effectiveHeight.toString();
    }

    // Apply quality if specified and supported
    if (quality != null &&
        manipulationCapabilities.canAdjustQuality &&
        manipulationCapabilities.qualityParameterName != null) {
      // Apply quality restrictions if specified
      final minQuality = manipulationCapabilities.minQuality ?? 1;
      final maxQuality = manipulationCapabilities.maxQuality ?? 100;
      final effectiveQuality = quality.clamp(minQuality, maxQuality);

      queryParams[manipulationCapabilities.qualityParameterName!] =
          effectiveQuality.toString();
    }

    // Build the new URI
    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Generates a URL with manipulated path segments
  String _generateUrlWithPathSegments(
      Uri uri, int? width, int? height, int? quality) {
    // This is a simplified implementation - in a real-world scenario,
    // this would need to handle various path segment patterns

    // If both width and height are available, we might replace a segment like "100x100"
    if (width != null && height != null) {
      final segments = List<String>.from(uri.pathSegments);

      // Look for a segment matching the pattern NxN
      for (var i = 0; i < segments.length; i++) {
        final match = RegExp(r'^(\d+)x(\d+)$').firstMatch(segments[i]);
        if (match != null) {
          segments[i] = '${width}x$height';
          return uri.replace(pathSegments: segments).toString();
        }
      }
    }

    // If only width is available, we might replace a segment like "w100"
    if (width != null) {
      final segments = List<String>.from(uri.pathSegments);

      // Look for a segment matching the pattern wN
      for (var i = 0; i < segments.length; i++) {
        final match = RegExp(r'^w(\d+)$').firstMatch(segments[i]);
        if (match != null) {
          segments[i] = 'w$width';
          return uri.replace(pathSegments: segments).toString();
        }
      }
    }

    // If only height is available, we might replace a segment like "h100"
    if (height != null) {
      final segments = List<String>.from(uri.pathSegments);

      // Look for a segment matching the pattern hN
      for (var i = 0; i < segments.length; i++) {
        final match = RegExp(r'^h(\d+)$').firstMatch(segments[i]);
        if (match != null) {
          segments[i] = 'h$height';
          return uri.replace(pathSegments: segments).toString();
        }
      }
    }

    // If no pattern was found or no dimension was provided
    return imageUrl;
  }

  /// Generates a URL with CDN-specific manipulations
  String _generateUrlWithCdnSpecific(
      Uri uri, int? width, int? height, int? quality) {
    // CDN-specific logic would go here, based on the detected CDN type
    return switch (manipulationCapabilities.cdnType) {
      CdnType.cloudinary => _generateCloudinaryUrl(uri, width, height, quality),
      CdnType.imgix => _generateImgixUrl(uri, width, height, quality),
      CdnType.wordpress => _generateWordpressUrl(uri, width, height, quality),
      _ => imageUrl,
    };
  }

  /// Generates a Cloudinary-specific URL
  String _generateCloudinaryUrl(
      Uri uri, int? width, int? height, int? quality) {
    // Example implementation for Cloudinary
    final segments = List<String>.from(uri.pathSegments);

    // Find the upload segment index
    final uploadIndex = segments.indexOf('upload');
    if (uploadIndex >= 0 && uploadIndex < segments.length - 1) {
      // Cloudinary format: /upload/[transformations]/[public_id]
      var transformations = '';

      // Add width and height if provided
      if (width != null || height != null) {
        transformations += 'c_fill,';
        if (width != null) transformations += 'w_$width,';
        if (height != null) transformations += 'h_$height,';
      }

      // Add quality if provided
      if (quality != null) {
        transformations += 'q_$quality,';
      }

      // Remove trailing comma
      if (transformations.isNotEmpty) {
        transformations =
            transformations.substring(0, transformations.length - 1);
      }

      // Insert transformations
      if (transformations.isNotEmpty) {
        segments.insert(uploadIndex + 1, transformations);
      }

      return uri.replace(pathSegments: segments).toString();
    }

    return imageUrl;
  }

  /// Generates an Imgix-specific URL
  String _generateImgixUrl(Uri uri, int? width, int? height, int? quality) {
    // Simplified implementation for Imgix
    final queryParams = Map<String, String>.from(uri.queryParameters);

    if (width != null) queryParams['w'] = width.toString();
    if (height != null) queryParams['h'] = height.toString();
    if (quality != null) queryParams['q'] = quality.toString();

    // Add auto=format for better optimization
    queryParams['auto'] = 'format';

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Generates a WordPress-specific URL
  String _generateWordpressUrl(Uri uri, int? width, int? height, int? quality) {
    // WordPress typically uses query parameters or specific paths
    final url = uri.toString();

    // Check if it's already a resized image
    final sizeMatch = RegExp(r'-(\d+)x(\d+)\.[a-zA-Z]+$').firstMatch(url);
    if (sizeMatch != null) {
      // Replace the existing dimensions
      if (width != null && height != null) {
        return url.replaceFirst(RegExp(r'-\d+x\d+\.[a-zA-Z]+$'),
            '-${width}x$height.${uri.pathSegments.last.split('.').last}');
      }
    }

    // If it's not already a resized image or we don't have both dimensions
    final queryParams = Map<String, String>.from(uri.queryParameters);

    if (width != null) queryParams['w'] = width.toString();
    if (height != null) queryParams['h'] = height.toString();
    if (quality != null) queryParams['quality'] = quality.toString();

    return uri.replace(queryParameters: queryParams).toString();
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'width': width,
      'height': height,
      'aspectRatio': aspectRatio,
      'manipulationCapabilities': manipulationCapabilities.toJson(),
      'dominantColor': dominantColor,
      'alternativeUrls': alternativeUrls,
      'fileSize': fileSize,
      'mimeType': mimeType,
    };
  }

  @override
  String toString() {
    return 'ImageMetadata(imageUrl: $imageUrl, width: $width, height: $height, '
        'aspectRatio: $aspectRatio, canResize: $canResize, '
        'canAdjustQuality: $canAdjustQuality)';
  }
}
