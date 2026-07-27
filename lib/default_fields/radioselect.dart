import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/optionselect_widget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for RadioSelect fields using the StatefulFieldWidget API.
///
/// RadioSelect extends OptionSelect, so it reuses [OptionSelectWidget], which
/// handles lifecycle, validation and change detection; the visual difference
/// lives in `radioFieldBuilder`, which the field supplies as its
/// `fieldBuilder`.
Widget buildRadioSelect(FieldBuilderContext context) {
  return OptionSelectWidget(context: context);
}
