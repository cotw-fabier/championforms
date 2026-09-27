import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClipboardFormat', () {
    test('built-in ids and kinds', () {
      expect(ClipboardFormat.plainText.id, 'text/plain');
      expect(ClipboardFormat.html.id, 'text/html');
      expect(ClipboardFormat.rtf.id, 'text/rtf');
      expect(ClipboardFormat.png.id, 'image/png');
      expect(ClipboardFormat.plainText.kind, ClipboardFormatKind.plainText);
      expect(ClipboardFormat.png.kind, ClipboardFormatKind.png);
    });

    test('isText is true for text formats only', () {
      expect(ClipboardFormat.plainText.isText, isTrue);
      expect(ClipboardFormat.html.isText, isTrue);
      expect(ClipboardFormat.rtf.isText, isTrue);
      expect(ClipboardFormat.png.isText, isFalse);
      expect(ClipboardFormat.custom('com.example.x').isText, isFalse);
    });

    test('custom formats', () {
      final f = ClipboardFormat.custom('com.championforms.data');
      expect(f.id, 'custom:com.championforms.data');
      expect(f.kind, ClipboardFormatKind.custom);
      expect(f.customName, 'com.championforms.data');
      expect(ClipboardFormat.html.customName, isNull);
    });

    test('custom validation rejects empty names and whitespace', () {
      expect(() => ClipboardFormat.custom(''), throwsArgumentError);
      expect(() => ClipboardFormat.custom('a b'), throwsArgumentError);
      expect(() => ClipboardFormat.custom('a\tb'), throwsArgumentError);
      expect(() => ClipboardFormat.custom('a\nb'), throwsArgumentError);
    });

    test('fromId round-trips every format', () {
      final formats = [
        ClipboardFormat.plainText,
        ClipboardFormat.html,
        ClipboardFormat.rtf,
        ClipboardFormat.png,
        ClipboardFormat.custom('com.championforms.demo'),
      ];
      for (final f in formats) {
        final parsed = ClipboardFormat.fromId(f.id);
        expect(parsed, f);
        expect(parsed.kind, f.kind);
      }
      expect(
        identical(
          ClipboardFormat.fromId('text/plain'),
          ClipboardFormat.plainText,
        ),
        isTrue,
      );
    });

    test('fromId rejects unknown ids', () {
      expect(() => ClipboardFormat.fromId('image/jpeg'), throwsArgumentError);
      expect(() => ClipboardFormat.fromId('custom:'), throwsArgumentError);
    });

    test('equality and hashCode are by id', () {
      final a = ClipboardFormat.custom('com.x');
      final b = ClipboardFormat.custom('com.x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(ClipboardFormat.custom('com.y')));
      expect(ClipboardFormat.html, isNot(ClipboardFormat.plainText));
      expect({a, b, ClipboardFormat.html}, hasLength(2));
      expect(a.toString(), 'ClipboardFormat(custom:com.x)');
    });
  });
}
