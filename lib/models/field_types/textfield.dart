import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/core/field_json.dart';
import 'package:championforms/models/field_condition.dart';
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

  /// Whether native spellcheck (passive red squiggly underlines on
  /// misspellings, tap-to-correct via long-press) is enabled on iOS/Android.
  ///
  /// `null` (default) falls through to [FormFieldDefaults.instance.spellCheck]
  /// (package default: `true`). Set explicitly to `false` to disable for
  /// this field only. Ignored if [spellCheckConfiguration] is explicitly
  /// provided.
  final bool? spellCheck;

  /// Whether native autocorrect (active text rewriting as you type) is
  /// enabled on iOS/Android.
  ///
  /// Independent from [spellCheck] — you can have one on without the
  /// other. `null` (default) falls through to
  /// [FormFieldDefaults.instance.autocorrect] (package default: `true`).
  /// Set explicitly to `false` for fields where autocorrect would be
  /// wrong (codes, URLs, structured input).
  final bool? autocorrect;

  /// Advanced escape hatch: custom spellcheck configuration passed
  /// directly to the underlying Material TextField. When non-null,
  /// overrides the [spellCheck] flag's effect on the spellcheck-underline
  /// behavior. Most consumers should use [spellCheck] alone.
  final flutter.SpellCheckConfiguration? spellCheckConfiguration;

  /// Whether the field plays a gentle lift-and-scale micro-interaction
  /// when it gains focus (roughly a 1px upward translation and a 0.8%
  /// scale-up, reversed on blur).
  ///
  /// `null` (default) falls through to
  /// [FormFieldDefaults.instance.animateInteractions] (package default:
  /// `true`). Set explicitly to `false` to disable for this field only —
  /// useful for fields embedded in already-animated layouts where any
  /// extra motion would compete for attention.
  final bool? animateInteractions;

  /// How the on-screen keyboard auto-capitalizes typed text on mobile
  /// (sentences, words, characters, or none).
  ///
  /// `null` (default) falls through to
  /// [FormFieldDefaults.instance.textCapitalization] (package default:
  /// [TextCapitalization.sentences], matching native iOS/Android fields).
  /// Set explicitly for fields where a different rule applies — e.g.
  /// [TextCapitalization.none] is forced by the email/url/username/password
  /// semantic constructors.
  final flutter.TextCapitalization? textCapitalization;

  /// The keyboard action button shown on mobile soft keyboards (e.g.
  /// [TextInputAction.send], [TextInputAction.done], [TextInputAction.go]).
  ///
  /// Direct passthrough to the underlying Material `TextField`.
  ///
  /// For multiline fields ([maxLines] != 1) the platform default is
  /// [TextInputAction.newline], which makes the soft-keyboard return key
  /// insert a line break with no way to submit. Set this to a submitting
  /// action (e.g. [TextInputAction.send]) to turn the return key into a
  /// submit button that fires [onSubmit] — note this replaces newline
  /// insertion on that key. To keep newline-via-Enter and still allow
  /// submission, leave this `null` and enable [submitOnControlEnter] for
  /// Ctrl/Cmd+Enter submission instead.
  final TextInputAction? textInputAction;

  /// Whether pressing Ctrl+Enter (or Cmd+Enter on macOS) submits the field,
  /// firing [onSubmit].
  ///
  /// Primarily useful for multiline fields ([maxLines] != 1) where plain
  /// Enter inserts a newline and there is otherwise no meaningful way to
  /// submit from a physical keyboard. Plain Enter still inserts a newline —
  /// only the Ctrl/Cmd modifier triggers submission. Works on desktop and any
  /// device with a hardware keyboard; soft-keyboard-only devices should use
  /// [textInputAction] instead.
  ///
  /// `null` (default) falls through to
  /// [FormFieldDefaults.instance.submitOnControlEnter] (package default:
  /// `false`). Has no effect unless [onSubmit] is also provided.
  final bool? submitOnControlEnter;

  /// Whether plain Enter submits the field (firing [onSubmit]) while
  /// Shift+Enter inserts a newline — the inverse of the default multiline
  /// behavior, matching the common "chat input" pattern.
  ///
  /// Only affects multiline fields ([maxLines] `null` or `> 1`); single-line
  /// fields already submit on Enter via [onSubmit]. When enabled, plain Enter
  /// is intercepted (no newline is inserted) and Shift+Enter inserts a line
  /// break instead.
  ///
  /// This is a hardware-keyboard behavior — it works on desktop and web (and
  /// devices with a physical keyboard). It does **not** affect mobile soft
  /// keyboards, where the return key sends a newline action directly; use
  /// [textInputAction] to control the soft-keyboard submit button there.
  ///
  /// `null` (default) falls through to
  /// [FormFieldDefaults.instance.submitOnEnter] (package default: `false`).
  /// Has no effect unless [onSubmit] is also provided.
  final bool? submitOnEnter;

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
    super.conditional,
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
    this.spellCheck,
    this.autocorrect,
    this.spellCheckConfiguration,
    this.animateInteractions,
    this.textCapitalization,
    this.textInputAction,
    this.submitOnControlEnter,
    this.submitOnEnter,
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
    FieldCondition? conditional,
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
    bool? spellCheck,
    bool? autocorrect,
    flutter.SpellCheckConfiguration? spellCheckConfiguration,
    bool? animateInteractions,
    flutter.TextCapitalization? textCapitalization,
    TextInputAction? textInputAction,
    bool? submitOnControlEnter,
    bool? submitOnEnter,
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
      conditional: conditional ?? this.conditional,
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
      spellCheck: spellCheck ?? this.spellCheck,
      autocorrect: autocorrect ?? this.autocorrect,
      spellCheckConfiguration:
          spellCheckConfiguration ?? this.spellCheckConfiguration,
      animateInteractions: animateInteractions ?? this.animateInteractions,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      textInputAction: textInputAction ?? this.textInputAction,
      submitOnControlEnter: submitOnControlEnter ?? this.submitOnControlEnter,
      submitOnEnter: submitOnEnter ?? this.submitOnEnter,
      fieldLayout: fieldLayout ?? this.fieldLayout,
      fieldBackground: fieldBackground ?? this.fieldBackground,
    );
  }

  /// Builds a [TextField] from its JSON map.
  ///
  /// Registered for the type names `textField`, `text`, `textarea`, `email`,
  /// `password`, `tel`, `url` and `number` — **one Dart class, several logical
  /// types**, because what separates them is a keyboard, an autofill hint and
  /// an obscure flag rather than a different widget. Reading `type` here is
  /// what lets a document say `"type": "email"` and get the email keyboard and
  /// autofill hint without also having to spell out `keyboardType` and
  /// `autofillHints`, which it has no vocabulary for.
  ///
  /// Recognised keys, all optional except `id`: `title`, `description`,
  /// `hintText`, `textFieldTitle`, `maxLines`, `maxLength`, `password`,
  /// `disabled`, `hideField`, `requestFocus`, `validateLive`, `defaultValue`,
  /// `validators`, `conditional`.
  ///
  /// Unrecognised keys are ignored rather than rejected. A document may have
  /// been written by a newer build, and a field that fails to *decode* takes
  /// the whole form down, where a field that ignores one key it does not
  /// understand does not.
  factory TextField.fromJson(Map<String, dynamic> json) {
    final type = FieldJson.type(json);
    final id = FieldJson.id(json);
    final title = FieldJson.string(json, 'title');
    final description = FieldJson.string(json, 'description');
    final defaultValue = FieldJson.defaultText(json);
    final validators = FieldJson.validators(json);
    final conditional = FieldJson.conditional(json);
    final disabled = FieldJson.boolean(json, 'disabled');
    final hideField = FieldJson.boolean(json, 'hideField');
    final requestFocus = FieldJson.boolean(json, 'requestFocus');
    final validateLive = FieldJson.boolean(json, 'validateLive');
    final maxLength = FieldJson.integer(json, 'maxLength');
    final hintText = FieldJson.string(json, 'hintText') ?? '';

    // A textarea's height is a property of the type, not something every
    // document has to remember to set; an explicit `maxLines` still wins.
    final maxLines =
        FieldJson.integer(json, 'maxLines') ?? (type == 'textarea' ? 5 : 1);

    switch (type) {
      case 'email':
        return TextField.email(
          id: id,
          title: title,
          description: description,
          defaultValue: defaultValue,
          validators: validators,
          validateLive: validateLive,
          disabled: disabled,
          hideField: hideField,
          conditional: conditional,
          requestFocus: requestFocus,
          maxLength: maxLength,
        );
      case 'password':
        return TextField.password(
          id: id,
          title: title,
          description: description,
          defaultValue: defaultValue,
          validators: validators,
          validateLive: validateLive,
          disabled: disabled,
          hideField: hideField,
          conditional: conditional,
          requestFocus: requestFocus,
          maxLength: maxLength,
        );
      case 'tel':
        return TextField.phone(
          id: id,
          title: title,
          description: description,
          defaultValue: defaultValue,
          validators: validators,
          validateLive: validateLive,
          disabled: disabled,
          hideField: hideField,
          conditional: conditional,
          requestFocus: requestFocus,
          maxLength: maxLength,
        );
      case 'url':
        return TextField.url(
          id: id,
          title: title,
          description: description,
          defaultValue: defaultValue,
          validators: validators,
          validateLive: validateLive,
          disabled: disabled,
          hideField: hideField,
          conditional: conditional,
          requestFocus: requestFocus,
          maxLength: maxLength,
        );
      default:
        return TextField(
          id: id,
          title: title,
          description: description,
          textFieldTitle: FieldJson.string(json, 'textFieldTitle'),
          hintText: hintText,
          maxLines: maxLines,
          maxLength: maxLength,
          password: FieldJson.boolean(json, 'password'),
          defaultValue: defaultValue,
          validators: validators,
          validateLive: validateLive,
          disabled: disabled,
          hideField: hideField,
          conditional: conditional,
          requestFocus: requestFocus,
          keyboardType: type == 'number'
              ? const flutter.TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                )
              : null,
        );
    }
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.words,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.words,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.words,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.words,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.none,
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
    FieldCondition? conditional,
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
          conditional: conditional,
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
          spellCheck: false,
          autocorrect: false,
          textCapitalization: flutter.TextCapitalization.words,
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
