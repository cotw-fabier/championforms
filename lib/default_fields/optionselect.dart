import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/optionselect_widget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for OptionSelect fields using the new StatefulFieldWidget API.
///
/// This simplified builder creates an [OptionSelectWidget] which handles all
/// lifecycle management, validation, and change detection automatically.
///
/// The actual UI rendering is delegated to the field's `fieldBuilder` property
/// (e.g., dropdownFieldBuilder, checkboxFieldBuilder, chipFieldBuilder).
Widget buildOptionSelect(FieldBuilderContext context) {
  return OptionSelectWidget(context: context);
}
