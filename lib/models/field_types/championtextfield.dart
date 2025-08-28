import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChampionTextField extends FormFieldDef {
  // Define the type of field type

  // Add a TextField override so we could write our own widget if we prefer. This will override the default field.
  final TextField? fieldOverride;

  final int? maxLines;

  /// Give this text field an autocomplete functionality.
  /// Use the AutoCompleteBuilder class to define the behavior of autocomplete
  /// functionality of this field. Fetch from remote sources or give it a predefined
  /// selection of options.
  final AutoCompleteBuilder? autoComplete;

  // Add a title to the text field itself if desired
  final String? textFieldTitle;

  // Add hint text if needed
  final String hintText;

  final Widget? leading;
  final Widget? trailing;

  // Does this field have a max length?
  final int? maxLength;

  // obfuscate the field
  final bool password;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  final String? defaultValue;

  /// Text Input type. Defaults to normal input.
  /// But if you want a numeric only field you can use this to set it to numeric
  /// Direct passthrough of default field
  final TextInputType? keyboardType;

  /// Text input formatters. Defaults to empty.
  /// Direct passthrough of inputFormatters from TextField
  final List<TextInputFormatter>? inputFormatters;

  // Add a builder for defining the field style

  // We need to have a callback which will be called when drag and drop
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onDrop;

  // Does this field support drag functionality?
  final bool draggable;

  // We need to have a callback which will be called when content is pasted
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onPaste;

  ChampionTextField({
    required super.id,
    this.fieldOverride,
    this.maxLines,
    this.autoComplete,
    this.textFieldTitle,
    this.hintText = "",
    super.icon,
    this.leading,
    this.trailing,
    super.theme,
    super.title,
    super.description,
    this.maxLength,
    super.disabled,
    super.hideField,
    super.requestFocus,
    this.password = false,
    this.defaultValue,
    this.keyboardType,
    this.inputFormatters,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    this.onDrop,
    this.draggable = true,
    this.onPaste,
    super.fieldLayout,
    super.fieldBackground,
  });

  // --- Implementation of FormFieldDef<String> Converters ---

  /// Converts the String value to a String (identity function).
  @override
  String Function(dynamic value) get asStringConverter => (dynamic value) {
        if (value is String) {
          return value;
        } else if (value == null && defaultValue != null) {
          return defaultValue!;
        } else if (value == null) {
          return ""; // Or throw, depending on desired behavior for null non-defaulted
        }
        throw TypeError(); // Will be caught by FieldResultAccessor
      };

  /// Converts the String value into a List containing that single String.
  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (dynamic value) {
        if (value is String) {
          return [value];
        } else if (value == null && defaultValue != null) {
          return [defaultValue!];
        } else if (value == null) {
          return [];
        }
        throw TypeError();
      };

  /// Converts the String value to bool (true if not empty, false otherwise).
  @override
  bool Function(dynamic value) get asBoolConverter => (dynamic value) {
        if (value is String) {
          return value.isNotEmpty;
        } else if (value == null && defaultValue != null) {
          return defaultValue!.isNotEmpty;
        } else if (value == null) {
          return false;
        }
        throw TypeError();
      };

  /// Text fields do not represent files. Returns null.
  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
