import 'dart:convert';

import 'package:http/http.dart' as http;

import 'feed_models.dart';
import 'rss_parser.dart';

class FeedException implements Exception {
  const FeedException(this.message);

  final String message;

  @override
  String toString() => 'FeedException: $message';
}

class FeedClient {
  FeedClient({http.Client? client, this._parser = const RssParser()})
    : _client = client ?? http.Client();

  final http.Client _client;
  final RssParser _parser;

  static const _timeout = Duration(seconds: 20);

  /// Throws [FeedException] for network or HTTP failures, [FormatException] for unparseable feeds.
  Future<ParsedFeed> fetch(Uri url) async {
    if (url.scheme != 'https' && url.scheme != 'http') {
      throw const FeedException('Feed URL must start with http:// or https://');
    }

    final http.Response response;
    try {
      response = await _client
          .get(url, headers: const {'User-Agent': 'PodMate/0.1'})
          .timeout(_timeout);
    } on Exception catch (e) {
      throw FeedException('Could not reach feed: $e');
    }

    if (response.statusCode != 200) {
      throw FeedException('Feed returned HTTP ${response.statusCode}');
    }

    return _parser.parse(_decodeBody(response));
  }

  // package:http falls back to Latin-1 without a charset, but feeds are overwhelmingly UTF-8.
  String _decodeBody(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.toLowerCase().contains('charset=')) return response.body;
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  void close() => _client.close();
}
