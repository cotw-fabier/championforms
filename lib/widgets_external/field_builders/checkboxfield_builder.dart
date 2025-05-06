import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/multiselect_widget.dart';
import 'package:flutter/material.dart';

Widget checkboxFieldBuilder(
  BuildContext context,
  ChampionFormController controller,
  ChampionOptionSelect field,
  FieldColorScheme currentColors,
  Function(bool focused) updateFocus,
  // updateSelectedOption is no longer directly needed here as we use toggleMultiSelectValue
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  // Listen to the controller to rebuild when the value changes
  // Use ListenableBuilder or Selector for more targeted rebuilds if needed,
  // but here we rely on the parent FormBuilder rebuilding.

  // Get the current selected options directly from the controller's value storage
  final List<MultiselectOption> currentSelectedOptions =
      controller.getFieldValue<List<MultiselectOption>>(field.id) ?? [];

  return MultiselectWidget(
    id: field.id,
    controller: controller,
    requestFocus: field.requestFocus,
    field: field,
    // The focus update is handled by MultiselectWidget internally via FocusNode listener
    // We don't need to explicitly pass updateFocus down if MultiselectWidget manages it.
    // Let's assume MultiselectWidget handles focus notification correctly.
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...(field.options ?? []).map(
          (option) {
            // Determine if this specific option is currently selected
            final bool isChecked = currentSelectedOptions
                .any((selected) => selected.value == option.value);

            return CheckboxListTile(
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                option.label,
                style: TextStyle(color: currentColors.textColor),
              ),
              activeColor:
                  currentColors.iconColor, // Use theme color for active
              checkColor:
                  currentColors.backgroundColor, // Color of the check mark
              hoverColor: currentColors.borderColor,
              tileColor: currentColors.backgroundColor,
              value: isChecked, // Use the current state from the controller
              onChanged: (bool? newValue) {
                // newValue is the target state after click
                if (newValue == null) return; // Should not happen

                // Use the dedicated toggle function in the controller.
                // This function handles adding/removing the value, triggering
                // live validation (if enabled), and calling onChange (if defined).
                if (newValue) {
                  // If the checkbox should become checked
                  controller.toggleMultiSelectValue(field.id,
                      toggleOn: [option.value]);
                } else {
                  // If the checkbox should become unchecked
                  controller.toggleMultiSelectValue(field.id,
                      toggleOff: [option.value]);
                }

                // No need to manually call validation or onChange here,
                // toggleMultiSelectValue -> updateFieldValue handles it.
              },
            );
          },
        ),
      ],
    ),
  );
}
