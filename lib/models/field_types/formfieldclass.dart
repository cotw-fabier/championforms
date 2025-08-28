import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
import 'package:championforms/widgets_external/field_layouts/simple_layout.dart';
import 'package:flutter/material.dart';

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
    ChampionFormController controller,
    FieldColorScheme currentColors,
    Widget renderedField,
  ) fieldLayout; // This is a wrapper around the entire field which adds things like title and description. You can override this with anything you want.
  final Widget Function(
    BuildContext context,
    FormFieldDef fieldDetails,
    ChampionFormController controller,
    FieldColorScheme currentColors,
    Widget renderedField,
  ) fieldBackground; // This is the background around the field itself.

  /// The default value for this field, matching the field's type.
  dynamic get defaultValue;

  // --- Conversion Function Getters ---

  /// Function to convert the raw value `dynamic` (expected to be T) to a display String.
  /// Throws a TypeError if the input value cannot be cast to T.
  String Function(dynamic value) get asStringConverter;

  /// Function to convert the raw value `dynamic` (expected to be T) to a List of Strings.
  /// Throws a TypeError if the input value cannot be cast to T.
  List<String> Function(dynamic value) get asStringListConverter;

  /// Function to convert the raw value `dynamic` (expected to be T) to a Boolean representation.
  /// (e.g., is the value considered "truthy" or "set"?)
  /// Throws a TypeError if the input value cannot be cast to T.
  bool Function(dynamic value) get asBoolConverter;

  /// Function to convert the raw value `dynamic` (expected to be T) to a List<FileModel>.
  /// Returns null if the field type does not support files.
  /// Throws a TypeError if the input value cannot be cast to T and conversion is attempted.
  List<FileModel>? Function(dynamic value)? get asFileListConverter;

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
