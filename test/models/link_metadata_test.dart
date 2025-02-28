// test/models/link_metadata_test.dart

import 'package:metalink/metalink.dart';
import 'package:test/test.dart';

void main() {
  group('LinkMetadata', () {
    test('creates instance with required properties', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
      );

      expect(metadata.originalUrl, 'https://example.com');
      expect(metadata.finalUrl, 'https://example.com');
      expect(metadata.title, isNull);
      expect(metadata.description, isNull);
      expect(metadata.imageMetadata, isNull);
      expect(metadata.hasImage, isFalse);
    });

    test('creates instance with all properties', () {
      final imageMetadata = ImageMetadata(
        imageUrl: 'https://example.com/image.jpg',
        width: 1200,
        height: 800,
      );

      final publishedTime = DateTime(2022, 1, 1);
      final modifiedTime = DateTime(2022, 1, 2);

      final metadata = LinkMetadata(
        title: 'Test Title',
        description: 'Test Description',
        imageMetadata: imageMetadata,
        videoUrl: 'https://example.com/video.mp4',
        audioUrl: 'https://example.com/audio.mp3',
        siteName: 'Example Site',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com/page',
        favicon: 'https://example.com/favicon.ico',
        keywords: ['test', 'example'],
        author: 'Test Author',
        publishedTime: publishedTime,
        modifiedTime: modifiedTime,
        contentType: 'article',
        locale: 'en-US',
        structuredData: {'type': 'Article'},
        extractionDurationMs: 123,
      );

      expect(metadata.title, 'Test Title');
      expect(metadata.description, 'Test Description');
      expect(metadata.imageMetadata, equals(imageMetadata));
      expect(metadata.videoUrl, 'https://example.com/video.mp4');
      expect(metadata.audioUrl, 'https://example.com/audio.mp3');
      expect(metadata.siteName, 'Example Site');
      expect(metadata.originalUrl, 'https://example.com');
      expect(metadata.finalUrl, 'https://example.com/page');
      expect(metadata.favicon, 'https://example.com/favicon.ico');
      expect(metadata.keywords, ['test', 'example']);
      expect(metadata.author, 'Test Author');
      expect(metadata.publishedTime, publishedTime);
      expect(metadata.modifiedTime, modifiedTime);
      expect(metadata.contentType, 'article');
      expect(metadata.locale, 'en-US');
      expect(metadata.structuredData, {'type': 'Article'});
      expect(metadata.extractionDurationMs, 123);
    });

    test('copyWith creates new instance with specified properties', () {
      final metadata = LinkMetadata(
        title: 'Original Title',
        description: 'Original Description',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
      );

      final updatedMetadata = metadata.copyWith(
        title: 'Updated Title',
        description: 'Updated Description',
      );

      expect(updatedMetadata.title, 'Updated Title');
      expect(updatedMetadata.description, 'Updated Description');
      expect(updatedMetadata.originalUrl, 'https://example.com');
      expect(updatedMetadata.finalUrl, 'https://example.com');

      // Original metadata should be unchanged
      expect(metadata.title, 'Original Title');
      expect(metadata.description, 'Original Description');
    });

    test('hasImage returns true when imageMetadata is not null', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
        imageMetadata: ImageMetadata(
          imageUrl: 'https://example.com/image.jpg',
        ),
      );

      expect(metadata.hasImage, isTrue);
    });

    test('hasVideo returns true when videoUrl is not null', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
        videoUrl: 'https://example.com/video.mp4',
      );

      expect(metadata.hasVideo, isTrue);
    });

    test('hasAudio returns true when audioUrl is not null', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
        audioUrl: 'https://example.com/audio.mp3',
      );

      expect(metadata.hasAudio, isTrue);
    });

    test('urlWasRedirected returns true when originalUrl != finalUrl', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com/page',
      );

      expect(metadata.urlWasRedirected, isTrue);
    });

    test('finalUrlNormalized removes trailing slash', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com/',
      );

      expect(metadata.finalUrlNormalized, 'https://example.com');
    });

    test('normalizedTitle removes common suffixes', () {
      final metadata = LinkMetadata(
        title: 'Test Title - Example Site',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
      );

      expect(metadata.normalizedTitle, 'Test Title');
    });

    test('hostname extracts host from finalUrl', () {
      final metadata = LinkMetadata(
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.org/page',
      );

      expect(metadata.hostname, 'example.org');
    });

    test('toJson and fromJson work correctly', () {
      final originalMetadata = LinkMetadata(
        title: 'Test Title',
        description: 'Test Description',
        imageMetadata: ImageMetadata(
          imageUrl: 'https://example.com/image.jpg',
          width: 1200,
          height: 800,
        ),
        videoUrl: 'https://example.com/video.mp4',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com/page',
        publishedTime: DateTime(2022, 1, 1),
      );

      final json = originalMetadata.toJson();
      final recreatedMetadata = LinkMetadata.fromJson(json);

      expect(recreatedMetadata.title, originalMetadata.title);
      expect(recreatedMetadata.description, originalMetadata.description);
      expect(recreatedMetadata.imageMetadata?.imageUrl,
          originalMetadata.imageMetadata?.imageUrl);
      expect(recreatedMetadata.imageMetadata?.width,
          originalMetadata.imageMetadata?.width);
      expect(recreatedMetadata.imageMetadata?.height,
          originalMetadata.imageMetadata?.height);
      expect(recreatedMetadata.videoUrl, originalMetadata.videoUrl);
      expect(recreatedMetadata.originalUrl, originalMetadata.originalUrl);
      expect(recreatedMetadata.finalUrl, originalMetadata.finalUrl);
      expect(recreatedMetadata.publishedTime?.toIso8601String(),
          originalMetadata.publishedTime?.toIso8601String());
    });

    test('toJsonString and fromJsonString work correctly', () {
      final originalMetadata = LinkMetadata(
        title: 'Test Title',
        description: 'Test Description',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com/page',
      );

      final jsonString = originalMetadata.toJsonString();
      final recreatedMetadata = LinkMetadata.fromJsonString(jsonString);

      expect(recreatedMetadata.title, originalMetadata.title);
      expect(recreatedMetadata.description, originalMetadata.description);
      expect(recreatedMetadata.originalUrl, originalMetadata.originalUrl);
      expect(recreatedMetadata.finalUrl, originalMetadata.finalUrl);
    });

    test('summary provides brief overview', () {
      final metadata = LinkMetadata(
        title: 'Test Title',
        description:
            'This is a very long description that should be truncated in the summary output to demonstrate that the summary method works correctly.',
        originalUrl: 'https://example.com',
        finalUrl: 'https://example.com',
        siteName: 'Example Site',
        imageMetadata: ImageMetadata(
          imageUrl: 'https://example.com/image.jpg',
        ),
      );

      final summary = metadata.summary;
      expect(summary, contains('Test Title'));
      expect(summary, contains('This is a very long description'));
      expect(summary, contains('Has Image: true'));
      expect(summary, contains('Site Name: Example Site'));
    });
  });
}
