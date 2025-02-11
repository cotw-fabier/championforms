import 'package:championforms/models/formresults.dart';
import 'package:email_validator/email_validator.dart';

class DefaultValidators {
  final int? start;
  final int? end;
  DefaultValidators({
    this.start,
    this.end,
  });

  bool isEmpty(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final FieldResultData data in result.values) {
        if ((data.value ?? "").trim().isEmpty) return false;
      }
    } else if (result.type == FieldType.bool) {
      if (result.values.isEmpty) return false;
    } else if (result.type == FieldType.file) {
      // File is considered empty if no items
      if (result.values.isEmpty) return false;
    }
    return true;
  }

  bool isLengthNotInRange(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        final String value = data.value?.trim() ?? "";
        final int length = value.length;
        if ((length <= (start ?? 0) || length >= (end ?? 0)) == false) {
          return false;
        }
      }
    }
    return true;
  }

  bool isDouble(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
        if ((RegExp(r'^\d*\.?\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  bool isDoubleOrNull(FieldResults result) {
    if (result.asString() == "") return true;
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
        if ((RegExp(r'^\d*\.?\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  bool isInteger(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
        if ((RegExp(r'^\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  bool isIntegerOrNull(FieldResults result) {
    if (result.asString() == "") return true;
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
        if ((RegExp(r'^\d+$').hasMatch(value)) == false) return false;
      }
    }
    return true;
  }

  bool isEmail(FieldResults result) {
    if (result.type == FieldType.string) {
      for (final data in result.values) {
        String value = data.value?.trim() ?? "";
        if ((EmailValidator.validate(value)) == false) return false;
      }
    }
    return true;
  }

  // ----------------------------
  // NEW FILE VALIDATORS
  // ----------------------------

  /// Checks if all files in [result] have a mime type that starts with at least
  /// one of the strings in [matchStrings].
  bool isMimeType(FieldResults result, List<String> matchStrings) {
    return result.asFile().every((file) {
      final mime = file.fileDetails?.mimeData?.mime;

      if (mime == null) return false;
      // Return false if mime is null, otherwise check if it starts with any pattern.
      return mime != null &&
          matchStrings.any((pattern) => mime.startsWith(pattern));
    });
  }

  /// Matches all images of mime type "image/*"
  bool fileIsImage(FieldResults result) {
    return isMimeType(result, ["image"]);
  }

  /// Matches jpg, png, svg, gif, and webp formats
  bool fileIsCommonImage(FieldResults result) {
    return isMimeType(result, [
      "image/jpeg", // .jpg
      "image/png", // .png
      "image/svg+xml", // .svg
      "image/gif", // .gif
      "image/webp", // .webp
    ]);
  }

  /// Matches doc/docx/pdf/txt/rtf/odt file formats.
  bool fileIsDocument(FieldResults result) {
    return isMimeType(result, [
      "application/msword", // .doc
      "application/vnd.openxmlformats-officedocument.wordprocessingml.document", // .docx
      "application/pdf", // .pdf
      "text/plain", // .txt
      "application/rtf", // .rtf
      "application/vnd.oasis.opendocument.text" // .odt
    ]);
  }
}
