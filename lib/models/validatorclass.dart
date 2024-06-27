import 'package:championforms/models/formresultstype.dart';

class FormBuilderValidator {
  final bool Function(FormResults results) validator;
  final String reason;

  FormBuilderValidator({
    required this.validator,
    required this.reason,
  });
}
