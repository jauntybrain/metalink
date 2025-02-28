// test/core/metadata_extractor_test.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:metalink/metalink.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Generate mocks
@GenerateMocks([http.Client, UrlOptimizer, ImageUrlAnalyzer, MetadataCache])
import 'metadata_extractor_test.mocks.dart';

void main() {
  group('MetadataExtractor', () {
    late MockClient mockClient;
    late MockUrlOptimizer mockUrlOptimizer;
    late MockImageUrlAnalyzer mockImageAnalyzer;
    late MockMetadataCache mockCache;
    late MetadataExtractor extractor;

    setUp(() {
      mockClient = MockClient();
      mockUrlOptimizer = MockUrlOptimizer();
      mockImageAnalyzer = MockImageUrlAnalyzer();
      mockCache = MockMetadataCache();

      extractor = MetadataExtractor(
        client: mockClient,
        urlOptimizer: mockUrlOptimizer,
        imageAnalyzer: mockImageAnalyzer,
        cache: mockCache,
        cacheEnabled: true,
      );
    });

    test('extract returns cached metadata if available', () async {
      const url = 'https://example.com';
      final cachedMetadata = LinkMetadata(
        title: 'Cached Title',
        description: 'Cached Description',
        originalUrl: url,
        finalUrl: url,
      );

      when(mockCache.get(url)).thenAnswer((_) async => cachedMetadata);

      final result = await extractor.extract(url);

      verify(mockCache.get(url)).called(1);
      expect(result, cachedMetadata);
      expect(result.title, 'Cached Title');
      expect(result.description, 'Cached Description');
    });

    test('extract handles URL optimization', () async {
      const originalUrl = 'https://example.com';
      const finalUrl = 'https://example.com/page';

      final optimizationResult = UrlOptimizationResult(
        originalUrl: originalUrl,
        finalUrl: finalUrl,
        response: http.Response(
          '''
          <html lang="">
            <head>
              <title>Example Page</title>
            </head>
            <body>
              <h1>Example</h1>
            </body>
          </html>
          ''',
          200,
          request: http.Request('GET', Uri.parse(finalUrl)),
        ),
        redirectCount: 1,
        optimizationDuration: 100,
      );

      when(mockCache.get(originalUrl)).thenAnswer((_) async => null);
      when(mockUrlOptimizer.optimize(originalUrl))
          .thenAnswer((_) async => optimizationResult);
      when(mockClient.send(any)).thenAnswer((_) async => http.StreamedResponse(
          Stream.value(utf8.encode(optimizationResult.response!.body)), 200));
      when(mockCache.put(any, any)).thenAnswer((_) async {});

      final result = await extractor.extract(originalUrl);

      verify(mockUrlOptimizer.optimize(originalUrl)).called(1);
      expect(result.originalUrl, originalUrl);
      expect(result.finalUrl, finalUrl);
      expect(result.urlWasRedirected, isTrue);
    });

    test('extract handles errors gracefully', () async {
      const url = 'https://example.com';

      when(mockCache.get(url)).thenAnswer((_) async => null);
      when(mockUrlOptimizer.optimize(url))
          .thenThrow(Exception('Network error'));

      final result = await extractor.extract(url);

      expect(result.originalUrl, url);
      expect(result.finalUrl, url);
      expect(result.title, isNull);
      expect(result.description, isNull);
    });

    test('extractMultiple processes URLs in parallel', () async {
      final urls = [
        'https://example.com/1',
        'https://example.com/2',
        'https://example.com/3',
      ];

      final metadata1 = LinkMetadata(
        title: 'Title 1',
        originalUrl: urls[0],
        finalUrl: urls[0],
      );

      final metadata2 = LinkMetadata(
        title: 'Title 2',
        originalUrl: urls[1],
        finalUrl: urls[1],
      );

      final metadata3 = LinkMetadata(
        title: 'Title 3',
        originalUrl: urls[2],
        finalUrl: urls[2],
      );

      when(mockCache.get(urls[0])).thenAnswer((_) async => metadata1);
      when(mockCache.get(urls[1])).thenAnswer((_) async => metadata2);
      when(mockCache.get(urls[2])).thenAnswer((_) async => metadata3);

      final results = await extractor.extractMultiple(urls);

      expect(results.length, 3);
      expect(results[0].title, 'Title 1');
      expect(results[1].title, 'Title 2');
      expect(results[2].title, 'Title 3');
    });

    test('dispose closes resources', () {
      extractor.dispose();
      verify(mockClient.close()).called(1);
      verify(mockUrlOptimizer.dispose()).called(1);
      verify(mockImageAnalyzer.dispose()).called(1);
    });
  });
}
