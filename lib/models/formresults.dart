import 'dart:convert';

import 'package:championforms/championforms.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/mime_data.dart';
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
      // formErrors.addAll(getFormBuilderErrors(results: collectedResults, definitions: definitions));
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

  /// Get the value converted to a String using the field's definition.
  String getAsString(String id, {String fallback = ""}) {
    final data = _getResultAndDef<dynamic>(id); // Use dynamic initially
    if (data.result != null && data.definition != null) {
      try {
        // Call the converter from the definition with the value from the result
        return data.definition!.asStringConverter(data.result!.value);
      } catch (e) {
        debugPrint("Error calling asStringConverter for field '$id': $e");
        return fallback; // Return fallback on error
      }
    }
    return fallback; // Return fallback if field not found
  }

  /// Get the value converted to a List<String> using the field's definition.
  List<String> getAsStringList(String id, {List<String> fallback = const []}) {
    final data = _getResultAndDef<dynamic>(id);
    if (data.result != null && data.definition != null) {
      try {
        return data.definition!.asStringListConverter(data.result!.value);
      } catch (e) {
        debugPrint("Error calling asStringListConverter for field '$id': $e");
        return fallback;
      }
    }
    return fallback;
  }

  /// Get the value converted to a bool using the field's definition.
  bool getAsBool(String id, {bool fallback = false}) {
    final data = _getResultAndDef<dynamic>(id);
    if (data.result != null && data.definition != null) {
      try {
        return data.definition!.asBoolConverter(data.result!.value);
      } catch (e) {
        debugPrint("Error calling asBoolConverter for field '$id': $e");
        return fallback;
      }
    }
    return fallback;
  }

  /// Get the value converted to a List<FileModel> using the field's definition.
  /// Returns fallback if the field doesn't exist or doesn't support file conversion.
  List<FileModel> getAsFileList(String id,
      {List<FileModel> fallback = const []}) {
    final data = _getResultAndDef<dynamic>(id);
    if (data.result != null && data.definition != null) {
      final converter = data.definition!.asFileListConverter;
      if (converter != null) {
        try {
          return converter(data.result!.value);
        } catch (e) {
          debugPrint("Error calling asFileListConverter for field '$id': $e");
          return fallback;
        }
      } else {
        // Field type doesn't support file conversion
        return fallback;
      }
    }
    return fallback;
  }

  // FieldResults grab(String id) {
  //   return results.firstWhere((item) => item.id == id);
  // }
}
