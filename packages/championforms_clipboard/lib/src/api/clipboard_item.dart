import 'dart:typed_data';

import 'clipboard_format.dart';

/// One clipboard item carrying several representations of the same content.
///
/// Text formats take `String` values; [ClipboardFormat.png] and custom formats
/// take `Uint8List`. The constructor enforces this so a backend never has to.
final class ClipboardItem {
  ClipboardItem(Map<ClipboardFormat, Object> values)
      : values = Map.unmodifiable(values) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    for (final MapEntry(:key, :value) in values.entries) {
      final ok = key.isText ? value is String : value is Uint8List;
      if (!ok) {
        throw ArgumentError(
          '${key.id} expects ${key.isText ? 'String' : 'Uint8List'}, '
          'got ${value.runtimeType}',
        );
      }
    }
  }

  final Map<ClipboardFormat, Object> values;
}

/// What a read returned: the requested formats that were present.
final class ClipboardReadResult {
  const ClipboardReadResult(this.values);

  static const empty = ClipboardReadResult({});

  /// Present formats only; absent formats have no key.
  final Map<ClipboardFormat, Object> values;

  bool get isEmpty => values.isEmpty;

  bool has(ClipboardFormat format) => values.containsKey(format);

  String? get plainText => values[ClipboardFormat.plainText] as String?;
  String? get html => values[ClipboardFormat.html] as String?;
  String? get rtf => values[ClipboardFormat.rtf] as String?;
  Uint8List? get png => values[ClipboardFormat.png] as Uint8List?;

  /// Bytes of a custom (or png) format, or null when absent.
  Uint8List? bytes(ClipboardFormat format) => values[format] as Uint8List?;
}

/// A clipboard operation failed at the platform level.
final class ClipboardException implements Exception {
  const ClipboardException(this.message, {this.code});

  final String message;

  /// Backend-specific status code (negative ABI status for FFI backends).
  final int? code;

  @override
  String toString() =>
      'ClipboardException(${code == null ? '' : '$code: '}$message)';
}
