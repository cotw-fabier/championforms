import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter/widgets.dart';

/// A layout element that arranges fields vertically within a [Row].
/// Its width can be defined as a fraction of the available row space.
class Column extends FormElement {
  /// The form elements (fields, or even nested rows/columns) inside this column.
  final List<FormElement> children;

  /// If true, validation errors from child fields within this column will be
  /// displayed together at the bottom of the column.
  final bool rollUpErrors;

  /// Hides the entire column from being displayed and processed.
  final bool hideField;

  /// Defines the width of the column as a fraction of the total row width (e.g., 0.5 for 50%).
  /// If not specified, remaining space in the row is divided equally among columns without a widthFactor.
  final double? widthFactor;

  /// Spacing between columns in the row.
  final double spacing;

  /// An optional builder to wrap the column's contents in a custom widget.
  final Widget Function(
    BuildContext context,
    Widget child,
    List<FormBuilderError>? errors,
  )? columnWrapper;

  Column({
    this.children = const [],
    this.rollUpErrors = false,
    this.hideField = false,
    this.widthFactor,
    this.columnWrapper,
    this.spacing = 10,
  });
}
