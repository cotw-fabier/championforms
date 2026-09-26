import 'package:championforms/championforms.dart' as form;

import '../model/doc_ids.dart';
import '../model/doc_markdown.dart';
import '../model/doc_plain_text.dart';
import '../model/doc_snapshot.dart';

/// Document conversions on a result accessor:
/// `results.grab('agreement').asDocument()`.
extension DocumentResultAccessor on form.FieldResultAccessor {
  /// The document value: a [DocSnapshot], or one decoded from its JSON map
  /// (as a document restored from saved JSON may hold). Null when the value
  /// is missing or is not a valid document.
  DocSnapshot? asDocument() {
    final raw = asRaw<Object>();
    if (raw is DocSnapshot) return raw;
    if (raw is Map) {
      try {
        return DocSnapshot.fromJson(raw.cast<String, dynamic>());
      } on FormatException {
        return null;
      } on TypeError {
        return null;
      }
    }
    return null;
  }

  /// The document as JSON (`DocSnapshot.toJson`), or null (see
  /// [asDocument]).
  Map<String, dynamic>? asDocumentJson() => asDocument()?.toJson();

  /// The document as Markdown (see `toMarkdown`), or [fallback] when there
  /// is no document.
  String asMarkdown({
    EmbeddedFieldRenderer? embeddedField,
    String fallback = '',
  }) => switch (asDocument()) {
    final DocSnapshot doc => toMarkdown(doc, embeddedField: embeddedField),
    null => fallback,
  };
}

/// Document helpers on collected results.
extension DocumentFormResults on form.FormResults {
  /// Every extracted value of document [docId], keyed by extract key.
  ///
  /// Extract rules register derived fields with ids `{docId}.{key}`, so
  /// this collects the results whose id is `docId` + `.` + a single id
  /// segment (`[A-Za-z0-9_]+`). Embedded field ids
  /// (`{docId}.field.{nodeId}`) have more segments and are not included.
  /// Hidden documents contribute nothing, because hidden fields are left out
  /// of results.
  Map<String, Object?> extracted(String docId) {
    final prefix = '$docId.';
    return {
      for (final e in results.entries)
        if (e.key.startsWith(prefix) &&
            isValidIdSegment(e.key.substring(prefix.length)))
          e.key.substring(prefix.length): e.value,
    };
  }
}
