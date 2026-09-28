import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pod_mate/data/rss/feed_client.dart';

const _feed = '''
<rss version="2.0"><channel><title>Café Talk</title>
<item><title>Ep</title><enclosure url="https://example.com/a.mp3"/></item>
</channel></rss>''';

void main() {
  final feedUrl = Uri.parse('https://example.com/feed.xml');

  test(
    'fetches and parses a feed, decoding UTF-8 when no charset is given',
    () async {
      late http.Request captured;
      final client = FeedClient(
        client: MockClient((request) async {
          captured = request;
          return http.Response.bytes(
            utf8.encode(_feed),
            200,
            headers: {'content-type': 'application/rss+xml'},
          );
        }),
      );

      final feed = await client.fetch(feedUrl);

      expect(captured.url, feedUrl);
      expect(captured.headers['User-Agent'], 'PodMate/0.1');
      expect(feed.title, 'Café Talk');
      expect(feed.episodes.single.audioUrl, 'https://example.com/a.mp3');
    },
  );

  test('respects an explicit charset', () async {
    final client = FeedClient(
      client: MockClient(
        (_) async => http.Response.bytes(
          latin1.encode(_feed),
          200,
          headers: {'content-type': 'text/xml; charset=iso-8859-1'},
        ),
      ),
    );

    expect((await client.fetch(feedUrl)).title, 'Café Talk');
  });

  test('rejects non-http schemes without making a request', () async {
    var called = false;
    final client = FeedClient(
      client: MockClient((_) async {
        called = true;
        return http.Response('', 200);
      }),
    );

    await expectLater(
      client.fetch(Uri.parse('file:///etc/passwd')),
      throwsA(isA<FeedException>()),
    );
    expect(called, isFalse);
  });

  test('throws FeedException on non-200 responses', () async {
    final client = FeedClient(
      client: MockClient((_) async => http.Response('Not found', 404)),
    );

    await expectLater(
      client.fetch(feedUrl),
      throwsA(
        isA<FeedException>().having(
          (e) => e.message,
          'message',
          contains('404'),
        ),
      ),
    );
  });

  test('wraps network errors in FeedException', () async {
    final client = FeedClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );

    await expectLater(client.fetch(feedUrl), throwsA(isA<FeedException>()));
  });

  test('wraps timeouts in FeedException', () async {
    final client = FeedClient(
      client: MockClient((_) async => throw TimeoutException('slow')),
    );

    await expectLater(client.fetch(feedUrl), throwsA(isA<FeedException>()));
  });

  test('propagates FormatException for invalid feeds', () async {
    final client = FeedClient(
      client: MockClient((_) async => http.Response('<html></html>', 200)),
    );

    await expectLater(client.fetch(feedUrl), throwsFormatException);
  });
}
