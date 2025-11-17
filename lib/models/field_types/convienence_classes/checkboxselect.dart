import 'package:championforms/models/field_builder_context.dart';
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

class CheckboxSelect extends OptionSelect {
  CheckboxSelect({
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
  }) : super(fieldBuilder: fieldBuilder ?? checkboxFieldBuilder);

  @override
  CheckboxSelect copyWith({
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
    return CheckboxSelect(
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
}
