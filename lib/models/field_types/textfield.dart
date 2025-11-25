import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/controllers/form_controller.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:flutter/services.dart';

/// Specifies the type of name for autofill configuration.
///
/// Used with [TextField.name] to set appropriate autofill hints.
enum NameType {
  /// Full name (given + family)
  full,

  /// First name / given name
  given,

  /// Last name / family name
  family,

  /// Middle name
  middle,

  /// Name prefix (e.g., Mr., Mrs., Dr.)
  prefix,

  /// Name suffix (e.g., Jr., III)
  suffix,

  /// Nickname
  nickname,
}

/// Helper function to get the autofill hint for a name type.
String _autofillHintForNameType(NameType type) {
  switch (type) {
    case NameType.full:
      return flutter.AutofillHints.name;
    case NameType.given:
      return flutter.AutofillHints.givenName;
    case NameType.family:
      return flutter.AutofillHints.familyName;
    case NameType.middle:
      return flutter.AutofillHints.middleName;
    case NameType.prefix:
      return flutter.AutofillHints.namePrefix;
    case NameType.suffix:
      return flutter.AutofillHints.nameSuffix;
    case NameType.nickname:
      return flutter.AutofillHints.nickname;
  }
}

class TextField extends Field {
  // Define the type of field type

  /// Custom field builder for overriding the default TextField rendering.
  ///
  /// When provided, this builder will be used instead of the default TextField widget.
  /// The builder receives a [FieldBuilderContext] with access to:
  /// - Field value via `ctx.getValue<String>()`
  /// - TextEditingController via `ctx.getTextController()`
  /// - FocusNode via `ctx.getFocusNode()`
  /// - Theme colors via `ctx.colors`
  /// - Value updates via `ctx.setValue(value)`
  ///
  /// Example:
  /// ```dart
  /// TextField(
  ///   id: 'phone',
  ///   fieldBuilder: (ctx) => CustomPhoneWidget(context: ctx),
  /// )
  /// ```
  final flutter.Widget Function(FieldBuilderContext)? fieldBuilder;

  final int? maxLines;

  /// Give this text field an autocomplete functionality.
  /// Use the AutoCompleteBuilder class to define the behavior of autocomplete
  /// functionality of this field. Fetch from remote sources or give it a predefined
  /// selection of options.
  final AutoCompleteBuilder? autoComplete;

  // Add a title to the text field itself if desired
  final String? textFieldTitle;

  // Add hint text if needed
  final String hintText;

  final flutter.Widget? leading;
  final flutter.Widget? trailing;

  // Does this field have a max length?
  final int? maxLength;

  // obfuscate the field
  final bool password;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  @override
  final String? defaultValue;

  /// Text Input type. Defaults to normal input.
  /// But if you want a numeric only field you can use this to set it to numeric
  /// Direct passthrough of default field
  final flutter.TextInputType? keyboardType;

  /// Text input formatters. Defaults to empty.
  /// Direct passthrough of inputFormatters from TextField
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints for browser/OS autofill functionality.
  ///
  /// Pass Flutter's [AutofillHints] constants to enable autofill suggestions.
  /// Use semantic constructors like [TextField.email] for automatic configuration.
  ///
  /// Example:
  /// ```dart
  /// form.TextField(
  ///   id: 'email',
  ///   autofillHints: [AutofillHints.email],
  /// )
  /// ```
  final Iterable<String>? autofillHints;

  // Add a builder for defining the field style

  // We need to have a callback which will be called when drag and drop
  final Future<void> Function({
    flutter.TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onDrop;

  // Does this field support drag functionality?
  final bool draggable;

  // We need to have a callback which will be called when content is pasted
  final Future<void> Function({
    flutter.TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onPaste;

  TextField({
    required super.id,
    this.fieldBuilder,
    this.maxLines,
    this.autoComplete,
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
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
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

  @override
  TextField copyWith({
    String? id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String? hintText,
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
    bool? password,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool? draggable,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
    flutter.Widget Function(
      flutter.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      flutter.Widget renderedField,
    )? fieldLayout,
    flutter.Widget Function(
      flutter.BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      flutter.Widget renderedField,
    )? fieldBackground,
  }) {
    return TextField(
      id: id ?? this.id,
      fieldBuilder: fieldBuilder ?? this.fieldBuilder,
      maxLines: maxLines ?? this.maxLines,
      autoComplete: autoComplete ?? this.autoComplete,
      textFieldTitle: textFieldTitle ?? this.textFieldTitle,
      hintText: hintText ?? this.hintText,
      icon: icon ?? this.icon,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      theme: theme ?? this.theme,
      title: title ?? this.title,
      description: description ?? this.description,
      maxLength: maxLength ?? this.maxLength,
      disabled: disabled ?? this.disabled,
      hideField: hideField ?? this.hideField,
      requestFocus: requestFocus ?? this.requestFocus,
      password: password ?? this.password,
      defaultValue: defaultValue ?? this.defaultValue,
      keyboardType: keyboardType ?? this.keyboardType,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      autofillHints: autofillHints ?? this.autofillHints,
      validators: validators ?? this.validators,
      validateLive: validateLive ?? this.validateLive,
      onSubmit: onSubmit ?? this.onSubmit,
      onChange: onChange ?? this.onChange,
      onDrop: onDrop ?? this.onDrop,
      draggable: draggable ?? this.draggable,
      onPaste: onPaste ?? this.onPaste,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
    );
  }

  // ==========================================================================
  // SEMANTIC NAMED CONSTRUCTORS
  // ==========================================================================

  /// Creates an email input field with autofill hints and email keyboard.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.email]
  /// - `keyboardType`: TextInputType.emailAddress (unless overridden)
  ///
  /// Example:
  /// ```dart
  /// form.TextField.email(
  ///   id: 'user_email',
  ///   title: 'Email Address',
  /// )
  /// ```
  TextField.email({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "email@example.com",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType ?? flutter.TextInputType.emailAddress,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints ?? const [flutter.AutofillHints.email],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a password input field with autofill hints and obscured text.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.password] or [AutofillHints.newPassword]
  /// - `password`: true (obscures text)
  /// - `maxLines`: 1 (passwords should be single line)
  ///
  /// Example:
  /// ```dart
  /// form.TextField.password(
  ///   id: 'login_password',
  ///   title: 'Password',
  /// )
  ///
  /// // For registration forms (new password)
  /// form.TextField.password(
  ///   id: 'new_password',
  ///   isNewPassword: true,
  /// )
  /// ```
  TextField.password({
    required String id,
    bool isNewPassword = false,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: 1,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: true,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints ??
              [
                isNewPassword
                    ? flutter.AutofillHints.newPassword
                    : flutter.AutofillHints.password
              ],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a phone number input field with autofill hints and phone keyboard.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.telephoneNumber]
  /// - `keyboardType`: TextInputType.phone
  ///
  /// Example:
  /// ```dart
  /// form.TextField.phone(
  ///   id: 'phone',
  ///   title: 'Phone Number',
  /// )
  /// ```
  TextField.phone({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType ?? flutter.TextInputType.phone,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.telephoneNumber],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a name input field with autofill hints.
  ///
  /// Use [nameType] to specify which part of the name:
  /// - [NameType.full] - Full name (default)
  /// - [NameType.given] - First name
  /// - [NameType.family] - Last name
  /// - [NameType.middle] - Middle name
  ///
  /// Example:
  /// ```dart
  /// form.TextField.name(
  ///   id: 'firstname',
  ///   nameType: form.NameType.given,
  ///   title: 'First Name',
  /// )
  /// ```
  TextField.name({
    required String id,
    NameType nameType = NameType.full,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType ?? flutter.TextInputType.name,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints ?? [_autofillHintForNameType(nameType)],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a username input field with autofill hints.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.username]
  ///
  /// Example:
  /// ```dart
  /// form.TextField.username(
  ///   id: 'username',
  ///   title: 'Username',
  /// )
  /// ```
  TextField.username({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.username],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a URL input field with autofill hints and URL keyboard.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.url]
  /// - `keyboardType`: TextInputType.url
  ///
  /// Example:
  /// ```dart
  /// form.TextField.url(
  ///   id: 'website',
  ///   title: 'Website URL',
  /// )
  /// ```
  TextField.url({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "https://",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType ?? flutter.TextInputType.url,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints ?? const [flutter.AutofillHints.url],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a street address input field with autofill hints.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.streetAddressLine1] or [AutofillHints.streetAddressLine2]
  ///
  /// Example:
  /// ```dart
  /// form.TextField.streetAddress(
  ///   id: 'street',
  ///   title: 'Street Address',
  /// )
  ///
  /// // For second address line
  /// form.TextField.streetAddress(
  ///   id: 'street2',
  ///   isSecondLine: true,
  ///   title: 'Apartment, suite, etc.',
  /// )
  /// ```
  TextField.streetAddress({
    required String id,
    bool isSecondLine = false,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints ??
              [
                isSecondLine
                    ? flutter.AutofillHints.streetAddressLine2
                    : flutter.AutofillHints.streetAddressLine1
              ],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a city input field with autofill hints.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.addressCity]
  ///
  /// Example:
  /// ```dart
  /// form.TextField.city(
  ///   id: 'city',
  ///   title: 'City',
  /// )
  /// ```
  TextField.city({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.addressCity],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a state/region input field with autofill hints.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.addressState]
  ///
  /// Example:
  /// ```dart
  /// form.TextField.state(
  ///   id: 'state',
  ///   title: 'State',
  /// )
  /// ```
  TextField.state({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.addressState],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a postal/ZIP code input field with autofill hints and number keyboard.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.postalCode]
  /// - `keyboardType`: TextInputType.number
  ///
  /// Example:
  /// ```dart
  /// form.TextField.postalCode(
  ///   id: 'zip',
  ///   title: 'ZIP Code',
  /// )
  /// ```
  TextField.postalCode({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType ?? flutter.TextInputType.number,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.postalCode],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  /// Creates a country input field with autofill hints.
  ///
  /// Configures:
  /// - `autofillHints`: [AutofillHints.countryName]
  ///
  /// Example:
  /// ```dart
  /// form.TextField.country(
  ///   id: 'country',
  ///   title: 'Country',
  /// )
  /// ```
  TextField.country({
    required String id,
    flutter.Widget Function(FieldBuilderContext)? fieldBuilder,
    int? maxLines,
    AutoCompleteBuilder? autoComplete,
    String? textFieldTitle,
    String hintText = "",
    flutter.Widget? icon,
    flutter.Widget? leading,
    flutter.Widget? trailing,
    FormTheme? theme,
    String? title,
    String? description,
    int? maxLength,
    bool disabled = false,
    bool hideField = false,
    bool requestFocus = false,
    String? defaultValue,
    flutter.TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Iterable<String>? autofillHints,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onDrop,
    bool draggable = true,
    Future<void> Function({
      flutter.TextEditingController controller,
      required String formId,
      required String fieldId,
    })? onPaste,
  }) : this(
          id: id,
          fieldBuilder: fieldBuilder,
          maxLines: maxLines,
          autoComplete: autoComplete,
          textFieldTitle: textFieldTitle,
          hintText: hintText,
          icon: icon,
          leading: leading,
          trailing: trailing,
          theme: theme,
          title: title,
          description: description,
          maxLength: maxLength,
          disabled: disabled,
          hideField: hideField,
          requestFocus: requestFocus,
          password: false,
          defaultValue: defaultValue,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints:
              autofillHints ?? const [flutter.AutofillHints.countryName],
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
          onDrop: onDrop,
          draggable: draggable,
          onPaste: onPaste,
        );

  // --- Implementation of Field<String> Converters ---

  /// Converts the String value to a String (identity function).
  @override
  String Function(dynamic value) get asStringConverter => (dynamic value) {
        if (value is String) {
          return value;
        } else if (value == null && defaultValue != null) {
          return defaultValue!;
        } else if (value == null) {
          return ""; // Or throw, depending on desired behavior for null non-defaulted
        }
        throw TypeError(); // Will be caught by FieldResultAccessor
      };

  /// Converts the String value into a List containing that single String.
  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (dynamic value) {
        if (value is String) {
          return [value];
        } else if (value == null && defaultValue != null) {
          return [defaultValue!];
        } else if (value == null) {
          return [];
        }
        throw TypeError();
      };

  /// Converts the String value to bool (true if not empty, false otherwise).
  @override
  bool Function(dynamic value) get asBoolConverter => (dynamic value) {
        if (value is String) {
          return value.isNotEmpty;
        } else if (value == null && defaultValue != null) {
          return defaultValue!.isNotEmpty;
        } else if (value == null) {
          return false;
        }
        throw TypeError();
      };

  /// Text fields do not represent files. Returns null.
  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter => null;
}
