// Suggested location: lib/default_fields/championcheckboxselect_builder.dart
// (or add to an existing relevant file)

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/convienence_classes/checkboxselect.dart'; // Import the specific field type
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';

Widget buildCheckboxSelect(
    BuildContext context,
    FormController controller,
    CheckboxSelect field, // Use the specific field type
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus) {
  // Use the field's own builder logic (which defaults to checkboxFieldBuilder)
  return field.fieldBuilder(
    context,
    controller,
    field, // Pass the specific field instance
    currentColors,
    updateFocus,
    (MultiselectOption? selectedOption) {
      // Update selected logic (handles both single and multi-select via controller)
      // The specific interaction (add/remove/replace) is managed within updateMultiselectValues
      if (selectedOption != null) {
        controller.updateMultiselectValues(field.id, [selectedOption],
            multiselect: field.multiselect);
      } else {
        // This 'else' might be less relevant for checkboxes unless there's a specific 'clear' action
        // Depending on checkboxFieldBuilder's behavior, resetting might occur differently.
        // Keeping it for consistency with buildOptionSelect pattern.
        // If multiselect is true, resetting typically clears all selections.
        // If multiselect is false, this might deselect the radio button equivalent.
        if (field.multiselect) {
          controller.resetMultiselectChoices(field.id);
        } else {
          // For single select (radio button style), null means deselect/reset.
          controller.resetMultiselectChoices(field.id);
        }
      }
      // --- Common logic ---
      if (field.validateLive == true) {
        FormResults.getResults(controller: controller, fields: [field]);
      }
      if (field.onChange != null) {
        final results =
            FormResults.getResults(controller: controller, fields: [field]);
        field.onChange!(results);
      }
    },
  );
}
