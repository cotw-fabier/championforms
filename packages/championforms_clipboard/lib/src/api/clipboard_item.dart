import 'dart:typed_data';

import 'clipboard_format.dart';

/// One clipboard item carrying several representations of the same content.
///
/// Text formats take `String` values; [ClipboardFormat.png],
/// [ClipboardFormat.gif] and custom formats take `Uint8List`;
/// [ClipboardFormat.files] takes a non-empty `List<String>` of paths. The
/// constructor enforces this so a backend never has to.
final class ClipboardItem {
  ClipboardItem(Map<ClipboardFormat, Object> values)
    : values = Map.unmodifiable({
        for (final MapEntry(:key, :value) in values.entries)
          key: _checked(key, value),
      }) {
    if (values.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
  }

  final Map<ClipboardFormat, Object> values;

  /// Validates [value] for [format]; a file list is copied unmodifiable.
  static Object _checked(ClipboardFormat format, Object value) {
    if (format.isFiles) {
      if (value is! List<String>) {
        throw ArgumentError(
          '${format.id} expects List<String>, got ${value.runtimeType}',
        );
      }
      if (value.isEmpty || value.any((p) => p.isEmpty || p.contains('\x00'))) {
        throw ArgumentError.value(
          value,
          format.id,
          'must be a non-empty list of non-empty paths without NUL',
        );
      }
      return List<String>.unmodifiable(value);
    }
    final ok = format.isText ? value is String : value is Uint8List;
    if (!ok) {
      throw ArgumentError(
        '${format.id} expects ${format.isText ? 'String' : 'Uint8List'}, '
        'got ${value.runtimeType}',
      );
    }
    return value;
  }
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
  Uint8List? get gif => values[ClipboardFormat.gif] as Uint8List?;

  /// Local file paths, or null when the clipboard holds no files (or this
  /// platform cannot read them back).
  List<String>? get files => values[ClipboardFormat.files] as List<String>?;

  /// Bytes of a custom (or png/gif) format, or null when absent.
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
