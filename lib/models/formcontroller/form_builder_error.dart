class FormBuilderError {
  final String formId;
  final String fieldId;
  final int validatorPosition;

  FormBuilderError({
    required this.formId,
    required this.fieldId,
    required this.validatorPosition,
  });
}
