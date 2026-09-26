import '../api/clipboard_backend.dart';
import '../api/clipboard_format.dart';
import '../api/clipboard_item.dart';

/// Stub — implemented in stage S2c (Rust FFI, see ABI.md).
class FfiClipboardBackend implements ClipboardBackend {
  @override
  Future<void> write(ClipboardItem item) => throw UnimplementedError();

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) =>
      throw UnimplementedError();

  @override
  Future<Set<ClipboardFormat>> availableFormats() =>
      throw UnimplementedError();

  @override
  bool supports(ClipboardFormat format) => false;
}
