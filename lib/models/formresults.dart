import 'dart:convert';

import 'package:championforms/championforms.dart';
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
  final dynamic _value; // The raw value from FieldResults<dynamic>
  final FormFieldDef<dynamic> _definition; // The corresponding field definition

  FieldResultAccessor._(this._id, this._value, this._definition);

  /// Get the raw value cast to type T.
  /// Returns null if the field's actual value is not of type T.
  T? asRaw<T>() {
    if (_value is T) {
      return _value as T;
    }
    debugPrint(
        "asRaw failed for field '$_id'. Expected $T, found ${_value?.runtimeType}");
    return null;
  }

  /// Get the value converted to a String using the field's definition.
  String asString({String fallback = ""}) {
    try {
      // Access the converter function stored in the definition
      return _definition.asStringConverter(_value);
    } catch (e) {
      debugPrint("Error calling asStringConverter for field '$_id': $e");
      return fallback;
    }
  }

  /// Get the value converted to a List<String> using the field's definition.
  List<String> asStringList({List<String> fallback = const []}) {
    try {
      return _definition.asStringListConverter(_value);
    } catch (e) {
      debugPrint("Error calling asStringListConverter for field '$_id': $e");
      return fallback;
    }
  }

  /// Get the value converted to a bool using the field's definition.
  bool asBool({bool fallback = false}) {
    try {
      return _definition.asBoolConverter(_value);
    } catch (e) {
      debugPrint("Error calling asBoolConverter for field '$_id': $e");
      return fallback;
    }
  }

  /// Get the value as a List<MultiselectOption>.
  /// Returns an empty list if the value is null or not the correct type.
  List<MultiselectOption> asMultiselectList() {
    // Check if the field definition is for a ChampionOptionSelect or subclass
    if (_definition is ChampionOptionSelect) {
      final List<dynamic>? rawList =
          asRaw<List<dynamic>>(); // Try getting as List<dynamic> first
      if (rawList != null) {
        // Attempt to cast each element safely
        final List<MultiselectOption> options = rawList
            .whereType<
                MultiselectOption>() // Filter only MultiselectOption elements
            .toList();
        // Optional: Check if lengths match to see if there were non-MultiselectOption items
        if (options.length != rawList.length) {
          debugPrint(
              "Warning for field '$_id': asMultiselectList found items that were not MultiselectOption.");
        }
        return options;
      } else {
        debugPrint(
            "asMultiselectList failed for field '$_id'. Value is null or not a List.");
        return []; // Return empty list if not a list or null
      }
    } else {
      debugPrint(
          "asMultiselectList called on field '$_id' which is not a ChampionOptionSelect type (${_definition.runtimeType}).");
      return []; // Not an option select field
    }
  }

  /// Get a single MultiselectOption from the list by its value (ID).
  /// Returns null if the field is not a multiselect type, the list is empty,
  /// or no option with the matching value is found.
  MultiselectOption? asMultiselect(String optionValue) {
    final List<MultiselectOption> options = asMultiselectList();
    if (options.isEmpty) {
      // Debug print already handled in asMultiselectList if field type mismatch or null/empty value
      return null;
    }
    // Use firstWhereOrNull from collection package for efficiency and null safety
    return options.firstWhereOrNull((option) => option.value == optionValue);
  }

  /// Get the value converted to a List<FileModel> using the field's definition.
  /// Returns fallback if the field doesn't exist or doesn't support file conversion.
  List<FileModel> asFileList({List<FileModel> fallback = const []}) {
    final converter = _definition.asFileListConverter;
    if (converter != null) {
      try {
        return converter(_value);
      } catch (e) {
        debugPrint("Error calling asFileListConverter for field '$_id': $e");
        return fallback;
      }
    } else {
      // Field type doesn't support file conversion
      return fallback;
    }
  }

  // Add other `as...` methods here mirroring the converters in FormFieldDef
  // e.g., asDouble, asInt, asFile, etc.
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
  final List<BaseFieldResults> results;
  // Store field definitions to access converter functions
  final Map<String, FormFieldDef<dynamic>> fieldDefinitions;
  const FormResults({
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
    required this.fieldDefinitions,
  });

  factory FormResults.getResults({
    required ChampionFormController controller,
    bool checkForErrors = true,
    List<FormFieldDef>? fields,
  }) {
    List<FormFieldDef> finalFields = fields ?? controller.fields;

    List<BaseFieldResults> collectedResults = [];
    Map<String, FormFieldDef<dynamic>> definitions = {};

    for (final field in finalFields) {
      if (field.hideField) continue; // Skip hidden fields

      // Retrieve the value dynamically.
      // The type T is implicitly defined by the field definition.
      // getFieldValue should ideally return the type expected by field.defaultValue
      final dynamic rawValue =
          controller.getFieldValue<dynamic>(field.id) ?? field.defaultValue;

      // Create the specific FieldResults<T> instance.
      // Casting rawValue might be needed if getFieldValue returns dynamic,
      // but ideally getFieldValue uses T from the field def somehow.
      // For now, we create FieldResults<dynamic> and rely on later casts.
      collectedResults
          .add(FieldResults<dynamic>(id: field.id, value: rawValue));
      definitions[field.id] = field;
    }

    // List<FieldResults> results = [];

    // for (final field in finalFields) {
    //   FieldType type;
    //   switch (field) {
    //     case ChampionTextField():
    //       type = FieldType.string;
    //       final value = controller.getFieldValue<String>(field.id) ?? "";
    //       results.add(FieldResults(
    //         id: field.id,
    //         values: [FieldResultData(value: value, id: field.id, type: type)],
    //         type: type,
    //       ));
    //       break;
    //     case ChampionOptionSelect():
    //       // If it's specifically a file upload, we use "file" as the type
    //       if (field is ChampionFileUpload) {
    //         type = FieldType.file;
    //       } else {
    //         type = FieldType.bool;
    //       }
    //       final value =
    //           controller.getFieldValue<List<MultiselectOption>>(field.id) ?? [];

    //       results.add(FieldResults(
    //         id: field.id,
    //         values: value
    //             .map((val) => FieldResultData(
    //                   value: val.value.toString(),
    //                   optionValue: val,
    //                   id: field.id,
    //                   mimeType: type == FieldType.file
    //                       ? (val.additionalData as FileModel).mimeData
    //                       : null,
    //                   active: true,
    //                   type: type,
    //                 ))
    //             .toList(),
    //         type: type,
    //       ));
    //       break;
    //     default:
    //       type = FieldType.string;
    //   }
    // }
    bool errorState = false;
    List<FormBuilderError> formErrors = [];
    if (checkForErrors) {
      // TODO: Update getFormBuilderErrors to work with the new structure
      // It will need access to 'collectedResults' and 'definitions'
      // to get both the value and the validation function from the definition.
      formErrors.addAll(getFormBuilderErrors(
        controller: controller,
        results: collectedResults,
        definitions: definitions,
      ));
      if (formErrors.isNotEmpty) {
        errorState = true;
      }
    }

    return FormResults(
      formErrors: formErrors,
      errorState: errorState,
      results: collectedResults,
      fieldDefinitions: definitions,
    );
  }

  // --- Helper to get result and definition ---
  // Returns null if field not found
  ({FieldResults<T>? result, FormFieldDef<T>? definition}) _getResultAndDef<T>(
      String id) {
    final baseResult = results.firstWhereOrNull((item) => item.id == id);
    final definition = fieldDefinitions[id];

    if (baseResult == null || definition == null) {
      return (result: null, definition: null); // Field not found
    }

    // Try to safely cast
    if (baseResult is FieldResults<T> && definition is FormFieldDef<T>) {
      return (result: baseResult, definition: definition);
    } else {
      // Log or handle type mismatch error?
      // This can happen if getAsRaw<T> is called with the wrong T
      debugPrint(
          "Type mismatch for field '$id'. Expected $T but found ${baseResult.runtimeType} / ${definition.runtimeType}");
      return (result: null, definition: null);
    }
  }

  // --- New Accessor Methods ---

  /// Get the raw value of the field cast to type T.
  /// Returns null if the field doesn't exist or the type T is incorrect.
  T? getAsRaw<T>(String id) {
    final baseResult = results.firstWhereOrNull((item) => item.id == id);
    if (baseResult is FieldResults<T>) {
      return baseResult.value;
    }
    // Log error if type mismatch?
    // debugPrint("getAsRaw failed for field '$id'. Expected $T, found ${baseResult?.runtimeType}");
    return null;
  }

  FieldResultAccessor grab(String id) {
    // Find the raw result object (which should be FieldResults<dynamic>)
    final baseResult = results.firstWhereOrNull((item) => item.id == id);
    // Find the corresponding field definition
    final definition = fieldDefinitions[id];

    if (baseResult != null && definition != null) {
      // Ensure baseResult is actually a FieldResults instance to access its value
      if (baseResult is FieldResults) {
        // Create and return the accessor, passing the value and definition
        return FieldResultAccessor._(id, baseResult.value, definition);
      } else {
        // This shouldn't happen if getResults is implemented correctly
        // debugPrint(
        //     "Error in grab(): Found result for '$id' but it's not a FieldResults instance.");
        throw (Exception(
            "Error in grab(): Found result for '$id' but it's not a FieldResults instance."));
        // return null;
      }
    }

    // Field not found
    throw (Exception(
        "Error in grab(): Attempting to find data for a field that doesn't exist '$id'."));
  }
}
