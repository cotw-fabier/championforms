import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/material.dart';

Widget fileUploadFieldBuilder(
  BuildContext context,
  ChampionFormController controller,
  ChampionOptionSelect field,
  FieldColorScheme currentColors,
  Function(bool focused) updateFocus,
  Function(MultiselectOption? selectedOption) updateSelectedOption,
) {
  return FileUploadWidget(
    id: field.id,
    controller: controller,
    field: field,
    currentColors: currentColors,
    onFocusChange: (bool focus) => updateFocus(focus),
    onFileOptionChange: (MultiselectOption? option) {
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
