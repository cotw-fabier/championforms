import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';

class NullField extends Field {
  // Define the type of field type

  @override
  final String? defaultValue;

  NullField({
    required super.id,
    super.icon,
    super.theme,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.requestFocus,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.fieldLayout,
    super.fieldBackground,
    this.defaultValue,
  });

  // --- Implementation of Field<String> Converters ---

  /// Converts the String value to a String (identity function).
  @override
  String Function(dynamic value) get asStringConverter => (dynamic value) {
        return "";
      };

  /// Converts the String value into a List containing that single String.
  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (dynamic value) {
        return [];
      };

  /// Converts the String value to bool (true if not empty, false otherwise).
  @override
  bool Function(dynamic value) get asBoolConverter => (dynamic value) {
        return false;
      };

  /// Text fields do not represent files. Returns null.
  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
