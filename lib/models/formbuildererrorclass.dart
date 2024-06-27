class FormBuilderError {
  final String reason;
  final String formId;
  final String fieldId;
  final int validatorPosition;

  const FormBuilderError({
    required this.reason,
    required this.formId,
    required this.fieldId,
    required this.validatorPosition,
  });
}
