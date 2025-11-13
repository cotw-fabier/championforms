import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for TextField using the new simplified API (v0.6.0+).
///
/// Creates a [TextFieldWidget] with the provided [FieldBuilderContext].
/// This builder uses the new single-parameter signature for cleaner integration.
///
/// **Example:**
/// ```dart
/// // Register globally (done automatically for built-in fields)
/// FormFieldRegistry.register<TextField>(
///   'textField',
///   buildTextField,
/// );
/// ```
Widget buildTextField(FieldBuilderContext context) {
  return TextFieldWidget(context: context);
}

extension TextFieldController on FormController {
  TextEditingController getTextEditingController(String fieldId) {
    // Check if we already have a FieldController for this field:
    final existing = getFieldController<TextEditingController>(fieldId);
    if (existing != null) {
      return existing;
    }

    // Otherwise, create a new TextEditingController:
    final newController = TextEditingController();
    addFieldController<TextEditingController>(fieldId, newController);

    return newController;
  }
}
