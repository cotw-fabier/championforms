import 'package:championforms/models/field_types/formfieldbase.dart';

class FormFieldRow implements FieldBase {
  @override
  final String id;
  @override
  final String? title;
  @override
  final String? description;
  final bool fullWidth;

  FormFieldRow({
    required this.id,
    this.title,
    this.description,
    this.fullWidth = true,
  });
}

class FormFieldColumn implements FieldBase {
  @override
  final String id;
  @override
  final String? title;
  @override
  final String? description;
  final bool fullWidth;

  FormFieldColumn({
    required this.id,
    this.title,
    this.description,
    this.fullWidth = true,
  });
}
