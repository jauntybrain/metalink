// lib/src/models/social_engagement.dart

/// Represents social media engagement metrics for a URL
class SocialEngagement {
  /// Creates a new instance of [SocialEngagement]
  SocialEngagement({
    this.likes,
    this.shares,
    this.comments,
    this.totalEngagement,
    this.facebook,
    this.twitter,
    this.linkedin,
    this.pinterest,
    this.reddit,
    this.other,
  });

  /// Creates an instance from a JSON map
  factory SocialEngagement.fromJson(Map<String, dynamic> json) {
    return SocialEngagement(
      likes: json['likes'] as int?,
      shares: json['shares'] as int?,
      comments: json['comments'] as int?,
      totalEngagement: json['totalEngagement'] as int?,
      facebook: json['facebook'] as Map<String, dynamic>?,
      twitter: json['twitter'] as Map<String, dynamic>?,
      linkedin: json['linkedin'] as Map<String, dynamic>?,
      pinterest: json['pinterest'] as Map<String, dynamic>?,
      reddit: json['reddit'] as Map<String, dynamic>?,
      other: json['other'] as Map<String, dynamic>?,
    );
  }

  /// Number of likes or reactions
  final int? likes;

  /// Number of shares or retweets
  final int? shares;

  /// Number of comments
  final int? comments;

  /// Total engagement (sum of likes, shares, and comments)
  final int? totalEngagement;

  /// Facebook engagement metrics
  final Map<String, dynamic>? facebook;

  /// Twitter engagement metrics
  final Map<String, dynamic>? twitter;

  /// LinkedIn engagement metrics
  final Map<String, dynamic>? linkedin;

  /// Pinterest engagement metrics
  final Map<String, dynamic>? pinterest;

  /// Reddit engagement metrics
  final Map<String, dynamic>? reddit;

  /// Additional platform-specific engagement metrics
  final Map<String, dynamic>? other;

  /// Creates a copy of this instance with the specified attributes
  SocialEngagement copyWith({
    int? likes,
    int? shares,
    int? comments,
    int? totalEngagement,
    Map<String, dynamic>? facebook,
    Map<String, dynamic>? twitter,
    Map<String, dynamic>? linkedin,
    Map<String, dynamic>? pinterest,
    Map<String, dynamic>? reddit,
    Map<String, dynamic>? other,
  }) {
    return SocialEngagement(
      likes: likes ?? this.likes,
      shares: shares ?? this.shares,
      comments: comments ?? this.comments,
      totalEngagement: totalEngagement ?? this.totalEngagement,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      pinterest: pinterest ?? this.pinterest,
      reddit: reddit ?? this.reddit,
      other: other ?? this.other,
    );
  }

  /// Converts this instance to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'likes': likes,
      'shares': shares,
      'comments': comments,
      'totalEngagement': totalEngagement,
      'facebook': facebook,
      'twitter': twitter,
      'linkedin': linkedin,
      'pinterest': pinterest,
      'reddit': reddit,
      'other': other,
    };
  }

  @override
  String toString() {
    return 'SocialEngagement(likes: $likes, shares: $shares, comments: $comments, totalEngagement: $totalEngagement)';
  }
}
