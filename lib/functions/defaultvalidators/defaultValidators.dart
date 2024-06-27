import 'package:championforms/models/formresultstype.dart';
import 'package:email_validator/email_validator.dart';

class DefaultValidators {
  bool isEmpty(FormResults result) {
    String trimmedValue = result.val().trim();
    return trimmedValue.isEmpty;
  }

  // Validator to check if the text length is not between min and max length
  bool isLengthNotInRange(FormResults result, int minLength, int maxLength) {
    String value = result.val().trim();
    int length = value.length;
    return length < minLength || length > maxLength;
  }

  bool isDouble(FormResults result) {
    String value = result.val().trim();
    // Use a RegExp to check if the string contains only digits and possibly decimal points
    return !RegExp(r'^\d*\.?\d+$').hasMatch(value);
  }

  // Validator to check if the input is not an integer
  bool isInteger(FormResults result) {
    String value = result.val().trim();
    // Use a RegExp to check if the string contains only digits
    return !RegExp(r'^\d+$').hasMatch(value);
  }

  bool isEmail(FormResults result) {
    // If result is an instance of handling single string or ChoiceChipValues
    if (result is StringItem || result is ChoiceChipResultsList) {
      // Directly validate the email
      return EmailValidator.validate(result.val());
    }
    // If result handles a list of strings
    else if (result is StringListItem) {
      // Validate each email in the list
      for (String email in result.valList()) {
        if (!EmailValidator.validate(email)) {
          return false; // Return false if any email is invalid
        }
      }
      return true; // Return true if all emails are valid
    }
    return false; // Default case to handle unexpected input types
  }
}

//DefaultValidators defaultValidators = DefaultValidators();
