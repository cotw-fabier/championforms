import 'dart:math';

import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter/widgets.dart';

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

  /// Columns use Flexible widgets to define their width.
  /// Defaults to flex: 1, but you can adjust here.
  final int columnFlex;

  /// Column Wrapper
  /// This is a builder which wraps your column in some form.
  /// If null then Champion Forms will just use a blank wrapper
  /// with some simple padding.
  final Widget Function(
    BuildContext context,
    ChampionColumn column,
    List<FormBuilderError>? errors,
    Widget child,
  )? columnWrapper;

  ChampionColumn({
    String? id, // Make id optional
    super.title,
    super.description,
    required this.fields,
    this.rollUpErrors = false,
    this.hideField = false,
    this.columnFlex = 1,
    this.columnWrapper,
  }) : super(id: id ?? _generateRandomId()); // Use a helper to generate an id

  // Helper function to generate a random ID
  static String _generateRandomId() {
    final random = Random();
    // For example, create a simple random id string.
    return 'championColumn_${random.nextInt(10000)}';
  }
}
