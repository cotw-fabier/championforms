import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formbuildererrorclass.dart';

/// Recursively finds all FormFieldDef instances within a list of elements.
List<FormFieldDef> _flattenFields(List<ChampionFormElement> elements) {
  final List<FormFieldDef> flatList = [];
  for (final element in elements) {
    if (element is FormFieldDef) {
      flatList.add(element);
    } else if (element is ChampionRow) {
      // Recurse into the row's children (which are columns)
      for (final column in element.children) {
        flatList.addAll(_flattenFields(column.children));
      }
    } else if (element is ChampionColumn) {
      // Recurse into the column's children
      flatList.addAll(_flattenFields(element.children));
    }
  }
  return flatList;
}

/// Gathers all validation errors from child fields within a given list of elements.
List<FormBuilderError> gatherAllChildErrors(
  List<ChampionFormElement> elements,
  ChampionFormController controller,
) {
  final List<FormBuilderError> allErrors = [];
  final List<FormFieldDef> allFields = _flattenFields(elements);

  for (final field in allFields) {
    allErrors.addAll(controller.findErrors(field.id));
  }
  return allErrors;
}
