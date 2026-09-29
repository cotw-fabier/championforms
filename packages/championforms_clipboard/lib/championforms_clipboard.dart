/// Multi-format system clipboard for Flutter.
///
/// Reads and writes several representations of one clipboard item at once
/// (plain text, HTML, RTF, PNG, GIF, local files and custom application
/// types) on macOS, iOS, Windows, Linux, Android and the web. Desktop and
/// iOS backends are Rust native assets; Android uses `package:jni`; the web
/// uses the async Clipboard API.
///
/// ```dart
/// await SystemClipboard.write(ClipboardItem({
///   ClipboardFormat.plainText: 'Hello',
///   ClipboardFormat.html: '<b>Hello</b>',
/// }));
/// final read = await SystemClipboard.read();
/// print(read.html);
/// ```
///
/// This package has no dependency on `championforms` and can be used on its
/// own.
library;

import 'src/api/clipboard_backend.dart';
import 'src/api/clipboard_format.dart';
import 'src/api/clipboard_item.dart';
import 'src/platform/backend_selector.dart';

export 'src/api/clipboard_backend.dart';
export 'src/api/clipboard_format.dart';
export 'src/api/clipboard_item.dart';
export 'src/api/fake_clipboard_backend.dart';

/// The process-wide clipboard.
///
/// Swap [backend] in tests (`SystemClipboard.backend = FakeClipboardBackend()`)
/// or to plug in another implementation.
abstract final class SystemClipboard {
  static ClipboardBackend? _backend;

  static ClipboardBackend get backend => _backend ??= createDefaultBackend();
  static set backend(ClipboardBackend value) => _backend = value;

  static Future<void> write(ClipboardItem item) => backend.write(item);

  static Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) =>
      backend.read(formats: formats);

  static Future<Set<ClipboardFormat>> availableFormats() =>
      backend.availableFormats();

  static bool supports(ClipboardFormat format) => backend.supports(format);
}
