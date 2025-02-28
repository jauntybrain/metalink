// lib/src/utils/html_parser.dart

import 'dart:convert';

import 'package:dart_helper_utils/dart_helper_utils.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// A utility class for parsing HTML content and extracting metadata
class HtmlParser {
  /// Parses HTML content into a [Document]
  static Document parse(String htmlContent) {
    return html_parser.parse(htmlContent);
  }

  /// Extracts content from a meta tag using a CSS selector
  ///
  /// Returns the content attribute value, or null if not found
  static String? extractMetaContent(Document document, String selector) {
    final elements = document.querySelectorAll(selector);
    if (elements.isNotEmpty) {
      // Check 'content' attribute first (standard for meta tags)
      final contentValue = elements.first.attributes['content'];
      if (contentValue != null && contentValue.isNotEmpty) {
        return contentValue;
      }

      // If no content attribute, try innerText or text content
      final textContent = elements.first.text;
      if (textContent.isNotEmpty) {
        return textContent;
      }
    }
    return null;
  }

  /// Extracts an attribute value from elements selected by a CSS selector
  ///
  /// Returns the attribute value, or null if not found
  static String? extractAttribute(
      Document document, String selector, String attribute) {
    final elements = document.querySelectorAll(selector);
    if (elements.isNotEmpty) {
      final value = elements.first.attributes[attribute];
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  /// Extracts text content from elements selected by a CSS selector
  ///
  /// Returns the text content, or null if not found
  static String? extractText(Document document, String selector) {
    final elements = document.querySelectorAll(selector);
    if (elements.isNotEmpty) {
      final text = elements.first.text;
      if (text.isNotEmptyOrNull) {
        return text.trim();
      }
    }
    return null;
  }

  /// Extracts multiple text values from elements selected by a CSS selector
  ///
  /// Returns a list of text values, or an empty list if none are found
  static List<String> extractMultipleTexts(Document document, String selector) {
    final elements = document.querySelectorAll(selector);
    return elements
        .map((element) => element.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Extracts a title from the document
  ///
  /// Tries multiple common selectors for title content
  static String? extractTitle(Document document) {
    // Try OpenGraph title
    var title = extractMetaContent(document, 'meta[property="og:title"]');

    // Try Twitter title
    if (title == null || title.isEmpty) {
      title = extractMetaContent(document, 'meta[name="twitter:title"]');
    }

    // Try standard meta title
    if (title == null || title.isEmpty) {
      title = extractMetaContent(document, 'meta[name="title"]');
    }

    // Try standard HTML title tag
    if (title == null || title.isEmpty) {
      title = extractText(document, 'title');
    }

    // Try standard heading tags
    if (title == null || title.isEmpty) {
      title = extractText(document, 'h1');
    }

    // Try schema.org attributes
    if (title == null || title.isEmpty) {
      title = extractAttribute(document, '[itemprop="headline"]', 'content');
      if (title == null || title.isEmpty) {
        title = extractText(document, '[itemprop="headline"]');
      }
    }

    // Clean up the title if found
    if (title != null && title.isNotEmpty) {
      // Remove common site name suffixes
      final suffixPattern = RegExp(r'\s[-|]\s.*$');
      title = title.replaceFirst(suffixPattern, '').trim();
    }

    return title;
  }

  /// Extracts a description from the document
  ///
  /// Tries multiple common selectors for description content
  static String? extractDescription(Document document) {
    // Try OpenGraph description
    var description =
        extractMetaContent(document, 'meta[property="og:description"]');

    // Try Twitter description
    if (description == null || description.isEmpty) {
      description =
          extractMetaContent(document, 'meta[name="twitter:description"]');
    }

    // Try standard meta description
    if (description == null || description.isEmpty) {
      description = extractMetaContent(document, 'meta[name="description"]');
    }

    // Try schema.org attributes
    if (description == null || description.isEmpty) {
      description =
          extractAttribute(document, '[itemprop="description"]', 'content');
      if (description == null || description.isEmpty) {
        description = extractText(document, '[itemprop="description"]');
      }
    }

    // Try first paragraph
    if (description == null || description.isEmpty) {
      final paragraphs = document.querySelectorAll('p');
      for (final p in paragraphs) {
        final text = p.text.trim();
        // Ensure the paragraph is reasonably long to be a description
        if (text.length > 50 && text.length < 500) {
          description = text;
          break;
        }
      }
    }

    return description;
  }

  /// Extracts an image URL from the document
  ///
  /// Tries multiple common selectors for image content
  static String? extractImageUrl(Document document, String baseUrl) {
    // Try OpenGraph image
    var imageUrl = extractMetaContent(document, 'meta[property="og:image"]');

    // Try Twitter image
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = extractMetaContent(document, 'meta[name="twitter:image"]');
    }

    // Try schema.org attributes
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = extractAttribute(document, '[itemprop="image"]', 'content');
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = extractAttribute(document, '[itemprop="image"]', 'src');
      }
    }

    // Try first large image
    if (imageUrl == null || imageUrl.isEmpty) {
      final images = document.querySelectorAll('img');
      for (final img in images) {
        // Skip small icons, spacers, etc.
        final width = img.attributes['width'];
        final height = img.attributes['height'];
        final src = img.attributes['src'];

        // Skip if no src or if it's a data URI (likely a tiny image or icon)
        if (src == null || src.isEmpty || src.startsWith('data:')) {
          continue;
        }

        // Check for images with substantial dimensions
        if (width != null && height != null) {
          final widthValue = int.tryParse(width);
          final heightValue = int.tryParse(height);

          // Consider an image substantial if both dimensions are > 100px
          if (widthValue != null &&
              heightValue != null &&
              widthValue > 100 &&
              heightValue > 100) {
            imageUrl = src;
            break;
          }
        } else {
          // If no dimensions, check for certain keywords in the filename or path
          final srcLower = src.toLowerCase();
          if (!srcLower.contains('icon') &&
              !srcLower.contains('logo') &&
              !srcLower.contains('banner') &&
              !srcLower.contains('avatar')) {
            imageUrl = src;
            break;
          }
        }
      }
    }

    // Resolve relative URLs if necessary
    if (imageUrl != null && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('//')) {
        // Protocol-relative URL
        final uri = Uri.parse(baseUrl);
        imageUrl = '${uri.scheme}:$imageUrl';
      } else if (imageUrl.startsWith('/')) {
        // Absolute path
        final uri = Uri.parse(baseUrl);
        imageUrl = '${uri.scheme}://${uri.host}$imageUrl';
      } else if (!imageUrl.startsWith('http')) {
        // Relative path
        final uri = Uri.parse(baseUrl);
        var basePath = '';
        if (uri.path.isNotEmpty) {
          final segments = uri.path.split('/');
          // Remove the last segment if it's not empty (likely a file)
          if (segments.isNotEmpty && segments.last.isNotEmpty) {
            segments.removeLast();
          }
          basePath = segments.join('/');
          if (!basePath.endsWith('/')) {
            basePath += '/';
          }
        }
        imageUrl = '${uri.scheme}://${uri.host}$basePath$imageUrl';
      }
    }

    return imageUrl;
  }

  /// Extracts a favicon URL from the document
  ///
  /// Tries multiple common selectors for favicon content
  static String? extractFavicon(Document document, String baseUrl) {
    // Try standard favicon link
    var faviconUrl = extractAttribute(
        document, 'link[rel="icon"], link[rel="shortcut icon"]', 'href');

    // Try Apple touch icon
    if (faviconUrl == null || faviconUrl.isEmpty) {
      faviconUrl = extractAttribute(
          document,
          'link[rel="apple-touch-icon"], link[rel="apple-touch-icon-precomposed"]',
          'href');
    }

    // Default to /favicon.ico if nothing else is found
    if (faviconUrl == null || faviconUrl.isEmpty) {
      final uri = Uri.parse(baseUrl);
      faviconUrl = '${uri.scheme}://${uri.host}/favicon.ico';
    } else {
      // Resolve relative URLs if necessary
      if (faviconUrl.startsWith('//')) {
        // Protocol-relative URL
        final uri = Uri.parse(baseUrl);
        faviconUrl = '${uri.scheme}:$faviconUrl';
      } else if (faviconUrl.startsWith('/')) {
        // Absolute path
        final uri = Uri.parse(baseUrl);
        faviconUrl = '${uri.scheme}://${uri.host}$faviconUrl';
      } else if (!faviconUrl.startsWith('http')) {
        // Relative path
        final uri = Uri.parse(baseUrl);
        var basePath = '';
        if (uri.path.isNotEmpty) {
          final segments = uri.path.split('/');
          // Remove the last segment if it's not empty (likely a file)
          if (segments.isNotEmpty && segments.last.isNotEmpty) {
            segments.removeLast();
          }
          basePath = segments.join('/');
          if (!basePath.endsWith('/')) {
            basePath += '/';
          }
        }
        faviconUrl = '${uri.scheme}://${uri.host}$basePath$faviconUrl';
      }
    }

    return faviconUrl;
  }

  /// Extracts the site name from the document
  ///
  /// Tries multiple common selectors for site name content
  static String? extractSiteName(Document document, String baseUrl) {
    // Try OpenGraph site name
    var siteName =
        extractMetaContent(document, 'meta[property="og:site_name"]');

    // Try application name
    if (siteName == null || siteName.isEmpty) {
      siteName = extractMetaContent(document, 'meta[name="application-name"]');
    }

    // If still not found, use the domain name as fallback
    if (siteName == null || siteName.isEmpty) {
      final uri = Uri.parse(baseUrl);
      siteName = uri.host.replaceFirst('www.', '');

      // Try to make the domain name more readable
      final parts = siteName.split('.');
      if (parts.length >= 2) {
        siteName = parts[parts.length - 2].capitalize();
      }
    }

    return siteName;
  }

  /// Extracts keywords or tags from the document
  ///
  /// Returns a list of keywords, or an empty list if none are found
  static List<String> extractKeywords(Document document) {
    // Try standard meta keywords
    final keywordsContent =
        extractMetaContent(document, 'meta[name="keywords"]');
    if (keywordsContent != null && keywordsContent.isNotEmpty) {
      return keywordsContent
          .split(',')
          .map((k) => k.trim())
          .where((k) => k.isNotEmpty)
          .toList();
    }

    // Try article tags
    final tags = extractMultipleTexts(
        document, '.tags a, a.tag, .post-tags a, a[rel="tag"]');
    if (tags.isNotEmpty) {
      return tags;
    }

    return [];
  }

  /// Extracts the author name from the document
  ///
  /// Tries multiple common selectors for author content
  static String? extractAuthor(Document document) {
    // Try standard meta author
    var author = extractMetaContent(document, 'meta[name="author"]');

    // Try OpenGraph article author
    if (author == null || author.isEmpty) {
      author = extractMetaContent(document, 'meta[property="article:author"]');
    }

    // Try schema.org attributes
    if (author == null || author.isEmpty) {
      author = extractAttribute(document, '[itemprop="author"]', 'content');
      if (author == null || author.isEmpty) {
        author = extractText(document, '[itemprop="author"]');
      }
    }

    // Try common author classes
    if (author == null || author.isEmpty) {
      author = extractText(document,
          '.author, .byline, .post-author, .entry-author, [class*="author"]');
    }

    return author;
  }

  /// Extracts a published date from the document
  ///
  /// Tries multiple common selectors for published date content
  /// Returns a [DateTime] object, or null if not found
  static DateTime? extractPublishedDate(Document document) {
    // Try article published time
    var publishedDateStr =
        extractMetaContent(document, 'meta[property="article:published_time"]');

    // Try schema.org attributes
    if (publishedDateStr == null || publishedDateStr.isEmpty) {
      publishedDateStr =
          extractAttribute(document, '[itemprop="datePublished"]', 'content');
      if (publishedDateStr == null || publishedDateStr.isEmpty) {
        publishedDateStr = extractText(document, '[itemprop="datePublished"]');
      }
    }

    // Try common date classes
    if (publishedDateStr == null || publishedDateStr.isEmpty) {
      publishedDateStr = extractText(document,
          '.published, .post-date, .entry-date, .date, time[datetime]');
    }

    // Try time element's datetime attribute
    if (publishedDateStr == null || publishedDateStr.isEmpty) {
      publishedDateStr = extractAttribute(document, 'time', 'datetime');
    }

    // Parse the date string if found
    if (publishedDateStr != null && publishedDateStr.isNotEmpty) {
      // Try various date formats
      final date = _parseDateTime(publishedDateStr);
      if (date != null) {
        return date;
      }
    }

    return null;
  }

  /// Extracts a modified date from the document
  ///
  /// Tries multiple common selectors for modified date content
  /// Returns a [DateTime] object, or null if not found
  static DateTime? extractModifiedDate(Document document) {
    // Try article modified time
    var modifiedDateStr =
        extractMetaContent(document, 'meta[property="article:modified_time"]');

    // Try schema.org attributes
    if (modifiedDateStr == null || modifiedDateStr.isEmpty) {
      modifiedDateStr =
          extractAttribute(document, '[itemprop="dateModified"]', 'content');
      if (modifiedDateStr == null || modifiedDateStr.isEmpty) {
        modifiedDateStr = extractText(document, '[itemprop="dateModified"]');
      }
    }

    // Try common date classes
    if (modifiedDateStr == null || modifiedDateStr.isEmpty) {
      modifiedDateStr =
          extractText(document, '.modified, .updated, .update-date');
    }

    // Parse the date string if found
    if (modifiedDateStr != null && modifiedDateStr.isNotEmpty) {
      // Try various date formats
      final date = _parseDateTime(modifiedDateStr);
      if (date != null) {
        return date;
      }
    }

    return null;
  }

  /// Extracts the locale from the document
  ///
  /// Tries multiple common selectors for locale content
  static String? extractLocale(Document document) {
    // Try OpenGraph locale
    var locale = extractMetaContent(document, 'meta[property="og:locale"]');

    // Try HTML lang attribute
    if (locale == null || locale.isEmpty) {
      locale = document.documentElement?.attributes['lang'];
    }

    // Try Content-Language meta tag
    if (locale == null || locale.isEmpty) {
      locale =
          extractMetaContent(document, 'meta[http-equiv="Content-Language"]');
    }

    return locale;
  }

  /// Extracts structured data (JSON-LD) from the document
  ///
  /// Returns a map of structured data, or null if not found
  static Map<String, dynamic>? extractStructuredData(Document document) {
    final jsonLdScripts =
        document.querySelectorAll('script[type="application/ld+json"]');
    if (jsonLdScripts.isEmpty) {
      return null;
    }

    // Collect all JSON-LD objects
    final allData = <Map<String, dynamic>>[];

    for (final script in jsonLdScripts) {
      final content = script.text.trim();
      if (content.isNotEmpty) {
        try {
          final dynamic parsedData = jsonDecode(content);
          if (parsedData is Map<String, dynamic>) {
            allData.add(parsedData);
          } else if (parsedData is List) {
            for (final item in parsedData) {
              if (item is Map<String, dynamic>) {
                allData.add(item);
              }
            }
          }
        } catch (e) {
          // Ignore JSON parsing errors
        }
      }
    }

    // If only one object was found, return it directly
    if (allData.length == 1) {
      return allData.first;
    }

    // If multiple objects were found, merge them by type
    if (allData.isNotEmpty) {
      final result = <String, dynamic>{};

      for (final data in allData) {
        final type = data['@type'];
        if (type != null) {
          // Group by type
          if (type is String) {
            result[type] = data;
          } else if (type is List) {
            for (final t in type) {
              if (t is String) {
                result[t] = data;
              }
            }
          }
        }
      }

      // If no types were found, just return the first object
      if (result.isEmpty && allData.isNotEmpty) {
        return allData.first;
      }

      return result.isNotEmpty ? result : null;
    }

    return null;
  }

  /// Extracts video URL from the document
  ///
  /// Tries multiple common selectors for video content
  static String? extractVideoUrl(Document document) {
    // Try OpenGraph video
    var videoUrl = extractMetaContent(
        document, 'meta[property="og:video"], meta[property="og:video:url"]');

    // Try Twitter player
    if (videoUrl == null || videoUrl.isEmpty) {
      videoUrl = extractMetaContent(document, 'meta[name="twitter:player"]');
    }

    // Try video element
    if (videoUrl == null || videoUrl.isEmpty) {
      final videoElements = document.querySelectorAll('video');
      if (videoElements.isNotEmpty) {
        // First check for source elements
        final sourceElements = videoElements.first.querySelectorAll('source');
        if (sourceElements.isNotEmpty) {
          videoUrl = sourceElements.first.attributes['src'];
        } else {
          // If no source elements, check the video src directly
          videoUrl = videoElements.first.attributes['src'];
        }
      }
    }

    // Try iframe elements (for embedded videos like YouTube, Vimeo, etc.)
    if (videoUrl == null || videoUrl.isEmpty) {
      final iframeElements = document.querySelectorAll('iframe');
      for (final iframe in iframeElements) {
        final src = iframe.attributes['src'];
        if (src != null &&
            (src.contains('youtube.com') ||
                src.contains('youtu.be') ||
                src.contains('vimeo.com') ||
                src.contains('player'))) {
          videoUrl = src;
          break;
        }
      }
    }

    return videoUrl;
  }

  /// Extracts audio URL from the document
  ///
  /// Tries multiple common selectors for audio content
  static String? extractAudioUrl(Document document) {
    // Try audio element
    final audioElements = document.querySelectorAll('audio');
    if (audioElements.isNotEmpty) {
      // First check for source elements
      final sourceElements = audioElements.first.querySelectorAll('source');
      if (sourceElements.isNotEmpty) {
        return sourceElements.first.attributes['src'];
      } else {
        // If no source elements, check the audio src directly
        return audioElements.first.attributes['src'];
      }
    }

    // Try podcast link
    final podcastLink = document
        .querySelector('link[type="application/rss+xml"][rel="alternate"]');
    if (podcastLink != null) {
      return podcastLink.attributes['href'];
    }

    return null;
  }

  /// Helper method to parse a date string into a [DateTime] object
  ///
  /// Tries various common date formats
  static DateTime? _parseDateTime(String dateStr) {
    // Try ISO 8601 format (standard for most metadata)
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // Try common date formats
    final formats = [
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
      // YYYY-MM-DD
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
      // MM/DD/YYYY
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})'),
      // DD.MM.YYYY
      RegExp(
          r'(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{4})'),
      // DD Mon YYYY
    ];

    final now = DateTime.now();

    for (final format in formats) {
      final match = format.firstMatch(dateStr);
      if (match != null) {
        try {
          if (format.pattern.contains('Jan|Feb|Mar')) {
            // Handle "DD Mon YYYY" format
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!;
            final year = int.parse(match.group(3)!);

            final monthMap = {
              'Jan': 1,
              'Feb': 2,
              'Mar': 3,
              'Apr': 4,
              'May': 5,
              'Jun': 6,
              'Jul': 7,
              'Aug': 8,
              'Sep': 9,
              'Oct': 10,
              'Nov': 11,
              'Dec': 12,
            };

            final month = monthMap[monthStr] ?? 1;
            return DateTime(year, month, day);
          } else if (format.pattern.contains(r'(\d{4})-(\d{2})-(\d{2})')) {
            // YYYY-MM-DD
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (format.pattern.contains(r'(\d{2})/(\d{2})/(\d{4})')) {
            // MM/DD/YYYY
            final month = int.parse(match.group(1)!);
            final day = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else if (format.pattern.contains(r'(\d{2})\.(\d{2})\.(\d{4})')) {
            // DD.MM.YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }

    // Try relative time phrases
    if (dateStr.contains('ago')) {
      final match =
          RegExp(r'(\d+)\s+(second|minute|hour|day|week|month|year)s?\s+ago')
              .firstMatch(dateStr);
      if (match != null) {
        try {
          final amount = int.parse(match.group(1)!);
          final unit = match.group(2)!;

          switch (unit) {
            case 'second':
              return now.subtract(Duration(seconds: amount));
            case 'minute':
              return now.subtract(Duration(minutes: amount));
            case 'hour':
              return now.subtract(Duration(hours: amount));
            case 'day':
              return now.subtract(Duration(days: amount));
            case 'week':
              return now.subtract(Duration(days: amount * 7));
            case 'month':
              return DateTime(now.year, now.month - amount, now.day);
            case 'year':
              return DateTime(now.year - amount, now.month, now.day);
          }
        } catch (_) {}
      }
    }

    // If all parsing attempts fail
    return null;
  }
}

/// String extension to add capitalization
extension StringCapitalization on String {
  /// Capitalizes the first letter of this string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
