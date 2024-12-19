// Lets build a model for holding a single field's results, including error information
import 'package:championforms/functions/geterrors.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/providers/formfield_value_by_id.dart';
import 'package:championforms/providers/formfieldsstorage.dart';
import 'package:championforms/providers/formliststringsprovider.dart';
import 'package:championforms/providers/multiselect_provider.dart';
import 'package:championforms/providers/quillcontrollerprovider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parchment/parchment.dart';
import 'package:parchment_delta/parchment_delta.dart';
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

  // As String -- join all values together into one long string, take in an optional seperator if desired or fall back to ", "

  // Optional result id
  String asString({String? id, String delimiter = ", ", String fallback = ""}) {
    String output = "";
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.active ?? false ? item?.id ?? "" : "";
      } else {
        // We're going to merge this all together into one long string of values
        output = values.map((item) => item.id).join(delimiter);
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output = item?.value ?? "";
      } else {
        // We're going to merge this all together into one long string of values
        output = values.map((item) => item.value).join(delimiter);
      }
    } else if (type == FieldType.parchment) {
      output = values
          .map((item) => ParchmentDocument.fromDelta(item.deltaValue ?? Delta())
              .toPlainText())
          .join(delimiter);
    }
    return output != "" ? output : fallback;
  }

  List<String> asStringList({String? id, List<String> fallback = const []}) {
    List<String> output = [];
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.active ?? false ? item?.id ?? "" : "");
      } else {
        // We're going to merge this all together into one long string of values
        output.addAll(values.map((item) => item.id).toList());
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        output.add(item?.value ?? "");
      } else {
        // We're going to merge this all together into one long string of values
        output.addAll(values.map((item) => item.value ?? "").toList());
      }
    } else if (type == FieldType.parchment) {
      output.addAll(values
          .map((item) => ParchmentDocument.fromDelta(item.deltaValue ?? Delta())
              .toPlainText())
          .toList());
    }
    return output != [] ? output : fallback;
  }

  // As Bool -- True or false. returns a list of true / false values

  List<bool> asBool({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return [item.active];
      } else {
        // We're going to merge this all together into one long string of values
        return values.map((item) => item.active).toList();
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return [false];
        return item.value != "" ? [true] : [false];
      } else {
        // We're going to merge this all together into one long string of values
        return values.map((item) => item.value != "" ? true : false).toList();
      }
    } else if (type == FieldType.parchment) {
      return values
          .map((item) => ParchmentDocument.fromDelta(item.deltaValue ?? Delta())
                      .toPlainText() !=
                  ""
              ? true
              : false)
          .toList();
    }
    return [];
  }

  // As Named Bool True or false. returns a map of ID / true / false values

  Map<String, bool> asBoolMap({String? id}) {
    if (type == FieldType.bool) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.id: item.active};
      } else {
        // We're going to merge this all together into one long string of values
        Map<String, bool> myMap = {
          for (var item in values) item.id: item.active
        };
        return myMap;
      }
    } else if (type == FieldType.string) {
      if (id != null) {
        // Return a single subvalue. We're checking if it exists.
        final item = values.firstWhereOrNull((data) => data.id == id);
        if (item == null) return {};
        return {item.value ?? item.id: item.value != "" ? true : false};
      } else {
        // We're going to merge this all together into one long string of values
        Map<String, bool> myMap = {
          for (var item in values)
            item.value ?? item.id: item.value != "" ? true : false
        };
        return myMap;
      }
    } else if (type == FieldType.parchment) {
      Map<String, bool> myMap = {
        for (var item in values)
          ParchmentDocument.fromDelta(item.deltaValue ?? Delta()).toPlainText():
              ParchmentDocument.fromDelta(item.deltaValue ?? Delta())
                          .toPlainText() !=
                      ""
                  ? true
                  : false
      };
      return myMap;
    }
    return {};
  }

  // As MultiSelect
  MultiselectOption? asMultiselectSingle({String? id}) {
    final item = values.firstWhereOrNull((data) => data.id == id);

    return item?.optionValue?.first;
  }

  // As MultiSelect List
  List<MultiselectOption> asMultiselectList({String? id}) {
    final item = values.firstWhereOrNull((data) => data.id == id);

    return item?.optionValue ?? [];
  }

  // SingleBool. Returns the first bool value.

  // As Map

  // As Delta. Returns the delta of the field.

  Delta asDelta({String delimiter = ", "}) {
    if (type == FieldType.parchment) {
      values.first.deltaValue ?? Delta();
    } else if (type == FieldType.string) {
      //return Delta.from(values.map((item) => item.value).join(delimiter));
      // TODO: Convert strings to delta
      return Delta();
    }

    return Delta();
  }

  //
}

enum FieldType {
  string,
  bool,
  parchment,
}

class FieldResultData {
  final FieldType type;
  final String id;
  final String? value;
  final List<MultiselectOption>? optionValue;
  final Delta? deltaValue;
  final bool active;
  const FieldResultData({
    this.type = FieldType.string,
    this.id = "noid",
    this.optionValue,
    this.value,
    this.active = false,
    this.deltaValue,
  });
}

// We're going to compress the form's fields into an object we can traverse with some handy helper functions for pulling the results out.
class FormResults {
  final String formId;
  final bool errorState;
  final List<FormBuilderError> formErrors;
  final List<FieldResults> results;
  // Because this is just a wrapper around calling Riverpod directly we're going to need access to widgetref
  const FormResults({
    required this.formId,
    this.errorState = false,
    this.formErrors = const [],
    required this.results,
  });

  // This factory pulls in all results and also does some handy error checking on the fields. The finished result can be worked with to find detailed information on each field.
  factory FormResults.getResults({
    required WidgetRef ref,
    required String formId,
    bool checkForErrors = true,
    List<FormFieldDef>? fields,
  }) {
    List<FormFieldDef> finalFields =
        fields ?? ref.read(formFieldsStorageNotifierProvider(formId));

    // Initialize our results list
    List<FieldResults> results = [];

    // Lets loop through our fields and add them to the results
    for (final field in finalFields) {
      // Loop through each field and we need to gather results and if asked report on field errors.

      // Start by determining the field type so we can properly associate the data to the field.

      FieldType type;
      switch (field) {
        case ChampionTextField():
          type = FieldType.string;
          final value =
              ref.read(textFormFieldValueByIdProvider(formId + field.id));

          results.add(FieldResults(
            id: field.id,
            values: [
              FieldResultData(value: value, id: formId + field.id, type: type)
            ],
            type: type,
          ));
          break;
        case ChampionOptionSelect():
          type = FieldType.bool;
          final value =
              ref.read(multiSelectOptionNotifierProvider(formId + field.id));

          results.add(FieldResults(
            id: field.id,
            values: [
              FieldResultData(
                  value: value.map((option) => option.value.toString()).join(
                      ", "), // Merge all the options into a comma seperated list
                  optionValue:
                      value, // This is the actual list of values which we can access in our field results.
                  id: formId + field.id,
                  active: true,
                  type: type)
            ],
            type: type,
          ));

          break;

        default:
          type = FieldType.string;
      }

      // Now that we know what field type we're working with. Grab the data from the field and convert it into a FormFieldData object to be added to the FormField list of results.

      // TODO Reintegrate chips and choice fields
      /*
      if (field.type == FormFieldType.chips ||
          field.type == FormFieldType.dropdown ||
          field.type == FormFieldType.checkbox) {
        final choiceChips =
            ref.read(choiceChipNotifierProvider(formId + field.id));
        List<FieldResultData> chipResults = [];
        for (final ChoiceChipValue choiceChip in choiceChips) {
          final fieldResult = FieldResultData(
            id: choiceChip.id,
            active: choiceChip.value,
            type: type,
          );
          chipResults.add(fieldResult);
        }

        results.add(FieldResults(
          id: field.id,
          values: chipResults,
          type: type,
        ));
      } else if (field.type == FormFieldType.tagField) {
        final stringList =
            ref.read(formListStringsNotifierProvider(formId + field.id));

        final List<FieldResultData> stringResults = stringList
            .map((item) => FieldResultData(
                  id: item,
                  value: item,
                  type: type,
                ))
            .toList();

        results.add(FieldResults(
          id: field.id,
          values: field.multiselect
              ? stringResults
              : (stringResults.isNotEmpty ? [stringResults.first] : []),
          type: type,
        ));
      } else if (field.type == FormFieldType.richText) {
        final controller =
            ref.read(quillControllerNotifierProvider(formId, field.id));

        final delta = controller.document.toDelta();

        results.add(FieldResults(
          id: field.id,
          values: [
            FieldResultData(
              type: type,
              id: field.id,
              deltaValue: delta,
            )
          ],
          type: type,
        ));
      } else {
      */

      //}
    }
    bool errorState;
    List<FormBuilderError> formErrors = [];
    // Check for errors and set the error state
    if (checkForErrors) {
      formErrors.addAll(
          getFormBuilderErrors(results: results, formId: formId, ref: ref));
      if (formErrors.isNotEmpty) {
        errorState = true;
      }
    }
    errorState = false;
    return FormResults(
      formId: formId,
      formErrors: formErrors,
      errorState: errorState,
      results: results,
    );
  }

  // Grab field value (or with default)
  FieldResults grab(String id) {
    return results.firstWhere((item) => item.id == id);
  }

  // Grab field list value (or with default)

  // Grab value or null

  // Grab list or null

  // execute error check
}
