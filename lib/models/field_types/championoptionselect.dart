import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/field_builders/dropdownfield_builder.dart';
import 'package:flutter/widgets.dart';

class ChampionOptionSelect extends FormFieldDef<List<MultiselectOption>> {
  // Define the type of field type
  //

  final Widget? leading;
  final Widget? trailing;

  // Options
  final List<MultiselectOption> options;

  // Multiselect?
  final bool multiselect;

  // These are the default values for the field. Use the specific one you need depending on the input required.
  final List<MultiselectOption> defaultValue;

  // match default value case sensitive?
  final bool caseSensitiveDefaultValue;

  // Add a builder for defining the field style
  Widget Function(
    BuildContext context,
    ChampionFormController controller,
    ChampionOptionSelect field,
    FieldColorScheme currentColors,
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

  // --- Implementation of FormFieldDef<List<MultiselectOption>> ---

  // @override
  // List<MultiselectOption> get defaultValue => _defaultValue; // Implement getter

  /// Converts the list of selected options to a comma-separated string of their values.
  @override
  String Function(dynamic value) get asStringConverter => (dynamic value) {
        List<MultiselectOption> effectiveValue;
        if (value is List<MultiselectOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.map((opt) => opt.value).join(', ');
      };

  /// Converts the list of selected options to a list of their string values.
  @override
  List<String> Function(dynamic value) get asStringListConverter =>
      (dynamic value) {
        List<MultiselectOption> effectiveValue;
        if (value is List<MultiselectOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.map((opt) => opt.value).toList();
      };

  /// Returns true if at least one option is selected.
  @override
  bool Function(dynamic value) get asBoolConverter => (dynamic value) {
        List<MultiselectOption> effectiveValue;
        if (value is List<MultiselectOption>) {
          effectiveValue = value;
        } else if (value == null) {
          effectiveValue = defaultValue;
        } else {
          throw TypeError();
        }
        return effectiveValue.isNotEmpty;
      };

  /// Base ChampionOptionSelect does not handle files. Returns null.
  /// Subclasses like ChampionFileUpload should override this.
  @override
  List<FileModel>? Function(dynamic value)? get asFileListConverter =>
      (dynamic value) {
        // This specific field type doesn't produce files directly from its primary value T.
        // Subclasses must override if they store FileModel in T or handle it differently.
        // If `value` were `List<MultiselectOption>` and additionalData held files,
        // the logic would go here, but ChampionFileUpload overrides this.
        if (value is List<MultiselectOption> || value == null) {
          // It's the correct primary type (or null), but this base class doesn't convert it to files.
          return null;
        }
        // If value is not List<MultiselectOption> and not null, it's an unexpected type.
        throw TypeError();
      };
}
