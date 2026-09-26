import 'clipboard_backend.dart';
import 'clipboard_format.dart';
import 'clipboard_item.dart';

/// In-memory [ClipboardBackend] for tests.
///
/// [unsupported] lets a test imitate a platform that drops some formats
/// (Android dropping custom types, say): writes silently skip them, exactly
/// as a real backend does.
class FakeClipboardBackend implements ClipboardBackend {
  FakeClipboardBackend({Set<ClipboardFormat> unsupported = const {}})
      : _unsupported = unsupported;

  final Set<ClipboardFormat> _unsupported;

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
    _contents = kept;
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
