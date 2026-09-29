import 'dart:convert';

// ignore: implementation_imports
import 'package:championforms_clipboard/src/ffi/ffi_clipboard_backend.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FFI file list encoding', () {
    test('paths are UTF-8 joined by NUL', () {
      final bytes = FfiClipboardBackend.encodePaths(['/a b', '/é/😀.gif']);
      expect(bytes.where((b) => b == 0), hasLength(1));
      expect(utf8.decode(bytes), '/a b\x00/é/😀.gif');
      expect(FfiClipboardBackend.decodePaths(bytes), ['/a b', '/é/😀.gif']);
    });

    test('empty segments are dropped', () {
      expect(
        FfiClipboardBackend.decodePaths(utf8.encode('\x00/a\x00\x00/b\x00')),
        ['/a', '/b'],
      );
      expect(FfiClipboardBackend.decodePaths(utf8.encode('')), isEmpty);
    });
  });
}
