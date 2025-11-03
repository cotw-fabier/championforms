// New base class for any element that can be in the form's `fields` list.
abstract class FormElement {
  const FormElement();
}

abstract class FieldBase extends FormElement {
  final String id;
  final String? title;
  final String? description;

  FieldBase({
    required this.id,
    this.title,
    this.description,
  });
}
