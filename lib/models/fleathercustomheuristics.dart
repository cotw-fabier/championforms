import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:parchment_delta/parchment_delta.dart';

class YoutubeEmbedInsertRule extends InsertRule {
  const YoutubeEmbedInsertRule();

  @override
  Delta? apply(Delta document, int index, Object data) {
    if (data is! String) return null;

    final iter = DeltaIterator(document);
    final before = iter.skip(index);
    final after = iter.next();

    // Ensure the data is a space and the pattern is present before it
    if (data != ' ' || before == null) return null;

    final beforeText = before.data is String ? before.data as String : '';
    final youtubePattern =
        RegExp(r'!https:\/\/www\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)$');
    final match = youtubePattern.firstMatch(beforeText.trim());
    debugPrint("Match: $match");

    if (match != null) {
      final videoId = match.group(1);
      final url = 'https://www.youtube.com/watch?v=$videoId';
      final thumbUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

      final youtubeEmbedDelta = {
        "insert": {
          "_type": "youtube",
          "_inline": false,
          "url": url,
          "subtitles": "English",
          "language": "en",
          "thumbUrl": thumbUrl
        }
      };

      final delta = Delta()
        ..retain(index - beforeText.length + 1)
        ..delete(beforeText.length + 1)
        ..insert(youtubeEmbedDelta);

      return delta;
    }

    return null;
  }
}
