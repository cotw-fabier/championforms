import 'package:championforms/models/field_types/formfieldbase.dart';

/// Build columns inside rows to format your forms visually.
/// Columns and Rows can collapse when a collapse bool is set
/// This allows you to manage collapse logic external to this library
class ChampionColumn extends FormFieldBase {
  /// The form fields inside this column.
  final List<FormFieldBase> fields;

  /// Roll up errors from child fields into the parent widget.
  final bool rollUpErrors;

  /// Hide field from processing and displaying. This will hide all fields below as well.
  final bool hideField;

  ChampionColumn({
    required super.id,
    super.title,
    super.description,
    required this.fields,
    this.rollUpErrors = false,
    this.hideField = false,
  });
}
