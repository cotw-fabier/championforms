import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/material.dart';

/// File upload field builder for FileUpload fields.
///
/// Updated in v0.5.4 to remove updateFocus parameter.
/// Focus management will be handled automatically by StatefulFieldWidget
/// when FileUpload is refactored (planned for future release).
///
/// Note: FileUpload widget still uses old API internally until full refactoring.
Widget fileUploadFieldBuilder(
  BuildContext context,
  FormController controller,
  OptionSelect field,
  FieldColorScheme currentColors,
  Function(FieldOption? selectedOption) updateSelectedOption,
) {
  return FileUploadWidget(
    id: field.id,
    controller: controller,
    field: field,
    currentColors: currentColors,
    onFocusChange: (bool focus) {
      // TODO: Remove this when FileUpload is refactored to use StatefulFieldWidget
      // For now, manually update focus tracking in controller
      controller.setFieldFocus(field.id, focus);
    },
    onFileOptionChange: (FieldOption? option) {
      // Commented out because we don't know what file options we have previously to uploading files.
      // So this has to be handled down at the widget level.
      // updateSelectedOption(option);

      if (field.onChange != null) {
        final FormResults results = FormResults.getResults(
          controller: controller,
          fields: [field],
        );
        field.onChange!(results);
      }
      // If also want to handle onSubmit
      if (field.onSubmit != null) {
        final FormResults results = FormResults.getResults(
          controller: controller,
          fields: [field],
        );
        field.onSubmit!(results);
      }
    },
  );
}
