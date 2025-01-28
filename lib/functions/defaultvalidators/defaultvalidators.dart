import 'package:championforms/models/formresults.dart';
import 'package:email_validator/email_validator.dart';

import 'dart:core';

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

  // 1. File is present (not empty)
  bool isFileNotEmpty(FieldResults result) {
    if (result.type == FieldType.file) {
      // check if we have any file
      if (result.values.isEmpty) return false;
    }
    return true;
  }

  // 2. Check if all files are images (png/jpg/jpeg/gif)
  bool isImageFile(FieldResults result) {
    if (result.type != FieldType.file) return true;
    final files = result.asFile();
    for (final file in files) {
      final extension = _getExtension(file.name);
      if (!_imageExtensions.contains(extension.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  // 3. Check if all files are documents (doc, docx, txt)
  bool isDocumentFile(FieldResults result) {
    if (result.type != FieldType.file) return true;
    final files = result.asFile();
    for (final file in files) {
      final extension = _getExtension(file.name);
      if (!_documentExtensions.contains(extension.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  // 4. CSV
  bool isCsvFile(FieldResults result) {
    if (result.type != FieldType.file) return true;
    final files = result.asFile();
    for (final file in files) {
      final extension = _getExtension(file.name);
      if (extension.toLowerCase() != ".csv") {
        return false;
      }
    }
    return true;
  }

  // 5. Excel (xls, xlsx)
  bool isExcelFile(FieldResults result) {
    if (result.type != FieldType.file) return true;
    final files = result.asFile();
    for (final file in files) {
      final extension = _getExtension(file.name);
      if (!(extension.toLowerCase() == ".xls" ||
          extension.toLowerCase() == ".xlsx")) {
        return false;
      }
    }
    return true;
  }

  // 6. PDF
  bool isPdfFile(FieldResults result) {
    if (result.type != FieldType.file) return true;
    final files = result.asFile();
    for (final file in files) {
      final extension = _getExtension(file.name);
      if (extension.toLowerCase() != ".pdf") {
        return false;
      }
    }
    return true;
  }

  // Helper
  String _getExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1) return "";
    return name.substring(dotIndex).toLowerCase();
  }

  static final _imageExtensions = [".png", ".jpg", ".jpeg", ".gif"];
  static final _documentExtensions = [".doc", ".docx", ".txt"];
}
