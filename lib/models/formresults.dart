import 'package:championforms/championforms.dart';
import 'package:championforms/models/championfileupload.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';

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
    }
    return output != "" ? output : fallback;
  }

  List<String> asStringList({String? id, List<String> fallback = const []}) {
    List<String> output = [];
    if (type == FieldType.bool) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.active ?? false ? item?.id ?? "" : "");
      } else {
        output.addAll(values.map((item) => item.id).toList());
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.value ?? "");
      } else {
        output.addAll(values.map((item) => item.value ?? "").toList());
      }
    }
    return output.isNotEmpty ? output : fallback;
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
        files.add(
          FileResultData(
            name: data.optionValue!.label,
            path: data.optionValue!.value,
            bytes: data.optionValue!.additionalData,
          ),
        );
      }
    }
    return files;
  }
}

enum FieldType {
  string,
  bool,
  parchment,
  file, // ADDED
}

class FileResultData {
  final String name; // e.g. file name
  final String path; // e.g. full path
  final Object? bytes; // raw file data or partial data
  const FileResultData({
    required this.name,
    required this.path,
    this.bytes,
  });
}

class FieldResultData {
  final FieldType type;
  final String id;
  final String? value;
  final MultiselectOption? optionValue;
  final bool active;
  const FieldResultData({
    this.type = FieldType.string,
    this.id = "noid",
    this.optionValue,
    this.value,
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
