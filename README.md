# MetaLink

A comprehensive URL metadata extraction package for Dart, providing rich link previews with image manipulation capabilities.

## Features

- **Rich Metadata Extraction**: Title, description, images, site name, and more
- **Smart Image URL Analysis**: Detect CDNs and their capabilities
- **Image URL Manipulation**: Generate resized versions of images
- **URL Optimization**: Handle redirects and clean tracking parameters
- **Caching**: Built-in memory and persistent caching
- **Domain-Specific Handling**: Optimized extraction for popular sites
- **Structure Data Support**: Extract JSON-LD and structured data
- **Content Analysis**: Detect content type, reading time, and more
- **Social Engagement**: Extract social metrics (optional)
- **Flexible and Configurable**: Customize behavior as needed

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  metalink: ^0.1.0
```

## Quick Usage

```dart
import 'package:metalink/metalink.dart';

void main() async {
  // Quick, one-time extraction
  final metadata = await SimpleMetaLink.extract('https://example.com');
  
  print('Title: ${metadata.title}');
  print('Description: ${metadata.description}');
  
  if (metadata.hasImage) {
    print('Image URL: ${metadata.imageMetadata?.imageUrl}');
  }
}
```

## Advanced Usage

### Creating a MetaLink Instance

For more control and repeated usage, create a MetaLink instance:

```dart
// Without caching
final metalink = MetaLink.create(
  timeout: Duration(seconds: 15),
  analyzeImages: true,
  extractStructuredData: true,
);

// With caching
final cachedMetalink = await MetaLink.createWithCache(
  cacheDuration: Duration(hours: 24),
  analyzeImages: true,
);
```

### Extracting Metadata

```dart
final metadata = await metalink.extract('https://example.com');

// Display basic information
print('Title: ${metadata.title}');
print('Description: ${metadata.description}');
print('Site Name: ${metadata.siteName}');

// Check if URL was redirected
if (metadata.urlWasRedirected) {
  print('Redirected from ${metadata.originalUrl} to ${metadata.finalUrl}');
}

// Working with images
if (metadata.hasImage) {
  final image = metadata.imageMetadata!;
  print('Image URL: ${image.imageUrl}');
  
  if (image.canResize) {
    // Generate a smaller version
    print('Resized URL: ${image.generateUrl(width: 600)}');
  }
}

// Don't forget to dispose when done
metalink.dispose();
```

### Extracting Multiple URLs

```dart
final urls = [
  'https://example.com',
  'https://example.org',
  'https://example.net',
];

final results = await metalink.extractMultiple(
  urls,
  concurrentRequests: 5,
);

for (final metadata in results) {
  print('${metadata.finalUrl}: ${metadata.title}');
}
```

### Working with Images

```dart
// Analyze an image URL
final imageMetadata = await metalink.analyzeImage(
  'https://example.com/image.jpg',
);

// Check manipulation capabilities
if (imageMetadata.canResizeWidth) {
  print('Image can be resized!');
  
  // Generate different sizes
  final smallUrl = imageMetadata.generateUrl(width: 400);
  final mediumUrl = imageMetadata.generateUrl(width: 800);
  final largeUrl = imageMetadata.generateUrl(width: 1200);
  
  print('Small: $smallUrl');
  print('Medium: $mediumUrl');
  print('Large: $largeUrl');
}

// Check CDN information
if (imageMetadata.manipulationCapabilities.cdnType != null) {
  print('CDN Detected: ${imageMetadata.manipulationCapabilities.cdnType}');
}
```

### URL Optimization

```dart
// Optimize a URL (follow redirects, remove tracking parameters)
final result = await metalink.optimizeUrl('https://example.com?utm_source=test');

print('Original URL: ${result.originalUrl}');
print('Final URL: ${result.finalUrl}');
print('Redirect count: ${result.redirectCount}');
```

## Configuration Options

MetaLink provides extensive configuration options:

```dart
final metalink = MetaLink.create(
  // HTTP client options
  timeout: Duration(seconds: 10),
  userAgent: 'My App/1.0',
  
  // URL handling
  followRedirects: true,
  optimizeUrls: true,
  maxRedirects: 5,
  
  // Feature flags
  analyzeImages: true,
  extractStructuredData: true,
  extractSocialMetrics: false,
  analyzeContent: false,
);
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.