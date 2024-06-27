import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresultstype.dart';
import 'package:championforms/providers/choicechipprovider.dart';
import 'package:championforms/providers/formliststringsprovider.dart';
import 'package:championforms/providers/textformfieldbyid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Map<String, FormResults> gatherFormBuilderResults(
    String id, List<FormFieldDef> fields, WidgetRef ref) {
  Map<String, FormResults> results = {};

  for (final field in fields) {
    if (field.type == FormFieldType.chips ||
        field.type == FormFieldType.dropdown ||
        field.type == FormFieldType.checkbox) {
      final value = ref.read(choiceChipNotifierProvider(id + field.id));
      results[field.id] = ChoiceChipResultsList(value);
    } else if (field.type == FormFieldType.tagField) {
      final value = ref.read(formListStringsNotifierProvider(id + field.id));
      results[field.id] = StringListItem(value);
    } else if (field.multiselect == true) {
      // TODO: Finish Multiselect form fields
      // You can add logic here to handle multiselect fields
      // For example:
      // final values = ref.read(multiselectFieldProvider(id));
      // results[field.id] = MultiSelectResultsList(values);
    } else {
      final value = ref.read(textFormFieldValueById(id + field.id));
      results[field.id] = StringItem(value);
    }
  }

  return results;
}
