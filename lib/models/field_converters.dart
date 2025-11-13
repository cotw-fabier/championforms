import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/file_model.dart';

/// Abstract base class defining converter function signatures.
///
/// [FieldConverters] defines the contract for converting field values from
/// their native storage type to common output formats like String,
/// list of String, bool, and list of FileModel.
///
/// ## Purpose
///
/// Different field types store values in different formats:
/// - Text fields: `String`
/// - Multiselect fields: list of FieldOption
/// - File fields: list of FileModel
/// - Numeric fields: `int` or `double`
///
/// Converters provide a consistent API for accessing these values in common
/// formats, enabling results processing without type-specific logic.
///
/// ## Implementation
///
/// Implement this abstract class via mixins that provide field-type-specific
/// conversion logic:
/// - [TextFieldConverters] for String-based fields
/// - [MultiselectFieldConverters] for list of FieldOption fields
/// - [FileFieldConverters] for file upload fields
/// - [NumericFieldConverters] for int/double fields
///
/// ## Error Handling
///
/// All converters throw [TypeError] when given an invalid input type.
/// This explicit failure model ensures errors are caught early rather
/// than silently returning incorrect results.
///
/// See also:
/// - [TextFieldConverters] for text field conversion
/// - [MultiselectFieldConverters] for multiselect conversion
/// - [FileFieldConverters] for file field conversion
/// - [NumericFieldConverters] for numeric field conversion
abstract class FieldConverters {
  /// Converts a field value to a display [String].
  ///
  /// **Returns:**
  /// A string representation suitable for display.
  ///
  /// **Throws:**
  /// [TypeError] if the value cannot be converted.
  String Function(dynamic value) get asStringConverter;

  /// Converts a field value to a list of String.
  ///
  /// **Returns:**
  /// A list of strings, or empty list for null values.
  ///
  /// **Throws:**
  /// [TypeError] if the value cannot be converted.
  List<String> Function(dynamic value) get asStringListConverter;

  /// Converts a field value to a [bool] representation.
  ///
  /// Typically represents whether the field has a "truthy" value
  /// (e.g., non-empty string, non-zero number, non-empty list).
  ///
  /// **Returns:**
  /// `true` if the value is considered "set" or "truthy", `false` otherwise.
  ///
  /// **Throws:**
  /// [TypeError] if the value cannot be converted.
  bool Function(dynamic value) get asBoolConverter;

  /// Converts a field value to a list of FileModel.
  ///
  /// Returns `null` if the field type does not support file uploads.
  ///
  /// **Returns:**
  /// A list of file models, null for non-file fields, or null for null values.
  ///
  /// **Throws:**
  /// [TypeError] if the value cannot be converted (when converter is non-null).
  List<FileModel>? Function(dynamic value)? get asFileListConverter;
}

/// Converter mixin for text-based fields (TextField).
///
/// Provides conversion logic for fields that store values as [String].
///
/// ## Conversion Rules
///
/// - **asStringConverter:**
///   - `String` → returns as-is
///   - `null` → returns `""`
///   - Other types → throws [TypeError]
///
/// - **asStringListConverter:**
///   - `String` → returns list with single string
///   - `null` → returns empty list
///   - Other types → throws [TypeError]
///
/// - **asBoolConverter:**
///   - Non-empty `String` → returns `true`
///   - Empty `String` or `null` → returns `false`
///   - Other types → throws [TypeError]
///
/// - **asFileListConverter:**
///   - Always `null` (text fields don't support files)
///
/// ## Usage
///
/// ```dart
/// class MyTextField extends Field with TextFieldConverters {
///   // Field implementation...
/// }
/// ```
///
/// See also:
/// - [FieldConverters] for the base interface
/// - [TextField] for the built-in text field implementation
mixin TextFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is String) return value;
        if (value == null) return "";
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is String) return [value];
        if (value == null) return [];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is String) return value.isNotEmpty;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

/// Converter mixin for multiselect fields (OptionSelect, CheckboxSelect, ChipSelect).
///
/// Provides conversion logic for fields that store values as list of FieldOption.
///
/// ## Conversion Rules
///
/// - **asStringConverter:**
///   - list of FieldOption → comma-separated labels (e.g., "Option 1, Option 2")
///   - `null` → returns `""`
///   - Other types → throws [TypeError]
///
/// - **asStringListConverter:**
///   - list of FieldOption → list of values (e.g., ["val1", "val2"])
///   - `null` → returns empty list
///   - Other types → throws [TypeError]
///
/// - **asBoolConverter:**
///   - Non-empty list of FieldOption → returns `true`
///   - Empty list or `null` → returns `false`
///   - Other types → throws [TypeError]
///
/// - **asFileListConverter:**
///   - Always `null` (multiselect fields don't support files)
///
/// ## Usage
///
/// ```dart
/// class MyMultiselectField extends Field with MultiselectFieldConverters {
///   // Field implementation...
/// }
/// ```
///
/// See also:
/// - [FieldConverters] for the base interface
/// - [OptionSelect] for the built-in multiselect field
/// - [FieldOption] for option definitions
mixin MultiselectFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is List<FieldOption>) {
          return value.map((o) => o.label).join(", ");
        }
        if (value == null) return "";
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is List<FieldOption>) {
          return value.map((o) => o.value).toList();
        }
        if (value == null) return [];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is List<FieldOption>) return value.isNotEmpty;
        if (value is List && value.isEmpty) return false;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}

/// Converter mixin for file upload fields (FileUpload).
///
/// Provides conversion logic for fields that store values as list of FileModel.
///
/// ## Conversion Rules
///
/// - **asStringConverter:**
///   - list of FileModel → comma-separated filenames (e.g., "file1.pdf, file2.jpg")
///   - `null` → returns `""`
///   - Other types → throws [TypeError]
///
/// - **asStringListConverter:**
///   - list of FileModel → list of filenames (e.g., ["file1.pdf", "file2.jpg"])
///   - `null` → returns empty list
///   - Other types → throws [TypeError]
///
/// - **asBoolConverter:**
///   - Non-empty list of FileModel → returns `true`
///   - Empty list or `null` → returns `false`
///   - Other types → throws [TypeError]
///
/// - **asFileListConverter:**
///   - list of FileModel → returns as-is
///   - `null` → returns `null`
///   - Other types → throws [TypeError]
///
/// ## Usage
///
/// ```dart
/// class MyFileField extends Field with FileFieldConverters {
///   // Field implementation...
/// }
/// ```
///
/// See also:
/// - [FieldConverters] for the base interface
/// - [FileUpload] for the built-in file field
/// - [FileModel] for file data structure
mixin FileFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is List<FileModel>) {
          return value.map((f) => f.fileName).join(", ");
        }
        if (value == null) return "";
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is List<FileModel>) {
          return value.map((f) => f.fileName).toList();
        }
        if (value == null) return [];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is List<FileModel>) return value.isNotEmpty;
        if (value is List && value.isEmpty) return false;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => (value) {
        if (value is List<FileModel>) return value;
        if (value == null) return null;
        throw TypeError();
      };
}

/// Converter mixin for numeric fields.
///
/// Provides conversion logic for fields that store values as [int] or [double].
///
/// ## Conversion Rules
///
/// - **asStringConverter:**
///   - `int` or `double` → string representation (e.g., "42", "3.14")
///   - `null` → returns `""`
///   - Other types → throws [TypeError]
///
/// - **asStringListConverter:**
///   - `int` or `double` → single-element list (e.g., ["42"])
///   - `null` → returns empty list
///   - Other types → throws [TypeError]
///
/// - **asBoolConverter:**
///   - Non-zero `int` or `double` → returns `true`
///   - Zero or `null` → returns `false`
///   - Other types → throws [TypeError]
///
/// - **asFileListConverter:**
///   - Always `null` (numeric fields don't support files)
///
/// ## Usage
///
/// ```dart
/// class MyNumericField extends Field with NumericFieldConverters {
///   // Field implementation...
/// }
/// ```
///
/// See also:
/// - [FieldConverters] for the base interface
mixin NumericFieldConverters implements FieldConverters {
  @override
  String Function(dynamic value) get asStringConverter => (value) {
        if (value is int || value is double) return value.toString();
        if (value == null) return "";
        throw TypeError();
      };

  @override
  List<String> Function(dynamic value) get asStringListConverter => (value) {
        if (value is int || value is double) return [value.toString()];
        if (value == null) return [];
        throw TypeError();
      };

  @override
  bool Function(dynamic value) get asBoolConverter => (value) {
        if (value is int) return value != 0;
        if (value is double) return value != 0.0;
        if (value == null) return false;
        throw TypeError();
      };

  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
