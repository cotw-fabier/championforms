// Android clipboard round trip (JNI backend) on a device or emulator:
//   cd packages/championforms_clipboard/example
//   flutter test integration_test/android_clipboard_test.dart -d <device>

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

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

  testWidgets('custom, PNG and RTF are unsupported and skipped', (
    tester,
  ) async {
    final custom = ClipboardFormat.custom('com.championforms.demo');
    expect(SystemClipboard.supports(custom), isFalse);
    expect(SystemClipboard.supports(ClipboardFormat.png), isFalse);
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
}
