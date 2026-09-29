import 'clipboard_format.dart';
import 'clipboard_item.dart';

/// A platform clipboard implementation.
///
/// Every operation is asynchronous: native backends hop to the platform's
/// main thread, and the web API is promise-based. Failures surface as
/// [ClipboardException]; a missing format is not a failure, it is simply
/// absent from the [ClipboardReadResult].
abstract interface class ClipboardBackend {
  /// Replaces the clipboard contents with [item] (all of its formats at
  /// once, as a single clipboard item).
  ///
  /// Formats this backend cannot write ([supports] returns false) are
  /// skipped, not an error. At least one format must be writable.
  Future<void> write(ClipboardItem item);

  /// Reads the clipboard's first item.
  ///
  /// With [formats], only those are read; otherwise every format this
  /// backend [supports] is attempted.
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats});

  /// Formats currently on the clipboard that this backend can read.
  Future<Set<ClipboardFormat>> availableFormats();

  /// Whether this backend can write [format] at all on this platform
  /// (e.g. custom formats on Android: false). A supported format can also be
  /// read back, with one exception: [ClipboardFormat.files] on Android is
  /// write only (a pasted `content://` URI is not a local path).
  bool supports(ClipboardFormat format);
}
