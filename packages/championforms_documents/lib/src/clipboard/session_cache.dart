import '../model/doc_clipboard_payload.dart';

/// What the last copy put on the clipboard, kept in memory.
final class DocClipboardCacheEntry {
  DocClipboardCacheEntry._({
    required this.plainTextHash,
    required this.plainTextLength,
    required this.payload,
    required this.encodedPayload,
    required Map<String, Object?> liveValues,
  }) : liveValues = Map.unmodifiable(liveValues);

  /// Hash of the normalized plain text that was written (see
  /// [DocClipboardSessionCache.normalizePlainText]).
  final int plainTextHash;
  final int plainTextLength;

  final DocClipboardPayload payload;

  /// [payload] exactly as encoded onto the clipboard, to recognize the same
  /// payload coming back through the custom format or the HTML.
  final String encodedPayload;

  /// The controller values of the copied embedded fields at copy time,
  /// keyed by the *copied* node id, in the controller's own shapes
  /// (`String`, `List<FieldOption>` including `FileUpload` files with their
  /// bytes, `Map<String, String>` for compound fields). Only fields whose
  /// codec produced a fragment are here, so a password never is.
  final Map<String, Object?> liveValues;
}

/// The in-process fallback for clipboards that keep only plain text.
///
/// After each copy the delegate remembers the payload, the live embedded
/// values and a hash of the plain text it wrote. A later paste whose plain
/// text hashes the same restores the full payload (ids, structure, marks)
/// even if the OS dropped the custom and HTML formats, and gets the live
/// values back, so `FileUpload` bytes, which never reach the system
/// clipboard, survive a copy and paste within the app.
///
/// Only the last copy is kept. [instance] is shared by every
/// `ChampionDocClipboard` that is not given its own cache, so a copy from
/// one document can be pasted into another.
final class DocClipboardSessionCache {
  DocClipboardSessionCache();

  static final instance = DocClipboardSessionCache();

  DocClipboardCacheEntry? _entry;

  /// The remembered copy, or null.
  DocClipboardCacheEntry? get entry => _entry;

  /// Line endings unified to `\n`, non-breaking spaces to spaces, trailing
  /// whitespace removed: the changes platforms make to plain text on the
  /// way through the clipboard.
  static String normalizePlainText(String text) => text
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll(' ', ' ')
      .trimRight();

  /// Replaces the remembered copy.
  void remember({
    required String plainText,
    required DocClipboardPayload payload,
    required String encodedPayload,
    Map<String, Object?> liveValues = const {},
  }) {
    final normalized = normalizePlainText(plainText);
    _entry = DocClipboardCacheEntry._(
      plainTextHash: normalized.hashCode,
      plainTextLength: normalized.length,
      payload: payload,
      encodedPayload: encodedPayload,
      liveValues: liveValues,
    );
  }

  /// The remembered copy when [plainText] (normalized) hashes like the plain
  /// text it wrote; null otherwise, or for empty text.
  DocClipboardCacheEntry? matchPlainText(String? plainText) {
    final entry = _entry;
    if (entry == null || plainText == null) return null;
    final normalized = normalizePlainText(plainText);
    if (normalized.isEmpty) return null;
    return normalized.length == entry.plainTextLength &&
            normalized.hashCode == entry.plainTextHash
        ? entry
        : null;
  }

  /// The remembered copy when [encodedPayload] is exactly the payload it
  /// wrote, else null.
  DocClipboardCacheEntry? matchEncoded(String encodedPayload) {
    final entry = _entry;
    return entry != null && entry.encodedPayload == encodedPayload
        ? entry
        : null;
  }

  void clear() => _entry = null;
}
