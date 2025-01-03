import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
import 'package:championforms/widgets_external/field_builders/checkboxfield_builder.dart';
import 'package:championforms/widgets_external/field_builders/dropdownfield_builder.dart';
import 'package:championforms/widgets_external/field_layouts/simple_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FormFieldType {
  textField,
  textArea,
  richText,
  richTextToolbar,
  chips,
  tagField,
  checkbox,
  dropdown,
  radio,

  // If you want to return a widget inside a form. Its probably better to simply make multiple forms with the same ID
  // And then organize the screen how you like.
  widget,
}

class FormFieldChoiceOption {
  final String value;
  final String name;

  FormFieldChoiceOption({
    required this.value,
    String? name,
  }) : name = name ?? value;
}

abstract class FormFieldDef implements FormFieldBase {
  // Add an ID
  @override
  final String id;

  // Add icon if needed
  final Widget? icon;

  // This is the field title and will be displayed next to the field.
  @override
  final String? title;
  @override
  final String? description;

  // Is this field disabled?
  final bool disabled;

  final FormTheme? theme;

  // Hide this field and don't include it at all in the outputs or validators. Helpful for building dynamic forms.
  final bool hideField;

  // This field will ask for focus. Best to only have one per form.
  final bool requestFocus;

  final List<FormBuilderValidator>? validators;
  final bool validateLive;

  // Functions
  // THis can be called on compatible fields. When you press enter or trigger a field submit it will trigger this function.
  final Function(FormResults results)? onSubmit;

  // This can be called on compatible fields. When the field changes, this function is run.
  final Function(FormResults results)? onChange;

  final Widget Function(
          BuildContext context,
          FormFieldDef fieldDetails,
          FieldColorScheme currentColors,
          List<FormBuilderError> errors,
          Widget renderedField)
      fieldLayout; // This is a wrapper around the entire field which adds things like title and description. You can override this with anything you want.
  final Widget Function(BuildContext context, FormFieldDef fieldDetails,
          FieldColorScheme currentColors, Widget renderedField)
      fieldBackground; // This is the background around the field itself.

  FormFieldDef({
    required this.id,
    this.icon,
    this.theme,
    this.title,
    this.description,
    this.disabled = false,
    this.hideField = false,
    this.requestFocus = false,
    this.validators,
    this.validateLive = false,
    this.onSubmit,
    this.onChange,
    //this.embeds = const [],
    this.fieldLayout = fieldSimpleLayout, // Default to the simple layout
    this.fieldBackground =
        fieldSimpleBackground, // Default to the simple (no) field background
  });
}

class ChampionTextField extends FormFieldDef {
  // Define the type of field type

  // Add a TextField override so we could write our own widget if we prefer. This will override the default field.
  final TextField? fieldOverride;

  final int? maxLines;

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

  // Add a builder for defining the field style

  // We need to have a callback which will be called when drag and drop
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onDrop;

  // Does this field support drag functionality?
  final bool draggable;

  // We need to have a callback which will be called when content is pasted
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onPaste;

  ChampionTextField({
    required super.id,
    this.fieldOverride,
    this.maxLines,
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
}

class ChampionOptionSelect extends FormFieldDef {
  // Define the type of field type

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
    WidgetRef ref,
    String formId,
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

class ChampionCheckboxSelect extends ChampionOptionSelect {
  // Add a builder for defining the field style
  Widget Function(
    BuildContext context,
    WidgetRef ref,
    String formId,
    List<MultiselectOption> choices,
    ChampionOptionSelect field,
    FieldState currentState,
    FieldColorScheme currentColors,
    List<String>? defaultValue,
    Function(bool focused) updateFocus,
    Function(MultiselectOption? selectedOption) updateSelectedOption,
  ) fieldBuilder;
  ChampionCheckboxSelect({
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
