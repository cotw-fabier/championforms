import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/widgets_external/field_builders/dropdownfield_builder.dart';
import 'package:flutter/widgets.dart';

class OptionSelect extends Field {
  // Define the type of field type
  //

  final Widget? leading;
  final Widget? trailing;

  // Options
  final List<FieldOption>? options;

  // Multiselect?
  final bool multiselect;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  final List<FieldOption> defaultValue;

  // match default value case sensitive?
  final bool caseSensitiveDefaultValue;

  /// Custom field builder for overriding the default rendering.
  ///
  /// When provided, this builder will be used instead of the default widget.
  /// The builder receives a [FieldBuilderContext] with access to:
  /// - Field value via `ctx.getValue<List<FieldOption>>()`
  /// - Value updates via `ctx.setValue(value)`
  /// - Theme colors via `ctx.colors`
  /// - Controller via `ctx.controller`
  ///
  /// Example:
  /// ```dart
  /// OptionSelect(
  ///   id: 'tags',
  ///   fieldBuilder: (ctx) => CustomTagWidget(context: ctx),
  /// )
  /// ```
  ///
  /// Note: Signature updated in v0.6.0+ to use FieldBuilderContext.
  final Widget Function(FieldBuilderContext) fieldBuilder;

  OptionSelect({
    required super.id,
    super.icon,
    this.options,
    this.multiselect = false,
    this.leading,
    this.trailing,
    super.theme,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.requestFocus,
    this.defaultValue = const [],
    this.caseSensitiveDefaultValue = true,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.fieldLayout,
    super.fieldBackground,
    Widget Function(FieldBuilderContext)? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? dropdownFieldBuilder;

  @override
  OptionSelect copyWith({
    String? id,
    Widget? icon,
    List<FieldOption>? options,
    bool? multiselect,
    Widget? leading,
    Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    List<FieldOption>? defaultValue,
    bool? caseSensitiveDefaultValue,
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
    Widget Function(FieldBuilderContext)? fieldBuilder,
  }) {
    return OptionSelect(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      options: options ?? this.options,
      multiselect: multiselect ?? this.multiselect,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      defaultValue: defaultValue ?? this.defaultValue,
      caseSensitiveDefaultValue: caseSensitiveDefaultValue ?? this.caseSensitiveDefaultValue,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
    );
  }

  // --- Implementation of Field<List<FieldOption>> ---

  // @override
  // List<FieldOption> get defaultValue => _defaultValue; // Implement getter

  /// Converts the list of selected options to a comma-separated string of their values.
  @override
  String Function(dynamic value) get asStringConverter => (dynamic value) {
        List<FieldOption> effectiveValue;
        if (value is List<FieldOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.map((opt) => opt.value).join(', ');
      };

  /// Converts the list of selected options to a list of their string values.
  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (dynamic value) {
        List<FieldOption> effectiveValue;
        if (value is List<FieldOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.map((opt) => opt.value).toList();
      };

  /// Returns true if at least one option is selected.
  @override
  bool Function(dynamic value) get asBoolConverter => (dynamic value) {
        List<FieldOption> effectiveValue;
        if (value is List<FieldOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.isNotEmpty;
      };

  /// Base OptionSelect does not handle files. Returns null.
  /// Subclasses like FileUpload should override this.
  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter =>
      (dynamic value) {
        // This specific field type doesn't produce files directly from its primary value T.
        // Subclasses must override if they store FileModel in T or handle it differently.
        // If `value` were `List<FieldOption>` and additionalData held files,
        // the logic would go here, but FileUpload overrides this.
        if (value is List<FieldOption> || value == null) {
          // It's the correct primary type (or null), but this base class doesn't convert it to files.
          return null;
        }
        // If value is not List<FieldOption> and not null, it's an unexpected type.
        throw TypeError();
      };
}
