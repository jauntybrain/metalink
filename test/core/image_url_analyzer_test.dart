// test/core/image_url_analyzer_test.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:metalink/metalink.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'image_url_analyzer_test.mocks.dart';

void main() {
  group('ImageUrlAnalyzer', () {
    late MockClient mockClient;
    late ImageUrlAnalyzer analyzer;

    setUp(() {
      mockClient = MockClient();
      analyzer = ImageUrlAnalyzer(
        client: mockClient,
        timeout: const Duration(seconds: 5),
        followRedirects: true,
        maxRedirects: 3,
        checkDimensions: true,
      );
    });

    test('analyze detects Cloudinary URLs', () async {
      const imageUrl =
          'https://res.cloudinary.com/demo/image/upload/w_300,h_200,c_crop/sample.jpg';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
            'content-length': '12345',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      expect(metadata.imageUrl, imageUrl);
      expect(metadata.manipulationCapabilities.cdnType, CdnType.cloudinary);
      expect(metadata.manipulationCapabilities.canAdjustWidth, isTrue);
      expect(metadata.manipulationCapabilities.canAdjustHeight, isTrue);
      expect(metadata.manipulationCapabilities.canAdjustQuality, isTrue);
      expect(metadata.manipulationCapabilities.manipulationStrategy,
          ImageManipulationStrategy.cdnSpecific);
      expect(metadata.mimeType, 'image/jpeg');
      expect(metadata.fileSize, 12345);
    });

    test('analyze detects width and height parameters in URL', () async {
      const imageUrl = 'https://example.com/image.jpg?w=800&h=600';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      expect(metadata.manipulationCapabilities.canAdjustWidth, isTrue);
      expect(metadata.manipulationCapabilities.canAdjustHeight, isTrue);
      expect(metadata.manipulationCapabilities.widthParameterName, 'w');
      expect(metadata.manipulationCapabilities.heightParameterName, 'h');
      expect(metadata.manipulationCapabilities.manipulationStrategy,
          ImageManipulationStrategy.queryParameters);
    });

    test('analyze detects dimension patterns in URL path', () async {
      const imageUrl = 'https://example.com/800x600/image.jpg';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      expect(metadata.manipulationCapabilities.canAdjustWidth, isTrue);
      expect(metadata.manipulationCapabilities.canAdjustHeight, isTrue);
      expect(metadata.manipulationCapabilities.manipulationStrategy,
          ImageManipulationStrategy.pathSegments);
    });

    test('analyze detects WordPress image patterns', () async {
      const imageUrl =
          'https://example.com/wp-content/uploads/2023/01/image-300x200.jpg';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      expect(metadata.manipulationCapabilities.cdnType, CdnType.wordpress);
      expect(metadata.manipulationCapabilities.canAdjustWidth, isTrue);
      expect(metadata.manipulationCapabilities.canAdjustHeight, isTrue);
    });

    test('analyze normalizes image URLs', () async {
      final urls = [
        '//example.com/image.jpg',
        'example.com/image.jpg',
        'https://example.com/image.jpg#fragment'
      ];

      for (final url in urls) {
        when(mockClient.send(any)).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('')),
            200,
            request: http.Request('HEAD',
                Uri.parse(url.startsWith('http') ? url : 'https://$url')),
            headers: {
              'content-type': 'image/jpeg',
            },
          );
        });

        final metadata = await analyzer.analyze(url);

        expect(metadata.imageUrl, startsWith('https://'));
        expect(metadata.imageUrl, isNot(contains('#')));
      }
    });

    test('generateUrl creates resized image URLs', () async {
      const imageUrl = 'https://example.com/image.jpg?width=800&height=600';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      // Test query parameter manipulation
      final resizedUrl400 = metadata.generateUrl(width: 400);
      expect(resizedUrl400, contains('width=400'));

      final resizedUrl200 = metadata.generateUrl(width: 200, height: 150);
      expect(resizedUrl200, contains('width=200'));
      expect(resizedUrl200, contains('height=150'));
    });

    test('analyzeMultiple processes multiple URLs', () async {
      final imageUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
        'https://example.com/image3.jpg',
      ];

      for (final url in imageUrls) {
        when(mockClient.send(argThat(predicate(
                (http.BaseRequest request) => request.url.toString() == url))))
            .thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('')),
            200,
            request: http.Request('HEAD', Uri.parse(url)),
            headers: {
              'content-type': 'image/jpeg',
            },
          );
        });
      }

      final results = await analyzer.analyzeMultiple(imageUrls);

      expect(results.length, 3);
      expect(results[0].imageUrl, imageUrls[0]);
      expect(results[1].imageUrl, imageUrls[1]);
      expect(results[2].imageUrl, imageUrls[2]);
    });

    test('generateResponsiveImageUrls creates responsive image set', () async {
      const imageUrl =
          'https://res.cloudinary.com/demo/image/upload/sample.jpg';

      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse(imageUrl)),
          headers: {
            'content-type': 'image/jpeg',
          },
        );
      });

      final metadata = await analyzer.analyze(imageUrl);

      final responsiveUrls = analyzer.generateResponsiveImageUrls(
        metadata,
        sizes: [
          {'width': 320},
          {'width': 640},
          {'width': 1024},
        ],
      );

      expect(responsiveUrls.length, 3);
      expect(responsiveUrls[0], contains('w_320'));
      expect(responsiveUrls[1], contains('w_640'));
      expect(responsiveUrls[2], contains('w_1024'));
    });

    test('analyze handles network errors gracefully', () async {
      const imageUrl = 'https://example.com/image.jpg';

      when(mockClient.send(any)).thenThrow(Exception('Network error'));

      final metadata = await analyzer.analyze(imageUrl);

      // Should still return basic metadata even if network request fails
      expect(metadata.imageUrl, imageUrl);
      expect(metadata.manipulationCapabilities.manipulationStrategy,
          ImageManipulationStrategy.none);
    });

    test('analyze handles different CDN types', () async {
      final cdnUrls = {
        'https://res.cloudinary.com/demo/image/upload/sample.jpg':
            CdnType.cloudinary,
        'https://example.imgix.net/image.jpg': CdnType.imgix,
        'https://cdn.shopify.com/s/files/1/0000/0000/products/image.jpg':
            CdnType.shopify,
        'https://i.vimeocdn.com/video/12345_640.jpg': CdnType.vimeo,
        'https://images.unsplash.com/photo-12345': CdnType.unsplash,
      };

      for (final entry in cdnUrls.entries) {
        final url = entry.key;
        final expectedCdnType = entry.value;

        when(mockClient.send(argThat(predicate(
                (http.BaseRequest request) => request.url.toString() == url))))
            .thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(utf8.encode('')),
            200,
            request: http.Request('HEAD', Uri.parse(url)),
            headers: {
              'content-type': 'image/jpeg',
            },
          );
        });

        final metadata = await analyzer.analyze(url);

        expect(metadata.manipulationCapabilities.cdnType, expectedCdnType,
            reason: 'Failed to detect CDN type for $url');
      }
    });

    test('dispose closes client', () {
      analyzer.dispose();
      verify(mockClient.close()).called(1);
    });
  });
}
