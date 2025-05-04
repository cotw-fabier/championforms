import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championtextfield.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/widgets_internal/field_widgets/textfieldwidget.dart';
import 'package:flutter/widgets.dart';

Widget buildChampionTextField(
    BuildContext context,
    ChampionFormController controller,
    ChampionTextField field,
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus) {
  // ... logic from TextFieldWidget build, calling overrideTextField etc.
  // You'll need to manage the TextEditingController and FocusNode interaction here or within TextFieldWidget.
  // This part requires careful adaptation of TextFieldWidget's logic.
  return TextFieldWidget(
    // Or directly build the TextField here
    controller: controller,
    field: field,
    fieldState: currentState,
    colorScheme: currentColors,
    // ... other parameters derived from field, state, controller
  );
}

extension ChampionTextFieldController on ChampionFormController {
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
