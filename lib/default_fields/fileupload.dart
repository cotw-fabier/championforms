// Suggested location: lib/default_fields/championfileupload_builder.dart
// (or add to an existing relevant file)

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/fileupload.dart'; // Import the specific field type
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';

/// Builder function for FileUpload fields.
///
/// Updated in v0.5.4 to remove updateFocus parameter for consistency with
/// other field types. FileUpload will be fully refactored to use StatefulFieldWidget
/// in a future release.
///
/// For now, this builder continues to use the old internal widget implementation
/// while maintaining the new external API.
Widget buildFileUpload(
    BuildContext context,
    FormController controller,
    FileUpload field, // Use the specific field type
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus) {
  // Use the field's own builder logic (which defaults to fileUploadFieldBuilder)
  return field.fieldBuilder(
    context,
    controller,
    field, // Pass the specific field instance
    currentColors,
    (FieldOption? selectedOption) {
      // Update selected logic: A new file is uploaded/selected, or potentially removed.
      // The FieldOption's additionalData should contain the FileModel.
      if (selectedOption != null) {
        // updateMultiselectValues handles adding/removing based on multiselect flag
        controller.updateMultiselectValues(field.id, [selectedOption],
            multiselect: field.multiselect);
      } else {
        // Null likely signifies clearing the selection or a specific file removal action
        // depending on the fileUploadFieldBuilder's implementation.
        // Assuming reset/clear all for simplicity based on the pattern.
        controller.resetMultiselectChoices(field.id);
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
