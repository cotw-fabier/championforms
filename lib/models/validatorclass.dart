class FormBuilderValidator {
  final bool Function(dynamic value) validator;
  final String reason;

  FormBuilderValidator({
    required this.validator,
    required this.reason,
  });
}
