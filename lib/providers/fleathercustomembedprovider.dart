import 'package:championforms/models/fleathercustomembeds.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fleathercustomembedprovider.g.dart';

/* Widget _embedBuilder(BuildContext context, EmbedNode node) {
  if (node.value.type == 'youtube') {
    final data = node.value.data;
    final url = data['url'];
    final thumbUrl = data['thumb_url'];
    final subtitles = data['subtitles'];
    final language = data['language'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
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

  // Handle other embed types...
  return defaultFleatherEmbedBuilder(context, node);
} */

@riverpod
class EmbedRegistryNotifier extends _$EmbedRegistryNotifier {
  @override
  Map<String, Embed> build() {
    return {};
  }

  registerEmbed(Embed embed) {
    state = {...state, embed.type: embed};
  }

  Widget buildEmbed(BuildContext context, EmbedNode node) {
    final _embeds = state;
    final embed = _embeds[node.value.type];
    if (embed != null) {
      return embed.build(context, node.value.data);
    }
    return defaultFleatherEmbedBuilder(context, node);
  }
}

@riverpod
Widget Function(BuildContext, EmbedNode) fleatherCustomEmbedNotifier(
    FleatherCustomEmbedNotifierRef ref) {
  final embedRegistry = ref.watch(embedRegistryNotifierProvider.notifier);

  return (BuildContext context, EmbedNode node) {
    return embedRegistry.buildEmbed(context, node);
  };
}
