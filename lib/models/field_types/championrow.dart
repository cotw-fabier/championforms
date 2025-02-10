import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';

/// Build rows to store column blocks.
/// This is mostly semantic to keep tabs on where your columns are
/// in your form definitions.
/// Rows can take a collapse bool which allows for responsive
/// layouts.
class ChampionRow extends FormFieldBase {
  /// A list of columns to display in your row content.
  final List<ChampionColumn> columns;

  /// Collapse the columns under the row into a vertical layout for
  /// mobile devices
  final bool collapse;

  /// Roll up errors from child fields into the parent widget.
  final bool rollUpErrors;

  /// Hide field from processing and displaying. This will hide all fields below as well.
  final bool hideField;

  ChampionRow({
    required super.id,
    super.title,
    super.description,
    required this.columns,
    this.collapse = false,
    this.rollUpErrors = false,
    this.hideField = false,
  });
}
