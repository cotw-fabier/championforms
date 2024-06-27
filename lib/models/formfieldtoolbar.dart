import 'package:championforms/models/formfieldbase.dart';
import 'package:fleather/fleather.dart';

class FormFieldToolbar implements FormFieldBase {
  // This should match the ID of the field that it is associated with.
  final String editorId;
  // This should match the ID of the form that it is associated with. If left blank the form builder will insert the form ID its a part of.
  // But you could add this to another form and modify a different form's field.
  final String? formId;
  // This toolbar builder allows you to customize the toolbar for the field.
  // It will use the correct controller without having to interact with ref.
  final FleatherToolbar Function(FleatherController controller)? toolbarBuilder;
  // Follow editor
  final bool followLastActiveQuill;

  // Hide the toolbar for some reason.
  final bool hideField;
  // Disable the toolbar for some reason.
  final bool disableField;

  FormFieldToolbar({
    required this.editorId,
    this.formId,
    this.followLastActiveQuill = false,
    this.toolbarBuilder,
    this.hideField = false,
    this.disableField = false,
  });
}
