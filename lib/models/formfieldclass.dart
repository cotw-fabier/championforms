import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
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
  final String? title;
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

  // Factory constructors for each type of field.

  // Sample Factory
  /* factory FormFieldDef.textField({
    //FormFieldType type = FormFieldType.textField,
    required String id,
    String hintText = "",
    Icon? icon,
    String? title,
    List<FormFieldChoiceOption> options = const [],
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool password = false,
    bool isSet = false,
    String? defaultValue,
    Delta? deltaValue,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormFieldDef>? children,
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    //embeds = const [],
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget? child,
    Widget Function({required Widget child})? fieldBuilder,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onPaste,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.textField,
      id: id,
      hintText: hintText,
      icon: icon,
      title: title,
      options: options,
      hideField: hideField,
      active: active,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      password: password,
      isSet: isSet,
      defaultValue: defaultValue,
      deltaValue: deltaValue,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      children: children,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      //embeds: embeds,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      child: child,
      fieldBuilder: fieldBuilder,
      onDrop: onDrop,
      draggable: draggable,
      onPaste: onPaste,
    );
  } */
/*
  // textField
  factory FormFieldDef.textField({
    required String id,
    TextField? fieldOverride,
    Icon? icon,
    Widget? leading,
    Widget? trailing,
    String? title,
    String? description,
    String hintText = "",
    bool? disabled = false,
    FormTheme? theme,
    bool hideField = false,
    bool requestFocus = false,
    bool password = false,
    String? defaultValue,
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String value, FormResults results)? onSubmit,
    Function(String value, FormResults results)? onChange,
    FieldLayoutDefault? layoutDefaults,
    Widget? fieldLayout,
    Widget? fieldBackground,
    Future<void> Function({
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onPaste,
  }) {
    return FormFieldTextField(
      id: id,
      fieldOverride: fieldOverride,
      maxLines: 1,
      hintText: hintText,
      icon: icon,
      leading: leading,
      trailing: trailing,
      title: title,
      theme: theme,
      disabled: disabled ?? false,
      description: description,
      hideField: hideField,
      requestFocus: requestFocus,
      password: password,
      onSubmit: onSubmit,
      onChange: onChange,
      defaultValue: defaultValue,
      validators: validators,
      validateLive: validateLive,
      layoutDefaults: layoutDefaults,
      fieldBackground: fieldBackground,
      fieldLayout: fieldLayout,
      onDrop: onDrop,
      draggable: draggable,
      onPaste: onPaste,
    );
  }
  // textField
  factory FormFieldDef.textArea({
    required String id,
    TextField? fieldOverride,
    Icon? icon,
    int? maxLines,
    Widget? leading,
    Widget? trailing,
    String? title,
    String? description,
    String hintText = "",
    bool? disabled = false,
    FormTheme? theme,
    bool hideField = false,
    bool requestFocus = false,
    bool password = false,
    String? defaultValue,
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    FieldLayoutDefault? layoutDefaults,
    Widget? fieldLayout,
    Widget? fieldBackground,
    Function(String value, FormResults results)? onSubmit,
    Function(String value, FormResults results)? onChange,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onPaste,
  }) {
    return FormFieldTextField(
      id: id,
      fieldOverride: fieldOverride,
      maxLines: maxLines,
      hintText: hintText,
      icon: icon,
      leading: leading,
      trailing: trailing,
      title: title,
      theme: theme,
      disabled: disabled ?? false,
      description: description,
      hideField: hideField,
      requestFocus: requestFocus,
      password: password,
      onSubmit: onSubmit,
      onChange: onChange,
      defaultValue: defaultValue,
      validators: validators,
      validateLive: validateLive,
      layoutDefaults: layoutDefaults,
      fieldBackground: fieldBackground,
      fieldLayout: fieldLayout,
      onDrop: onDrop,
      draggable: draggable,
      onPaste: onPaste,
    );
  }
*/
/*
  // richText
  factory FormFieldDef.richText({
    required String id,
    String hintText = "",
    Icon? icon,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool isSet = false,
    Delta? deltaValue,
    String? defaultValue,
    Function(String value, FormResults results)? onChange,
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onPaste,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.richText,
      id: id,
      hintText: hintText,
      icon: icon,
      title: title,
      disabled: disabled ?? false,
      description: description,
      theme: theme,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      deltaValue: deltaValue,
      defaultValue: defaultValue,
      onChange: onChange,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
      onDrop: onDrop,
      draggable: draggable,
      onPaste: onPaste,
    );
  }

  // richTextToolbar
  // We use the [FormFieldToolbar] class instead.

  // chips
  factory FormFieldDef.chips({
    required String id,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    List<FormFieldChoiceOption> options = const [],
    Function(String value, FormResults results)? onChange,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool isSet = false,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.chips,
      id: id,
      title: title,
      description: description,
      disabled: disabled ?? false,
      theme: theme,
      onChange: onChange,
      options: options,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
    );
  }

  // tagfield
  factory FormFieldDef.tagField({
    required String id,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    Function(String value, FormResults results)? onChange,
    Function(String value, FormResults results)? onSubmit,
    List<FormFieldChoiceOption> options = const [],
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool isSet = false,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.tagField,
      id: id,
      title: title,
      description: description,
      disabled: disabled ?? false,
      theme: theme,
      onSubmit: onSubmit,
      onChange: onChange,
      options: options,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
    );
  }

  // checkbox
  factory FormFieldDef.checkbox({
    required String id,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    Function(String value, FormResults results)? onChange,
    List<FormFieldChoiceOption> options = const [],
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool isSet = false,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.checkbox,
      id: id,
      title: title,
      description: description,
      disabled: disabled ?? false,
      theme: theme,
      onChange: onChange,
      options: options,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
    );
  }

  // dropdown
  factory FormFieldDef.dropdown({
    required String id,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    Function(String value, FormResults results)? onChange,
    Function(String value, FormResults results)? onSubmit,
    List<FormFieldChoiceOption> options = const [],
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool isSet = false,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.dropdown,
      id: id,
      title: title,
      description: description,
      disabled: disabled ?? false,
      theme: theme,
      onSubmit: onSubmit,
      onChange: onChange,
      options: options,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
    );
  }

  // radio
  factory FormFieldDef.radio({
    required String id,
    String? title,
    String? description,
    bool? disabled,
    FormTheme? theme,
    Function(String value, FormResults results)? onChange,
    List<FormFieldChoiceOption> options = const [],
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool multiselect = false,
    bool searchable = false,
    bool isSet = false,
    List<String>? defaultValues = const [],
    List<Map<String, String>>? fieldOptions = const [],
    List<FormBuilderValidator>? validators,
    bool validateLive = false,
    Function(String)? callBack,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.radio,
      id: id,
      title: title,
      description: description,
      disabled: disabled ?? false,
      theme: theme,
      onChange: onChange,
      options: options,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      multiselect: multiselect,
      searchable: searchable,
      defaultValues: defaultValues,
      fieldOptions: fieldOptions,
      validators: validators,
      validateLive: validateLive,
      callBack: callBack,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
    );
  }
// Display any widget
  factory FormFieldDef.widget({
    required String id,
    required Widget child,
    String hintText = "",
    String? title,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    double? height,
    double? maxHeight,
    double? width,
    int? flex,
    bool fillArea = false,
    Widget Function({required Widget child})? fieldBuilder,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      FleatherController? fleatherController,
      TextEditingController? controller,
      required String formId,
      required String fieldId,
      required WidgetRef ref,
    })? onPaste,
  }) {
    return FormFieldDef._internal(
      type: FormFieldType.widget,
      id: id,
      hintText: hintText,
      title: title,
      hideField: hideField,
      active: active,
      height: height,
      maxHeight: maxHeight,
      width: width,
      flex: flex,
      fillArea: fillArea,
      fieldBuilder: fieldBuilder,
      onDrop: onDrop,
      draggable: draggable,
      onPaste: onPaste,
    );
  }*/
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

/*
class FormFieldChipsField implements FormFieldDef  {
  // Define the type of field type
  final FormFieldType type;
  final String id;

  // Add hint text if needed
  final String hintText;

  // Add icon if needed
  final Icon? icon;

  // This is the field title and will be displayed next to the field.
  final String? title;
  final String? description;

  // Is this field disabled?
  final bool disabled;

  final FormTheme? theme;
  // Options for dropdown, radio, and chips
  final List<FormFieldChoiceOption> options;

  // Enable multi-select for checkboxes, chips, and dropdowns.
  final bool multiselect;

  // Enable search for dropdowns and chips
  final bool searchable;

  // Hide this field and don't include it at all in the outputs or validators. Helpful for building dynamic forms.
  final bool hideField;

  // This field will ask for focus. Best to only have one per form.
  final bool requestFocus;

  final bool active;

  // obfuscate the field
  final bool password;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  final bool isSet;
  final String? defaultValue;
  final Delta?
      deltaValue; // specifically for Rich Text Field. Flutter Quill Delta.
  final List<String>? defaultValues;

  final List<FormBuilderValidator>? validators;
  final List<Map<String, String>>?
      fieldOptions; // Special options about the field which we don't want to add a new param to the model for.
  final bool validateLive;

  // children FormFieldDef so you can create rows, columns, tabs, and more.
  final List<FormFieldDef>? children;

  // Functions
  // THis can be called on compatible fields. When you press enter or trigger a field submit it will trigger this function.
  final Function(String value, FormResults results)? onSubmit;

  // This can be called on compatible fields. When the field changes, this function is run.
  final Function(String value, FormResults results)? onChange;

  // THis function triggers.....?
  final Function(String)? callBack;

  // For quill fields, support custom embeds from this app.
  //final List<EmbedBuilder> embeds;

  // This is layout specific.
  final double? height;
  final double? maxHeight;
  final double? width;

  // Do we want this field to attempt to fill available space. Layout controls above override this functionality.
  final int? flex;
  final bool fillArea;

  // This works for only the "widget" form field type.
  final Widget? child;

  // Add a builder for defining the field style
  final Widget Function({required Widget child})? fieldBuilder;

  // We need to have a callback which will be called when drag and drop
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onDrop;

  // Does this field support drag functionality?
  final bool draggable;

  // We need to have a callback which will be called when content is pasted
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onPaste;

  FormFieldDef._internal({
    this.type = FormFieldType.textField,
    required this.id,
    this.hintText = "",
    this.icon,
    this.theme,
    this.title,
    this.description,
    this.disabled = false,
    this.options = const [],
    this.hideField = false,
    this.active = true,
    this.requestFocus = false,
    this.multiselect = false,
    this.searchable = false,
    this.password = false,
    this.isSet = false,
    this.defaultValue,
    this.deltaValue,
    this.defaultValues = const [],
    this.fieldOptions = const [],
    this.children,
    this.validators,
    this.validateLive = false,
    this.callBack,
    this.onSubmit,
    this.onChange,
    //this.embeds = const [],
    this.height,
    this.maxHeight,
    this.width,
    this.flex,
    this.fillArea = false,
    this.child,
    this.fieldBuilder,
    this.onDrop,
    this.draggable = true,
    this.onPaste,
  });
}
*/
