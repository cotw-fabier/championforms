import 'dart:typed_data';

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_clipboard_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('writes through SystemClipboard and lists the formats', (
    tester,
  ) async {
    final fake = FakeClipboardBackend(unsupported: {demoFormat});
    SystemClipboard.backend = fake;

    await tester.pumpWidget(const ClipboardInspectorApp());
    expect(find.text('(none)'), findsOneWidget);

    await tester.tap(find.text('HTML'));
    await tester.pumpAndSettle();

    expect(fake.contents[ClipboardFormat.html], contains('<b>bold</b>'));
    expect(find.text('On the clipboard (2 formats)'), findsOneWidget);
    expect(find.text('text/html'), findsWidgets);

    // Custom is unsupported by this fake: it is skipped, plain text stays.
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(fake.contents.keys, [ClipboardFormat.plainText]);
  });

  testWidgets('shows write failures in the last-error field', (tester) async {
    SystemClipboard.backend = FakeClipboardBackend(
      unsupported: {ClipboardFormat.rtf, ClipboardFormat.plainText},
    );
    await tester.pumpWidget(const ClipboardInspectorApp());
    await tester.tap(find.text('RTF'));
    await tester.pumpAndSettle();
    final error = tester.widget<SelectableText>(
      find.byKey(const Key('lastError')),
    );
    expect(error.data, contains('No writable format'));
  });

  test('hexPreview', () {
    expect(hexPreview(Uint8List.fromList([0, 15, 255])), '00 0f ff');
    expect(
      hexPreview(Uint8List.fromList(List.filled(40, 1)), max: 2),
      '01 01 …',
    );
  });
}
