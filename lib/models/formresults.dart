import 'dart:convert';

import 'package:championforms/championforms.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/mime_data.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

class FieldResults {
  final String id;
  final List<FieldResultData> values;
  final FieldType type;

  const FieldResults({
    required this.id,
    required this.values,
    required this.type,
  });

  // As String
  String asString({String? id, String delimiter = ", ", String fallback = ""}) {
    String output = "";
    if (type == FieldType.bool) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.active ?? false ? item?.value ?? "" : "";
      } else {
        output = values.map((item) => item.value).join(delimiter);
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.value ?? "";
      } else {
        output = values.map((item) => item.value).join(delimiter);
      }
    } else if (type == FieldType.file) {
      // If the file is of type text then we can return the result as a string
      // otherwise just return filename

      final item = values.firstWhereOrNull((data) => data.id == id);

      // we can't select a single ID since we don't have a preset list of values
      output = [
        // If the mime type starts with text then we can return the text as a string.
        ...values
            .where((fileData) =>
                (fileData.optionValue as FileModel)
                    .mimeData
                    ?.mime
                    .startsWith("text") ??
                false)
            .map((fileData) => utf8
                .decode((fileData.optionValue as FileModel).fileBytes ?? [])),

        // If not, then we will just return the filename
        ...values
            .where((fileData) => !((fileData.optionValue as FileModel)
                    .mimeData
                    ?.mime
                    .startsWith("text") ??
                false))
            .map((fileData) => (fileData.optionValue as FileModel).fileName),
      ].join(", ");
    }
    return output != "" ? output : fallback;
  }

  /// Converts the object's string representation to a double.
  ///
  /// Uses [asString] internally to get the string value, optionally filtered by [id].
  /// Throws a [FormatException] if the resulting string cannot be parsed into a double.
  /// Does not use the 'delimiter' or 'fallback' parameters of [asString].
  double asDouble({String? id, double? fallback}) {
    // Call asString, potentially getting a specific value if id is provided.
    // We avoid passing fallback to ensure we only parse the actual value or an empty string.
    final stringValue = asString(id: id, fallback: "");

    try {
      // Attempt to parse the string. This throws FormatException if invalid.
      return double.parse(stringValue);
    } on FormatException catch (e) {
      if (fallback != null) {
        return fallback;
      }

      // Re-throw the exception or a custom one.
      // Adding the problematic string value to the message can be helpful for debugging.
      throw FormatException(
          "Input string cannot be parsed as a double: '$stringValue'",
          e.source,
          e.offset);
    }
  }

  /// Converts the object's string representation to an integer.
  ///
  /// Uses [asString] internally to get the string value, optionally filtered by [id].
  /// Throws a [FormatException] if the resulting string cannot be parsed into an integer.
  /// Does not use the 'delimiter' or 'fallback' parameters of [asString].
  int asInt({String? id, int? fallback}) {
    // Call asString, potentially getting a specific value if id is provided.
    // We avoid passing fallback to ensure we only parse the actual value or an empty string.
    final stringValue = asString(id: id, fallback: "");

    try {
      // Attempt to parse the string. This throws FormatException if invalid.
      return int.parse(stringValue);
    } on FormatException catch (e) {
      // If there is a fallback
      if (fallback != null) {
        return fallback;
      }

      // Re-throw the exception or a custom one.
      throw FormatException(
          "Input string cannot be parsed as an int: '$stringValue'",
          e.source,
          e.offset);
    }
  }

  List<String> asStringList({String? id, List<String> fallback = const []}) {
    List<String> output = [];
    if (type == FieldType.bool) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.active ?? false ? item?.id ?? "" : "");
      } else {
        output.addAll(values.map((item) => item.value ?? "").toList());
        //debugPrint(values.join(", "));
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.value ?? "");
      } else {
        output.addAll(values.map((item) => item.value ?? "").toList());
      }
    } else if (type == FieldType.file) {
      // If the file is of type text then we can return the result as a string
      // otherwise just return filename

      final item = values.firstWhereOrNull((data) => data.id == id);

      // we can't select a single ID since we don't have a preset list of values
      output.addAll([
        // If the mime type starts with text then we can return the text as a string.
        ...values
            .where((fileData) =>
                (fileData.optionValue as FileModel)
                    .mimeData
                    ?.mime
                    .startsWith("text") ??
                false)
            .map((fileData) => utf8
                .decode((fileData.optionValue as FileModel).fileBytes ?? [])),

        // If not, then we will just return the filename
        ...values
            .where((fileData) => !((fileData.optionValue as FileModel)
                    .mimeData
                    ?.mime
                    .startsWith("text") ??
                false))
            .map((fileData) => (fileData.optionValue as FileModel).fileName),
      ]);
    }
    return output.isNotEmpty ? output : fallback;
  }

  /// Converts the object's string list representation to a list of doubles.
  ///
  /// Uses [asStringList] internally to get the list of strings, optionally
  /// filtered by [id].
  /// Attempts to parse each string into a double using [double.tryParse].
  /// Strings that cannot be parsed are ignored.
  ///
  /// If the resulting list of doubles is empty (either because the initial
  /// string list was empty or no strings could be parsed), the provided [fallback]
  /// list is returned. If [fallback] is null, an empty list `[]` is returned.
  List<double> asDoubleList({String? id, List<double>? fallback}) {
    // Call asStringList. Note: We don't pass a fallback here,
    // let asStringList return its default (usually empty list) if applicable.
    final stringList = asStringList(id: id);
    final List<double> resultList = [];

    for (final str in stringList) {
      final double? parsedValue = double.tryParse(str);
      if (parsedValue != null) {
        resultList.add(parsedValue);
      }
      // Ignore strings that don't parse (parsedValue is null)
    }

    // If the list is empty after trying to parse, return the fallback.
    // Otherwise, return the list of successfully parsed doubles.
    return resultList.isNotEmpty ? resultList : (fallback ?? const []);
  }

  /// Converts the object's string list representation to a list of integers.
  ///
  /// Uses [asStringList] internally to get the list of strings, optionally
  /// filtered by [id].
  /// Attempts to parse each string into an integer using [int.tryParse].
  /// Strings that cannot be parsed are ignored.
  ///
  /// If the resulting list of integers is empty (either because the initial
  /// string list was empty or no strings could be parsed), the provided [fallback]
  /// list is returned. If [fallback] is null, an empty list `[]` is returned.
  List<int> asIntList({String? id, List<int>? fallback}) {
    // Call asStringList.
    final stringList = asStringList(id: id);
    final List<int> resultList = [];

    for (final str in stringList) {
      final int? parsedValue = int.tryParse(str);
      if (parsedValue != null) {
        resultList.add(parsedValue);
      }
      // Ignore strings that don't parse (parsedValue is null)
    }

    // If the list is empty after trying to parse, return the fallback.
    // Otherwise, return the list of successfully parsed integers.
    return resultList.isNotEmpty ? resultList : (fallback ?? const []);
  }

  List<bool> asBool({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return [item.active];
      } else {
        return values.map((item) => item.active).toList();
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return item.value != "" ? [true] : [false];
      } else {
        return values.map((item) => item.value != "" ? true : false).toList();
      }
    } else if (type == FieldType.file) {
      // If the file is of type text then we can return the result as a string
      // otherwise just return filename

      final item = values.firstWhereOrNull((data) => data.id == id);

      // just return true if set.
      if (item?.optionValue is FileModel) {
        return [true];
      } else {
        return [false];
      }
    }
    return [];
  }

  Map<String, bool> asBoolMap({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.id: item.active};
      } else {
        return {for (var item in values) item.id: item.active};
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.value ?? item.id: item.value != "" ? true : false};
      } else {
        return {
          for (var item in values)
            item.value ?? item.id: item.value != "" ? true : false
        };
      }
    } else if (type == FieldType.file) {
      return {for (var item in values) item.id: item.optionValue != null};
    }
    return {};
  }

  MultiselectOption? asMultiselectSingle({String? id}) {
    MultiselectOption? item;
    if (id != null) {
      item = values.firstWhereOrNull((data) => data.id == id)?.optionValue;
    } else {
      item = values.firstOrNull?.optionValue;
    }

    return item;
  }

  List<MultiselectOption> asMultiselectList({String? id}) {
    return values
        .where((v) => v.optionValue != null)
        .map((data) => data.optionValue!)
        .toList();
  }

  // --------------------------
  // NEW FUNCTION: asFile()
  // This will return a list of "FileResult" or you can directly return
  // a list of multiselect with the data. We'll create a small wrapper class:
  // We'll call it "FileResultData"
  // --------------------------

  List<FileResultData> asFile() {
    // Only interpret these as files if the FieldType is "file"
    if (type != FieldType.file) {
      return [];
    }
    final files = <FileResultData>[];
    for (var data in values) {
      if (data.optionValue != null) {
        try {
          files.add(
            FileResultData(
              name: data.optionValue!.label,
              path: data.optionValue!.value,
              fileDetails: data.optionValue!.additionalData as FileModel,
            ),
          );
        } catch (e) {
          debugPrint("Failed to parse file data: $e");
        }
      }
    }
    return files;
  }
}

enum FieldType {
  string, // A plain string
  bool, // A bool switch
  parchment, // Rich text format
  file, // A file with file bytes data or a byte stream.
}

class FileResultData {
  final String name; // e.g. file name
  final String path; // e.g. full path
  final FileModel? fileDetails; // raw file data or partial data
  const FileResultData({
    required this.name,
    required this.path,
    this.fileDetails,
  });
}

class FieldResultData {
  final FieldType type;
  final String id;
  final String? value;
  final MimeData? mimeType;
  final MultiselectOption? optionValue;
  final bool active;
  const FieldResultData({
    this.type = FieldType.string,
    this.id = "noid",
    this.optionValue,
    this.value,
    this.mimeType, // Default to bytes unless set otherwise.
    this.active = false,
  });
}

class FormResults {
  final bool errorState;
  final List<FormBuilderError> formErrors;
  final List<FieldResults> results;
  const FormResults({
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
  });

  factory FormResults.getResults({
    required ChampionFormController controller,
    bool checkForErrors = true,
    List<FormFieldDef>? fields,
  }) {
    List<FormFieldDef> finalFields = fields ?? controller.fields;

    List<FieldResults> results = [];

    for (final field in finalFields) {
      FieldType type;
      switch (field) {
        case ChampionTextField():
          type = FieldType.string;
          final value = controller.findTextFieldValue(field.id)?.value ?? "";
          results.add(FieldResults(
            id: field.id,
            values: [FieldResultData(value: value, id: field.id, type: type)],
            type: type,
          ));
          break;
        case ChampionOptionSelect():
          // If it's specifically a file upload, we use "file" as the type
          if (field is ChampionFileUpload) {
            type = FieldType.file;
          } else {
            type = FieldType.bool;
          }
          final value = controller.findMultiselectValue(field.id)?.values ?? [];

          results.add(FieldResults(
            id: field.id,
            values: value
                .map((val) => FieldResultData(
                      value: val.value.toString(),
                      optionValue: val,
                      id: field.id,
                      mimeType: type == FieldType.file
                          ? (val.additionalData as FileModel).mimeData
                          : null,
                      active: true,
                      type: type,
                    ))
                .toList(),
            type: type,
          ));
          break;
        default:
          type = FieldType.string;
      }
    }
    bool errorState = false;
    List<FormBuilderError> formErrors = [];
    if (checkForErrors) {
      formErrors.addAll(
          getFormBuilderErrors(results: results, controller: controller));
      if (formErrors.isNotEmpty) {
        errorState = true;
      }
    }
    return FormResults(
      formErrors: formErrors,
      errorState: errorState,
      results: results,
    );
  }

  FieldResults grab(String id) {
    return results.firstWhere((item) => item.id == id);
  }
}
