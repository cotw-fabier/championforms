import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/field_builders/checkboxfield_builder.dart';
import 'package:flutter/widgets.dart';

class CheckboxSelect extends OptionSelect {
  // Add a builder for defining the field style
  @override
  Widget Function(
    BuildContext context,
    FormController controller,
    OptionSelect field,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus,
    Function(MultiselectOption? selectedOption) updateSelectedOption,
  ) fieldBuilder;
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
    this.fieldBuilder = checkboxFieldBuilder,
  });
}
