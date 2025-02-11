// Take in a list of ChampionColumn and display them horizontally or vertically depending on if the collapse bool is set.

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/rowcolumn_widgets/column_builder.dart';
import 'package:flutter/material.dart';

/// A helper widget or function to display a [ChampionRow].
/// It arranges a list of column widgets horizontally or vertically
/// depending on [rowField.collapse].
/// If [rowField.rollUpErrors] is `true`, it displays all rolled-up
/// errors at the bottom.

class ChampionRowWidget extends StatelessWidget {
  final ChampionRow rowField;
  final List<ChampionColumn> columns;
  final List<FormBuilderError>? errors;
  final FieldColorScheme colorScheme;
  final ChampionFormController controller;
  final FormTheme theme;
  final EdgeInsets? fieldPadding;

  const ChampionRowWidget({
    super.key,
    required this.rowField,
    required this.columns,
    this.errors,
    required this.colorScheme,
    required this.theme,
    required this.controller,
    this.fieldPadding,
  });

  @override
  Widget build(BuildContext context) {
    // You can style the Row container or add labels, etc. below as needed
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      child: Container(
        // Example style or color if you want to highlight the row based on the colorScheme

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row-level title/description if desired:
            if (rowField.title != null) ...[
              Text(
                rowField.title!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
            ],
            if (rowField.description != null) ...[
              Text(
                rowField.description!,
              ),
              const SizedBox(height: 8),
            ],
            // Actual row vs. column layout
            if (rowField.collapse)
              LayoutBuilder(builder: (context, constraints) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columns
                      .map((column) => Builder(builder: (context) {
                            return ChampionColumnWidget(
                              controller: controller,
                              columnWrapper: column.columnWrapper,
                              errors: errors,
                              columnField: column,
                              colorScheme: colorScheme,
                              theme: theme,
                            );
                          }))
                      .toList(),
                );
              })
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: columns
                    .map((column) => Builder(builder: (context) {
                          return Flexible(
                            flex: column.columnFlex.clamp(1, 10000),
                            child: ChampionColumnWidget(
                              controller: controller,
                              columnWrapper: column.columnWrapper,
                              errors: errors,
                              columnField: column,
                              colorScheme: colorScheme,
                              theme: theme,
                              fieldPadding: fieldPadding,
                            ),
                          );
                        }))
                    .toList(),
              ),
            // If we're rolling up errors, display them here
            if (rowField.rollUpErrors && errors != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: fieldPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: errors!
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
