import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:collection/collection.dart';

import 'package:flutter/foundation.dart'; // For debugPrint

// Assuming FormFieldDef, BaseFieldResults, FieldResults, ChampionFormController,
// FormBuilderValidator, and FormBuilderError classes are accessible.

List<FormBuilderError> getFormBuilderErrors({
  required List<BaseFieldResults> results, // Changed to List<BaseFieldResults>
  required Map<String, FormFieldDef> definitions, // Added definitions map
  required ChampionFormController
      controller, // Keep controller for error management
}) {
  final List<FormBuilderError> errors = [];

  // Iterate through the definitions map keys (field IDs)
  for (final fieldId in definitions.keys) {
    final fieldDef = definitions[fieldId];
    final baseResult = results.firstWhereOrNull((r) => r.id == fieldId);

    // Skip validation checks if definition or result is missing
    if (fieldDef == null || baseResult == null) {
      debugPrint(
          "Skipping validation for $fieldId: Missing definition or result.");
      continue;
    }

    final FieldResultAccessor fieldAccessor;
    if (baseResult is! FieldResults) {
      debugPrint(
          "Error in getFormBuilderErrors: Result for '$fieldId' is not a FieldResults instance. Skipping.");
      continue;
    }

    // Skip validation if the field is hidden or disabled
    if (fieldDef.hideField == true) {
      debugPrint("Skipping validation for $fieldId: Field is hidden.");
      continue;
    }
    if (fieldDef.disabled == true) {
      debugPrint("Skipping validation for $fieldId: Field is disabled.");
      continue;
    }

    // Get the actual value from the FieldResults object
    final dynamic fieldValue = baseResult.value;

    // Clear previous errors for this field *before* running new validation
    // Note: Set noNotify to true if addError below also notifies, to prevent double notifications.
    // Adjust based on whether clearErrors/addError notify listeners internally.
    controller.clearErrors(fieldId,
        noNotify: true); // Assuming clearErrors might notify

    int validatorPosition = 0;
    if (fieldDef.validators != null) {
      // Iterate through the validators (List<FormBuilderValidator<dynamic>>)
      for (final validatorDef in fieldDef.validators!) {
        bool validationPassed = true; // Assume pass unless validator fails
        try {
          // Call the validator function, passing the actual field VALUE
          // validatorDef.validator expects type T, fieldValue is dynamic.
          if (!validatorDef.validator(fieldValue)) {
            validationPassed = false;
          }
        } catch (e) {
          // Catch potential runtime type errors during the dynamic validator call
          debugPrint(
              "Error executing validator $validatorPosition for field '$fieldId': $e. Value type: ${fieldValue?.runtimeType}");
          // Consider the validation as failed if an error occurs during execution
          validationPassed = false;

          // Add a specific error for the failed validator execution
          final errorOutput = FormBuilderError(
            fieldId: fieldId,
            reason:
                "Validator execution error: ${e.toString()}", // Use specific reason
            validatorPosition: validatorPosition,
          );
          errors.add(errorOutput);
          // Add error to controller (check if addError notifies)
          controller.addError(errorOutput,
              noNotify: false); // Let addError notify
        }

        // If the validation explicitly failed (returned false)
        if (!validationPassed) {
          final errorOutput = FormBuilderError(
            fieldId: fieldId,
            reason: validatorDef
                .reason, // Use the reason from the validator definition
            validatorPosition: validatorPosition,
          );
          // Avoid adding duplicate errors if already added in catch block
          if (!errors.any((err) =>
              err.fieldId == fieldId &&
              err.validatorPosition == validatorPosition)) {
            errors.add(errorOutput);
            // Add error to controller (check if addError notifies)
            controller.addError(errorOutput,
                noNotify: false); // Let addError notify
          }
        }
        validatorPosition++;
      }
    }
  }

  // Optionally, notify listeners once after all errors are processed if
  // clearErrors and addError had noNotify: true.
  // controller.notifyListeners();

  return errors;
}
