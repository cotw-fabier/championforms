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
  final Field
      _definition; // The corresponding field definition, stored as dynamic
  final Map<String, dynamic> _results; // Reference to all results
  final Map<String, Field>
      _fieldDefinitions; // Reference to all field definitions

  FieldResultAccessor._(
    this._id,
    this._value,
    this._definition,
    this._results,
    this._fieldDefinitions,
  );

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

  /// Get the value as a List<FieldOption>.
  /// This method specifically handles OptionSelect fields.
  /// It doesn't use a generic converter but checks the value type directly.
  List<FieldOption> asMultiselectList() {
    // Check definition type for early exit and clarity.
    if (_definition is! OptionSelect) {
      // Log if called on an incompatible field type.
      debugPrint(
          "asMultiselectList called on field '$_id' which is not a OptionSelect type (${_definition.runtimeType}). Returning empty list.");
      return [];
    }

    final valueToConsider = _getValueForConversion(); // Get value or default

    if (valueToConsider is List) {
      // If it's a list, filter its elements to ensure they are FieldOption.
      // This handles cases where the list might contain other types (though unlikely if well-managed).
      final List<FieldOption> options = valueToConsider
          .whereType<FieldOption>() // Safely filters and casts
          .toList();

      // Optional: Log a warning if the original list contained non-FieldOption items.
      if (options.length != valueToConsider.length) {
        debugPrint(
            "Warning for field '$_id': asMultiselectList found items that were not FieldOption.");
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

  /// Get a single FieldOption from the list by its value (ID).
  FieldOption? asMultiselect(String optionValue) {
    // Reuse the corrected asMultiselectList logic.
    final List<FieldOption> options = asMultiselectList();
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

  /// Get the first file from the file list, or null if no files.
  /// Convenience method for single file upload fields.
  FileModel? asFile() {
    final fileList = asFileList();
    return fileList.isNotEmpty ? fileList.first : null;
  }

  /// Get the compound field value as a joined string from all sub-fields.
  ///
  /// This method detects compound fields by checking if the field ID has
  /// associated sub-fields (pattern: fields starting with `{fieldId}_`).
  /// It collects string values from all sub-fields, filters out empty values,
  /// and joins them with the specified delimiter.
  ///
  /// **Parameters:**
  /// - [delimiter]: String used to join sub-field values (default: ", ")
  /// - [fallback]: String to return if no sub-fields found or all are empty (default: "")
  ///
  /// **Returns:**
  /// A joined string of all non-empty sub-field values, or the fallback if
  /// no sub-fields exist or all sub-field values are empty.
  ///
  /// **Example:**
  /// ```dart
  /// // Assuming compound field "name" has sub-fields:
  /// // "name_firstname" = "John"
  /// // "name_middlename" = ""
  /// // "name_lastname" = "Doe"
  ///
  /// final fullName = results.grab("name").asCompound();
  /// // Result: "John, Doe" (middlename filtered out because empty)
  ///
  /// final fullNameSpaced = results.grab("name").asCompound(delimiter: " ");
  /// // Result: "John Doe"
  /// ```
  ///
  /// **Note:**
  /// If called on a non-compound field (no sub-fields found), returns the
  /// fallback value with a debug warning.
  String asCompound({String delimiter = ", ", String fallback = ""}) {
    // Get all sub-field IDs for this compound field
    final subFieldIds = _getSubFieldIds(_id);

    // If no sub-fields found, this is not a compound field
    if (subFieldIds.isEmpty) {
      debugPrint(
          "asCompound called on field '$_id' which has no sub-fields. Returning fallback.");
      return fallback;
    }

    // Collect string values from all sub-fields
    final subValues = <String>[];
    for (final subFieldId in subFieldIds) {
      // Access each sub-field's value through a new accessor
      final subFieldValue = _results[subFieldId];
      final subFieldDefinition = _fieldDefinitions[subFieldId];

      if (subFieldDefinition != null) {
        // Create accessor for this sub-field
        final subFieldAccessor = FieldResultAccessor._(
          subFieldId,
          subFieldValue,
          subFieldDefinition,
          _results,
          _fieldDefinitions,
        );

        // Get string value and add to list if not empty
        final stringValue = subFieldAccessor.asString();
        if (stringValue.isNotEmpty) {
          subValues.add(stringValue);
        }
      }
    }

    // Join all non-empty values with delimiter
    if (subValues.isEmpty) {
      return fallback;
    }

    return subValues.join(delimiter);
  }

  /// Helper method to get all sub-field IDs for a compound field.
  ///
  /// Queries the field definitions map for IDs starting with the pattern
  /// `{compoundId}_` to identify all sub-fields belonging to a compound field.
  ///
  /// **Parameters:**
  /// - [compoundId]: The ID of the compound field
  ///
  /// **Returns:**
  /// List of sub-field IDs that belong to the compound field, or empty list
  /// if no sub-fields found.
  ///
  /// **Example:**
  /// ```dart
  /// // If fieldDefinitions contains:
  /// // "name_firstname", "name_lastname", "email"
  ///
  /// final subFields = _getSubFieldIds("name");
  /// // Result: ["name_firstname", "name_lastname"]
  /// ```
  List<String> _getSubFieldIds(String compoundId) {
    final prefix = '${compoundId}_';
    return _fieldDefinitions.keys
        .where((id) => id.startsWith(prefix))
        .toList();
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
  final String path; // e.g. full path (value from FieldOption)
  final FileModel?
      fileDetails; // raw file data from FieldOption.additionalData
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
  final Map<String, Field> fieldDefinitions;
  const FormResults({
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
    required this.fieldDefinitions,
  });

  factory FormResults.getResults({
    required FormController controller,
    bool checkForErrors = true, // Whether to run validation.
    List<Field>? fields, // Optional: Process only specific fields.
  }) {
    // Determine the list of fields to process.
    List<Field> finalFields = fields ?? controller.activeFields;

    // Initialize containers for results, definitions, and errors.
    Map<String, dynamic> collectedResults = {};
    Map<String, Field> definitions = {};
    List<FormBuilderError> formErrors = [];
    bool errorState = false; // Track overall error status.

    // Separate compound fields for later validation
    List<CompoundField> compoundFields = [];

    // First pass: Collect all field values and definitions
    for (final field in finalFields) {
      // Skip fields explicitly marked as hidden.
      if (field.hideField) continue;

      // Store the field definition, casting its type parameter to dynamic for the map.
      // The actual instance retains its specific type (e.g., Field<String>).
      definitions[field.id] = field as Field;

      // Retrieve the raw value from the controller.
      // Use dynamic type hint. Fall back to the field's default value if controller returns null.
      final rawValue = controller.getFieldValue(field.id) ?? field.defaultValue;

      // Store the raw value (which could be null) in the results map.
      collectedResults[field.id] = rawValue;

      // Track compound fields for later validation
      if (field is CompoundField) {
        compoundFields.add(field);
      }
    }

    // Second pass: Run validation
    // Validate regular fields first, then compound fields
    for (final field in finalFields) {
      if (field.hideField) continue;

      final rawValue = collectedResults[field.id];

      // Skip compound fields in this pass (validated later)
      if (field is CompoundField) {
        continue;
      }

      // Validate regular fields
      if (rawValue == null) {
        _validateField<dynamic>(field, rawValue, controller, formErrors);
      } else if (rawValue is String) {
        _validateField<String>(
            field as Field, rawValue, controller, formErrors);
      } else if (rawValue is int) {
        _validateField<int>(
            field as Field, rawValue, controller, formErrors);
      } else if (rawValue is bool) {
        _validateField<bool>(
            field as Field, rawValue, controller, formErrors);
      } else if (rawValue is List<FieldOption>) {
        _validateField<List<FieldOption>>(
            field as Field, rawValue, controller, formErrors);
      } else {
        _validateField<dynamic>(field, rawValue, controller, formErrors);
      }

      if (formErrors.isNotEmpty) {
        errorState = true;
      }
    }

    // Third pass: Validate compound fields after all sub-fields are in definitions
    for (final compoundField in compoundFields) {
      _validateCompoundField(
          compoundField, collectedResults, definitions, controller, formErrors);

      if (formErrors.isNotEmpty) {
        errorState = true;
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
  // ({FieldResults<T>? result, Field<T>? definition}) _getResultAndDef<T>(
  //     String id) {
  //   final baseResult = results.firstWhereOrNull((item) => item.id == id);
  //   final definition = fieldDefinitions[id];

  //   if (baseResult == null || definition == null) {
  //     return (result: null, definition: null); // Field not found
  //   }

  //   // Try to safely cast
  //   if (baseResult is FieldResults<T> && definition is Field<T>) {
  //     return (
  //       result: baseResult as FieldResults<T>?,
  //       definition: definition as Field<T>?
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
      return FieldResultAccessor._(
          id, value, definition, results, fieldDefinitions);
    } else {
      // The definition wasn't found for this id.
      debugPrint(// Using debugPrint as this is Flutter code
          "Debug in grab(): Field definition for '$id' not found. " +
              "Returning a FieldResultAccessor with a dummy definition. " +
              "It could be that the field wasn't displayed and not added to the controller" +
              "So returning default empty value" +
              "Available field definition keys: ${fieldDefinitions.keys.join(', ')}");

      // Create the "dummy" definition.
      final Field dummyDefinition = NullField(id: id);

      // Create the accessor, passing null for the value (as it's an "empty" accessor
      // due to missing definition) and the dummy definition.
      return FieldResultAccessor._(
          id, null, dummyDefinition, results, fieldDefinitions);
    }
  }

  /// Convenience method to check if a field definition exists for a given ID.
  bool hasField(String id) {
    return fieldDefinitions.containsKey(id);
  }
}

// Add this helper method to your FormResults class:
void _validateField<T>(
  Field field,
  T? rawValue,
  FormController controller,
  List<FormBuilderError> formErrors,
) {
  if (field.validators == null || field.validators!.isEmpty || field.disabled) {
    return;
  }

  controller.clearErrors(field.id);

  for (int i = 0; i < field.validators!.length; i++) {
    final validator = field.validators![i];
    try {
      final bool isValid = validator.validator(rawValue as T?);

      if (!isValid) {
        final error = FormBuilderError(
          reason: validator.reason,
          fieldId: field.id,
          validatorPosition: i,
        );
        formErrors.add(error);
        controller.addError(error);
      }
    } catch (e, s) {
      // Handle validation errors
      debugPrint("Validation error for field ${field.id}: $e");
      formErrors.add(FormBuilderError(
        reason: "Validation failed: $e",
        fieldId: field.id,
        validatorPosition: i,
      ));
    }
  }
}

/// Validates a compound field using FormResults accessor.
///
/// Compound field validators expect a [FieldResultAccessor] that allows them
/// to access sub-field values via results.grab(). This is different from
/// regular field validators which receive the raw field value.
void _validateCompoundField(
  CompoundField field,
  Map<String, dynamic> collectedResults,
  Map<String, Field> definitions,
  FormController controller,
  List<FormBuilderError> formErrors,
) {
  if (field.validators == null || field.validators!.isEmpty || field.disabled) {
    return;
  }

  controller.clearErrors(field.id);

  // Create a temporary FormResults instance that compound field validators can use
  // to access sub-field values via results.grab()
  final tempResults = FormResults(
    formErrors: formErrors,
    errorState: formErrors.isNotEmpty,
    results: collectedResults,
    fieldDefinitions: definitions,
  );

  // Run each validator with the FormResults instance
  // Compound field validators expect FormResults (not FieldResultAccessor)
  // so they can call results.grab() to access sub-field values
  for (int i = 0; i < field.validators!.length; i++) {
    final validator = field.validators![i];
    try {
      final bool isValid = validator.validator(tempResults);

      if (!isValid) {
        final error = FormBuilderError(
          reason: validator.reason,
          fieldId: field.id,
          validatorPosition: i,
        );
        formErrors.add(error);
        controller.addError(error);
      }
    } catch (e, s) {
      // Handle validation errors
      debugPrint("Compound field validation error for ${field.id}: $e");
      debugPrint("Stack trace: $s");
      formErrors.add(FormBuilderError(
        reason: "Validation failed: $e",
        fieldId: field.id,
        validatorPosition: i,
      ));
    }
  }
}
