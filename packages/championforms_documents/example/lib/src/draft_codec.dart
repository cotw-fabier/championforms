/// A saved draft: the template it was made from and the form's values,
/// JSON-shaped.
class Draft {
  const Draft({required this.templateId, required this.values, this.savedAt});

  static const version = 1;

  final String templateId;
  final DateTime? savedAt;

  /// Field id → JSON value, as `FormController.exportValues` returns it and
  /// `setFieldValues` takes it back: the document as `DocSnapshot.toJson()`,
  /// its blocks' values under `agreement.field.<nodeId>`, text as a string,
  /// option selects as their selected option values, a rating as an int,
  /// file uploads as metadata (not restorable).
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
