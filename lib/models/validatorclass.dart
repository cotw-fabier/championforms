class Validator {
  final bool Function(dynamic value) validator;
  final String reason;

  Validator({
    required this.validator,
    required this.reason,
  });
}
