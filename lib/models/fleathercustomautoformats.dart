import 'dart:convert';

import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:parchment_delta/parchment_delta.dart';

class AutoFormatYoutubeEmbed extends AutoFormat {
  static final _youtubePattern =
      RegExp(r'!https:\/\/www\.youtube\.com\/watch\?v=([a-zA-Z0-9_-]+)$');

  const AutoFormatYoutubeEmbed();

  @override
  AutoFormatResult? apply(
      ParchmentDocument document, int position, String data) {
    // This rule applies to a space inserted after a YouTube URL, so we can ignore everything else.
    if (data != ' ') return null;

    final documentDelta = document.toDelta();
    final iter = DeltaIterator(documentDelta);
    final previous = iter.skip(position);
    // No previous operation means nothing to analyze.
    if (previous == null || previous.data is! String) return null;
    final previousText = previous.data as String;

    // Split text of previous operation in lines and words and take the last word to test.
    final candidate = previousText.split('\n').last.split(' ').last;
    final match = _youtubePattern.firstMatch(candidate);
    if (match == null) return null;

    final videoId = match.group(1);
    final url = 'https://www.youtube.com/watch?v=$videoId';
    final thumbUrl = 'https://img.youtube.com/vi/$videoId/0.jpg';

    final youtubeEmbed = EmbeddableObject("youtube", inline: false, data: {
      "url": url,
      "subtitles": "English",
      "language": "en",
      "thumbUrl": thumbUrl
    });

    /*  final youtubeEmbedDelta = {
      "insert": {
        "_type": "youtube",
        "_inline": false,
        "url": url,
        "subtitles": "English",
        "language": "en",
        "thumbUrl": thumbUrl
      }
    };

    

    final youtubeDelta = Delta.fromJson([youtubeEmbedDelta]); */

    final youtubeEmbedDelta = {
      "_type": "youtube",
      "_inline": false,
      "url": url,
      "subtitles": "English",
      "language": "en",
      "thumbUrl": thumbUrl
    };

/*     /* debugPrint("Position: $position\n Match: ${match.group(0)}");
    debugPrint(
        "Delete positions: ${position - match.group(0)!.length} - $position"); */

    debugPrint("$candidate");
    debugPrint("Candidate Delete Length: ${candidate.length + 1}");
    debugPrint("Delete Start point: ${position - candidate.length}");
    debugPrint("Delete End point: $position");
    debugPrint("Position: $position");
    debugPrint("Document Length: ${document.length}"); */

    final change = Delta()
      ..retain(position - candidate.length)
      ..delete(candidate.length + 1)
      ..insert('\n')
      ..insert(youtubeEmbedDelta)
      ..insert('\n');

    final undo = change.invert(documentDelta);
    document.compose(change, ChangeSource.local);
    //document.delete(position - match.group(0)!.length, position);
    //document.insert(position, youtubeEmbed);

    return AutoFormatResult(
      change: change,
      undo: undo,
      undoPositionCandidate: position - candidate.length + 1,
      selection:
          TextSelection.collapsed(offset: position - candidate.length + 2),
      undoSelection: TextSelection.collapsed(offset: position),
    );
  }
}
