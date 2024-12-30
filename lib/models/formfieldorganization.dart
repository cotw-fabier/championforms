import 'package:championforms/models/formfieldbase.dart';

class FormFieldRow implements FormFieldBase {
  final String id;
  final String? title;
  final String? description;
  final bool fullWidth;

  FormFieldRow({
    required this.id,
    this.title,
    this.description,
    this.fullWidth = true,
  });
}

class FormFieldColumn implements FormFieldBase {
  final String id;
  final String? title;
  final String? description;
  final bool fullWidth;

  FormFieldColumn({
    required this.id,
    this.title,
    this.description,
    this.fullWidth = true,
  });
}
