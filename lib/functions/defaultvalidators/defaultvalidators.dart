import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

/// A collection of reusable validator functions for form fields.
///
/// These validators operate on a `dynamic` value. They are designed to be safe by
/// attempting to first convert the dynamic input into an expected type. If this
/// conversion fails, the validation returns `false` instead of throwing an error.
///
/// Most validators are static methods and can be called directly without instantiation:
/// ```dart
/// form.Validators.isEmail(value)
/// form.Validators.stringIsNotEmpty(value)
/// ```
///
/// The `stringLengthInRange` validator requires instantiation with min/max parameters:
/// ```dart
/// Validators(minLength: 5, maxLength: 10).stringLengthInRange(value)
/// ```
class Validators {
  final int? minLength;
  final int? maxLength;

  Validators({
    this.minLength,
    this.maxLength,
  });

  // --- String Validators ---

  /// **Checks if a value is a non-empty string.**
  ///
  /// This validator attempts to convert any non-null value to a `String`.
  /// Returns `true` if the resulting string has content after trimming.
  /// Returns `false` for `null` or if the value results in an empty string.
  static bool stringIsNotEmpty(dynamic value) {
    if (value == null) {
      return false;
    }
    // Attempt to convert the input to a String before validation.
    final String stringValue = value.toString();
    return stringValue.trim().isNotEmpty;
  }

  /// **Checks if a value is null or an empty string.**
  ///
  /// This validator attempts to convert any non-null value to a `String`.
  /// Returns `true` if the value is `null` or the resulting string is empty.
  static bool stringIsEmpty(dynamic value) {
    if (value == null) {
      return true;
    }
    // Attempt to convert the input to a String before validation.
    final String stringValue = value.toString();
    return stringValue.trim().isEmpty;
  }

  /// **Checks if a string's length is within a specified range.**
  ///
  /// Attempts to convert the value to a `String`. Returns `true` if the resulting
  /// string's trimmed length falls within `minLength` and `maxLength`.
  bool stringLengthInRange(dynamic value) {
    // Treat null as a string of length 0.
    final String strValue = value?.toString() ?? '';

    if (strValue.trim().isEmpty) {
      // An empty string is valid only if the minimum length is 0.
      return (minLength ?? 0) == 0;
    }
    final length = strValue.trim().length;
    final min = minLength;
    final max = maxLength;

    if (min != null && max != null) {
      return length >= min && length <= max;
    } else if (min != null) {
      return length >= min;
    } else if (max != null) {
      return length <= max;
    }
    return true; // No range defined, so it passes.
  }

  // --- Numeric Validators ---

  /// **Checks if a value can be interpreted as a `double`.**
  ///
  /// Returns `true` if the value is already a number (`int` or `double`) or if it's a `String`
  /// that can be parsed into a `double`. Returns `false` for all other cases.
  static bool isDouble(dynamic value) {
    if (value == null) return false;
    if (value is double || value is int) return true;

    // Attempt conversion from string.
    final String stringValue = value.toString();
    if (double.tryParse(stringValue.trim()) != null) {
      return true;
    }

    debugPrint(
        'Validation failed for isDouble: Value of type ${value.runtimeType} could not be converted to a double.');
    return false;
  }

  /// **Checks if a value is `null` or can be interpreted as a `double`.**
  static bool isDoubleOrNull(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    // Leverage the isDouble logic for the actual check.
    return isDouble(value);
  }

  /// **Checks if a value can be interpreted as an `int`.**
  ///
  /// Returns `true` if the value is already an `int` or if it's a `String`
  /// that can be parsed into an `int`. Returns `false` for all other cases.
  static bool isInteger(dynamic value) {
    if (value == null) return false;
    if (value is int) return true;

    // Attempt conversion from string.
    final String stringValue = value.toString();
    if (int.tryParse(stringValue.trim()) != null) {
      return true;
    }

    debugPrint(
        'Validation failed for isInteger: Value of type ${value.runtimeType} could not be converted to an int.');
    return false;
  }

  /// **Checks if a value is `null` or can be interpreted as an `int`.**
  static bool isIntegerOrNull(dynamic value) {
    if (value == null) return true;
    if (value is String && value.trim().isEmpty) return true;
    // Leverage the isInteger logic for the actual check.
    return isInteger(value);
  }

  // --- Format Validators ---

  /// **Checks if a string value is a valid email format.**
  ///
  /// The value must be a `String` to be evaluated.
  /// Returns `false` for non-string types or invalid email formats.
  static bool isEmail(dynamic value) {
    if (value is! String || value.trim().isEmpty) {
      if (value != null && value is! String) {
        debugPrint(
            'Validation failed for isEmail: Expected String, got ${value.runtimeType}');
      }
      return false;
    }
    return EmailValidator.validate(value.trim());
  }

  /// **Checks if a string value is `null`, empty, or a valid email format.**
  static bool isEmailOrNull(dynamic value) {
    if (value == null) return true;
    if (value is! String) {
      debugPrint(
          'Validation failed for isEmailOrNull: Expected String, got ${value.runtimeType}');
      return false;
    }
    if (value.trim().isEmpty) return true;
    return EmailValidator.validate(value.trim());
  }

  // --- List Validators ---

  /// **Checks if a value is a non-empty list.**
  ///
  /// Note: Unlike primitives, non-list types cannot be safely converted.
  /// This validator returns `true` only if the value is a `List` and is not empty.
  static bool listIsNotEmpty(dynamic value) {
    if (value is List) {
      return value.isNotEmpty;
    }
    if (value != null) {
      debugPrint(
          'Validation failed for listIsNotEmpty: Expected List, got ${value.runtimeType}');
    }
    return false;
  }

  /// **Checks if a value is `null` or an empty list.**
  static bool listIsEmpty(dynamic value) {
    if (value == null) return true;
    if (value is List) {
      return value.isEmpty;
    }
    debugPrint(
        'Validation failed for listIsEmpty: Expected List, got ${value.runtimeType}');
    return false;
  }

  // --- File Validators (Operating on List<FieldOption>) ---

  /// Helper to safely extract FileModel from a FieldOption.
  static FileModel? _getFileModelFromOption(FieldOption option) {
    if (option.additionalData is FileModel) {
      return option.additionalData as FileModel;
    }
    debugPrint(
        "Warning: FieldOption.additionalData was not a FileModel, which is required for file validation.");
    return null;
  }

  /// Helper to ensure the value is a `List<FieldOption>`. Returns null on failure.
  static List<FieldOption>? _ensureListOfFieldOption(dynamic value) {
    if (value == null) return []; // Treat null as an empty list.
    if (value is List && value.every((e) => e is FieldOption)) {
      return value.cast<FieldOption>();
    }
    debugPrint(
        'File validation failed: Expected List<FieldOption>, got ${value.runtimeType}');
    return null;
  }

  /// **Checks if all uploaded files match a given set of MIME types.**
  static bool fileIsMimeType(dynamic value, List<String> matchStrings) {
    final options = _ensureListOfFieldOption(value);
    if (options == null) return false; // Invalid input type.
    if (options.isEmpty) return true; // No files to validate.

    return options.every((option) {
      final fileModel = _getFileModelFromOption(option);
      final mime = fileModel?.mimeData?.mime;
      if (mime == null) {
        debugPrint(
            "Validation Warning: Mime type check failed for '${fileModel?.fileName}' because mimeData was null.");
        return false;
      }
      return matchStrings.any((pattern) => mime.startsWith(pattern));
    });
  }

  /// **Checks if all uploaded files are images.** (MIME starts with "image/")
  static bool fileIsImage(dynamic value) {
    return fileIsMimeType(value, ["image/"]);
  }

  /// **Checks if all uploaded files are common image types.**
  static bool fileIsCommonImage(dynamic value) {
    return fileIsMimeType(value, const [
      "image/jpeg",
      "image/png",
      "image/svg+xml",
      "image/gif",
      "image/webp",
    ]);
  }

  /// **Checks if all uploaded files are common document types.**
  static bool fileIsDocument(dynamic value) {
    return fileIsMimeType(value, const [
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/pdf",
      "text/plain",
      "application/rtf",
      "application/vnd.oasis.opendocument.text"
    ]);
  }
}
