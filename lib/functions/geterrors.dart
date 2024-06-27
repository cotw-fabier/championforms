import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresultstype.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/providers/formerrorprovider.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

List<FormBuilderError> getFormBuilderErrors(
    {required List<FormFieldDef> fields,
    required Map<String, FormResults> results,
    required String formId,
    required WidgetRef ref}) {
  List<FormBuilderError> errors = [];
  for (final field in fields) {
    final FormResults? result = results[field.id];
    // Skip validation if no result is found.
    if (result == null) continue;
    // skip validation if the field is hidden.
    if (field.hideField == true) continue;
    // skip validation if the field is locked.
    if (field.active == false) continue;

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

      if (errorResult) {
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
