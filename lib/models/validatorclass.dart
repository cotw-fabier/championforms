import 'package:championforms/models/formresults.dart';

class FormBuilderValidator {
  final bool Function(FieldResults results) validator;
  final String reason;

  FormBuilderValidator({
    required this.validator,
    required this.reason,
  });
}
