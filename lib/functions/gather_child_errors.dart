import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/column.dart';
import 'package:championforms/models/field_types/row.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formbuildererrorclass.dart';

/// Recursively finds all Field instances within a list of elements.
List<Field> _flattenFields(List<FormElement> elements) {
  final List<Field> flatList = [];
  for (final element in elements) {
    if (element is Field) {
      flatList.add(element);
    } else if (element is Row) {
      // Recurse into the row's children (which are columns)
      for (final column in element.children) {
        flatList.addAll(_flattenFields(column.children));
      }
    } else if (element is Column) {
      // Recurse into the column's children
      flatList.addAll(_flattenFields(element.children));
    }
  }
  return flatList;
}

/// Gathers all validation errors from child fields within a given list of elements.
List<FormBuilderError> gatherAllChildErrors(
  List<FormElement> elements,
  FormController controller,
) {
  final List<FormBuilderError> allErrors = [];
  final List<Field> allFields = _flattenFields(elements);

  for (final field in allFields) {
    allErrors.addAll(controller.findErrors(field.id));
  }
  return allErrors;
}
