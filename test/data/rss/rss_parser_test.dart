import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pod_mate/data/rss/rss_parser.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  const parser = RssParser();

  group('RssParser.parse', () {
    test('reads channel metadata with iTunes tags and CDATA', () {
      final feed = parser.parse(_fixture('itunes_feed.xml'));

      expect(feed.title, 'Café Talk');
      expect(feed.author, 'Jane Host');
      expect(feed.description, '<p>Weekly chats about <b>coffee</b>.</p>');
      expect(feed.artworkUrl, 'https://example.com/show.jpg');
    });

    test('parses episodes and skips items without an enclosure', () {
      final episodes = parser.parse(_fixture('itunes_feed.xml')).episodes;

      expect(episodes.map((e) => e.guid), [
        'ep-2',
        'https://example.com/ep1.mp3',
      ]);

      final latest = episodes.first;
      expect(latest.title, 'Episode 2: Espresso');
      expect(latest.audioUrl, 'https://example.com/ep2.mp3');
      expect(latest.description, 'All about espresso.');
      expect(latest.duration, const Duration(hours: 1, minutes: 2, seconds: 3));
      expect(latest.pubDate, DateTime.utc(2026, 9, 8, 11, 30));
      expect(latest.artworkUrl, 'https://example.com/ep2.jpg');
    });

    test('falls back to iTunes title and summary', () {
      final episode = parser.parse(_fixture('itunes_feed.xml')).episodes[1];

      expect(episode.title, 'Episode 1: Beans');
      expect(episode.description, 'Where beans come from.');
      expect(episode.duration, const Duration(minutes: 45));
      expect(episode.pubDate, DateTime.utc(2026, 9, 1, 9));
      expect(episode.artworkUrl, isNull);
    });

    test('handles a minimal feed with <image><url> artwork and odd namespace casing', () {
      final feed = parser.parse(_fixture('minimal_feed.xml'));

      expect(feed.title, 'Minimal Show');
      expect(feed.author, isNull);
      expect(feed.artworkUrl, 'https://example.com/fallback.png');
      expect(
        feed.episodes.single.duration,
        const Duration(minutes: 45, seconds: 30),
      );
      expect(feed.episodes.single.pubDate, isNull);
    });

    test('throws FormatException for malformed XML', () {
      expect(() => parser.parse('<rss><channel>'), throwsFormatException);
    });

    test('throws FormatException for non-RSS XML', () {
      expect(
        () => parser.parse('<feed xmlns="http://www.w3.org/2005/Atom"/>'),
        throwsFormatException,
      );
    });

    test('throws FormatException when the channel has no title', () {
      expect(
        () => parser.parse('<rss version="2.0"><channel></channel></rss>'),
        throwsFormatException,
      );
    });
  });

  group('parseItunesDuration', () {
    test('accepts seconds, MM:SS and HH:MM:SS', () {
      expect(parseItunesDuration('90'), const Duration(seconds: 90));
      expect(parseItunesDuration('90.5'), const Duration(milliseconds: 90500));
      expect(
        parseItunesDuration('05:07'),
        const Duration(minutes: 5, seconds: 7),
      );
      expect(
        parseItunesDuration(' 2:00:01 '),
        const Duration(hours: 2, seconds: 1),
      );
    });

    test('returns null for invalid values', () {
      expect(parseItunesDuration(''), isNull);
      expect(parseItunesDuration('abc'), isNull);
      expect(parseItunesDuration('1:2:3:4'), isNull);
      expect(parseItunesDuration('-5'), isNull);
    });
  });

  group('parseRssDate', () {
    test('parses RFC 822 variants to UTC', () {
      expect(
        parseRssDate('Wed, 02 Oct 2002 13:00:00 GMT'),
        DateTime.utc(2002, 10, 2, 13),
      );
      expect(
        parseRssDate('Wed, 2 Oct 2002 08:00:00 EST'),
        DateTime.utc(2002, 10, 2, 13),
      );
      expect(
        parseRssDate('02 October 2002 15:30 +0230'),
        DateTime.utc(2002, 10, 2, 13),
      );
      expect(
        parseRssDate('Wed, 02 Oct 02 13:00:00 -0000'),
        DateTime.utc(2002, 10, 2, 13),
      );
      expect(
        parseRssDate('Wed, 02 Oct 2002 13:00:00'),
        DateTime.utc(2002, 10, 2, 13),
      );
    });

    test('falls back to ISO 8601', () {
      expect(
        parseRssDate('2026-09-08T13:30:00+02:00'),
        DateTime.utc(2026, 9, 8, 11, 30),
      );
    });

    test('returns null for unparseable dates', () {
      expect(parseRssDate('sometime last week'), isNull);
      expect(parseRssDate('02 Foo 2002 13:00 GMT'), isNull);
    });
  });
}
