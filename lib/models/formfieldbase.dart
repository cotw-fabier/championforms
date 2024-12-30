abstract class FormFieldBase {
  final String id;
  final String? title;
  final String? description;

  FormFieldBase({
    required this.id,
    this.title,
    this.description,
  });
}
