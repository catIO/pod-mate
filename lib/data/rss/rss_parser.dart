import 'package:xml/xml.dart';

import 'feed_models.dart';

class RssParser {
  const RssParser();

  static const _itunesNamespace = 'http://www.itunes.com/dtds/podcast-1.0.dtd';

  /// Throws [FormatException] if [source] is not a well-formed RSS 2.0 feed.
  ParsedFeed parse(String source) {
    final XmlDocument document;
    try {
      document = XmlDocument.parse(source);
    } on XmlException catch (e) {
      throw FormatException('Invalid XML: ${e.message}');
    }

    final root = document.rootElement;
    final channel = root.getElement('channel');
    if (root.name.local != 'rss' || channel == null) {
      throw const FormatException('Not an RSS feed');
    }

    final title = _text(channel, 'title') ?? _itunesText(channel, 'title');
    if (title == null) {
      throw const FormatException('Feed has no title');
    }

    return ParsedFeed(
      title: title,
      author: _itunesText(channel, 'author'),
      description:
          _text(channel, 'description') ?? _itunesText(channel, 'summary'),
      artworkUrl:
          _itunesImage(channel) ?? _text(channel.getElement('image'), 'url'),
      episodes: channel
          .findElements('item')
          .map(_parseItem)
          .whereType<ParsedEpisode>()
          .toList(),
    );
  }

  // Items without a playable enclosure are skipped.
  ParsedEpisode? _parseItem(XmlElement item) {
    final audioUrl = _blankToNull(
      item.getElement('enclosure')?.getAttribute('url'),
    );
    if (audioUrl == null) return null;

    final pubDate = _text(item, 'pubDate');
    final duration = _itunesText(item, 'duration');
    return ParsedEpisode(
      guid: _text(item, 'guid') ?? audioUrl,
      title: _text(item, 'title') ?? _itunesText(item, 'title') ?? 'Untitled',
      audioUrl: audioUrl,
      description: _text(item, 'description') ?? _itunesText(item, 'summary'),
      duration: duration == null ? null : parseItunesDuration(duration),
      pubDate: pubDate == null ? null : parseRssDate(pubDate),
      artworkUrl: _itunesImage(item),
    );
  }

  String? _text(XmlElement? parent, String name) =>
      _blankToNull(parent?.getElement(name)?.innerText);

  // Matches by prefix as well, since some feeds declare the namespace URI with different casing.
  XmlElement? _itunesElement(XmlElement parent, String name) {
    for (final element in parent.childElements) {
      if (element.name.local != name) continue;
      final uri = element.name.namespaceUri?.toLowerCase();
      if (uri == _itunesNamespace || element.name.prefix == 'itunes') {
        return element;
      }
    }
    return null;
  }

  String? _itunesText(XmlElement parent, String name) =>
      _blankToNull(_itunesElement(parent, name)?.innerText);

  String? _itunesImage(XmlElement parent) =>
      _blankToNull(_itunesElement(parent, 'image')?.getAttribute('href'));

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Parses `itunes:duration` values such as `3600`, `3600.5`, `62:03` or `1:02:03`.
Duration? parseItunesDuration(String value) {
  final parts = value.trim().split(':');
  if (parts.length > 3) return null;

  var totalSeconds = 0.0;
  for (final part in parts) {
    final number = double.tryParse(part);
    if (number == null || number < 0) return null;
    totalSeconds = totalSeconds * 60 + number;
  }
  return Duration(milliseconds: (totalSeconds * 1000).round());
}

final _rfc822 = RegExp(
  r'^(?:[A-Za-z]+,?\s*)?(\d{1,2})\s+([A-Za-z]+)\s+(\d{2,4})\s+'
  r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*([A-Za-z]+|[+-]\d{4})?$',
);

const _months = {
  'jan': 1,
  'feb': 2,
  'mar': 3,
  'apr': 4,
  'may': 5,
  'jun': 6,
  'jul': 7,
  'aug': 8,
  'sep': 9,
  'oct': 10,
  'nov': 11,
  'dec': 12,
};

const _zoneOffsetHours = {
  'gmt': 0,
  'ut': 0,
  'utc': 0,
  'z': 0,
  'est': -5,
  'edt': -4,
  'cst': -6,
  'cdt': -5,
  'mst': -7,
  'mdt': -6,
  'pst': -8,
  'pdt': -7,
};

/// Parses RFC 822 `pubDate` values leniently, falling back to ISO 8601. Returns UTC.
DateTime? parseRssDate(String value) {
  final trimmed = value.trim();
  final match = _rfc822.firstMatch(trimmed);
  if (match == null) return DateTime.tryParse(trimmed)?.toUtc();

  final monthName = match[2]!.toLowerCase();
  final month = _months[monthName.length >= 3 ? monthName.substring(0, 3) : ''];
  if (month == null) return null;

  var year = int.parse(match[3]!);
  if (year < 100) year += year < 50 ? 2000 : 1900;

  final local = DateTime.utc(
    year,
    month,
    int.parse(match[1]!),
    int.parse(match[4]!),
    int.parse(match[5]!),
    int.parse(match[6] ?? '0'),
  );
  return local.subtract(_zoneOffset(match[7]));
}

Duration _zoneOffset(String? zone) {
  if (zone == null) return Duration.zero;
  if (zone.startsWith('+') || zone.startsWith('-')) {
    final sign = zone.startsWith('-') ? -1 : 1;
    final hours = int.parse(zone.substring(1, 3));
    final minutes = int.parse(zone.substring(3, 5));
    return Duration(minutes: sign * (hours * 60 + minutes));
  }
  return Duration(hours: _zoneOffsetHours[zone.toLowerCase()] ?? 0);
}
