// Android clipboard round trip (JNI backend) on a device or emulator:
//   cd packages/championforms_clipboard/example
//   flutter test integration_test/android_clipboard_test.dart -d <device>

import 'dart:convert';
import 'dart:io';

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// A valid 1x1 transparent PNG.
final _png = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
  '60e6kgAAAABJRU5ErkJggg==',
);

/// A 1x1 GIF89a.
final _gif = base64.decode(
  'R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final skip = !isAndroid; // Android only

  testWidgets('HTML plus plain text round-trips', (tester) async {
    const plain = 'Hello bold world';
    const html = '<p>Hello <b>bold</b> world</p>';
    await SystemClipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: plain,
        ClipboardFormat.html: html,
      }),
    );

    final read = await SystemClipboard.read();
    expect(read.plainText, plain);
    expect(read.html, html);

    // ClipDescription lists only text/html; plain text is inferred.
    expect(await SystemClipboard.availableFormats(), {
      ClipboardFormat.plainText,
      ClipboardFormat.html,
    });

    final onlyHtml = await SystemClipboard.read(
      formats: [ClipboardFormat.html],
    );
    expect(onlyHtml.values.keys, [ClipboardFormat.html]);
  }, skip: skip);

  testWidgets('plain text only', (tester) async {
    await SystemClipboard.write(
      ClipboardItem({ClipboardFormat.plainText: 'just text'}),
    );
    final read = await SystemClipboard.read();
    expect(read.plainText, 'just text');
    expect(read.html, isNull);
    expect(await SystemClipboard.availableFormats(), {
      ClipboardFormat.plainText,
    });
  }, skip: skip);

  testWidgets('HTML without plain text gets a derived plain text', (
    tester,
  ) async {
    await SystemClipboard.write(
      ClipboardItem({ClipboardFormat.html: '<p>One &amp; two</p><p>Three</p>'}),
    );
    final read = await SystemClipboard.read();
    expect(read.html, '<p>One &amp; two</p><p>Three</p>');
    expect(read.plainText, 'One & two\nThree');
  }, skip: skip);

  testWidgets('custom and RTF are unsupported and skipped', (tester) async {
    final custom = ClipboardFormat.custom('com.championforms.demo');
    expect(SystemClipboard.supports(custom), isFalse);
    expect(SystemClipboard.supports(ClipboardFormat.rtf), isFalse);

    await SystemClipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: 'fallback',
        custom: Uint8List.fromList([1, 2, 3]),
      }),
    );
    final read = await SystemClipboard.read(
      formats: [ClipboardFormat.plainText, custom],
    );
    expect(read.plainText, 'fallback');
    expect(read.has(custom), isFalse);

    await expectLater(
      SystemClipboard.write(ClipboardItem({custom: Uint8List(1)})),
      throwsA(isA<ClipboardException>()),
    );
  }, skip: skip);

  testWidgets('PNG, GIF and files are supported', (tester) async {
    for (final f in [
      ClipboardFormat.png,
      ClipboardFormat.gif,
      ClipboardFormat.files,
    ]) {
      expect(SystemClipboard.supports(f), isTrue, reason: f.id);
    }
  }, skip: skip);

  testWidgets('PNG and GIF round-trip through content URIs', (tester) async {
    await SystemClipboard.write(
      ClipboardItem({ClipboardFormat.png: _png, ClipboardFormat.gif: _gif}),
    );
    expect(await SystemClipboard.availableFormats(), {
      ClipboardFormat.png,
      ClipboardFormat.gif,
    });
    final read = await SystemClipboard.read();
    expect(read.png, _png);
    expect(read.gif, _gif);
    expect(read.plainText, isNull);
  }, skip: skip);

  testWidgets('text and an image share one clip', (tester) async {
    await SystemClipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: 'caption',
        ClipboardFormat.html: '<b>caption</b>',
        ClipboardFormat.png: _png,
      }),
    );
    expect(await SystemClipboard.availableFormats(), {
      ClipboardFormat.plainText,
      ClipboardFormat.html,
      ClipboardFormat.png,
    });
    final read = await SystemClipboard.read();
    expect(read.plainText, 'caption');
    expect(read.html, '<b>caption</b>');
    expect(read.png, _png);
  }, skip: skip);

  testWidgets('files are copied, served and write only', (tester) async {
    final dir = await Directory.systemTemp.createTemp('cfclip');
    addTearDown(() => dir.delete(recursive: true));
    final video = File('${dir.path}/clip one.mp4');
    await video.writeAsBytes(List.generate(200000, (i) => i % 251));
    // A .png file comes back as an image, which proves the URI is served.
    final picture = File('${dir.path}/picture.png');
    await picture.writeAsBytes(_png);

    await SystemClipboard.write(
      ClipboardItem({
        ClipboardFormat.plainText: 'two files',
        ClipboardFormat.files: [video.path, picture.path],
      }),
    );
    expect(await SystemClipboard.availableFormats(), {
      ClipboardFormat.plainText,
      ClipboardFormat.png,
    });
    final read = await SystemClipboard.read();
    expect(read.plainText, 'two files');
    expect(read.png, _png);
    expect(read.files, isNull, reason: 'files are write only on Android');

    // The copies live in one batch folder of the served cache folder, and
    // the next write clears it.
    // Dart's systemTemp is <data>/code_cache; Context.getCacheDir() is
    // <data>/cache.
    final served = Directory(
      '${Directory.systemTemp.parent.path}/cache/championforms_clipboard',
    );
    final staged = served
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => f.path.split('/').last)
        .toSet();
    expect(staged, {'clip one.mp4', 'picture.png'});
    await SystemClipboard.write(
      ClipboardItem({ClipboardFormat.plainText: 'text only'}),
    );
    expect(served.listSync(), isEmpty);
  }, skip: skip);

  testWidgets('a missing file fails the write', (tester) async {
    await expectLater(
      SystemClipboard.write(
        ClipboardItem({
          ClipboardFormat.files: ['/definitely/not/here.mp4'],
        }),
      ),
      throwsA(isA<ClipboardException>()),
    );
  }, skip: skip);
}
