import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_colors.dart';
import 'package:championforms/models/field_condition.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/widgets_external/field_backgrounds/simplewrapper.dart';
import 'package:championforms/widgets_external/field_layouts/simple_layout.dart';
import 'package:flutter/widgets.dart';

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

abstract class Field implements FieldBase {
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

  /// Whether this field is rendered read-only.
  ///
  /// A disabled field is **still part of the form**: it is drawn, its value is
  /// collected into `FormResults.results`, and it round-trips through
  /// `grab()`. It is simply not editable, and its validators do not run — a
  /// rule the person has no way to act on must not block their submission.
  ///
  /// This is *not* HTML's `disabled`, which drops the input from the
  /// submission. The common case here is a value the form shows but owns
  /// elsewhere — an account email, a plan tier, a record id — and that value
  /// has to survive the round trip. To leave a field out of the results
  /// entirely, use [hideField] or [conditional].
  final bool disabled;

  final FormTheme? theme;

  /// Emphasis/role for this field's color palette, independent of its runtime
  /// state. Defaults to [FieldColors.normal]. Set to [FieldColors.destructive]
  /// to render the field in the error palette while it is empty and unfocused.
  final FieldColors colors;

  /// Whether this field plays the validation "wiggle" animation on a
  /// validation failure.
  ///
  /// Nullable: `null` (the default) means fall through to
  /// `FormFieldDefaults.instance.animateValidationErrors`. Set `true`/`false`
  /// to explicitly override the app-wide default for this field.
  final bool? animateValidationErrors;

  /// Whether to leave this field out of the form entirely.
  ///
  /// A hidden field is not drawn, not collected, and not validated — it is
  /// absent from `results` and `fieldDefinitions` both. The form is not asking
  /// the question, so there is no answer to report and no rule to enforce; a
  /// required field behind a false condition must never block a submission the
  /// person was never given the chance to satisfy.
  ///
  /// The field stays registered with the controller
  /// (`FormController.registeredFields`) and keeps its value, so unhiding it
  /// restores the answer. Together with [conditional] this is the only
  /// mechanism for "not part of this submission" — see [disabled] for the
  /// shown-but-locked case.
  final bool hideField;

  /// Serializable show/hide logic evaluated against the form's live values.
  ///
  /// [hideField] is a decision made once, when the field is constructed. This
  /// is a decision remade on every change, and — unlike a callback — it is
  /// *data*, so it survives being written to a database row, diffed between two
  /// versions of a form, and edited in a visual builder.
  ///
  /// A field this hides is not rendered **and is not validated**, exactly as
  /// [hideField] already behaves: a required field behind a false condition
  /// must never block a submission the person was never given a chance to
  /// satisfy. `FormController.isFieldHidden` is where the two are combined, and
  /// is what both the builder and `FormResults` consult.
  ///
  /// ```dart
  /// TextField(
  ///   id: 'team_size',
  ///   conditional: const FieldCondition(rules: [
  ///     ConditionRule(
  ///       fieldId: 'role',
  ///       operator: ConditionOperator.equals,
  ///       value: 'team',
  ///     ),
  ///   ]),
  /// )
  /// ```
  ///
  /// Note for custom field authors: `copyWith` on the built-in field types
  /// carries this across, but the abstract `copyWith` signature deliberately
  /// does not declare it — adding a parameter there would break every existing
  /// override. A custom field that wants `conditional` to survive a copy should
  /// add an optional `FieldCondition? conditional` parameter to its own
  /// `copyWith` and forward it.
  final FieldCondition? conditional;

  // This field will ask for focus. Best to only have one per form.
  final bool requestFocus;

  final List<Validator>? validators;
  final bool validateLive;

  // Functions
  // THis can be called on compatible fields. When you press enter or trigger a field submit it will trigger this function.
  final Function(FormResults results)? onSubmit;

  // This can be called on compatible fields. When the field changes, this function is run.
  final Function(FormResults results)? onChange;

  final Widget Function(
    BuildContext context,
    Field fieldDetails,
    FormController controller,
    FieldColorScheme currentColors,
    Widget renderedField,
  ) fieldLayout; // This is a wrapper around the entire field which adds things like title and description. You can override this with anything you want.
  final Widget Function(
    BuildContext context,
    Field fieldDetails,
    FormController controller,
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

  /// Creates a copy of this field with the given fields replaced with new values.
  ///
  /// This method must be implemented by all Field subclasses to support
  /// proper field copying, especially for compound fields where sub-fields
  /// need to have their IDs prefixed while preserving all other properties.
  ///
  /// Each subclass should accept nullable parameters for all its properties
  /// and return a new instance with updated values.
  ///
  /// Example implementation:
  /// ```dart
  /// @override
  /// TextField copyWith({
  ///   String? id,
  ///   String? title,
  ///   bool? disabled,
  ///   String? hintText,
  ///   // ... all other properties
  /// }) {
  ///   return TextField(
  ///     id: id ?? this.id,
  ///     title: title ?? this.title,
  ///     disabled: disabled ?? this.disabled,
  ///     hintText: hintText ?? this.hintText,
  ///     // ... all other properties
  ///   );
  /// }
  /// ```
  ///
  /// NOTE: `colors` and `animateValidationErrors` are intentionally NOT declared
  /// on this abstract signature. Base-library fields add them to their own
  /// concrete `copyWith` overrides (a valid override may add extra optional named
  /// parameters), but keeping them off the abstract keeps existing external
  /// custom-field `copyWith` overrides valid — adding them here would force every
  /// custom subclass to declare the new parameters, which would be a breaking
  /// change. See CLAUDE.md "Field emphasis colors".
  Field copyWith({
    String? id,
    Widget? icon,
    FormTheme? theme,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? requestFocus,
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
  });

  Field({
    required this.id,
    this.icon,
    this.theme,
    this.colors = FieldColors.normal,
    this.animateValidationErrors,
    this.title,
    this.description,
    this.disabled = false,
    this.hideField = false,
    this.conditional,
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
