import 'package:flutter/material.dart';

abstract class Embed {
  Widget build(BuildContext context, Map<String, dynamic> data);
  String get type;
}

class YoutubeEmbed implements Embed {
  @override
  Widget build(BuildContext context, Map<String, dynamic> data) {
    final url = data['url'];
    final thumbUrl = data['thumbUrl'];
    final subtitles = data['subtitles'];
    final language = data['language'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          if (thumbUrl != null)
            Image.network(thumbUrl, width: 300, height: 169, fit: BoxFit.cover),
          Text(
            'Language: $language',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            'Subtitles: $subtitles',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          TextButton(
            onPressed: () => {}, // _launchUrl(url),
            child: Text('Watch on YouTube'),
          ),
        ],
      ),
    );
  }

  @override
  String get type => 'youtube';
}
