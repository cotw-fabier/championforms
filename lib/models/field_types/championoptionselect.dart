import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/field_builders/dropdownfield_builder.dart';
import 'package:flutter/widgets.dart';

class ChampionOptionSelect extends FormFieldDef {
  // Define the type of field type
  //

  @override
  FieldType get fieldType => FieldType.string;

  final Widget? leading;
  final Widget? trailing;

  // Options
  final List<MultiselectOption> options;

  // Multiselect?
  final bool multiselect;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  final List<String> defaultValue;

  // match default value case sensitive?
  final bool caseSensitiveDefaultValue;

  // Add a builder for defining the field style
  Widget Function(
    BuildContext context,
    ChampionFormController controller,
    List<MultiselectOption> choices,
    ChampionOptionSelect field,
    FieldState currentState,
    FieldColorScheme currentColors,
    List<String>? defaultValue,
    Function(bool focused) updateFocus,
    Function(MultiselectOption? selectedOption) updateSelectedOption,
  ) fieldBuilder;

  ChampionOptionSelect({
    required super.id,
    super.icon,
    required this.options,
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
    this.fieldBuilder = dropdownFieldBuilder,
  });
}
