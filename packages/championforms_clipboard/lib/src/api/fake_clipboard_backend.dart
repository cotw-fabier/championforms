import 'clipboard_backend.dart';
import 'clipboard_format.dart';
import 'clipboard_item.dart';

/// In-memory [ClipboardBackend] for tests.
///
/// [unsupported] lets a test imitate a platform that drops some formats
/// (Android dropping custom types, say): writes silently skip them, exactly
/// as a real backend does. [writeOnly] imitates a format a platform can put
/// on the clipboard but not read back ([ClipboardFormat.files] on Android):
/// it is supported and recorded in [writes], but [read], [availableFormats]
/// and [contents] never report it.
///
/// Typical sets: iOS `unsupported: {ClipboardFormat.files}`; Android
/// `unsupported: {ClipboardFormat.rtf, ...custom formats}, writeOnly:
/// {ClipboardFormat.files}`; the web `unsupported: {ClipboardFormat.gif,
/// ClipboardFormat.files}`.
class FakeClipboardBackend implements ClipboardBackend {
  FakeClipboardBackend({
    Set<ClipboardFormat> unsupported = const {},
    Set<ClipboardFormat> writeOnly = const {},
  }) : _unsupported = unsupported,
       _writeOnly = writeOnly;

  final Set<ClipboardFormat> _unsupported;
  final Set<ClipboardFormat> _writeOnly;

  Map<ClipboardFormat, Object> _contents = {};

  /// Every item written, oldest first.
  final List<ClipboardItem> writes = [];

  /// The current contents, as a read of all formats would return them.
  Map<ClipboardFormat, Object> get contents => Map.unmodifiable(_contents);

  @override
  bool supports(ClipboardFormat format) => !_unsupported.contains(format);

  @override
  Future<void> write(ClipboardItem item) async {
    final kept = {
      for (final e in item.values.entries)
        if (supports(e.key)) e.key: e.value,
    };
    if (kept.isEmpty) {
      throw const ClipboardException('No writable format in item');
    }
    writes.add(item);
    _contents = {
      for (final e in kept.entries)
        if (!_writeOnly.contains(e.key)) e.key: e.value,
    };
  }

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) async {
    final wanted = formats ?? _contents.keys;
    return ClipboardReadResult({
      for (final f in wanted)
        if (_contents.containsKey(f)) f: _contents[f]!,
    });
  }

  @override
  Future<Set<ClipboardFormat>> availableFormats() async =>
      _contents.keys.toSet();

  /// Test helper: simulate another app putting [values] on the clipboard.
  void setExternal(Map<ClipboardFormat, Object> values) =>
      _contents = Map.of(values);

  void clear() => _contents = {};
}
