import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:flutter/widgets.dart';

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

  @override
  NullField copyWith({
    String? id,
    Widget? icon,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    String? defaultValue,
  }) {
    return NullField(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

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
