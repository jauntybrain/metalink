// test/core/url_optimizer_test.dart

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:metalink/src/core/url_optimizer.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'url_optimizer_test.mocks.dart';

void main() {
  group('UrlOptimizer', () {
    late MockClient mockClient;
    late UrlOptimizer optimizer;

    setUp(() {
      mockClient = MockClient();
      optimizer = UrlOptimizer(
        client: mockClient,
        followRedirects: true,
        maxRedirects: 3,
        timeout: const Duration(seconds: 5),
      );
    });

    test('optimize normalizes URLs', () async {
      // Just a URL with no redirects
      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse('https://example.com')),
        );
      });

      // Test with various URL formats
      final result1 = await optimizer.optimize('example.com');
      expect(result1.originalUrl, 'example.com');
      expect(result1.finalUrl, 'https://example.com');

      final result2 = await optimizer.optimize('https://example.com/');
      expect(result2.originalUrl, 'https://example.com/');
      expect(result2.finalUrl, 'https://example.com');

      final result3 = await optimizer.optimize('https://example.com');
      expect(result3.originalUrl, 'https://example.com');
      expect(result3.finalUrl, 'https://example.com');
    });

    test('optimize handles protocol-relative URLs', () async {
      // Setup mock for protocol-relative URL redirect
      when(mockClient.send(argThat(predicate((http.BaseRequest request) =>
              request.url.toString() == 'https://example.com'))))
          .thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          301,
          request: http.Request('HEAD', Uri.parse('https://example.com')),
          headers: {'location': '//cdn.example.com/resource'},
        );
      });

      when(mockClient.send(argThat(predicate((http.BaseRequest request) =>
              request.url.toString() == 'https://cdn.example.com/resource'))))
          .thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request(
              'HEAD', Uri.parse('https://cdn.example.com/resource')),
        );
      });

      final result = await optimizer.optimize('https://example.com');

      expect(result.originalUrl, 'https://example.com');
      expect(result.finalUrl, 'https://cdn.example.com/resource');
      expect(result.redirectCount, 1);
    });

    test('optimize handles relative URLs', () async {
      // Setup mock for relative URL redirect
      when(mockClient.send(argThat(predicate((http.BaseRequest request) =>
              request.url.toString() == 'https://example.com/page'))))
          .thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          301,
          request: http.Request('HEAD', Uri.parse('https://example.com/page')),
          headers: {'location': '/new-page'},
        );
      });

      when(mockClient.send(argThat(predicate((http.BaseRequest request) =>
              request.url.toString() == 'https://example.com/new-page'))))
          .thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request:
              http.Request('HEAD', Uri.parse('https://example.com/new-page')),
        );
      });

      final result = await optimizer.optimize('https://example.com/page');

      expect(result.originalUrl, 'https://example.com/page');
      expect(result.finalUrl, 'https://example.com/new-page');
      expect(result.redirectCount, 1);
    });

    test('optimize removes tracking parameters', () async {
      // URL with tracking parameters but no redirects
      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          200,
          request: http.Request('HEAD', Uri.parse('https://example.com')),
        );
      });

      const urlWithTracking =
          'https://example.com?utm_source=test&utm_medium=email&utm_campaign=newsletter&fbclid=123';
      final result = await optimizer.optimize(urlWithTracking);

      expect(result.originalUrl, urlWithTracking);
      expect(result.finalUrl, 'https://example.com');
    });

    test('optimize handles network errors', () async {
      when(mockClient.send(any)).thenThrow(Exception('Network error'));

      final result = await optimizer.optimize('https://example.com');

      expect(result.originalUrl, 'https://example.com');
      expect(result.finalUrl, 'https://example.com');
      expect(result.error, isNotNull);
      expect(result.isSuccessful, isFalse);
    });

    test('optimize respects followRedirects flag', () async {
      // Create optimizer with followRedirects = false
      final noRedirectOptimizer = UrlOptimizer(
        client: mockClient,
        followRedirects: false,
        timeout: const Duration(seconds: 5),
      );

      // Should ignore redirect response
      when(mockClient.send(any)).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(utf8.encode('')),
          301,
          request: http.Request('HEAD', Uri.parse('https://example.com')),
          headers: {'location': 'https://www.example.com'},
        );
      });

      final result = await noRedirectOptimizer.optimize('https://example.com');

      expect(result.originalUrl, 'https://example.com');
      expect(result.finalUrl, 'https://example.com');
      expect(result.redirectCount, 0);
      expect(result.wasRedirected, isFalse);
    });

    test('dispose closes client', () {
      optimizer.dispose();
      verify(mockClient.close()).called(1);
    });
  });
}
