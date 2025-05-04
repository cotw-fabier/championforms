class FormBuilderValidator<T> {
  final bool Function(T value) validator;
  final String reason;

  FormBuilderValidator({
    required this.validator,
    required this.reason,
  });
}
