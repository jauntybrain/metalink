// lib/src/models/link_metadata.dart

import 'dart:convert';

import 'content_analysis.dart';
import 'image_metadata.dart';
import 'social_engagement.dart';

/// Extension to add URI conversion to String
extension StringUriExtension on String {
  /// Converts this string to a [Uri]
  Uri get toUri => Uri.parse(this);
}

/// Represents comprehensive metadata extracted from a URL
class LinkMetadata {
  /// Creates a new instance of [LinkMetadata]
  LinkMetadata({
    required this.originalUrl,
    required this.finalUrl,
    this.title,
    this.description,
    this.imageMetadata,
    this.videoUrl,
    this.audioUrl,
    this.siteName,
    this.favicon,
    this.keywords = const [],
    this.author,
    this.publishedTime,
    this.modifiedTime,
    this.contentType,
    this.locale,
    this.structuredData,
    this.socialEngagement,
    this.contentAnalysis,
    this.extractionDurationMs,
  });

  /// Creates an instance from a JSON map
  factory LinkMetadata.fromJson(Map<String, dynamic> json) {
    return LinkMetadata(
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageMetadata: json['imageMetadata'] != null
          ? ImageMetadata.fromJson(
              json['imageMetadata'] as Map<String, dynamic>)
          : null,
      videoUrl: json['videoUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      siteName: json['siteName'] as String?,
      originalUrl: json['originalUrl'] as String,
      finalUrl: json['finalUrl'] as String,
      favicon: json['favicon'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      author: json['author'] as String?,
      publishedTime: json['publishedTime'] != null
          ? DateTime.parse(json['publishedTime'] as String)
          : null,
      modifiedTime: json['modifiedTime'] != null
          ? DateTime.parse(json['modifiedTime'] as String)
          : null,
      contentType: json['contentType'] as String?,
      locale: json['locale'] as String?,
      structuredData: json['structuredData'] as Map<String, dynamic>?,
      socialEngagement: json['socialEngagement'] != null
          ? SocialEngagement.fromJson(
              json['socialEngagement'] as Map<String, dynamic>)
          : null,
      contentAnalysis: json['contentAnalysis'] != null
          ? ContentAnalysis.fromJson(
              json['contentAnalysis'] as Map<String, dynamic>)
          : null,
      extractionDurationMs: json['extractionDurationMs'] as int?,
    );
  }

  /// Creates an instance from a JSON string
  factory LinkMetadata.fromJsonString(String jsonString) {
    return LinkMetadata.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// The title of the page
  final String? title;

  /// The description or summary of the page
  final String? description;

  /// Metadata for the primary image
  final ImageMetadata? imageMetadata;

  /// URL of the primary video, if any
  final String? videoUrl;

  /// URL of the primary audio, if any
  final String? audioUrl;

  /// Name of the site or publisher
  final String? siteName;

  /// The URL that was originally provided
  final String originalUrl;

  /// The final URL after following redirects
  final String finalUrl;

  /// URL of the site's favicon
  final String? favicon;

  /// List of keywords or tags
  final List<String> keywords;

  /// Author of the content
  final String? author;

  /// When the content was first published
  final DateTime? publishedTime;

  /// When the content was last modified
  final DateTime? modifiedTime;

  /// Content type (article, product, video, etc.)
  final String? contentType;

  /// Content locale (e.g., 'en-US', 'fr-FR')
  final String? locale;

  /// Structured data extracted from the page (JSON-LD, etc.)
  final Map<String, dynamic>? structuredData;

  /// Social media engagement metrics
  final SocialEngagement? socialEngagement;

  /// Content analysis results
  final ContentAnalysis? contentAnalysis;

  /// Duration of the extraction process in milliseconds
  final int? extractionDurationMs;

  /// Creates a copy of this instance with the specified attributes
  LinkMetadata copyWith({
    String? title,
    String? description,
    ImageMetadata? imageMetadata,
    String? videoUrl,
    String? audioUrl,
    String? siteName,
    String? originalUrl,
    String? finalUrl,
    String? favicon,
    List<String>? keywords,
    String? author,
    DateTime? publishedTime,
    DateTime? modifiedTime,
    String? contentType,
    String? locale,
    Map<String, dynamic>? structuredData,
    SocialEngagement? socialEngagement,
    ContentAnalysis? contentAnalysis,
    int? extractionDurationMs,
  }) {
    return LinkMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      imageMetadata: imageMetadata ?? this.imageMetadata,
      videoUrl: videoUrl ?? this.videoUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      siteName: siteName ?? this.siteName,
      originalUrl: originalUrl ?? this.originalUrl,
      finalUrl: finalUrl ?? this.finalUrl,
      favicon: favicon ?? this.favicon,
      keywords: keywords ?? this.keywords,
      author: author ?? this.author,
      publishedTime: publishedTime ?? this.publishedTime,
      modifiedTime: modifiedTime ?? this.modifiedTime,
      contentType: contentType ?? this.contentType,
      locale: locale ?? this.locale,
      structuredData: structuredData ?? this.structuredData,
      socialEngagement: socialEngagement ?? this.socialEngagement,
      contentAnalysis: contentAnalysis ?? this.contentAnalysis,
      extractionDurationMs: extractionDurationMs ?? this.extractionDurationMs,
    );
  }

  /// Returns true if the metadata includes an image
  bool get hasImage => imageMetadata?.imageUrl != null;

  /// Returns true if the metadata includes a video
  bool get hasVideo => videoUrl != null;

  /// Returns true if the metadata includes audio
  bool get hasAudio => audioUrl != null;

  /// Returns the hostname of the final URL
  String get hostname => finalUrl.toUri.host;

  /// Returns true if the original URL was redirected to a different URL
  bool get urlWasRedirected => originalUrl != finalUrl;

  /// Returns the final URL with a trailing slash removed, if present
  String get finalUrlNormalized {
    if (finalUrl.endsWith('/')) {
      return finalUrl.substring(0, finalUrl.length - 1);
    }
    return finalUrl;
  }

  /// Returns a normalized title with common suffixes removed
  String get normalizedTitle {
    if (title == null) return '';

    // Remove common website suffixes
    final suffixPattern = RegExp(r'\s[-|]\s.*$');
    return title!.replaceFirst(suffixPattern, '').trim();
  }

  /// Returns a summary of the metadata for debugging purposes
  String get summary {
    return '''
URL: $finalUrl
Title: $title
Description: ${description?.substring(0, description!.length > 100 ? 100 : description!.length)}...
Has Image: $hasImage
Has Video: $hasVideo
Site Name: $siteName
''';
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'imageMetadata': imageMetadata?.toJson(),
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'siteName': siteName,
      'originalUrl': originalUrl,
      'finalUrl': finalUrl,
      'favicon': favicon,
      'keywords': keywords,
      'author': author,
      'publishedTime': publishedTime?.toIso8601String(),
      'modifiedTime': modifiedTime?.toIso8601String(),
      'contentType': contentType,
      'locale': locale,
      'structuredData': structuredData,
      'socialEngagement': socialEngagement?.toJson(),
      'contentAnalysis': contentAnalysis?.toJson(),
      'extractionDurationMs': extractionDurationMs,
    };
  }

  /// Converts this instance to a JSON string
  String toJsonString() => jsonEncode(toJson());

  @override
  String toString() {
    return 'LinkMetadata(title: $title, finalUrl: $finalUrl, hasImage: $hasImage)';
  }
}
