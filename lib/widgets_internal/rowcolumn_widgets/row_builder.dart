// Take in a list of ChampionColumn and display them horizontally or vertically depending on if the collapse bool is set.

import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

/// A helper widget or function to display a [ChampionRow].
/// It arranges a list of column widgets horizontally or vertically
/// depending on [rowField.collapse].
/// If [rowField.rollUpErrors] is `true`, it displays all rolled-up
/// errors at the bottom.
Widget buildChampionRow(
  ChampionRow rowField,
  List<Widget> columnWidgets,
  List<FormBuilderError> errors,
  FieldColorScheme colorScheme,
) {
  // You can style the Row container or add labels, etc. below as needed
  return Container(
    // Example style or color if you want to highlight the row based on the colorScheme
    decoration: BoxDecoration(
      border: Border.all(
        color: colorScheme.borderColor,
      ),
    ),
    padding: const EdgeInsets.all(8.0),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columnWidgets,
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: columnWidgets,
          ),
        // If we're rolling up errors, display them here
        if (rowField.rollUpErrors && errors.isNotEmpty) ...[
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
