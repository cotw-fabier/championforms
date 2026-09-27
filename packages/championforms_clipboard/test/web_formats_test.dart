import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_clipboard/src/web/web_formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('webMimeTypeFor', () {
    test('built-in formats use their MIME type', () {
      expect(webMimeTypeFor(ClipboardFormat.plainText), 'text/plain');
      expect(webMimeTypeFor(ClipboardFormat.html), 'text/html');
      expect(webMimeTypeFor(ClipboardFormat.rtf), 'text/rtf');
      expect(webMimeTypeFor(ClipboardFormat.png), 'image/png');
    });

    test('custom formats use the web custom prefix', () {
      expect(
        webMimeTypeFor(ClipboardFormat.custom('com.championforms.demo')),
        'web application/x-com.championforms.demo',
      );
    });
  });

  group('webFormatForMimeType', () {
    test('maps built-in types, ignoring case and parameters', () {
      expect(webFormatForMimeType('text/plain'), ClipboardFormat.plainText);
      expect(
        webFormatForMimeType('text/plain;charset=utf-8'),
        ClipboardFormat.plainText,
      );
      expect(webFormatForMimeType('Text/HTML'), ClipboardFormat.html);
      expect(webFormatForMimeType('text/rtf'), ClipboardFormat.rtf);
      expect(webFormatForMimeType('application/rtf'), ClipboardFormat.rtf);
      expect(webFormatForMimeType('image/png'), ClipboardFormat.png);
    });

    test('maps custom types with and without the web prefix', () {
      final f = ClipboardFormat.custom('com.championforms.demo');
      expect(
        webFormatForMimeType('web application/x-com.championforms.demo'),
        f,
      );
      expect(webFormatForMimeType('application/x-com.championforms.demo'), f);
    });

    test('round-trips every format', () {
      for (final f in [
        ClipboardFormat.plainText,
        ClipboardFormat.html,
        ClipboardFormat.rtf,
        ClipboardFormat.png,
        ClipboardFormat.custom('com.x.y'),
      ]) {
        expect(webFormatForMimeType(webMimeTypeFor(f)), f);
      }
    });

    test('unknown types map to null', () {
      expect(webFormatForMimeType('image/jpeg'), isNull);
      expect(webFormatForMimeType('web text/plain'), isNull);
      expect(webFormatForMimeType('application/x-'), isNull);
      expect(webFormatForMimeType('Files'), isNull);
    });
  });
}
