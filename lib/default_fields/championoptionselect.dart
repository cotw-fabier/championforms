import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';

Widget buildChampionOptionSelect(
    BuildContext context,
    ChampionFormController controller,
    ChampionOptionSelect field,
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus) {
  // Use the field's own builder logic
  return field.fieldBuilder(
      context,
      controller,
      field.options, // Pass options
      field,
      currentState,
      currentColors,
      controller
              .findMultiselectValue(field.id)
              ?.values
              .map((v) => v.value ?? '')
              .toList() ??
          [], // Get current value for default
      updateFocus, (MultiselectOption? selectedOption) {
    // Update selected logic
    if (selectedOption != null) {
      controller.updateMultiselectValues(field.id, [selectedOption],
          multiselect: field.multiselect);
    } else {
      controller.resetMultiselectChoices(field.id);
    }
    if (field.validateLive == true) {
      FormResults.getResults(controller: controller, fields: [field]);
    }
    if (field.onChange != null) {
      final results =
          FormResults.getResults(controller: controller, fields: [field]);
      field.onChange!(results);
    }
  });
}
