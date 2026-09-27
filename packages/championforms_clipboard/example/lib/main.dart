// Clipboard inspector: writes each format through SystemClipboard and lists
// what is on the clipboard now. Works on every platform; formats a platform
// cannot carry are reported by SystemClipboard.supports and skipped on write.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ClipboardInspectorApp());

/// The custom format the demo writes.
final demoFormat = ClipboardFormat.custom('com.championforms.demo');

/// Every format the inspector knows about, in display order.
final inspectedFormats = [
  ClipboardFormat.plainText,
  ClipboardFormat.html,
  ClipboardFormat.rtf,
  ClipboardFormat.png,
  demoFormat,
];

class ClipboardInspectorApp extends StatelessWidget {
  const ClipboardInspectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clipboard inspector',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const InspectorPage(),
    );
  }
}

class InspectorPage extends StatefulWidget {
  const InspectorPage({super.key});

  @override
  State<InspectorPage> createState() => _InspectorPageState();
}

class _InspectorPageState extends State<InspectorPage> {
  /// What the last refresh found: format → value (null when the format was
  /// listed as available but the read returned nothing).
  Map<ClipboardFormat, Object?> _contents = {};
  String? _lastError;
  String? _status;
  bool _busy = false;

  Future<void> _run(String label, Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _status = '$label…';
    });
    try {
      await action();
      setState(() {
        _lastError = null;
        _status = '$label: done';
      });
    } catch (e) {
      setState(() {
        _lastError = '$label: $e';
        _status = '$label: failed';
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _write(String label, Map<ClipboardFormat, Object> values) =>
      _run('Write $label', () async {
        await SystemClipboard.write(ClipboardItem(values));
        await _refreshContents();
      });

  Future<void> _refresh() => _run('Refresh', _refreshContents);

  Future<void> _refreshContents() async {
    final available = await SystemClipboard.availableFormats();
    final read = available.isEmpty
        ? ClipboardReadResult.empty
        : await SystemClipboard.read(formats: available.toList());
    setState(() {
      _contents = {for (final f in available) f: read.values[f]};
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clipboard inspector'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Write', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _write('plain', {
                        ClipboardFormat.plainText: 'Hello from championforms',
                      }),
                child: const Text('Plain text'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _write('HTML', {
                        ClipboardFormat.plainText: 'Hello bold world',
                        ClipboardFormat.html:
                            '<p>Hello <b>bold</b> <i>world</i></p>',
                      }),
                child: const Text('HTML'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _write('RTF', {
                        ClipboardFormat.plainText: 'Hello RTF',
                        ClipboardFormat.rtf: r'{\rtf1\ansi Hello {\b RTF}\par}',
                      }),
                child: const Text('RTF'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () async => _write('PNG', {
                        ClipboardFormat.png: await generateDemoPng(),
                      }),
                child: const Text('PNG'),
              ),
              FilledButton.tonal(
                onPressed: _busy
                    ? null
                    : () => _write('custom', {
                        ClipboardFormat.plainText: 'custom payload',
                        demoFormat: Uint8List.fromList(
                          utf8.encode('{"demo":true,"n":42}'),
                        ),
                      }),
                child: const Text('Custom'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Backend supports', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in inspectedFormats)
                Chip(
                  avatar: Icon(
                    SystemClipboard.supports(f) ? Icons.check : Icons.close,
                    size: 18,
                  ),
                  label: Text(f.id),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Last error', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(
            _lastError ?? '(none)',
            key: const Key('lastError'),
            style: TextStyle(
              color: _lastError == null ? null : theme.colorScheme.error,
            ),
          ),
          if (_status != null) ...[
            const SizedBox(height: 4),
            Text(_status!, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: 16),
          Text(
            'On the clipboard (${_contents.length} formats)',
            style: theme.textTheme.titleMedium,
          ),
          if (_contents.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Nothing readable. Press Refresh after copying.'),
            ),
          for (final MapEntry(key: format, :value) in _contents.entries)
            Card(
              child: ListTile(
                title: Text(format.id),
                subtitle: _ValueView(format: format, value: value),
              ),
            ),
        ],
      ),
    );
  }
}

class _ValueView extends StatelessWidget {
  const _ValueView({required this.format, required this.value});

  final ClipboardFormat format;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final v = value;
    if (v == null) return const Text('(listed, but the read returned nothing)');
    if (v is String) {
      final shown = v.length > 2000 ? '${v.substring(0, 2000)}…' : v;
      return SelectableText(shown);
    }
    final bytes = v as Uint8List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText('${bytes.length} bytes: ${hexPreview(bytes)}'),
        if (format == ClipboardFormat.png)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Image.memory(
              bytes,
              height: 48,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) => const Text('(not a decodable image)'),
            ),
          ),
      ],
    );
  }
}

/// The first [max] bytes of [bytes] as space-separated hex.
String hexPreview(Uint8List bytes, {int max = 32}) {
  final shown = bytes
      .take(max)
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join(' ');
  return bytes.length > max ? '$shown …' : shown;
}

/// A small 16×16 PNG drawn with dart:ui, so it works on every platform.
Future<Uint8List> generateDemoPng() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 16, 16),
    Paint()..color = Colors.indigo,
  );
  canvas.drawCircle(const Offset(8, 8), 5, Paint()..color = Colors.amber);
  final image = await recorder.endRecording().toImage(16, 16);
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
