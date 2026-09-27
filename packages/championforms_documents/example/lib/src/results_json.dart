import 'dart:convert';

import 'package:championforms/championforms.dart' as form;

/// The whole of [results] as a JSON map: the values (`results.toJson()`,
/// sorted by id) plus the error state and errors.
Map<String, Object?> resultsToJson(form.FormResults results) => {
  'errorState': results.errorState,
  'errors': [
    for (final e in results.formErrors)
      {'fieldId': e.fieldId, 'reason': e.reason},
  ],
  'values': Map.fromEntries(
    results.toJson().entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
  ),
};

const _encoder = JsonEncoder.withIndent('  ');

String prettyJson(Object? json) => _encoder.convert(json);
