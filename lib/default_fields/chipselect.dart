import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/optionselect_widget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for ChipSelect fields using the new StatefulFieldWidget API.
///
/// ChipSelect extends OptionSelect, so we reuse the same [OptionSelectWidget]
/// which handles all lifecycle management, validation, and change detection automatically.
Widget buildChipSelect(FieldBuilderContext context) {
  return OptionSelectWidget(context: context);
}
