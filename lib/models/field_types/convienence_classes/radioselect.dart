import 'package:championforms/core/field_json.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_condition.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/widgets_external/field_builders/radiofield_builder.dart';
import 'package:flutter/widgets.dart';

/// A single-select group rendered as radio buttons.
///
/// `CheckboxSelect(multiselect: false)` has always *behaved* as a radio group —
/// `toggleMultiSelectValue` clears the other choices when `multiselect` is
/// false — while looking like a set of ticks. Square ticks say "pick as many as
/// you like" and round radios say "pick exactly one", and that is the only
/// signal a person gets about what the control will do before they try it.
///
/// `multiselect` is fixed to false. A multi-select radio group is not a thing,
/// and leaving the parameter open would make it possible to build a control
/// whose appearance actively lies about its behaviour.
///
/// ```dart
/// RadioSelect(
///   id: 'plan',
///   title: 'Which plan?',
///   options: [
///     FieldOption(value: 'monthly', label: 'Monthly'),
///     FieldOption(value: 'annual', label: 'Annual', hintText: 'Two months free'),
///   ],
/// )
/// ```
class RadioSelect extends OptionSelect {
  /// Creates a radio group.
  RadioSelect({
    required super.id,
    super.icon,
    required super.options,
    super.leading,
    super.trailing,
    super.theme,
    super.title,
    super.description,
    super.disabled,
    super.hideField,
    super.conditional,
    super.requestFocus,
    super.defaultValue = const [],
    super.caseSensitiveDefaultValue = true,
    super.validators,
    super.validateLive,
    super.onSubmit,
    super.onChange,
    super.fieldLayout,
    super.fieldBackground,
    Widget Function(FieldBuilderContext)? fieldBuilder,
  }) : super(
          multiselect: false,
          fieldBuilder: fieldBuilder ?? radioFieldBuilder,
        );

  /// Builds a [RadioSelect] from its JSON map.
  ///
  /// Registered for the type names `radioSelect` and `radio`. Recognised keys
  /// are the same as [OptionSelect.fromJson] minus `multiselect`, which is
  /// fixed.
  factory RadioSelect.fromJson(Map<String, dynamic> json) {
    final options = FieldJson.options(json);
    return RadioSelect(
      id: FieldJson.id(json),
      title: FieldJson.string(json, 'title'),
      description: FieldJson.string(json, 'description'),
      options: options,
      defaultValue: FieldJson.defaultSelection(json, options),
      caseSensitiveDefaultValue:
          FieldJson.boolean(json, 'caseSensitiveDefaultValue', fallback: true),
      disabled: FieldJson.boolean(json, 'disabled'),
      hideField: FieldJson.boolean(json, 'hideField'),
      requestFocus: FieldJson.boolean(json, 'requestFocus'),
      validateLive: FieldJson.boolean(json, 'validateLive'),
      validators: FieldJson.validators(json),
      conditional: FieldJson.conditional(json),
    );
  }

  @override
  RadioSelect copyWith({
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
    FieldCondition? conditional,
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
    // `multiselect` is accepted for signature compatibility with the base
    // class and deliberately ignored: a radio group that could be copied into
    // a multi-select would look like radios and behave like checkboxes.
    return RadioSelect(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      options: options ?? this.options,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      conditional: conditional ?? this.conditional,
      requestFocus: requestFocus ?? this.requestFocus,
      defaultValue: defaultValue ?? this.defaultValue,
      caseSensitiveDefaultValue:
          caseSensitiveDefaultValue ?? this.caseSensitiveDefaultValue,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
    );
  }
}
