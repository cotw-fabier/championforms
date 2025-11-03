import 'package:championforms/models/field_types/column.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';

/// Build rows to store column blocks.
/// Rows can take a collapse bool which allows for responsive
/// layouts.
class Row extends FormElement {
  /// A list of columns to display in your row content.
  final List<Column> children;

  /// If true, collapses the columns into a single vertical layout.
  /// Useful for responsive design on smaller screens.
  final bool collapse;

  /// If true, validation errors from child fields within this row will be
  /// displayed together at the bottom of the row.
  final bool rollUpErrors;

  /// Hides the entire row from being displayed and processed.
  final bool hideField;

  /// Spacing between columns in the row.
  final double spacing;

  Row({
    this.children = const [],
    this.collapse = false,
    this.rollUpErrors = false,
    this.hideField = false,
    this.spacing = 10,
  });
}
