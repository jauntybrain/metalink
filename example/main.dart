// ignore_for_file: avoid_print
import 'package:metalink/metalink.dart';

void main() async {
  // Simple, one-time extraction
  print('===== Simple Extraction =====');
  final metadata = await SimpleMetaLink.extract('https://flutter.dev');

  print('Title: ${metadata.title}');
  print('Description: ${metadata.description}');

  if (metadata.hasImage) {
    print('Image URL: ${metadata.imageMetadata?.imageUrl}');
    print('Can Adjust Quality: ${metadata.imageMetadata?.canAdjustQuality}');
  }

  // Simple, one-time extraction
  print('===== Simple Extraction =====');
  final googleMapsMetadata =
      await SimpleMetaLink.extract('https://maps.app.goo.gl/Z8tSQT966fuGg17K9');

  print('Title: ${googleMapsMetadata.title}');
  print('Description: ${googleMapsMetadata.description}');

  if (googleMapsMetadata.hasImage) {
    print('Image URL: ${googleMapsMetadata.imageMetadata?.imageUrl}');
    print(
        'Can Adjust Quality: ${googleMapsMetadata.imageMetadata?.canAdjustQuality}');
  }

  print('\n===== Advanced Usage =====');

  // Create a reusable instance with caching
  final metalink = await MetaLink.createWithCache(
    cacheDuration: const Duration(hours: 2),
    analyzeImages: true,
    extractStructuredData: true,
    analyzeContent: true,
  );

  try {
    // Extract metadata for a URL
    final githubMetadata =
        await metalink.extract('https://github.com/flutter/flutter');

    // Display comprehensive information
    print('Title: ${githubMetadata.title}');
    print('Description: ${githubMetadata.description}');
    print('Site Name: ${githubMetadata.siteName}');
    print('Favicon: ${githubMetadata.favicon}');

    // Show author and publication information
    if (githubMetadata.author != null) {
      print('Author: ${githubMetadata.author}');
    }

    if (githubMetadata.publishedTime != null) {
      print('Published: ${githubMetadata.publishedTime}');
    }

    // Display content analysis
    if (githubMetadata.contentAnalysis != null) {
      final analysis = githubMetadata.contentAnalysis!;
      print('Content Type: ${analysis.contentType}');
      print('Word Count: ${analysis.wordCount}');
      print('Reading Time: ${analysis.readingTime}');
    }

    // Work with images
    if (githubMetadata.hasImage) {
      final image = githubMetadata.imageMetadata!;
      print('\nImage Information:');
      print('URL: ${image.imageUrl}');

      if (image.width != null && image.height != null) {
        print('Dimensions: ${image.width}x${image.height}');
      }

      if (image.fileSize != null) {
        print('Size: ${(image.fileSize! / 1024).toStringAsFixed(2)} KB');
      }

      if (image.canResize) {
        print('\nImage can be resized!');

        // Generate different sizes
        final smallUrl = image.generateUrl(width: 400);
        final mediumUrl = image.generateUrl(width: 800);

        print('Small (400px): $smallUrl');
        print('Medium (800px): $mediumUrl');
      }
    }

    // Handle multiple URLs
    print('\n===== Multiple URLs =====');
    final urls = [
      'https://dart.dev',
      'https://pub.dev',
      'https://medium.com',
    ];

    final results = await metalink.extractMultiple(
      urls,
      concurrentRequests: 3,
    );

    for (final result in results) {
      print('${result.finalUrl}: ${result.title}');
    }

    // Analyze an image separately
    print('\n===== Image Analysis =====');
    const imageUrl =
        'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1600&q=80';
    final imageMetadata = await metalink.analyzeImage(imageUrl);

    print('Image URL: ${imageMetadata.imageUrl}');

    if (imageMetadata.manipulationCapabilities.cdnType != null) {
      print('CDN: ${imageMetadata.manipulationCapabilities.cdnType?.name}');
    }

    if (imageMetadata.canAdjustQuality) {
      print(
          'Quality parameter: ${imageMetadata.manipulationCapabilities.qualityParameterName}');
      print('High quality: ${imageMetadata.generateUrl(quality: 90)}');
      print('Low quality: ${imageMetadata.generateUrl(quality: 30)}');
    }

    // Optimize a URL
    print('\n===== URL Optimization =====');
    final optimizeResult = await metalink.optimizeUrl(
        'https://example.com?utm_source=test&utm_medium=example&ref=12345');

    print('Original URL: ${optimizeResult.originalUrl}');
    print('Cleaned URL: ${optimizeResult.finalUrl}');
  } finally {
    // Don't forget to dispose when done
    metalink.dispose();
  }
}
