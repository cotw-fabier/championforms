import 'dart:typed_data';

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClipboardItem', () {
    test('accepts String for text formats and Uint8List for binary', () {
      final item = ClipboardItem({
        ClipboardFormat.plainText: 'a',
        ClipboardFormat.html: '<b>a</b>',
        ClipboardFormat.rtf: r'{\rtf1 a}',
        ClipboardFormat.png: Uint8List.fromList([1, 2]),
        ClipboardFormat.custom('com.x'): Uint8List(0),
      });
      expect(item.values, hasLength(5));
    });

    test('accepts GIF bytes and a file list, copied unmodifiable', () {
      final paths = ['/tmp/a.mp4', '/tmp/b c.gif'];
      final item = ClipboardItem({
        ClipboardFormat.gif: Uint8List.fromList([0x47, 0x49, 0x46]),
        ClipboardFormat.files: paths,
      });
      paths.add('/tmp/late');
      final stored = item.values[ClipboardFormat.files]! as List<String>;
      expect(stored, ['/tmp/a.mp4', '/tmp/b c.gif']);
      expect(() => stored.add('x'), throwsUnsupportedError);
    });

    test('rejects bad file lists', () {
      for (final bad in <Object>[
        <String>[],
        [''],
        ['/ok', 'bad\x00path'],
        '/tmp/a.mp4',
        [1, 2],
        Uint8List(1),
      ]) {
        expect(
          () => ClipboardItem({ClipboardFormat.files: bad}),
          throwsArgumentError,
          reason: '$bad',
        );
      }
      expect(
        () => ClipboardItem({ClipboardFormat.gif: 'not bytes'}),
        throwsArgumentError,
      );
    });

    test('rejects empty items', () {
      expect(() => ClipboardItem({}), throwsArgumentError);
    });

    test('rejects wrong value types', () {
      expect(
        () => ClipboardItem({ClipboardFormat.plainText: Uint8List(1)}),
        throwsArgumentError,
      );
      expect(
        () => ClipboardItem({ClipboardFormat.png: 'not bytes'}),
        throwsArgumentError,
      );
      expect(
        () => ClipboardItem({ClipboardFormat.custom('com.x'): 'text'}),
        throwsArgumentError,
      );
      expect(
        () => ClipboardItem({ClipboardFormat.html: 42}),
        throwsArgumentError,
      );
    });

    test('values are unmodifiable and copied', () {
      final source = <ClipboardFormat, Object>{ClipboardFormat.plainText: 'a'};
      final item = ClipboardItem(source);
      source[ClipboardFormat.html] = '<p>';
      expect(item.values, hasLength(1));
      expect(
        () => item.values[ClipboardFormat.html] = 'x',
        throwsUnsupportedError,
      );
    });
  });

  group('ClipboardReadResult', () {
    test('typed accessors', () {
      final png = Uint8List.fromList([137, 80]);
      final custom = ClipboardFormat.custom('com.x');
      final result = ClipboardReadResult({
        ClipboardFormat.plainText: 'plain',
        ClipboardFormat.html: '<i>h</i>',
        ClipboardFormat.rtf: 'rtf',
        ClipboardFormat.png: png,
        custom: Uint8List.fromList([7]),
      });
      expect(result.isEmpty, isFalse);
      expect(result.plainText, 'plain');
      expect(result.html, '<i>h</i>');
      expect(result.rtf, 'rtf');
      expect(result.png, png);
      expect(result.bytes(custom), [7]);
      expect(result.gif, isNull);
      expect(result.files, isNull);
      expect(result.bytes(ClipboardFormat.png), png);
      expect(result.has(custom), isTrue);
    });

    test('gif and files accessors', () {
      final gif = Uint8List.fromList([0x47]);
      final result = ClipboardReadResult({
        ClipboardFormat.gif: gif,
        ClipboardFormat.files: const ['/a', '/b'],
      });
      expect(result.gif, gif);
      expect(result.bytes(ClipboardFormat.gif), gif);
      expect(result.files, ['/a', '/b']);
    });

    test('absent formats read as null', () {
      const result = ClipboardReadResult.empty;
      expect(result.isEmpty, isTrue);
      expect(result.plainText, isNull);
      expect(result.html, isNull);
      expect(result.rtf, isNull);
      expect(result.png, isNull);
      expect(result.gif, isNull);
      expect(result.files, isNull);
      expect(result.bytes(ClipboardFormat.custom('com.x')), isNull);
      expect(result.has(ClipboardFormat.plainText), isFalse);
    });
  });

  test('ClipboardException toString', () {
    expect(
      const ClipboardException('boom').toString(),
      'ClipboardException(boom)',
    );
    expect(
      const ClipboardException('boom', code: -3).toString(),
      'ClipboardException(-3: boom)',
    );
  });
}
