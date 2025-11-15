import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/multiselect_option.dart';
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
}
