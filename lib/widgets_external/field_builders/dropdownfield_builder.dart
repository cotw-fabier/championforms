import 'package:championforms/functions/inputdecoration_from_theme.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget dropdownFieldBuilder(
  BuildContext context,
  WidgetRef ref,
  String formId,
  List<MultiselectOption> choices,
  ChampionOptionSelect field,
  FieldState currentState,
  FieldColorScheme currentColors,
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  return DropdownButtonFormField<String>(
      value: choices.isNotEmpty ? choices.first.value.toString() : null,
      items: field.options
          .map((option) => DropdownMenuItem<String>(
                value: option.value.toString(),
                child: Text(option.label),
              ))
          .toList(),
      onSaved: field.onSubmit != null
          ? (String? value) {
              final FormResults results = FormResults.getResults(
                  ref: ref, formId: formId, fields: [field]);
              field.onSubmit!(results);
            }
          : null,
      onChanged: (String? value) {
        // Find the value we're going to pass.
        if (value != null) {
          final selectedOption =
              field.options.firstWhere((val) => value == val.value.toString());

          updateSelectedOption(selectedOption);
        } else {
          updateSelectedOption(null);
        }

// Handle onchanged behavior
        if (field.onChange != null) {
          final FormResults results =
              FormResults.getResults(ref: ref, formId: formId, fields: [field]);

          field.onChange!(results);
        }
      },
      decoration: getInputDecorationFromScheme(currentColors));
}
