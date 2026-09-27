// Browser-only tests for WebClipboardBackend.
//
// Run with: flutter test --platform chrome test/web_backend_browser_test.dart
@TestOn('browser')
library;

import 'dart:typed_data';

import 'package:championforms_clipboard/championforms_clipboard_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

web.ClipboardEvent _event(String type, web.DataTransfer? data) =>
    web.ClipboardEvent(
      type,
      web.ClipboardEventInit(clipboardData: data, cancelable: true),
    );

void main() {
  final custom = ClipboardFormat.custom('com.championforms.demo');

  group('supports', () {
    test('mandatory formats are supported', () {
      final backend = WebClipboardBackend();
      expect(backend.supports(ClipboardFormat.plainText), isTrue);
      expect(backend.supports(ClipboardFormat.html), isTrue);
      expect(backend.supports(ClipboardFormat.png), isTrue);
    });

    test('RTF and custom formats follow ClipboardItem.supports', () {
      final backend = WebClipboardBackend();
      expect(
        backend.supports(ClipboardFormat.rtf),
        web.ClipboardItem.supports('text/rtf'),
      );
      expect(
        backend.supports(custom),
        web.ClipboardItem.supports('web application/x-com.championforms.demo'),
      );
    });
  });

  group('readFromPasteEvent', () {
    test('reads plain text and HTML from clipboardData', () {
      final data = web.DataTransfer()
        ..setData('text/plain', 'Hello')
        ..setData('text/html', '<b>Hello</b>')
        ..setData('application/x-com.championforms.demo', 'ignored');
      final result = WebClipboardBackend.readFromPasteEvent(
        _event('paste', data),
      );
      expect(result.plainText, 'Hello');
      expect(result.html, '<b>Hello</b>');
      expect(result.has(custom), isFalse);
      expect(result.values, hasLength(2));
    });

    test('absent formats are absent, not empty strings', () {
      final data = web.DataTransfer()..setData('text/plain', 'only');
      final result = WebClipboardBackend.readFromPasteEvent(
        _event('paste', data),
      );
      expect(result.plainText, 'only');
      expect(result.has(ClipboardFormat.html), isFalse);
    });

    test('an event without clipboardData reads as empty', () {
      final result = WebClipboardBackend.readFromPasteEvent(
        _event('paste', null),
      );
      expect(result.isEmpty, isTrue);
    });
  });

  group('writeToCopyEvent', () {
    test('writes text formats and prevents the default', () {
      final data = web.DataTransfer();
      final event = _event('copy', data);
      final wrote = WebClipboardBackend.writeToCopyEvent(
        event,
        ClipboardItem({
          ClipboardFormat.plainText: 'Hi',
          ClipboardFormat.html: '<i>Hi</i>',
          ClipboardFormat.png: Uint8List.fromList([1, 2, 3]),
        }),
      );
      expect(wrote, isTrue);
      expect(event.defaultPrevented, isTrue);
      expect(data.getData('text/plain'), 'Hi');
      expect(data.getData('text/html'), '<i>Hi</i>');
      expect(data.getData('image/png'), '');
    });

    test('items without text formats leave the event alone', () {
      final event = _event('copy', web.DataTransfer());
      final wrote = WebClipboardBackend.writeToCopyEvent(
        event,
        ClipboardItem({ClipboardFormat.png: Uint8List(1)}),
      );
      expect(wrote, isFalse);
      expect(event.defaultPrevented, isFalse);
    });
  });

  test('write surfaces browser refusals as ClipboardException', () async {
    // Headless test browsers normally refuse clipboard writes (no user
    // gesture / focus). Either the write succeeds, or it fails with a
    // ClipboardException rather than a raw JS error.
    final backend = WebClipboardBackend();
    try {
      await backend.write(ClipboardItem({ClipboardFormat.plainText: 'x'}));
    } on ClipboardException catch (e) {
      expect(e.message, contains('Clipboard'));
    }
  });

  test('write with no supported format throws', () async {
    final backend = WebClipboardBackend();
    if (backend.supports(ClipboardFormat.rtf)) return;
    await expectLater(
      backend.write(ClipboardItem({ClipboardFormat.rtf: r'{\rtf1 x}'})),
      throwsA(isA<ClipboardException>()),
    );
  });
}
