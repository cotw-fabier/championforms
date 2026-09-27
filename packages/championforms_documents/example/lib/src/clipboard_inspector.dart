import 'dart:convert';

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter/material.dart';

/// Lists the formats on the system clipboard and a preview of each: text
/// truncated, bytes as a length (custom formats that are UTF-8 JSON, like
/// the ChampionForms payload, are shown as text).
class ClipboardInspector extends StatefulWidget {
  const ClipboardInspector({super.key});

  @override
  State<ClipboardInspector> createState() => _ClipboardInspectorState();
}

class _ClipboardInspectorState extends State<ClipboardInspector> {
  static const _previewLength = 400;

  bool _loading = false;
  String? _error;
  List<(ClipboardFormat, String)>? _entries;

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final formats = await SystemClipboard.availableFormats();
      final read = await SystemClipboard.read(formats: formats.toList());
      final entries = [for (final f in formats) (f, _preview(read.values[f]))]
        ..sort((a, b) => a.$1.id.compareTo(b.$1.id));
      if (!mounted) return;
      setState(() => _entries = entries);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _preview(Object? value) {
    final String text;
    switch (value) {
      case null:
        return '(not readable)';
      case final String s:
        text = s;
      case final List<int> bytes:
        try {
          text = '${bytes.length} bytes: ${utf8.decode(bytes)}';
        } on FormatException {
          return '${bytes.length} bytes';
        }
      default:
        return value.runtimeType.toString();
    }
    return text.length <= _previewLength
        ? text
        : '${text.substring(0, _previewLength)}… (${text.length} chars)';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    final entries = _entries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Copying from a document writes the ChampionForms payload, '
                'HTML and plain text at once. Paste into Google Docs or Word '
                'for formatted output; paste back here to recreate blocks '
                'with their values.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              key: const ValueKey('clipboard-refresh'),
              onPressed: _loading ? null : _refresh,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_error != null)
          Text(
            'Could not read the clipboard: $_error',
            style: TextStyle(color: theme.colorScheme.error),
          )
        else if (entries == null)
          Text('Press Refresh to inspect.', style: theme.textTheme.bodySmall)
        else if (entries.isEmpty)
          Text('The clipboard is empty.', style: theme.textTheme.bodySmall)
        else
          for (final (format, preview) in entries)
            Padding(
              key: ValueKey('clipboard-format-${format.id}'),
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(format.id),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(preview, style: mono),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
