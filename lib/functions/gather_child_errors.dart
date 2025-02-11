import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formbuildererrorclass.dart';

/// Recursively gather *all* errors for a list of fields.
/// This is used so a parent row/column can "roll up" child errors
/// and display them in one place.
List<FormBuilderError> gatherAllChildErrors(
  List<FormFieldBase> fields,
  ChampionFormController controller,
) {
  final allErrors = <FormBuilderError>[];

  for (final f in fields) {
    // Direct errors for this field
    allErrors.addAll(controller.findErrors(f.id));

    // If it's a row, gather errors from each column inside
    if (f is ChampionRow) {
      for (final col in f.columns) {
        allErrors.addAll(gatherAllChildErrors(col.fields, controller));
      }
    }
    // If it's a column, gather from the fields inside
    else if (f is ChampionColumn) {
      allErrors.addAll(gatherAllChildErrors(f.fields, controller));
    }
  }

  return allErrors;
}
