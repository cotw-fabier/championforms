import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/convienence_classes/chipselect.dart'; // Import the specific field type
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';

Widget buildChipSelect(
    BuildContext context,
    FormController controller,
    ChipSelect field, // Use the specific field type
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus) {
  // Use the field's own builder logic (which defaults to checkboxFieldBuilder in the provided code)
  // Note: You might want ChipSelect to default to a specific chipFieldBuilder instead.
  return field.fieldBuilder(
    context,
    controller,
    field, // Pass the specific field instance
    currentColors,
    updateFocus,
    (MultiselectOption? selectedOption) {
      // Update selected logic - same logic as checkbox applies
      if (selectedOption != null) {
        controller.updateMultiselectValues(field.id, [selectedOption],
            multiselect: field.multiselect);
      } else {
        // Reset logic for chips (handle single vs multi)
        if (field.multiselect) {
          // Assuming clear/reset for null. Deselection of a specific chip should pass that chip.
          controller.resetMultiselectChoices(field.id);
        } else {
          // Single select chip (radio button style) reset.
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
