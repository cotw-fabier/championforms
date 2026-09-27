// Stress, large-payload and CF_HTML tests for the Rust FFI backend (macOS,
// iOS, Windows, Linux). Uses the real system clipboard, so it overwrites its
// contents.
//
//   tool/macos_integration_test.sh packages/championforms_clipboard/example \
//       integration_test/ffi_clipboard_stress_test.dart
//   flutter test integration_test/ffi_clipboard_stress_test.dart -d windows
//   xvfb-run -a flutter test integration_test/ffi_clipboard_stress_test.dart -d linux
import 'dart:io' show Platform, ProcessInfo;

import 'package:championforms_clipboard/championforms_clipboard.dart';
// ignore: implementation_imports
import 'package:championforms_clipboard/src/ffi/ffi_clipboard_backend.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

final _custom = ClipboardFormat.custom('com.championforms.stress');

/// Longest a single write or read may take before the op counts as hung.
const _opTimeout = Duration(seconds: 10);

/// Deterministic bytes covering every byte value, including runs of 0x00.
Uint8List _bytes(int length, int seed) {
  final out = Uint8List(length);
  var x = seed;
  for (var i = 0; i < length; i++) {
    x = (x * 1103515245 + 12345) & 0x7fffffff;
    out[i] = (i % 97 == 0) ? 0 : (x >> 16) & 0xff;
  }
  return out;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final native =
      Platform.isMacOS ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isLinux;
  final clipboard = FfiClipboardBackend();

  Future<void> write(ClipboardItem item, String what) => clipboard
      .write(item)
      .timeout(_opTimeout, onTimeout: () => fail('write hung: $what'));

  Future<ClipboardReadResult> read(
    List<ClipboardFormat> formats,
    String what,
  ) => clipboard
      .read(formats: formats)
      .timeout(_opTimeout, onTimeout: () => fail('read hung: $what'));

  testWidgets('100 sequential write/read cycles with alternating formats', (
    tester,
  ) async {
    final rssBefore = ProcessInfo.currentRss;
    final sw = Stopwatch()..start();
    for (var i = 0; i < 100; i++) {
      final what = 'cycle $i (kind ${i % 5})';
      switch (i % 5) {
        case 0:
          final text = 'cycle $i plain é 😀';
          await write(ClipboardItem({ClipboardFormat.plainText: text}), what);
          final r = await read([
            ClipboardFormat.plainText,
            ClipboardFormat.html,
          ], what);
          expect(r.plainText, text, reason: what);
          expect(r.has(ClipboardFormat.html), isFalse, reason: what);
        case 1:
          final html = '<p>cycle <b>$i</b> ü</p>';
          await write(
            ClipboardItem({
              ClipboardFormat.plainText: 'cycle $i ü',
              ClipboardFormat.html: html,
            }),
            what,
          );
          final r = await read([
            ClipboardFormat.plainText,
            ClipboardFormat.html,
          ], what);
          expect(r.plainText, 'cycle $i ü', reason: what);
          expect(r.html, html, reason: what);
        case 2:
          final bytes = _bytes(4096 + i, i);
          await write(ClipboardItem({_custom: bytes}), what);
          final r = await read([_custom, ClipboardFormat.plainText], what);
          expect(r.bytes(_custom), bytes, reason: what);
        case 3:
          final rtf = '{\\rtf1\\ansi cycle $i \\b bold\\b0}';
          await write(
            ClipboardItem({
              ClipboardFormat.rtf: rtf,
              ClipboardFormat.plainText: 'cycle $i bold',
            }),
            what,
          );
          final r = await read([
            ClipboardFormat.rtf,
            ClipboardFormat.plainText,
          ], what);
          expect(r.rtf, rtf, reason: what);
          expect(r.plainText, 'cycle $i bold', reason: what);
        case 4:
          final bytes = _bytes(512, 1000 + i);
          final item = ClipboardItem({
            ClipboardFormat.plainText: 'mixed $i',
            ClipboardFormat.html: '<i>mixed $i</i>',
            _custom: bytes,
          });
          await write(item, what);
          final formats = await clipboard.availableFormats().timeout(
            _opTimeout,
            onTimeout: () => fail('availableFormats hung: $what'),
          );
          expect(
            formats,
            containsAll([
              ClipboardFormat.plainText,
              ClipboardFormat.html,
              _custom,
            ]),
            reason: what,
          );
          final r = await read([
            ClipboardFormat.plainText,
            ClipboardFormat.html,
            _custom,
          ], what);
          expect(r.plainText, 'mixed $i', reason: what);
          expect(r.html, '<i>mixed $i</i>', reason: what);
          expect(r.bytes(_custom), bytes, reason: what);
      }
    }
    sw.stop();
    final rssAfter = ProcessInfo.currentRss;
    final growthMb = (rssAfter - rssBefore) / (1024 * 1024);
    debugPrint(
      'stress: 100 cycles in ${sw.elapsedMilliseconds} ms, '
      'RSS ${(rssBefore / 1048576).toStringAsFixed(1)} -> '
      '${(rssAfter / 1048576).toStringAsFixed(1)} MB',
    );
    // The payloads total well under 1 MB; a per-cycle leak of the written
    // or read buffers would show up as tens of MB. Generous for GC noise.
    expect(growthMb, lessThan(64), reason: 'RSS grew by $growthMb MB');
  }, skip: !native);

  testWidgets('a 5 MB custom payload round-trips byte for byte', (
    tester,
  ) async {
    final bytes = _bytes(5 * 1024 * 1024, 42);
    final sw = Stopwatch()..start();
    await write(ClipboardItem({_custom: bytes}), '5 MB custom');
    final writeMs = sw.elapsedMilliseconds;
    final r = await read([_custom], '5 MB custom');
    debugPrint(
      '5 MB custom: write $writeMs ms, '
      'read ${sw.elapsedMilliseconds - writeMs} ms',
    );
    final got = r.bytes(_custom);
    expect(got, isNotNull);
    expect(got!.length, bytes.length);
    expect(listEquals(got, bytes), isTrue, reason: 'content differs');
  }, skip: !native);

  testWidgets('a 1 MB HTML string round-trips exactly', (tester) async {
    final buffer = StringBuffer('<div>');
    var row = 0;
    while (buffer.length < 1024 * 1024) {
      buffer.write(
        '<p id="r$row">Row $row: <b>bold</b> <i>é ü 漢字 😀</i> '
        '&amp; <a href="https://example.com/?a=1&amp;b=$row">link</a></p>\n',
      );
      row++;
    }
    buffer.write('</div>');
    final html = buffer.toString();
    final plain = 'large html, $row rows';
    await write(
      ClipboardItem({
        ClipboardFormat.html: html,
        ClipboardFormat.plainText: plain,
      }),
      '1 MB html',
    );
    final r = await read([
      ClipboardFormat.html,
      ClipboardFormat.plainText,
    ], '1 MB html');
    expect(r.plainText, plain);
    expect(r.html?.length, html.length);
    expect(r.html == html, isTrue, reason: 'content differs');
  }, skip: !native);

  group('CF_HTML (Windows)', () {
    // On Windows, HTML goes through the "HTML Format" clipboard format with
    // its byte-offset header; everything written must come back unchanged.
    const samples = {
      'plain fragment': '<p>Hello <b>world</b></p>',
      'multibyte UTF-8': '<p>Héllo wörld — 漢字 😀 ✓</p>',
      'comments and CRLF':
          '<!-- a comment -->\r\n<ul>\r\n<li>one</li>\r\n<li>two</li>\r\n</ul>',
      'fragment-like markers in text':
          '<p>StartFragment:0000000000 &lt;!--EndFragment--&gt;</p>',
      'attributes and entities':
          '<a href="https://example.com/?q=1&amp;r=2" title="&quot;x&quot;">'
          'link &lt;tag&gt;</a>',
    };

    for (final e in samples.entries) {
      testWidgets('${e.key} round-trips identically', (tester) async {
        await write(
          ClipboardItem({
            ClipboardFormat.html: e.value,
            ClipboardFormat.plainText: 'cf_html ${e.key}',
          }),
          e.key,
        );
        final r = await read([
          ClipboardFormat.html,
          ClipboardFormat.plainText,
        ], e.key);
        expect(r.html, e.value);
        expect(r.plainText, 'cf_html ${e.key}');
      }, skip: !Platform.isWindows);
    }

    testWidgets('HTML alone is readable and listed', (tester) async {
      const html = '<h1>only html</h1>';
      await write(ClipboardItem({ClipboardFormat.html: html}), 'html only');
      final formats = await clipboard.availableFormats().timeout(_opTimeout);
      expect(formats, contains(ClipboardFormat.html));
      final r = await read([ClipboardFormat.html], 'html only');
      expect(r.html, html);
    }, skip: !Platform.isWindows);
  });

  // Last, so the clipboard is left holding known text.
  testWidgets('leaves a marker on the clipboard', (tester) async {
    await write(
      ClipboardItem({ClipboardFormat.plainText: 'championforms stress ok'}),
      'marker',
    );
    final r = await read([ClipboardFormat.plainText], 'marker');
    expect(r.plainText, 'championforms stress ok');
  }, skip: !native);
}
