import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';

/// Makes any results value JSON-encodable: documents as their JSON, options
/// as `{value, label}`, files as name and size.
Object? jsonSafe(Object? value) => switch (value) {
  null || String() || num() || bool() => value,
  DocSnapshot() => value.toJson(),
  form.FieldOption(additionalData: final form.FileModel file) => {
    'file': file.fileName,
    'bytes': file.fileBytes?.length,
  },
  form.FieldOption() => {'value': value.value, 'label': value.label},
  Map() => {for (final e in value.entries) '${e.key}': jsonSafe(e.value)},
  Iterable() => [for (final v in value) jsonSafe(v)],
  _ => value.toString(),
};

/// The whole of [results] as a JSON map: values keyed by field id, plus the
/// error state and errors.
Map<String, Object?> resultsToJson(form.FormResults results) => {
  'errorState': results.errorState,
  'errors': [
    for (final e in results.formErrors)
      {'fieldId': e.fieldId, 'reason': e.reason},
  ],
  'values': {
    for (final id in results.results.keys.toList()..sort())
      id: jsonSafe(results.results[id]),
  },
};

const _encoder = JsonEncoder.withIndent('  ');

String prettyJson(Object? value) => _encoder.convert(jsonSafe(value));
