class ParsedFeed {
  const ParsedFeed({
    required this.title,
    required this.episodes,
    this.author,
    this.description,
    this.artworkUrl,
  });

  final String title;
  final String? author;
  final String? description;
  final String? artworkUrl;
  final List<ParsedEpisode> episodes;
}

class ParsedEpisode {
  const ParsedEpisode({
    required this.guid,
    required this.title,
    required this.audioUrl,
    this.description,
    this.duration,
    this.pubDate,
    this.artworkUrl,
  });

  final String guid;
  final String title;
  final String audioUrl;
  final String? description;
  final Duration? duration;
  final DateTime? pubDate;
  final String? artworkUrl;
}
