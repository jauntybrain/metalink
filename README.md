# MetaLink

[![pub package](https://img.shields.io/pub/v/metalink.svg)](https://pub.dev/packages/metalink)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful, customizable URL metadata extraction library for Dart that provides rich link previews with sophisticated image URL analysis and manipulation capabilities.

## 🚀 Features

- **Rich Metadata Extraction**: Extract comprehensive metadata including title, description, images, site name, and more.
- **Smart Image Analysis**: Automatically detect CDNs and their capabilities, supporting common services like Cloudinary, Imgix, and WordPress.
- **Image URL Manipulation**: Generate optimized versions of images at different sizes and qualities.
- **URL Optimization**: Handle redirects and clean tracking parameters automatically.
- **Domain-Specific Optimizations**: Special handling for popular websites like YouTube, Twitter, Medium, and more.
- **Caching**: Built-in memory and persistent caching using Hive.
- **Content Analysis**: Detect content type, reading time, and more.
- **Pure Dart**: No Flutter dependencies, use in any Dart project.

## 📦 Installation

Add MetaLink to your `pubspec.yaml`:

```yaml
dependencies:
  metalink: ^<LATEST VERSION>
```

Then run:

```bash
dart pub get
```

## 🔍 Quick Start

```dart
import 'package:metalink/metalink.dart';

void main() async {
  // Quick, one-time extraction
  final metadata = await SimpleMetaLink.extract('https://flutter.dev');
  
  print('Title: ${metadata.title}');
  print('Description: ${metadata.description}');
  
  if (metadata.hasImage) {
    print('Image URL: ${metadata.imageMetadata?.imageUrl}');
  }
}
```

## 📚 Usage Examples

### Creating a MetaLink Instance

For repeated use, create a MetaLink instance:

```dart
// Create instance without caching
final metalink = MetaLink.create(
  timeout: Duration(seconds: 15),
  analyzeImages: true,
  extractStructuredData: true,
);

// Create instance with caching
final cachedMetalink = await MetaLink.createWithCache(
  cacheDuration: Duration(hours: 2),
  analyzeImages: true,
);
```

### Extracting URL Metadata

```dart
final metadata = await metalink.extract('https://github.com/flutter/flutter');

// Basic metadata
print('Title: ${metadata.title}');
print('Description: ${metadata.description}');
print('Site Name: ${metadata.siteName}');

// Check if URL was redirected
if (metadata.urlWasRedirected) {
  print('Redirected from ${metadata.originalUrl} to ${metadata.finalUrl}');
}

// Access image data if available
if (metadata.hasImage) {
  final image = metadata.imageMetadata!;
  print('Image URL: ${image.imageUrl}');
  
  if (image.canResize) {
    // Generate resized versions
    print('Medium size: ${image.generateUrl(width: 800)}');
    print('Thumbnail: ${image.generateUrl(width: 200, height: 200)}');
  }
}

// Don't forget to dispose when done
metalink.dispose();
```

### Processing Multiple URLs

```dart
final urls = [
  'https://dart.dev',
  'https://pub.dev',
  'https://medium.com',
];

final results = await metalink.extractMultiple(
  urls,
  concurrentRequests: 3,  // Process 3 URLs in parallel
);

for (final result in results) {
  print('${result.finalUrl}: ${result.title}');
}
```

### Working with Images

```dart
// Analyze an image URL separately
final imageUrl = 'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=1600&q=80';
final imageMetadata = await metalink.analyzeImage(imageUrl);

print('Image URL: ${imageMetadata.imageUrl}');

if (imageMetadata.manipulationCapabilities.cdnType != null) {
  print('CDN: ${imageMetadata.manipulationCapabilities.cdnType}');
}

// Generate different sizes
if (imageMetadata.canResize) {
  final smallUrl = imageMetadata.generateUrl(width: 400);
  final mediumUrl = imageMetadata.generateUrl(width: 800);
  final largeUrl = imageMetadata.generateUrl(width: 1200);
  
  print('Small: $smallUrl');
  print('Medium: $mediumUrl');
  print('Large: $largeUrl');
}

// Generate different qualities
if (imageMetadata.canAdjustQuality) {
  final highQuality = imageMetadata.generateUrl(quality: 90);
  final lowQuality = imageMetadata.generateUrl(quality: 30);
  
  print('High Quality: $highQuality');
  print('Low Quality: $lowQuality');
}
```

### URL Optimization

```dart
// Clean tracking parameters and follow redirects
final result = await metalink.optimizeUrl(
  'https://example.com?utm_source=test&utm_medium=email&fbclid=123'
);

print('Original URL: ${result.originalUrl}');
print('Cleaned URL: ${result.finalUrl}');
print('Redirect count: ${result.redirectCount}');
```

## 🧩 Configuration Options

MetaLink provides comprehensive configuration options:

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

## 📋 Metadata Properties

The `LinkMetadata` class contains a wealth of information:

| Property         | Description                                  |
|------------------|----------------------------------------------|
| `title`          | Page title                                   |
| `description`    | Page description or summary                  |
| `imageMetadata`  | Metadata for the primary image               |
| `videoUrl`       | URL of the primary video (if any)            |
| `audioUrl`       | URL of the primary audio (if any)            |
| `siteName`       | Name of the site or publisher                |
| `originalUrl`    | The URL originally provided                  |
| `finalUrl`       | The final URL after redirects                |
| `favicon`        | URL of the site's favicon                    |
| `keywords`       | List of keywords or tags                     |
| `author`         | Author of the content                        |
| `publishedTime`  | When the content was published               |
| `modifiedTime`   | When the content was last modified           |
| `contentType`    | Content type (article, product, video, etc.) |
| `locale`         | Content locale                               |
| `structuredData` | Structured data extracted from the page      |

## 📊 Image Metadata Properties

The `ImageMetadata` class provides information about images:

| Property                   | Description                                        |
|----------------------------|----------------------------------------------------|
| `imageUrl`                 | The image URL                                      |
| `width`                    | Image width (if available)                         |
| `height`                   | Image height (if available)                        |
| `aspectRatio`              | Image aspect ratio (width/height)                  |
| `manipulationCapabilities` | Information about how the image can be manipulated |
| `dominantColor`            | Dominant color (if detected)                       |
| `alternativeUrls`          | Alternative URLs for the same image                |
| `fileSize`                 | File size in bytes (if available)                  |
| `mimeType`                 | MIME type (if detected)                            |

## 🧠 Architecture

MetaLink is designed with a modular architecture:

- **Core Components**
  - `MetadataExtractor` - The main extraction engine
  - `ImageUrlAnalyzer` - Analyzes and manipulates image URLs
  - `UrlOptimizer` - Handles redirects and URL cleaning
  - `MetadataCache` - Caches extraction results

- **Models**
  - `LinkMetadata` - Contains all extracted information
  - `ImageMetadata` - Image-specific metadata with manipulation capabilities
  - `ContentAnalysis` - Content classification and readability metrics
  - `SocialEngagement` - Social media engagement metrics

- **Utilities**
  - `CdnDetector` - Detects and handles CDN-specific patterns
  - `HtmlParser` - Extracts information from HTML documents
  - `DomainPatterns` - Domain-specific extraction patterns

## 🔧 Extending and Customizing

### Custom HTTP Client

You can provide your own HTTP client for specialized needs:

```dart
import 'package:http/http.dart' as http;

// Create a custom client
final client = http.Client();
// Configure the client as needed...

// Use the custom client with MetaLink
final metalink = MetaLink.create(
  client: client,
);
```

### Custom Caching

You can implement custom caching:

```dart
// Create a custom Box
final box = await Hive.openBox<String>('custom_metadata_cache');

// Create a MetadataCache with the custom box
final cache = MetadataCache(box: box);

// Use the custom cache with MetaLink
final metalink = MetadataExtractor(
  cache: cache,
  cacheEnabled: true,
);
```

## 📱 Flutter Integration

For Flutter applications, consider using the [metalink_flutter](https://pub.dev/packages/metalink_flutter) package, which provides ready-to-use widgets for link previews.

## Web Platform Limitations

When using this package in Flutter Web, browser security policies,
specifically Cross-Origin Resource Sharing ([CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)), restrict direct HTTP requests to external domains.
To work around this limitation, consider the following options:

- **If you control the server**: Enable [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) by configuring the server to include appropriate response headers (e.g., `Access-Control-Allow-Origin: *` or your app’s domain). This allows the browser to permit requests from your Flutter Web app.
- **Alternative**: Set up your server to act as a proxy. Make a direct request from your Flutter Web app to your server, which then fetches the metadata from the external domain and returns it to your app. This bypasses [CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) restrictions entirely, as the request originates server-side.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.
