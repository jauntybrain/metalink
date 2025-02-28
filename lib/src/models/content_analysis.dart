// lib/src/models/content_analysis.dart

/// Content type classification
enum ContentType {
  /// Article or blog post
  article,

  /// Product page
  product,

  /// Video content
  video,

  /// Audio content
  audio,

  /// Image gallery
  gallery,

  /// Profile page
  profile,

  /// Event page
  event,

  /// Home page
  homepage,

  /// Search results
  search,

  /// Error page
  error,

  /// Other or unknown type
  other;
}

/// Content sentiment analysis result
enum ContentSentiment {
  /// Positive sentiment
  positive,

  /// Neutral sentiment
  neutral,

  /// Negative sentiment
  negative,

  /// Mixed sentiment
  mixed,

  /// Unknown sentiment
  unknown,
}

/// Represents content analysis results for a URL
class ContentAnalysis {
  /// Creates a new instance of [ContentAnalysis]
  ContentAnalysis({
    this.contentType,
    this.language,
    this.readingTimeSeconds,
    this.wordCount,
    this.sentiment,
    this.sentimentScore,
    this.qualityScore,
    this.isProbablyPaywalled,
    this.requiresAuthentication,
    this.topics = const [],
    this.entities,
    this.additionalData,
  });

  /// Creates an instance from a JSON map
  factory ContentAnalysis.fromJson(Map<String, dynamic> json) {
    return ContentAnalysis(
      contentType: json['contentType'] != null
          ? ContentType.values.firstWhere(
              (e) => e.name == json['contentType'],
              orElse: () => ContentType.other,
            )
          : null,
      language: json['language'] as String?,
      readingTimeSeconds: json['readingTimeSeconds'] as int?,
      wordCount: json['wordCount'] as int?,
      sentiment: json['sentiment'] != null
          ? ContentSentiment.values.firstWhere(
              (e) => e.name == json['sentiment'],
              orElse: () => ContentSentiment.unknown,
            )
          : null,
      sentimentScore: json['sentimentScore'] as double?,
      qualityScore: json['qualityScore'] as double?,
      isProbablyPaywalled: json['isProbablyPaywalled'] as bool?,
      requiresAuthentication: json['requiresAuthentication'] as bool?,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      entities: (json['entities'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(
          k,
          (v as List<dynamic>).map((e) => e as String).toList(),
        ),
      ),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// The detected content type
  final ContentType? contentType;

  /// The primary language of the content (ISO code)
  final String? language;

  /// Estimated reading time in seconds
  final int? readingTimeSeconds;

  /// Word count of the main content
  final int? wordCount;

  /// Detected content sentiment
  final ContentSentiment? sentiment;

  /// Sentiment score (-1.0 to 1.0, where -1.0 is very negative, 1.0 is very positive)
  final double? sentimentScore;

  /// Estimated content quality score (0.0 to 1.0)
  final double? qualityScore;

  /// Whether the content appears to be behind a paywall
  final bool? isProbablyPaywalled;

  /// Whether the content appears to require authentication
  final bool? requiresAuthentication;

  /// Main topics or categories
  final List<String> topics;

  /// Named entities detected in the content
  final Map<String, List<String>>? entities;

  /// Additional analysis results
  final Map<String, dynamic>? additionalData;

  /// Creates a copy of this instance with the specified attributes
  ContentAnalysis copyWith({
    ContentType? contentType,
    String? language,
    int? readingTimeSeconds,
    int? wordCount,
    ContentSentiment? sentiment,
    double? sentimentScore,
    double? qualityScore,
    bool? isProbablyPaywalled,
    bool? requiresAuthentication,
    List<String>? topics,
    Map<String, List<String>>? entities,
    Map<String, dynamic>? additionalData,
  }) {
    return ContentAnalysis(
      contentType: contentType ?? this.contentType,
      language: language ?? this.language,
      readingTimeSeconds: readingTimeSeconds ?? this.readingTimeSeconds,
      wordCount: wordCount ?? this.wordCount,
      sentiment: sentiment ?? this.sentiment,
      sentimentScore: sentimentScore ?? this.sentimentScore,
      qualityScore: qualityScore ?? this.qualityScore,
      isProbablyPaywalled: isProbablyPaywalled ?? this.isProbablyPaywalled,
      requiresAuthentication:
          requiresAuthentication ?? this.requiresAuthentication,
      topics: topics ?? this.topics,
      entities: entities ?? this.entities,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Estimated reading time as a human-readable string
  String get readingTime {
    if (readingTimeSeconds == null) return 'Unknown';
    final minutes = (readingTimeSeconds! / 60).round();
    if (minutes < 1) return 'Less than a minute';
    if (minutes == 1) return '1 minute';
    return '$minutes minutes';
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'contentType': contentType?.name,
      'language': language,
      'readingTimeSeconds': readingTimeSeconds,
      'wordCount': wordCount,
      'sentiment': sentiment?.name,
      'sentimentScore': sentimentScore,
      'qualityScore': qualityScore,
      'isProbablyPaywalled': isProbablyPaywalled,
      'requiresAuthentication': requiresAuthentication,
      'topics': topics,
      'entities': entities,
      'additionalData': additionalData,
    };
  }

  @override
  String toString() {
    return 'ContentAnalysis(contentType: $contentType, language: $language, wordCount: $wordCount, readingTime: $readingTime)';
  }
}
