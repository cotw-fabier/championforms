import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/optionselect_widget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for CheckboxSelect fields using the new StatefulFieldWidget API.
///
/// CheckboxSelect extends OptionSelect, so we reuse the same [OptionSelectWidget]
/// which handles all lifecycle management, validation, and change detection automatically.
Widget buildCheckboxSelect(FieldBuilderContext context) {
  return OptionSelectWidget(context: context);
}
