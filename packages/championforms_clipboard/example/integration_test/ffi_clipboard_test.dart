// Native round trip through the Rust FFI backend (macOS, iOS, Windows,
// Linux). Uses the real system clipboard, so it overwrites its contents.
//
//   flutter test integration_test/ffi_clipboard_test.dart -d macos
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:championforms_clipboard/championforms_clipboard.dart';
// ignore: implementation_imports
import 'package:championforms_clipboard/src/ffi/ffi_clipboard_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final _custom = ClipboardFormat.custom('com.championforms.test');
final _missing = ClipboardFormat.custom('com.championforms.missing');

const _text = 'plain é 😀 — ✓';
const _html = '<p>Héllo <b>wörld</b> 😀</p>';
const _rtf = r'{\rtf1\ansi Hello \b world\b0}';

/// A valid 1x1 transparent PNG.
final _png = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// A 1x1 GIF89a.
final _gif = base64.decode(
  'R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
);

/// Custom bytes including 0x00 and every other byte value.
final _customBytes = Uint8List.fromList([
  0,
  1,
  0,
  255,
  ...List.generate(256, (i) => i),
  0,
]);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final native =
      Platform.isMacOS ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isLinux;
  final clipboard = FfiClipboardBackend();

  Future<void> writeAll() => clipboard.write(
    ClipboardItem({
      ClipboardFormat.plainText: _text,
      ClipboardFormat.html: _html,
      ClipboardFormat.rtf: _rtf,
      ClipboardFormat.png: _png,
      _custom: _customBytes,
    }),
  );

  testWidgets('supports every format kind', (tester) async {
    for (final f in [
      ClipboardFormat.plainText,
      ClipboardFormat.html,
      ClipboardFormat.rtf,
      ClipboardFormat.png,
      ClipboardFormat.gif,
      _custom,
    ]) {
      expect(clipboard.supports(f), isTrue, reason: f.id);
    }
    // UIPasteboard has no file references.
    expect(clipboard.supports(ClipboardFormat.files), !Platform.isIOS);
  }, skip: !native);

  testWidgets('GIF round-trips next to PNG', (tester) async {
    await clipboard.write(
      ClipboardItem({ClipboardFormat.png: _png, ClipboardFormat.gif: _gif}),
    );
    final r = await clipboard.read(
      formats: [ClipboardFormat.png, ClipboardFormat.gif],
    );
    expect(r.png, _png);
    expect(r.gif, _gif);
    expect(
      await clipboard.availableFormats(),
      containsAll([ClipboardFormat.png, ClipboardFormat.gif]),
    );
  }, skip: !native);

  testWidgets('a file list round-trips with other formats', (tester) async {
    final dir = await Directory.systemTemp.createTemp('cfclip files ');
    addTearDown(() => dir.delete(recursive: true));
    final paths = <String>[];
    for (final name in ['clip one.mp4', 'x😀#%.gif']) {
      final f = File('${dir.path}/$name');
      await f.writeAsBytes([1, 2, 3]);
      paths.add(f.resolveSymbolicLinksSync());
    }

    await clipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: 'two files',
        ClipboardFormat.gif: _gif,
        ClipboardFormat.files: paths,
      }),
    );
    final r = await clipboard.read(
      formats: [
        ClipboardFormat.files,
        ClipboardFormat.plainText,
        ClipboardFormat.gif,
      ],
    );
    expect(r.files, paths);
    expect(r.plainText, 'two files');
    expect(r.gif, _gif);
    expect(await clipboard.availableFormats(), contains(ClipboardFormat.files));

    // Files alone, then a text write drops them.
    await clipboard.write(
      ClipboardItem({
        ClipboardFormat.files: [paths[0]],
      }),
    );
    expect((await clipboard.read(formats: [ClipboardFormat.files])).files, [
      paths[0],
    ]);
    await clipboard.write(ClipboardItem({ClipboardFormat.plainText: 'text'}));
    expect(
      (await clipboard.read(formats: [ClipboardFormat.files])).files,
      isNull,
    );
    expect(
      await clipboard.availableFormats(),
      isNot(contains(ClipboardFormat.files)),
    );
  }, skip: !native || Platform.isIOS);

  testWidgets('writes all five formats and reads them back exactly', (
    tester,
  ) async {
    await writeAll();
    final r = await clipboard.read(
      formats: [
        ClipboardFormat.plainText,
        ClipboardFormat.html,
        ClipboardFormat.rtf,
        ClipboardFormat.png,
        _custom,
        _missing,
      ],
    );
    expect(r.plainText, _text);
    expect(r.html, _html);
    expect(r.rtf, _rtf);
    expect(r.png, _png);
    expect(r.bytes(_custom), _customBytes);
    expect(r.has(_missing), isFalse, reason: 'a missing format is absent');

    final available = await clipboard.availableFormats();
    expect(
      available,
      containsAll([
        ClipboardFormat.plainText,
        ClipboardFormat.html,
        ClipboardFormat.rtf,
        ClipboardFormat.png,
        _custom,
      ]),
    );
    expect(available, isNot(contains(_missing)));

    // Reading without a format list reads everything available.
    final all = await clipboard.read();
    expect(all.plainText, _text);
    expect(all.bytes(_custom), _customBytes);
  }, skip: !native);

  testWidgets('20 concurrent reads each get their own reply', (tester) async {
    await writeAll();
    final formats = [
      ClipboardFormat.plainText,
      ClipboardFormat.html,
      ClipboardFormat.rtf,
      ClipboardFormat.png,
      _custom,
    ];
    final results = await Future.wait([
      for (var i = 0; i < 20; i++) clipboard.read(formats: [formats[i % 5]]),
    ]);
    for (var i = 0; i < 20; i++) {
      final r = results[i];
      expect(r.values.keys, [formats[i % 5]], reason: 'request $i');
    }
    expect(results[0].plainText, _text);
    expect(results[4].bytes(_custom), _customBytes);
  }, skip: !native);

  testWidgets('works from a background isolate (main-thread hop)', (
    tester,
  ) async {
    final got = await Isolate.run(() async {
      final bg = FfiClipboardBackend();
      await bg.write(
        ClipboardItem({
          ClipboardFormat.plainText: 'from a background isolate é',
          ClipboardFormat.custom('com.championforms.test'): Uint8List.fromList([
            9,
            0,
            7,
          ]),
        }),
      );
      final r = await bg.read(
        formats: [
          ClipboardFormat.plainText,
          ClipboardFormat.custom('com.championforms.test'),
        ],
      );
      return (
        r.plainText,
        r.bytes(ClipboardFormat.custom('com.championforms.test'))!.toList(),
      );
    });
    expect(got.$1, 'from a background isolate é');
    expect(got.$2, [9, 0, 7]);
    // And the UI isolate sees the same clipboard.
    final r = await clipboard.read(formats: [ClipboardFormat.plainText]);
    expect(r.plainText, 'from a background isolate é');
  }, skip: !native);

  testWidgets('writing plain text only leaves html absent', (tester) async {
    await writeAll();
    await clipboard.write(
      ClipboardItem({ClipboardFormat.plainText: 'only plain'}),
    );
    final r = await clipboard.read(
      formats: [ClipboardFormat.plainText, ClipboardFormat.html, _custom],
    );
    expect(r.plainText, 'only plain');
    expect(r.has(ClipboardFormat.html), isFalse);
    expect(r.has(_custom), isFalse);
    final available = await clipboard.availableFormats();
    expect(available, contains(ClipboardFormat.plainText));
    expect(available, isNot(contains(ClipboardFormat.html)));
  }, skip: !native);

  testWidgets('empty text round-trips', (tester) async {
    await clipboard.write(ClipboardItem({ClipboardFormat.plainText: ''}));
    final r = await clipboard.read(formats: [ClipboardFormat.plainText]);
    expect(r.plainText ?? '', '');
  }, skip: !native);

  // Last, so the clipboard is left holding known text (check with pbpaste).
  testWidgets('leaves a marker on the clipboard', (tester) async {
    await clipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: 'championforms ffi ok é😀',
        ClipboardFormat.html: '<b>championforms ffi ok</b>',
      }),
    );
    final r = await clipboard.read(formats: [ClipboardFormat.plainText]);
    expect(r.plainText, 'championforms ffi ok é😀');
  }, skip: !native);
}
