// Native round trip through the Rust FFI backend (macOS, iOS, Windows,
// Linux). Uses the real system clipboard, so it overwrites its contents.
//
//   flutter test integration_test/ffi_clipboard_test.dart -d macos
import 'dart:convert';
import 'dart:io' show Platform;
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
      _custom,
    ]) {
      expect(clipboard.supports(f), isTrue, reason: f.id);
    }
  }, skip: !native);

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
