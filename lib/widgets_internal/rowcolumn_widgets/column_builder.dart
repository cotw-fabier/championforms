import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

/// A helper widget or function to display a [ChampionColumn].
/// It simply arranges its child fields vertically.
/// If [columnField.rollUpErrors] is `true`, it displays all rolled-up
/// errors at the bottom.
Widget buildChampionColumn(
  ChampionColumn columnField,
  List<FormBuilderError> errors,
  FieldColorScheme colorScheme,
) {
  return Container(
    // Example styling or border:
    decoration: BoxDecoration(
      border: Border.all(
        color: colorScheme.borderColor,
      ),
    ),
    padding: const EdgeInsets.all(8.0),
    child: Column(
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
        ...childFieldWidgets,
        // If we're rolling up errors, display them here
        if (columnField.rollUpErrors && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map(
                  (err) => Text(
                    err.reason,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
                .toList(),
          ),
        ]
      ],
    ),
  );
}
