import 'package:championforms/championforms.dart';
import 'package:championforms/models/formresults.dart';
import 'package:email_validator/email_validator.dart';

class DefaultValidators {
  bool isEmpty(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final FieldResultData data in result.values) {
        if (data.value?.trim() == "") return false;
      }
    } else if (result.type == FieldType.bool) {
      if (result.values.isEmpty) return false;
    } else if (result.type == FieldType.parchment) {
      if (result.values.first.deltaValue == Delta()) return false;
    }

    return true;
  }

  // Validator to check if the text length is not between min and max length
  bool isLengthNotInRange(FieldResults result, int minLength, int maxLength) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        final String value = data.value?.trim() ?? "";
        final int length = value.length;
        if ((length < minLength || length > maxLength) == false) return false;
      }
    }
    return true;
  }

  bool isDouble(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
// Use a RegExp to check if the string contains only digits and possibly decimal points

        if ((!RegExp(r'^\d*\.?\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  // Validator to check if the input is not an integer
  bool isInteger(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
// Use a RegExp to check if the string contains only digits

        if ((!RegExp(r'^\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  bool isEmail(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
// Use a RegExp to check if the string contains only digits

        if ((!EmailValidator.validate(value)) == false) return false;
      }
    }
    return true;
  }
}

//DefaultValidators defaultValidators = DefaultValidators();
