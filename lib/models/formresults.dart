// Lets build a model for holding a single field's results, including error information
import 'package:championforms/championforms.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresultstype.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/providers/formfieldsstorage.dart';
import 'package:championforms/providers/formliststringsprovider.dart';
import 'package:championforms/providers/quillcontrollerprovider.dart';
import 'package:championforms/providers/textformfieldbyid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parchment_delta/parchment_delta.dart';

class FieldResults {
  final String id;
  final List<FieldResultData> values;
  final FieldType type;

  const FieldResults({
    required this.id,
    required this.values,
    required this.type,
  });
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
  final Delta? deltaValue;
  final bool active;
  const FieldResultData({
    this.type = FieldType.string,
    this.id = "noid",
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
      if (field.type == FormFieldType.richText) {
        type = FieldType.parchment;
      } else if (field.type == FormFieldType.textArea ||
          field.type == FormFieldType.textField ||
          field.type == FormFieldType.tagField) {
        type = FieldType.string;
      } else {
        type = FieldType.bool;
      }

      // Now that we know what field type we're working with. Grab the data from the field and convert it into a FormFieldData object to be added to the FormField list of results.
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
          values: field.multiselect ? stringResults : [stringResults.first],
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
        final value = ref.read(textFormFieldValueById(formId + field.id));

        results.add(FieldResults(
          id: field.id,
          values: [FieldResultData(value: value, id: value, type: type)],
          type: type,
        ));
      }
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
  //String grabField

  // Grab field list value (or with default)

  // Grab value or null

  // Grab list or null

  // execute error check
}
