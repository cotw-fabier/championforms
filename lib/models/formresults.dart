import 'dart:convert';

import 'package:championforms/championforms.dart';
import 'package:championforms/models/field_types/formfielddefnull.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

// --- Base class for type erasure in lists ---
abstract class BaseFieldResults {
  final String id;
  BaseFieldResults({required this.id});
}

class FieldResults<T> extends BaseFieldResults {
  final T value; // Stores the actual typed value

  FieldResults({
    required super.id,
    required this.value,
  });
}

/// Provides access to a single field's result value and its conversion methods.
/// Returned by FormResults.grab().
class FieldResultAccessor {
  final String _id;
  final dynamic _value; // The raw value directly stored
  final FormFieldDef<dynamic>
      _definition; // The corresponding field definition, stored as dynamic

  FieldResultAccessor._(this._id, this._value, this._definition);

  /// Helper to get the value to be used by converters (handles default value).
  dynamic _getValueForConversion() {
    // Prefer the actual value if it's not null.
    // Otherwise, use the default value from the definition.
    return _value ?? _definition.defaultValue;
  }

  /// Get the raw value cast to type T.
  /// Returns null if the field's actual value is not of type T.
  T? asRaw<T>() {
    final valueToConsider = _getValueForConversion(); // Use helper
    if (valueToConsider is T) {
      return valueToConsider;
    }
    // This debug print might be redundant if the value was already null
    // and the default didn't match T.
    if (_value != null && _value is! T) {
      // Only print if _value existed but was wrong type
      debugPrint(
          "asRaw failed for field '$_id'. Expected $T, found ${_value?.runtimeType}");
    } else if (_value == null &&
        _definition.defaultValue != null &&
        _definition.defaultValue is! T) {
      // Only print if default existed but was wrong type
      debugPrint(
          "asRaw failed for field '$_id'. Expected $T, default value was ${_definition.defaultValue?.runtimeType}");
    }
    return null;
  }

  /// Get the value converted to a String using the field's definition.
  String asString({String fallback = ""}) {
    try {
      // Get the converter function. Its static type is Function, runtime type depends on the field.
      final Function converterFunction = _definition.asStringConverter;
      final valueToConvert = _getValueForConversion();

      if (valueToConvert == null) {
        // If both original value and default value are null, return fallback.
        // This condition might be rare if fields usually have defaults or initial values.
        // debugPrint("Field '$_id': Value and default value are both null for asString. Returning fallback.");
        return fallback;
      }

      // Use Function.apply for dynamic invocation. Pass valueToConvert in a list.
      final result = Function.apply(converterFunction, [valueToConvert]);

      // Check the type of the result.
      if (result is String) {
        return result;
      } else {
        // Log if the converter didn't return a String as expected.
        debugPrint(
            "Field '$_id': asString converter returned non-String result: $result (${result?.runtimeType}). Returning fallback.");
        return fallback;
      }
    } catch (e, s) {
      // Log any exception during the conversion process.
      _logConversionError('asStringConverter', e, s);
      return fallback;
    }
  }

  /// Get the value converted to a List<String> using the field's definition.
  List<String> asStringList({List<String> fallback = const []}) {
    try {
      final Function converterFunction = _definition.asStringListConverter;
      final valueToConvert = _getValueForConversion();

      if (valueToConvert == null) {
        // debugPrint("Field '$_id': Value and default value are both null for asStringList. Returning fallback.");
        return fallback;
      }

      // Use Function.apply
      final result = Function.apply(converterFunction, [valueToConvert]);

      // Check if the result is the expected List<String>
      if (result is List<String>) {
        return result;
      } else if (result is List) {
        // If it's a List but not specifically List<String>, attempt to cast its elements.
        // This handles cases where the runtime type might be List<dynamic>.
        try {
          return result.cast<String>().toList(); // Use toList() after cast
        } catch (castError, castStack) {
          debugPrint(
              "Field '$_id': asStringList converter returned List but failed to cast elements to String: $castError\n$castStack. Returning fallback.");
          return fallback;
        }
      } else {
        // Log if the result wasn't a List at all.
        debugPrint(
            "Field '$_id': asStringList converter returned non-List result: $result (${result?.runtimeType}). Returning fallback.");
        return fallback;
      }
    } catch (e, s) {
      _logConversionError('asStringListConverter', e, s);
      return fallback;
    }
  }

  /// Get the value converted to a bool using the field's definition.
  bool asBool({bool fallback = false}) {
    try {
      final Function converterFunction = _definition.asBoolConverter;
      final valueToConvert = _getValueForConversion();

      if (valueToConvert == null) {
        // debugPrint("Field '$_id': Value and default value are both null for asBool. Returning fallback.");
        return fallback;
      }

      // Use Function.apply
      final result = Function.apply(converterFunction, [valueToConvert]);

      // Check if the result is a boolean.
      if (result is bool) {
        return result;
      } else {
        debugPrint(
            "Field '$_id': asBool converter returned non-bool result: $result (${result?.runtimeType}). Returning fallback.");
        return fallback;
      }
    } catch (e, s) {
      _logConversionError('asBoolConverter', e, s);
      return fallback;
    }
  }

  /// Get the value as a List<MultiselectOption>.
  /// This method specifically handles ChampionOptionSelect fields.
  /// It doesn't use a generic converter but checks the value type directly.
  List<MultiselectOption> asMultiselectList() {
    // Check definition type for early exit and clarity.
    if (_definition is! ChampionOptionSelect) {
      // Log if called on an incompatible field type.
      debugPrint(
          "asMultiselectList called on field '$_id' which is not a ChampionOptionSelect type (${_definition.runtimeType}). Returning empty list.");
      return [];
    }

    final valueToConsider = _getValueForConversion(); // Get value or default

    if (valueToConsider is List) {
      // If it's a list, filter its elements to ensure they are MultiselectOption.
      // This handles cases where the list might contain other types (though unlikely if well-managed).
      final List<MultiselectOption> options = valueToConsider
          .whereType<MultiselectOption>() // Safely filters and casts
          .toList();

      // Optional: Log a warning if the original list contained non-MultiselectOption items.
      if (options.length != valueToConsider.length) {
        debugPrint(
            "Warning for field '$_id': asMultiselectList found items that were not MultiselectOption.");
      }
      return options;
    } else if (valueToConsider == null) {
      // If both value and default were null.
      return [];
    } else {
      // Log if the value (or default) was not a List type.
      debugPrint(
          "asMultiselectList failed for field '$_id'. Value is not a List. Found type: ${valueToConsider?.runtimeType}");
      return []; // Return empty list if not a list
    }
  }

  /// Get a single MultiselectOption from the list by its value (ID).
  MultiselectOption? asMultiselect(String optionValue) {
    // Reuse the corrected asMultiselectList logic.
    final List<MultiselectOption> options = asMultiselectList();
    if (options.isEmpty) {
      return null; // No options to search within.
    }
    // Use firstWhereOrNull for safe searching.
    return options.firstWhereOrNull((option) => option.value == optionValue);
  }

  /// Get the value converted to a List<FileModel> using the field's definition.
  List<FileModel> asFileList({List<FileModel> fallback = const []}) {
    // Get the specific file list converter function from the definition. Might be null.
    final converterFunction = _definition.asFileListConverter;

    // Check if this field type actually supports file list conversion.
    if (converterFunction == null) {
      // debugPrint("Field '$_id': This field type does not support asFileList conversion. Returning fallback.");
      return fallback;
    }

    try {
      final valueToConvert = _getValueForConversion();

      if (valueToConvert == null) {
        // debugPrint("Field '$_id': Value and default value are both null for asFileList. Returning fallback.");
        return fallback;
      }

      // Use Function.apply
      final result = Function.apply(converterFunction, [valueToConvert]);

      // Check if the result is the expected List<FileModel>
      if (result is List<FileModel>) {
        return result;
      } else if (result is List) {
        // If it's a List but not List<FileModel>, attempt to cast elements.
        try {
          return result.cast<FileModel>().toList();
        } catch (castError, castStack) {
          debugPrint(
              "Field '$_id': asFileList converter returned List but failed to cast elements to FileModel: $castError\n$castStack. Returning fallback.");
          return fallback;
        }
      } else {
        // Log if the result wasn't a List.
        debugPrint(
            "Field '$_id': asFileList converter returned non-List result: $result (${result?.runtimeType}). Returning fallback.");
        return fallback;
      }
    } catch (e, s) {
      _logConversionError('asFileListConverter', e, s);
      return fallback;
    }
  }

  /// Helper for logging conversion errors consistently.
  void _logConversionError(
      String converterName, dynamic error, StackTrace stack) {
    final valueToConvert =
        _getValueForConversion(); // Recalculate for logging context
    debugPrint("--- Conversion Error ---");
    debugPrint("Field ID: '$_id'");
    debugPrint("Converter: $converterName");
    debugPrint("Error: $error");
    debugPrint("Stack: $stack");
    debugPrint(" -> Value was: $_value (${_value?.runtimeType})");
    debugPrint(
        " -> Default was: ${_definition.defaultValue} (${_definition.defaultValue?.runtimeType})");
    debugPrint(
        " -> Effective Value for Conversion: $valueToConvert (${valueToConvert?.runtimeType})");
    // Attempt to get the runtime type of the specific converter function
    try {
      dynamic actualConverter;
      switch (converterName) {
        case 'asStringConverter':
          actualConverter = _definition.asStringConverter;
          break;
        case 'asStringListConverter':
          actualConverter = _definition.asStringListConverter;
          break;
        case 'asBoolConverter':
          actualConverter = _definition.asBoolConverter;
          break;
        case 'asFileListConverter':
          actualConverter = _definition.asFileListConverter;
          break;
        default:
          actualConverter = 'Unknown Converter';
          break;
      }
      // Ensure actualConverter isn't null before accessing runtimeType
      if (actualConverter != null) {
        debugPrint(
            " -> Converter function runtime type: ${actualConverter.runtimeType}");
      } else if (converterName == 'asFileListConverter') {
        // This is expected if the field doesn't support file conversion
        debugPrint(
            " -> Converter function: Not available (field likely doesn't support file conversion).");
      } else {
        debugPrint(" -> Converter function: Could not be retrieved.");
      }
    } catch (e) {
      debugPrint(
          " -> Could not determine converter function type at runtime: $e");
    }
    debugPrint("------------------------");
  }
}

class FileResultData {
  final String name; // e.g. file name
  final String path; // e.g. full path (value from MultiselectOption)
  final FileModel?
      fileDetails; // raw file data from MultiselectOption.additionalData
  const FileResultData({
    required this.name,
    required this.path,
    this.fileDetails,
  });
}

class FormResults {
  final bool errorState;
  final List<FormBuilderError> formErrors;
  // Store raw values directly, keyed by field ID.
  final Map<String, dynamic> results;
  // Store field definitions, keyed by field ID. Use dynamic type argument.
  final Map<String, FormFieldDef<dynamic>> fieldDefinitions;
  const FormResults({
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
    required this.fieldDefinitions,
  });

  factory FormResults.getResults({
    required ChampionFormController controller,
    bool checkForErrors = true, // Whether to run validation.
    List<FormFieldDef<dynamic>>?
        fields, // Optional: Process only specific fields.
  }) {
    // Determine the list of fields to process.
    List<FormFieldDef<dynamic>> finalFields = fields ?? controller.activeFields;

    // Initialize containers for results, definitions, and errors.
    Map<String, dynamic> collectedResults = {};
    Map<String, FormFieldDef<dynamic>> definitions = {};
    List<FormBuilderError> formErrors = [];
    bool errorState = false; // Track overall error status.

    // Iterate through each field definition.
    for (final field in finalFields) {
      // Skip fields explicitly marked as hidden.
      if (field.hideField) continue;

      // Store the field definition, casting its type parameter to dynamic for the map.
      // The actual instance retains its specific type (e.g., FormFieldDef<String>).
      definitions[field.id] = field as FormFieldDef<dynamic>;

      // Retrieve the raw value from the controller.
      // Use dynamic type hint. Fall back to the field's default value if controller returns null.
      final rawValue =
          controller.getFieldValue<dynamic>(field.id) ?? field.defaultValue;

      // Store the raw value (which could be null) in the results map.
      collectedResults[field.id] = rawValue;

      // --- Validation (if enabled) ---
      if (checkForErrors &&
          field.validators != null &&
          field.validators!.isNotEmpty) {
        int validatorPos = 0; // Track position for error reporting.
        // Iterate through each validator defined for the field.
        for (final validatorDef in field.validators!) {
          try {
            // Get the validator function (static type Function).
            final Function validatorFunc = validatorDef.validator;
            // Dynamically invoke the validator using Function.apply.
            // Pass the rawValue (which might be null) in a list.
            // Cast the result to bool, assuming validators return boolean.
            final bool isValid =
                Function.apply(validatorFunc, [rawValue]) as bool;

            // If the validator returns false, add an error.
            if (!isValid) {
              formErrors.add(FormBuilderError(
                reason:
                    validatorDef.reason, // User-defined reason for the error.
                fieldId: field.id,
                validatorPosition: validatorPos,
              ));
              errorState = true; // Mark that at least one error occurred.
            }
          } catch (e, s) {
            // Catch exceptions during validator invocation (e.g., type error inside validator).
            debugPrint(
                "--- Validation Error --- \nField ID: '${field.id}' \nValidator Position: $validatorPos \nReason: ${validatorDef.reason} \nError: $e\nStack: $s");
            debugPrint(" -> Value was: '$rawValue' (${rawValue?.runtimeType})");
            debugPrint(
                " -> Validator func type: ${validatorDef.validator.runtimeType}");
            debugPrint("----------------------");
            // Add a generic error indicating validation failure.
            formErrors.add(FormBuilderError(
              reason:
                  "Validation failed for rule '${validatorDef.reason}'. Error: $e",
              fieldId: field.id,
              validatorPosition: validatorPos,
            ));
            errorState = true;
          }
          validatorPos++; // Increment validator position.
        }
      }
    }

    // Return the constructed FormResults object.
    return FormResults(
      formErrors: formErrors,
      errorState: errorState,
      results: collectedResults,
      fieldDefinitions: definitions,
    );
  }

  // --- Helper to get result and definition ---
  // Returns null if field not found
  // ({FieldResults<T>? result, FormFieldDef<T>? definition}) _getResultAndDef<T>(
  //     String id) {
  //   final baseResult = results.firstWhereOrNull((item) => item.id == id);
  //   final definition = fieldDefinitions[id];

  //   if (baseResult == null || definition == null) {
  //     return (result: null, definition: null); // Field not found
  //   }

  //   // Try to safely cast
  //   if (baseResult is FieldResults<T> && definition is FormFieldDef<T>) {
  //     return (
  //       result: baseResult as FieldResults<T>?,
  //       definition: definition as FormFieldDef<T>?
  //     );
  //   } else {
  //     // Log or handle type mismatch error?
  //     // This can happen if getAsRaw<T> is called with the wrong T
  //     debugPrint(
  //         "Type mismatch for field '$id'. Expected $T but found ${baseResult.runtimeType} / ${definition.runtimeType}");
  //     return (result: null, definition: null);
  //   }
  // }

  // --- New Accessor Methods ---

  /// Get the raw value of the field cast to type T.
  /// Returns null if the field doesn't exist or the type T is incorrect.
  T? getAsRaw<T>(String id) {
    // Check if the field definition exists.
    if (hasField(id)) {
      // Delegate to the accessor's logic for consistency.
      // grab(id) throws if field doesn't exist, but hasField check prevents that here.
      return grab(id).asRaw<T>();
    }
    debugPrint("getAsRaw failed for field '$id'. Field not found in results.");
    return null;
  }

  FieldResultAccessor grab(String id) {
    // Retrieve the potentially null value and definition from the maps.
    final value = results[id];
    final definition = fieldDefinitions[id];

    // Check if the definition exists. If yes, the field was processed.
    // Check if the definition exists.
    if (definition != null) {
      // If yes, the field was processed and has a valid definition.
      // Create the accessor, passing the (potentially null) value and the actual definition.
      return FieldResultAccessor._(id, value, definition);
    } else {
      // The definition wasn't found for this id.
      debugPrint(// Using debugPrint as this is Flutter code
          "Debug in grab(): Field definition for '$id' not found. " +
              "Returning a FieldResultAccessor with a dummy definition. " +
              "It could be that the field wasn't displayed and not added to the controller" +
              "So returning default empty value" +
              "Available field definition keys: ${fieldDefinitions.keys.join(', ')}");

      // Create the "dummy" definition.
      final FormFieldDef<dynamic> dummyDefinition = FormFieldNull(id: id);

      // Create the accessor, passing null for the value (as it's an "empty" accessor
      // due to missing definition) and the dummy definition.
      return FieldResultAccessor._(id, null, dummyDefinition);
    }
  }

  /// Convenience method to check if a field definition exists for a given ID.
  bool hasField(String id) {
    return fieldDefinitions.containsKey(id);
  }
}
