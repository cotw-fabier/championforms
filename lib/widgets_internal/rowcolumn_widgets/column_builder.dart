import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/functions/gather_child_errors.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

/// A helper widget or function to display a [ChampionColumn].
/// It simply arranges its child fields vertically.
/// If [columnField.rollUpErrors] is `true`, it displays all rolled-up
/// errors at the bottom.
class ChampionColumnWidget extends StatelessWidget {
  final ChampionColumn columnField;
  final List<FormBuilderError>? errors;
  final FieldColorScheme colorScheme;
  final ChampionFormController controller;
  final FormTheme theme;
  final EdgeInsets? fieldPadding;
  final Widget Function(
    BuildContext context,
    ChampionColumn column,
    List<FormBuilderError>? errors,
    Widget child,
  )? columnWrapper;

  const ChampionColumnWidget({
    super.key,
    required this.columnField,
    this.errors,
    required this.colorScheme,
    required this.controller,
    required this.columnWrapper,
    required this.theme,
    this.fieldPadding,
  });

  @override
  Widget build(BuildContext context) {
    // Gather errors from the column's fields
    List<FormBuilderError> colChildErrors = [];
    if (columnField.rollUpErrors) {
      colChildErrors = gatherAllChildErrors(columnField.fields, controller);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        // Example styling or border:

        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Column-level title/description if desired
            if (columnField.title != null) ...[
              Text(
                columnField.title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            if (columnField.description != null) ...[
              Text(
                columnField.description!,
              ),
              const SizedBox(height: 8),
            ],
            // Actual column of children
            FormBuilderWidget(
              controller: controller,
              fields: columnField.fields,
              theme: theme,
              parentErrors: colChildErrors.isNotEmpty ? colChildErrors : null,
              fieldPadding: fieldPadding,
            ),
            // If we're rolling up errors, display them here
            if (columnField.rollUpErrors && colChildErrors.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: fieldPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: colChildErrors
                      .map(
                        (err) => Text(
                          err.reason,
                          style: TextStyle(
                              color: theme.errorColorScheme?.textColor),
                        ),
                      )
                      .toList(),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
