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
  bool stringIsNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  /// Checks if a String value is null or empty after trimming.
  /// Returns `true` if the string is empty/null, `false` otherwise.
  /// Note: Often, `stringIsNotEmpty` is more useful for validation (e.g., required field).
  bool stringIsEmpty(String? value) {
    return value == null || value.trim().isEmpty;
  }

  /// Checks if a String value's length is within the specified range (inclusive).
  /// Assumes the string should not be empty if ranges are specified.
  /// Returns `true` if the length is within range, `false` otherwise or if the value is null/empty.
  bool stringLengthInRange(String? value) {
    if (value == null || value.trim().isEmpty) {
      // If it's empty, it can't be in a specific length range unless minLength is 0.
      return minLength == 0 && (maxLength == null || maxLength! >= 0);
    }
    final length = value.trim().length;
    final min = minLength;
    final max = maxLength;

    if (min != null && max != null) {
      return length >= min && length <= max;
    } else if (min != null) {
      return length >= min;
    } else if (max != null) {
      return length <= max;
    }
    // If no min or max is set, any length is considered "in range"
    return true;
  }

  /// Checks if a String value represents a valid double.
  /// Returns `true` if it's a double, `false` otherwise (including if null/empty).
  bool stringIsDouble(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    // Use double.tryParse for robustness
    return double.tryParse(value.trim()) != null;
    // Original Regex check (less robust than tryParse):
    // return RegExp(r'^\d*\.?\d+$').hasMatch(value.trim());
  }

  /// Checks if a String value is null, empty, or represents a valid double.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsDoubleOrNull(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    return double.tryParse(value.trim()) != null;
    // Original Regex check:
    // return RegExp(r'^\d*\.?\d+$').hasMatch(value.trim());
  }

  /// Checks if a String value represents a valid integer.
  /// Returns `true` if it's an integer, `false` otherwise (including if null/empty).
  bool stringIsInteger(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    // Use int.tryParse for robustness
    return int.tryParse(value.trim()) != null;
    // Original Regex check:
    // return RegExp(r'^\d+$').hasMatch(value.trim());
  }

  /// Checks if a String value is null, empty, or represents a valid integer.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsIntegerOrNull(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    return int.tryParse(value.trim()) != null;
    // Original Regex check:
    // return RegExp(r'^\d+$').hasMatch(value.trim());
  }

  /// Checks if a String value is a valid email format.
  /// Returns `true` if it's a valid email, `false` otherwise (including if null/empty).
  bool stringIsEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return EmailValidator.validate(value.trim());
  }

  /// Checks if a String value is a valid email format or is null/empty.
  /// Returns `true` if valid, `false` otherwise.
  bool stringIsEmailOrNull(String? value) {
    if (value == null || value.trim().isEmpty) return true;
    return EmailValidator.validate(value.trim());
  }

  // --- List Validators (for Multiselect/File Uploads etc.) ---

  /// Checks if a List value is not null and not empty.
  /// Returns `true` if the list has items, `false` otherwise.
  bool listIsNotEmpty(List? value) {
    return value != null && value.isNotEmpty;
  }

  /// Checks if a List value is null or empty.
  /// Returns `true` if the list is empty/null, `false` otherwise.
  bool listIsEmpty(List? value) {
    return value == null || value.isEmpty;
  }

  // --- File Validators (Operating on List<MultiselectOption>) ---
  // These are designed for ChampionFileUpload fields where T = List<MultiselectOption>
  // and FileModel is expected in additionalData.

  /// Helper to safely extract FileModel from a MultiselectOption.
  FileModel? _getFileModelFromOption(MultiselectOption option) {
    if (option.additionalData is FileModel) {
      return option.additionalData as FileModel;
    } else {
      // Log a warning if data is missing or incorrect type during validation
      debugPrint(
          "Validation Warning: Expected FileModel in additionalData for option value '${option.value}', but found ${option.additionalData?.runtimeType ?? 'null'}.");
      return null;
    }
  }

  /// Checks if all files represented by the selected [options] have a mime type
  /// that starts with at least one of the strings in [matchStrings].
  /// Returns `true` if all files match (or if the list is null/empty), `false` otherwise.
  bool fileIsMimeType(
      List<MultiselectOption>? options, List<String> matchStrings) {
    if (options == null || options.isEmpty) {
      return true; // No files to validate, so it passes. Use listIsNotEmpty for required check.
    }

    return options.every((option) {
      final fileModel = _getFileModelFromOption(option);
      // We *require* mimeData for this validation. If it's missing, validation fails.
      // Note: mimeData might only be available *after* the file is read, which
      // might not happen before validation runs. This validator might need
      // adjustment based on when mime data is populated.
      // Consider validating based on file extension initially if needed.
      final mime = fileModel?.mimeData?.mime;

      if (mime == null) {
        debugPrint(
            "Validation Warning: Mime type check failed for '${fileModel?.fileName ?? option.value}' because mimeData was null.");
        return false; // Cannot validate without mime type
      }
      // Check if it starts with any pattern.
      return matchStrings.any((pattern) => mime.startsWith(pattern));
    });
  }

  /// Checks if all files represented by [options] have a mime type starting with "image/".
  /// Returns `true` if all are images, `false` otherwise.
  bool fileIsImage(List<MultiselectOption>? options) {
    return fileIsMimeType(
        options, ["image/"]); // Be more specific with trailing slash
  }

  /// Checks if all files represented by [options] have common image mime types.
  /// Returns `true` if all match, `false` otherwise.
  bool fileIsCommonImage(List<MultiselectOption>? options) {
    return fileIsMimeType(options, const [
      "image/jpeg", // .jpg, .jpeg
      "image/png", // .png
      "image/svg+xml", // .svg
      "image/gif", // .gif
      "image/webp", // .webp
      // Add others if needed, e.g., "image/bmp"
    ]);
  }

  /// Checks if all files represented by [options] have common document mime types.
  /// Returns `true` if all match, `false` otherwise.
  bool fileIsDocument(List<MultiselectOption>? options) {
    return fileIsMimeType(options, const [
      "application/msword", // .doc
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document", // .docx
      "application/pdf", // .pdf
      "text/plain", // .txt
      "application/rtf", // .rtf
      "application/vnd.oasis.opendocument.text" // .odt
      // Add others if needed, e.g., "text/csv", "application/vnd.ms-excel"
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
      return listIsEmpty(listValue); // Use the new list validator
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
