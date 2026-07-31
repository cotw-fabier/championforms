import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/core/field_json.dart';
import 'package:championforms/models/field_colors.dart';
import 'package:championforms/models/field_condition.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/widgets_external/field_builders/checkboxfield_builder.dart';
import 'package:flutter/widgets.dart';

class ChipSelect extends OptionSelect {
  ChipSelect({
    required super.id,
    super.icon,
    required super.options,
    super.multiselect = false,
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
    super.colors,
    super.animateValidationErrors,
    Widget Function(FieldBuilderContext)? fieldBuilder,
  }) : super(fieldBuilder: fieldBuilder ?? checkboxFieldBuilder);

  /// Builds a [ChipSelect] from its JSON map.
  ///
  /// Registered for the type names `chipSelect` and `chips`. Recognised keys
  /// are the same as [OptionSelect.fromJson].
  factory ChipSelect.fromJson(Map<String, dynamic> json) {
    final options = FieldJson.options(json);
    return ChipSelect(
      id: FieldJson.id(json),
      title: FieldJson.string(json, 'title'),
      description: FieldJson.string(json, 'description'),
      options: options,
      multiselect: FieldJson.boolean(json, 'multiselect', fallback: true),
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
  ChipSelect copyWith({
    String? id,
    Widget? icon,
    List<FieldOption>? options,
    bool? multiselect,
    Widget? leading,
    Widget? trailing,
    FormTheme? theme,
    FieldColors? colors,
    bool? animateValidationErrors,
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
    return ChipSelect(
      id: id ?? this.id,
      icon: icon ?? this.icon,
      options: options ?? this.options,
      multiselect: multiselect ?? this.multiselect,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      colors: colors ?? this.colors,
      animateValidationErrors:
          animateValidationErrors ?? this.animateValidationErrors,
      title: title ?? this.title,
      description: description ?? this.description,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      conditional: conditional ?? this.conditional,
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
}
