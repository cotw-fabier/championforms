import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:parchment_delta/parchment_delta.dart';

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

class FormFieldDef implements FormFieldBase {
  // Define the type of field type
  final FormFieldType type;
  final String id;

  // Add hint text if needed
  final String hintText;

  // Add icon if needed
  final Icon? icon;

  // This is the field title and will be displayed next to the field.
  final String? title;

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
    this.title,
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

  // textField
  factory FormFieldDef.textField({
    required String id,
    String hintText = "",
    Icon? icon,
    String? title,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool password = false,
    bool isSet = false,
    String? defaultValue,
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
      type: FormFieldType.textField,
      id: id,
      hintText: hintText,
      icon: icon,
      title: title,
      hideField: hideField,
      active: active,
      requestFocus: requestFocus,
      password: password,
      isSet: isSet,
      defaultValue: defaultValue,
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

  // textArea
  factory FormFieldDef.textArea({
    required String id,
    String hintText = "",
    Icon? icon,
    String? title,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool isSet = false,
    String? defaultValue,
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
      type: FormFieldType.textArea,
      id: id,
      hintText: hintText,
      icon: icon,
      title: title,
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      defaultValue: defaultValue,
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

  // richText
  factory FormFieldDef.richText({
    required String id,
    String hintText = "",
    Icon? icon,
    String? title,
    bool hideField = false,
    bool active = true,
    bool requestFocus = false,
    bool isSet = false,
    Delta? deltaValue,
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
      hideField: hideField,
      active: active,
      isSet: isSet,
      requestFocus: requestFocus,
      deltaValue: deltaValue,
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
      type: FormFieldType.chips,
      id: id,
      title: title,
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
// textField
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
  }
}
