import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart';

class TextField extends Field {
  // Define the type of field type

  /// Custom field builder for overriding the default TextField rendering.
  ///
  /// When provided, this builder will be used instead of the default TextField widget.
  /// The builder receives a [FieldBuilderContext] with access to:
  /// - Field value via `ctx.getValue<String>()`
  /// - TextEditingController via `ctx.getTextController()`
  /// - FocusNode via `ctx.getFocusNode()`
  /// - Theme colors via `ctx.colors`
  /// - Value updates via `ctx.setValue(value)`
  ///
  /// Example:
  /// ```dart
  /// TextField(
  ///   id: 'phone',
  ///   fieldBuilder: (ctx) => CustomPhoneWidget(context: ctx),
  /// )
  /// ```
  final flutter.Widget Function(FieldBuilderContext)? fieldBuilder;

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

  final flutter.Widget? leading;
  final flutter.Widget? trailing;

  // Does this field have a max length?
  final int? maxLength;

  // obfuscate the field
  final bool password;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  @override
  final String? defaultValue;

  /// Text Input type. Defaults to normal input.
  /// But if you want a numeric only field you can use this to set it to numeric
  /// Direct passthrough of default field
  final flutter.TextInputType? keyboardType;

  /// Text input formatters. Defaults to empty.
  /// Direct passthrough of inputFormatters from TextField
  final List<TextInputFormatter>? inputFormatters;

  // Add a builder for defining the field style

  // We need to have a callback which will be called when drag and drop
  final Future<void> Function({
    flutter.TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onDrop;

  // Does this field support drag functionality?
  final bool draggable;

  // We need to have a callback which will be called when content is pasted
  final Future<void> Function({
    flutter.TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onPaste;

  TextField({
    required super.id,
    this.fieldBuilder,
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

  @override
  TextField copyWith({
    String? id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String? hintText,
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    bool? password,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool? draggable,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
    flutter.Widget Function(
      flutter.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      flutter.Widget renderedField,
    )? fieldLayout,
    flutter.Widget Function(
      flutter.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      flutter.Widget renderedField,
    )? fieldBackground,
  }) {
    return TextField(
      id: id ?? this.id,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
      maxLines: maxLines ?? this.maxLines,
      autoComplete: autoComplete ?? this.autoComplete,
      textFieldTitle: textFieldTitle ?? this.textFieldTitle,
      hintText: hintText ?? this.hintText,
      icon: icon ?? this.icon,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      maxLength: maxLength ?? this.maxLength,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      password: password ?? this.password,
      defaultValue: defaultValue ?? this.defaultValue,
      keyboardType: keyboardType ?? this.keyboardType,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      onDrop: onDrop ?? this.onDrop,
      draggable: draggable ?? this.draggable,
      onPaste: onPaste ?? this.onPaste,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
    );
  }

  // --- Implementation of Field<String> Converters ---

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
