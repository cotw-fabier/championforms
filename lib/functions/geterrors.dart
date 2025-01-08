import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:collection/collection.dart';

List<FormBuilderError> getFormBuilderErrors({
  List<FormFieldDef>? fields,
  required List<FieldResults> results,
  required ChampionFormController controller,
}) {
  List<FormBuilderError> errors = [];

  List<FormFieldDef> finalFields = fields ?? controller.fields;

  for (final field in finalFields) {
    final FieldResults? result =
        results.firstWhereOrNull((item) => item.id == field.id);
    // Skip validation if no result is found.
    if (result == null) continue;
    // skip validation if the field is hidden.
    if (field.hideField == true) continue;
    // skip validation if the field is locked.
    if (field.disabled == true) continue;

    // Run the validators in order and add the results to the errors.
    int validatorPosition = 0;
    // Start by invalidating previous errors.
    controller.clearErrors(field.id);
    for (final FormBuilderValidator validator in field.validators ?? []) {
      final errorResult = validator.validator(result);

      if (!errorResult) {
        final errorOutput = FormBuilderError(
          fieldId: field.id,
          reason: validator.reason,
          validatorPosition: validatorPosition,
        );

        errors.add(errorOutput);
        controller.addError(errorOutput);
      }

      validatorPosition++;
    }
  }

  return errors;
}
