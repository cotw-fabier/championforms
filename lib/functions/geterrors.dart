import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/providers/formerrorprovider.dart';
import 'package:championforms/providers/formfieldsstorage.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<FormBuilderError> getFormBuilderErrors(
    {List<FormFieldDef>? fields,
    required List<FieldResults> results,
    required String formId,
    required WidgetRef ref}) {
  List<FormBuilderError> errors = [];

  List<FormFieldDef> finalFields =
      fields ?? ref.read(formFieldsStorageNotifierProvider(formId));

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
    for (final FormBuilderValidator validator in field.validators ?? []) {
      // Start by invalidating previous errors.
      ref
          .read(formBuilderErrorNotifierProvider(
                  formId, field.id, validatorPosition)
              .notifier)
          .clearError();

      final errorResult = validator.validator(result);

      if (!errorResult) {
        final errorOutput = FormBuilderError(
          fieldId: field.id,
          formId: formId,
          reason: validator.reason,
          validatorPosition: validatorPosition,
        );

        errors.add(errorOutput);

        ref
            .read(formBuilderErrorNotifierProvider(
                    formId, field.id, validatorPosition)
                .notifier)
            .setError(errorOutput);
      }

      validatorPosition++;
    }
  }

  return errors;
}
