import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode if needed, or just debugPrint

/// A collection of reusable validator functions for ChampionForms fields.
///
/// These validators operate on the raw value type `T` expected by
/// `FormBuilderValidator<T>`.
class DefaultValidators {
  final int? minLength; // Renamed start to minLength for clarity
  final int? maxLength; // Renamed end to maxLength for clarity

  DefaultValidators({
    this.minLength,
    this.maxLength,
  });

  // --- String Validators ---

  /// Checks if a String value is not null and not empty after trimming.
  /// Returns `true` if the string is valid (has content), `false` otherwise.
  bool stringIsNotEmpty(dynamic value) {
    if (value == null) {
      // return false on null since it is technically empty.
      return false;
    }
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String, got ${value.runtimeType}');
    }
    return (value as String).trim().isNotEmpty;
  }

  /// Checks if a String value is null or empty after trimming.
  /// Returns `true` if the string is empty/null, `false` otherwise.
  /// Note: Often, `stringIsNotEmpty` is more useful for validation (e.g., required field).
  bool stringIsEmpty(dynamic value) {
    if (value == null) return true;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    return (value as String).trim().isEmpty;
  }

  /// Checks if a String value's length is within the specified range (inclusive).
  /// Assumes the string should not be empty if ranges are specified.
  /// Returns `true` if the length is within range, `false` otherwise or if the value is null/empty.
  bool stringLengthInRange(dynamic value) {
    if (value == null) {
      // If null, it can't be in a specific length range unless minLength is 0 and no maxLength or maxLength >= 0.
      return minLength == 0 && (maxLength == null || maxLength! >= 0);
    }
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) {
      return minLength == 0 && (maxLength == null || maxLength! >= 0);
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
    return true;
  }

  /// Checks if a String value represents a valid double.
  /// Returns `true` if it's a double, `false` otherwise (including if null/empty).
  bool stringIsDouble(dynamic value) {
    if (value == null)
      return false; // Or throw if null is not acceptable for this check
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return false;
    return double.tryParse(strValue.trim()) != null;
  }

  /// Checks if a String value is null, empty, or represents a valid double.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsDoubleOrNull(dynamic value) {
    if (value == null) return true;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return true;
    return double.tryParse(strValue.trim()) != null;
  }

  /// Checks if a String value represents a valid integer.
  /// Returns `true` if it's an integer, `false` otherwise (including if null/empty).
  bool stringIsInteger(dynamic value) {
    if (value == null) return false;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return false;
    return int.tryParse(strValue.trim()) != null;
  }

  /// Checks if a String value is null, empty, or represents a valid integer.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsIntegerOrNull(dynamic value) {
    if (value == null) return true;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return true;
    return int.tryParse(strValue.trim()) != null;
  }

  /// Checks if a String value is a valid email format.
  /// Returns `true` if it's a valid email, `false` otherwise (including if null/empty).
  bool stringIsEmail(dynamic value) {
    if (value == null) return false;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return false;
    return EmailValidator.validate(strValue.trim());
  }

  /// Checks if a String value is a valid email format or is null/empty.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsEmailOrNull(dynamic value) {
    if (value == null) return true;
    if (value is! String) {
      throw ArgumentError(
          'Invalid type: Expected String or null, got ${value.runtimeType}');
    }
    final String strValue = value as String;
    if (strValue.trim().isEmpty) return true;
    return EmailValidator.validate(strValue.trim());
  }

  // --- List Validators (for Multiselect/File Uploads etc.) ---

  // --- List Validators (for Multiselect/File Uploads etc.) ---

  /// Checks if a List value is not null and not empty.
  /// Returns `true` if the list has items, `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List.
  bool listIsNotEmpty(dynamic value) {
    if (value == null) return false;
    if (value is! List) {
      throw ArgumentError(
          'Invalid type: Expected List or null, got ${value.runtimeType}');
    }
    return (value as List).isNotEmpty;
  }

  /// Checks if a List value is null or empty.
  /// Returns `true` if the list is empty/null, `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List.
  bool listIsEmpty(dynamic value) {
    if (value == null) return true;
    if (value is! List) {
      throw ArgumentError(
          'Invalid type: Expected List or null, got ${value.runtimeType}');
    }
    return (value as List).isEmpty;
  }

  // --- File Validators (Operating on List<MultiselectOption>) ---
  // These are designed for ChampionFileUpload fields where T = List<MultiselectOption>
  // and FileModel is expected in additionalData.

  /// Helper to safely extract FileModel from a MultiselectOption.
  FileModel? _getFileModelFromOption(MultiselectOption option) {
    // Ensure additionalData is FileModel or null
    if (option.additionalData == null || option.additionalData is FileModel) {
      return option.additionalData as FileModel?;
    }
    // Optionally, throw if additionalData is present but not a FileModel
    // throw ArgumentError('Invalid additionalData type in MultiselectOption: Expected FileModel or null, got ${option.additionalData.runtimeType}');
    debugPrint(
        "Warning: MultiselectOption.additionalData was not a FileModel. For file validation, it should be.");
    return null; // Or handle as an error case
  }

  List<MultiselectOption> _ensureListOfMultiselectOption(dynamic value,
      {bool allowNull = false}) {
    if (value == null) {
      if (allowNull)
        return []; // Or throw if null is not acceptable even if allowNull is true but means "empty list is ok"
      throw ArgumentError(
          'Invalid type: Expected List<MultiselectOption>, got null');
    }
    if (value is! List) {
      throw ArgumentError(
          'Invalid type: Expected List<MultiselectOption>, got ${value.runtimeType}');
    }
    if (!(value as List).every((e) => e is MultiselectOption)) {
      final firstNonOption = (value as List)
          .firstWhere((e) => e is! MultiselectOption, orElse: () => null);
      throw ArgumentError(
          'Invalid type: Expected List to contain only MultiselectOption elements, but found element of type ${firstNonOption?.runtimeType}');
    }
    return (value as List).cast<MultiselectOption>();
  }

  /// Checks if all files represented by the selected options have a mime type
  /// that starts with at least one of the strings in [matchStrings].
  /// Returns `true` if all files match (or if the list is null/empty), `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List<MultiselectOption>.
  bool fileIsMimeType(dynamic value, List<String> matchStrings) {
    // If value is null, treat as empty list for this validator's logic
    final List<MultiselectOption> options =
        _ensureListOfMultiselectOption(value, allowNull: true);

    if (options.isEmpty) {
      return true; // No files to validate, so it passes. Use listIsNotEmpty for required check.
    }

    return options.every((option) {
      final fileModel = _getFileModelFromOption(option);
      final mime = fileModel?.mimeData?.mime;

      if (mime == null) {
        debugPrint(
            "Validation Warning: Mime type check failed for '${fileModel?.fileName}' because mimeData was null.");
        return false; // Cannot validate without mime type
      }
      return matchStrings.any((pattern) => mime.startsWith(pattern));
    });
  }

  /// Checks if all files represented by [options] have a mime type starting with "image/".
  /// Returns `true` if all are images, `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List<MultiselectOption>.
  bool fileIsImage(dynamic value) {
    // _ensureListOfMultiselectOption will be called by fileIsMimeType
    return fileIsMimeType(value, ["image/"]);
  }

  /// Checks if all files represented by [options] have common image mime types.
  /// Returns `true` if all match, `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List<MultiselectOption>.
  bool fileIsCommonImage(dynamic value) {
    return fileIsMimeType(value, const [
      "image/jpeg",
      "image/png",
      "image/svg+xml",
      "image/gif",
      "image/webp",
    ]);
  }

  /// Checks if all files represented by [options] have common document mime types.
  /// Returns `true` if all match, `false` otherwise.
  /// Throws ArgumentError if value is not null and not a List<MultiselectOption>.
  bool fileIsDocument(dynamic value) {
    return fileIsMimeType(value, const [
      "application/msword",
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "application/pdf",
      "text/plain",
      "application/rtf",
      "application/vnd.oasis.opendocument.text"
    ]);
  }

  // ===========================================================================
  // DEPRECATED Validators (Using old FieldResults signature)
  // ===========================================================================
  // These are provided for backward compatibility.
  // Prefer using the type-safe validators above with FormBuilderValidator<T>.

  @Deprecated(
      'Use stringIsNotEmpty(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isEmpty(FieldResultAccessor? result) {
    // This check was complex. The simplest equivalent using the new system
    // is to check if the string representation is empty.
    // For list types, check if the list is empty.
    // Note: This might not perfectly match the old behavior for all field types.
    if (result == null) return true; // If field doesn't exist, treat as empty

    // Try getting as list first (covers multiselect, file upload)
    List? listValue = result.asRaw<List>(); // Try getting raw list
    if (listValue != null) {
      return listValue.isEmpty;
      // return listIsEmpty(listValue); // Use the new list validator
    }

    // Fallback to string check
    return stringIsEmpty(result.asString());
  }

  @Deprecated(
      'Use stringLengthInRange(value) with FormBuilderValidator<String> and DefaultValidators(minLength: start, maxLength: end) instead. Will be removed in future versions.')
  bool isLengthNotInRange(FieldResultAccessor? result) {
    // We need to invert the result of the new validator
    if (result == null)
      return true; // Or false? Depends on interpretation. Let's say true (it's not *in* range).
    return !stringLengthInRange(result.asString());
  }

  @Deprecated(
      'Use stringIsDouble(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isDouble(FieldResultAccessor? result) {
    if (result == null) return false;
    return stringIsDouble(result.asString());
  }

  @Deprecated(
      'Use stringIsDoubleOrNull(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isDoubleOrNull(FieldResultAccessor? result) {
    if (result == null) return true; // Treat non-existent field as null
    return stringIsDoubleOrNull(result.asString());
  }

  @Deprecated(
      'Use stringIsInteger(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isInteger(FieldResultAccessor? result) {
    if (result == null) return false;
    return stringIsInteger(result.asString());
  }

  @Deprecated(
      'Use stringIsIntegerOrNull(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isIntegerOrNull(FieldResultAccessor? result) {
    if (result == null) return true; // Treat non-existent field as null
    return stringIsIntegerOrNull(result.asString());
  }

  @Deprecated(
      'Use stringIsEmail(value) with FormBuilderValidator<String> instead. Will be removed in future versions.')
  bool isEmail(FieldResultAccessor? result) {
    if (result == null) return false;
    return stringIsEmail(result.asString());
  }

  // --- Deprecated File Validators ---

  // @Deprecated(
  //     'Use a lambda with FormBuilderValidator<List<MultiselectOption>> and fileIsMimeType(files, matchStrings) instead. Example: validator: (opts) => DefaultValidators().fileIsMimeType(result?.asFileList() ?? [], ["image/"]). Will be removed in future versions.')
  // bool isMimeType(FieldResultAccessor? result, List<String> matchStrings) {
  //   if (result == null)
  //     return true; // Treat non-existent field as valid (no files to check)
  //   return fileIsMimeType(result.asFileList(), matchStrings);
  // }
}
