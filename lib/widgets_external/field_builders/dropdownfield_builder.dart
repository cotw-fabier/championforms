import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/functions/inputdecoration_from_theme.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/multiselect_widget.dart';
import 'package:flutter/material.dart';

Widget dropdownFieldBuilder(
  BuildContext context,
  ChampionFormController controller,
  List<MultiselectOption> choices,
  ChampionOptionSelect field,
  FieldState currentState,
  FieldColorScheme currentColors,
  List<String>? defaultValue,
  Function(bool focused) updateFocus,
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  return MultiselectWidget(
    id: field.id,
    controller: controller,
    requestFocus: field.requestFocus,
    child: DropdownButtonFormField<String>(
      value: defaultValue != null && defaultValue.isNotEmpty
          ? defaultValue.first
          : null,
      dropdownColor: currentColors.backgroundColor,
      items: field.options
          .map((option) => DropdownMenuItem<String>(
                value: option.value.toString(),
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: currentColors.textColor,
                  ),
                ),
              ))
          .toList(),
      onSaved: field.onSubmit != null
          ? (String? value) {
              final FormResults results = FormResults.getResults(
                  controller: controller, fields: [field]);
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
              FormResults.getResults(controller: controller, fields: [field]);

          field.onChange!(results);
        }
      },
      decoration: getInputDecorationFromScheme(currentColors)?.copyWith(
        prefixIcon: field.leading,
        suffixIcon: field.trailing,
        icon: field.icon,
      ),
    ),
  );
}
