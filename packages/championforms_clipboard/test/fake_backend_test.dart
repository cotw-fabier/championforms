import 'dart:typed_data';

import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final custom = ClipboardFormat.custom('com.championforms.data');

  group('FakeClipboardBackend', () {
    test('write then read round-trips every format', () async {
      final backend = FakeClipboardBackend();
      final png = Uint8List.fromList([1, 2, 3]);
      await backend.write(
        ClipboardItem({
          ClipboardFormat.plainText: 'hi',
          ClipboardFormat.html: '<b>hi</b>',
          ClipboardFormat.png: png,
          custom: Uint8List.fromList([9]),
        }),
      );
      final all = await backend.read();
      expect(all.plainText, 'hi');
      expect(all.html, '<b>hi</b>');
      expect(all.png, png);
      expect(all.bytes(custom), [9]);
      expect(await backend.availableFormats(), {
        ClipboardFormat.plainText,
        ClipboardFormat.html,
        ClipboardFormat.png,
        custom,
      });
      expect(backend.writes, hasLength(1));
    });

    test('gif and files round-trip; files can be write only', () async {
      final gif = Uint8List.fromList([0x47, 0x49, 0x46]);
      final item = ClipboardItem({
        ClipboardFormat.plainText: 'clip.mp4',
        ClipboardFormat.gif: gif,
        ClipboardFormat.files: ['/tmp/clip.mp4'],
      });

      final desktop = FakeClipboardBackend();
      await desktop.write(item);
      final r = await desktop.read();
      expect(r.gif, gif);
      expect(r.files, ['/tmp/clip.mp4']);

      final android = FakeClipboardBackend(writeOnly: {ClipboardFormat.files});
      expect(android.supports(ClipboardFormat.files), isTrue);
      await android.write(item);
      expect(android.writes.single.values, contains(ClipboardFormat.files));
      expect(await android.availableFormats(), {
        ClipboardFormat.plainText,
        ClipboardFormat.gif,
      });
      expect((await android.read()).files, isNull);

      final web = FakeClipboardBackend(
        unsupported: {ClipboardFormat.gif, ClipboardFormat.files},
      );
      await web.write(item);
      expect(await web.availableFormats(), {ClipboardFormat.plainText});
    });

    test('read with formats returns only requested, present formats', () async {
      final backend = FakeClipboardBackend();
      await backend.write(ClipboardItem({ClipboardFormat.plainText: 'x'}));
      final r = await backend.read(
        formats: [ClipboardFormat.html, ClipboardFormat.plainText],
      );
      expect(r.values.keys, [ClipboardFormat.plainText]);
    });

    test('unsupported formats are skipped on write', () async {
      final backend = FakeClipboardBackend(unsupported: {custom});
      expect(backend.supports(custom), isFalse);
      expect(backend.supports(ClipboardFormat.html), isTrue);
      await backend.write(
        ClipboardItem({ClipboardFormat.plainText: 'p', custom: Uint8List(1)}),
      );
      expect(await backend.availableFormats(), {ClipboardFormat.plainText});
      expect((await backend.read()).has(custom), isFalse);
      // The original item is still recorded.
      expect(backend.writes.single.values, contains(custom));
    });

    test('write with nothing writable throws and keeps contents', () async {
      final backend = FakeClipboardBackend(unsupported: {custom});
      await backend.write(ClipboardItem({ClipboardFormat.plainText: 'keep'}));
      await expectLater(
        backend.write(ClipboardItem({custom: Uint8List(1)})),
        throwsA(isA<ClipboardException>()),
      );
      expect((await backend.read()).plainText, 'keep');
      expect(backend.writes, hasLength(1));
    });

    test('write replaces previous contents', () async {
      final backend = FakeClipboardBackend();
      await backend.write(
        ClipboardItem({
          ClipboardFormat.plainText: 'a',
          ClipboardFormat.html: '<p>a</p>',
        }),
      );
      await backend.write(ClipboardItem({ClipboardFormat.plainText: 'b'}));
      final r = await backend.read();
      expect(r.plainText, 'b');
      expect(r.html, isNull);
    });

    test('setExternal and clear simulate other apps', () async {
      final backend = FakeClipboardBackend();
      backend.setExternal({ClipboardFormat.html: '<i>ext</i>'});
      expect((await backend.read()).html, '<i>ext</i>');
      expect(backend.writes, isEmpty);
      backend.clear();
      expect((await backend.read()).isEmpty, isTrue);
      expect(await backend.availableFormats(), isEmpty);
    });
  });

  group('SystemClipboard', () {
    test('delegates to a swapped backend', () async {
      final first = FakeClipboardBackend();
      final second = FakeClipboardBackend(unsupported: {custom});
      SystemClipboard.backend = first;
      expect(identical(SystemClipboard.backend, first), isTrue);
      await SystemClipboard.write(
        ClipboardItem({ClipboardFormat.plainText: 'one'}),
      );
      expect(first.contents[ClipboardFormat.plainText], 'one');

      SystemClipboard.backend = second;
      expect(identical(SystemClipboard.backend, second), isTrue);
      expect(SystemClipboard.supports(custom), isFalse);
      expect((await SystemClipboard.read()).isEmpty, isTrue);
      second.setExternal({ClipboardFormat.plainText: 'two'});
      final read = await SystemClipboard.read(
        formats: [ClipboardFormat.plainText],
      );
      expect(read.plainText, 'two');
      expect(await SystemClipboard.availableFormats(), {
        ClipboardFormat.plainText,
      });
      // The first backend is untouched by the swap.
      expect(first.contents[ClipboardFormat.plainText], 'one');
    });
  });
}
