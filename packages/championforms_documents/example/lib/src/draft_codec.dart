import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';

/// A saved draft: the template it was made from and the form's values,
/// JSON-shaped.
class Draft {
  const Draft({required this.templateId, required this.values, this.savedAt});

  static const version = 1;

  final String templateId;
  final DateTime? savedAt;

  /// Field id → JSON value: the document as `DocSnapshot.toJson()`, text as
  /// a string, option selects as their selected option values, a rating as
  /// an int, file uploads as file metadata (names and sizes only).
  final Map<String, Object?> values;

  Map<String, dynamic> toJson() => {
    'version': version,
    'templateId': templateId,
    if (savedAt != null) 'savedAt': savedAt!.toIso8601String(),
    'values': values,
  };

  factory Draft.fromJson(Map<String, dynamic> json) {
    if (json['version'] != version) {
      throw FormatException('Unsupported draft version ${json['version']}');
    }
    final templateId = json['templateId'];
    final values = json['values'];
    if (templateId is! String || values is! Map) {
      throw const FormatException('A draft needs "templateId" and "values"');
    }
    return Draft(
      templateId: templateId,
      savedAt: DateTime.tryParse('${json['savedAt']}'),
      values: values.cast<String, Object?>(),
    );
  }
}

/// Reads every saveable value off [controller].
///
/// Derived fields (`agreement.parties`…) are skipped: they are recomputed
/// from the document. File uploads keep only metadata; their bytes are not
/// written to the draft.
Map<String, Object?> captureValues(form.FormController controller) {
  final values = <String, Object?>{};
  for (final field in controller.registeredFields) {
    if (field is DerivedField) continue;
    final raw = controller.getFieldValueOrNull<Object>(field.id);
    if (raw == null) continue;
    final Object? json = switch ((field, raw)) {
      (DocumentField(), _) => DocumentField.coerce(raw)?.toJson(),
      (form.FileUpload(), final List list) => [
        for (final o in list.whereType<form.FieldOption>())
          {
            'name': o.label,
            if (o.additionalData case final form.FileModel f)
              'size': f.fileBytes?.length,
          },
      ],
      (form.OptionSelect(), final List list) => [
        for (final o in list.whereType<form.FieldOption>()) o.value,
      ],
      (_, final String s) => s,
      (_, final num n) => n,
      (_, final bool b) => b,
      _ => null,
    };
    if (json != null) values[field.id] = json;
  }
  return values;
}

/// The result of [restoreValues].
class RestoreReport {
  RestoreReport({required this.restored, required this.skipped});

  /// Ids whose value was written.
  final List<String> restored;

  /// Ids that could not be restored (unknown field, file bytes, bad shape).
  final List<String> skipped;
}

/// Writes a draft's [values] back into [controller].
///
/// Documents go first, through `setFieldValues`: rehydrating a document
/// registers its embedded fields, and only then can their values be set.
/// Everything else is restored with `restorePastedFieldValue`, which knows
/// the value shape of each field type (option values → `FieldOption`s).
RestoreReport restoreValues(
  form.FormController controller,
  Map<String, Object?> values,
) {
  final fields = {for (final f in controller.registeredFields) f.id: f};
  final restored = <String>[];
  final skipped = <String>[];

  final documents = <String, Object?>{};
  for (final MapEntry(:key, :value) in values.entries) {
    if (fields[key] is DocumentField && value is Map) {
      final doc = DocumentField.coerce(value);
      if (doc == null) {
        skipped.add(key);
      } else {
        documents[key] = doc;
      }
    }
  }
  controller.setFieldValues(documents);
  restored.addAll(documents.keys);

  // Re-read: the documents just registered their embedded fields.
  final current = {for (final f in controller.registeredFields) f.id: f};
  for (final MapEntry(:key, :value) in values.entries) {
    if (documents.containsKey(key) || skipped.contains(key)) continue;
    final field = current[key];
    if (field == null || field is DerivedField || field is form.FileUpload) {
      skipped.add(key);
      continue;
    }
    final ok = restorePastedFieldValue(controller, field, switch (value) {
      final List list => list.cast<Object?>().whereType<String>().toList(),
      _ => value,
    }, noNotify: true);
    (ok ? restored : skipped).add(key);
  }
  controller.setFieldValues(const {});
  return RestoreReport(restored: restored, skipped: skipped);
}
