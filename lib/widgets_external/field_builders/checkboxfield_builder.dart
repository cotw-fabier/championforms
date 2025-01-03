import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/multiselect_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget checkboxFieldBuilder(
  BuildContext context,
  WidgetRef ref,
  String formId,
  List<MultiselectOption> choices,
  ChampionOptionSelect field,
  FieldState currentState,
  FieldColorScheme currentColors,
  List<String>? defaultValue,
  Function(bool focused) updateFocus,
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  return MultiselectWidget(
    id: formId + field.id,
    requestFocus: field.requestFocus,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // If you still want an "input decoration" style, you can add a label or similar.
        // Otherwise, just display the checkboxes.
        // e.g.:
        // if (field.label != null) Text(field.label, style: TextStyle(...)),

        ...field.options.map(
          (option) {
            // Check if this option is in the defaultValue (list of strings)
            final bool isChecked =
                defaultValue?.contains(option.value.toString()) ?? false;

            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                option.label,
                style: TextStyle(color: currentColors.textColor),
              ),
              activeColor: currentColors.textColor,
              hoverColor: currentColors.hintTextColor,
              tileColor: currentColors.backgroundColor,
              value: isChecked,
              onChanged: (bool? value) {
                // The user checked this box
                updateSelectedOption(option);

                // Handle onChanged behavior if provided
                if (field.onChange != null) {
                  final FormResults results = FormResults.getResults(
                    ref: ref,
                    formId: formId,
                    fields: [field],
                  );
                  field.onChange!(results);
                }

                // If you also want to handle onSubmit when toggling checkboxes
                if (field.onSubmit != null) {
                  final FormResults results = FormResults.getResults(
                    ref: ref,
                    formId: formId,
                    fields: [field],
                  );
                  field.onSubmit!(results);
                }
              },
            );
          },
        ),
      ],
    ),
  );
}
