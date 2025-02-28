// lib/src/utils/domain_patterns.dart

/// A utility class for working with domain-specific patterns
class DomainPatterns {
  /// Map of domains to their known metadata patterns
  static final Map<String, DomainMetadataPattern> domainPatterns = {
    'youtube.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractVideoId: true,
      extractChannelInfo: true,
    ),
    'vimeo.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractVideoId: true,
    ),
    'twitter.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractTweetId: true,
      extractAuthorInfo: true,
    ),
    'medium.com': DomainMetadataPattern(
      titleSelector: 'meta[name="title"]',
      descriptionSelector: 'meta[name="description"]',
      imageSelector: 'meta[property="og:image"]',
      extractAuthorInfo: true,
      extractPublishedDate: true,
    ),
    'github.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractRepoInfo: true,
      extractLanguageInfo: true,
    ),
    'amazon.com': DomainMetadataPattern(
      titleSelector: '#productTitle',
      descriptionSelector: '#productDescription',
      imageSelector: '#landingImage',
      extractProductInfo: true,
      extractPriceInfo: true,
    ),
    'linkedin.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractProfileInfo: true,
    ),
    'instagram.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractAuthorInfo: true,
    ),
    'pinterest.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractPinInfo: true,
    ),
    'reddit.com': DomainMetadataPattern(
      titleSelector: 'meta[property="og:title"]',
      descriptionSelector: 'meta[property="og:description"]',
      imageSelector: 'meta[property="og:image"]',
      extractSubredditInfo: true,
      extractAuthorInfo: true,
    ),
    // Additional domains can be added as needed
  };

  /// Gets the domain pattern for the given domain
  ///
  /// Returns a default pattern if the domain does not have a specific pattern
  static DomainMetadataPattern getPatternForDomain(String domain) {
    // Normalize the domain by removing www. prefix and extracting the base domain
    final normalizedDomain = _normalizeDomain(domain);

    // Check for exact domain match
    if (domainPatterns.containsKey(normalizedDomain)) {
      return domainPatterns[normalizedDomain]!;
    }

    // Check for domain endings (e.g., example.medium.com should match medium.com)
    for (final entry in domainPatterns.entries) {
      if (normalizedDomain.endsWith('.${entry.key}')) {
        return entry.value;
      }
    }

    // Return a default pattern if no match is found
    return DomainMetadataPattern();
  }

  /// Normalizes a domain by removing www. prefix
  static String _normalizeDomain(String d) {
    var domain = d;
    domain = domain.toLowerCase();
    if (domain.startsWith('www.')) {
      domain = domain.substring(4);
    }
    return domain;
  }
}

/// Represents metadata extraction patterns for a specific domain
class DomainMetadataPattern {
  /// Creates a new instance of [DomainMetadataPattern]
  DomainMetadataPattern({
    this.titleSelector =
        'meta[property="og:title"], meta[name="twitter:title"], meta[name="title"], title',
    this.descriptionSelector =
        'meta[property="og:description"], meta[name="twitter:description"], meta[name="description"]',
    this.imageSelector =
        'meta[property="og:image"], meta[name="twitter:image"]',
    this.faviconSelector = 'link[rel="icon"], link[rel="shortcut icon"]',
    this.siteNameSelector = 'meta[property="og:site_name"]',
    this.keywordsSelector = 'meta[name="keywords"]',
    this.authorSelector =
        'meta[name="author"], meta[property="article:author"]',
    this.publishedDateSelector = 'meta[property="article:published_time"]',
    this.modifiedDateSelector = 'meta[property="article:modified_time"]',
    this.localeSelector = 'meta[property="og:locale"]',
    this.extractVideoId = false,
    this.extractChannelInfo = false,
    this.extractTweetId = false,
    this.extractAuthorInfo = false,
    this.extractPublishedDate = false,
    this.extractRepoInfo = false,
    this.extractLanguageInfo = false,
    this.extractProductInfo = false,
    this.extractPriceInfo = false,
    this.extractProfileInfo = false,
    this.extractPinInfo = false,
    this.extractSubredditInfo = false,
  });

  /// CSS selector for the title
  final String titleSelector;

  /// CSS selector for the description
  final String descriptionSelector;

  /// CSS selector for the image
  final String imageSelector;

  /// CSS selector for the favicon
  final String faviconSelector;

  /// CSS selector for the site name
  final String siteNameSelector;

  /// CSS selector for keywords or tags
  final String keywordsSelector;

  /// CSS selector for the author
  final String authorSelector;

  /// CSS selector for the published date
  final String publishedDateSelector;

  /// CSS selector for the modified date
  final String modifiedDateSelector;

  /// CSS selector for the locale
  final String localeSelector;

  /// Whether to extract video ID information
  final bool extractVideoId;

  /// Whether to extract channel information (for video sites)
  final bool extractChannelInfo;

  /// Whether to extract tweet ID information
  final bool extractTweetId;

  /// Whether to extract author information
  final bool extractAuthorInfo;

  /// Whether to extract published date information
  final bool extractPublishedDate;

  /// Whether to extract repository information (for GitHub)
  final bool extractRepoInfo;

  /// Whether to extract programming language information (for GitHub)
  final bool extractLanguageInfo;

  /// Whether to extract product information (for e-commerce)
  final bool extractProductInfo;

  /// Whether to extract price information (for e-commerce)
  final bool extractPriceInfo;

  /// Whether to extract profile information (for social profiles)
  final bool extractProfileInfo;

  /// Whether to extract pin information (for Pinterest)
  final bool extractPinInfo;

  /// Whether to extract subreddit information (for Reddit)
  final bool extractSubredditInfo;
}
