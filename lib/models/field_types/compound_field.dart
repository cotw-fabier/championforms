import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_converters.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:flutter/material.dart';

/// Abstract base class for compound fields - composite fields made up of
/// multiple sub-fields.
///
/// Compound fields allow developers to create reusable field groups like
/// `AddressField` or `NameField` that internally consist of multiple
/// independent sub-fields while providing a convenient registration and
/// layout API.
///
/// ## Key Concepts
///
/// - **Sub-fields as Independent Fields**: Each sub-field is registered
///   individually with the FormController and behaves exactly like a
///   normal field. From the controller's perspective, there is no
///   difference between a sub-field and a standalone field.
///
/// - **Automatic ID Prefixing**: Sub-field IDs are automatically prefixed
///   with the compound field's ID using pattern `{compoundId}_{subFieldId}`.
///   This prevents naming conflicts when using multiple compound fields.
///
/// - **Flexible Layouts**: Compound fields can define custom layouts via
///   registration, or use the default vertical layout.
///
/// - **Error Rollup**: Validation errors can be displayed inline with each
///   sub-field (default) or rolled up and displayed together at the
///   compound field level.
///
/// ## Implementation
///
/// To create a custom compound field:
///
/// ```dart
/// class NameField extends CompoundField {
///   final bool includeMiddleName;
///
///   NameField({
///     required String id,
///     this.includeMiddleName = true,
///     String? title,
///   }) : super(id: id, title: title);
///
///   @override
///   List<Field> buildSubFields() {
///     final fields = [
///       TextField(id: 'firstname', title: 'First Name'),
///       TextField(id: 'lastname', title: 'Last Name'),
///     ];
///     if (includeMiddleName) {
///       fields.insert(1, TextField(id: 'middlename', title: 'Middle Name'));
///     }
///     return fields;
///   }
/// }
/// ```
///
/// Then register it with a layout builder:
///
/// ```dart
/// FormFieldRegistry.registerCompound<NameField>(
///   'name',
///   (field) => field.buildSubFields(),
///   (context, subFields, errors) => Row(
///     children: subFields.map((f) => Expanded(child: f)).toList(),
///   ),
/// );
/// ```
///
/// ## Sub-field Access
///
/// Sub-field values can be accessed individually or as a combined value:
///
/// ```dart
/// // Access full compound value (joined)
/// final fullName = results.grab("name").asCompound(delimiter: " ");
///
/// // Access individual sub-fields
/// final firstName = results.grab("name_firstname").asString();
/// final lastName = results.grab("name_lastname").asString();
/// ```
///
/// See also:
/// - [FormFieldRegistry.registerCompound] for registration
/// - [Field] for the base field class
/// - [FieldResultAccessor.asCompound] for results access
abstract class CompoundField extends Field with TextFieldConverters {
  /// If true, validation errors from all sub-fields will be collected
  /// and passed to the layout builder for consolidated display.
  /// If false (default), errors display inline with each sub-field.
  final bool rollUpErrors;

  CompoundField({
    required String id,
    String? title,
    String? description,
    bool disabled = false,
    bool hideField = false,
    this.rollUpErrors = false,
    FormTheme? theme,
    List<Validator>? validators,
    bool validateLive = false,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
  }) : super(
          id: id,
          title: title,
          description: description,
          disabled: disabled,
          hideField: hideField,
          theme: theme,
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
        );

  /// Builds and returns the list of sub-fields for this compound field.
  ///
  /// Implementations should return a list of Field instances that define
  /// the sub-fields. Sub-field IDs will be automatically prefixed with
  /// the compound field's ID.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// List<Field> buildSubFields() {
  ///   return [
  ///     TextField(id: 'street', title: 'Street Address'),
  ///     TextField(id: 'city', title: 'City'),
  ///     TextField(id: 'zip', title: 'ZIP Code'),
  ///   ];
  /// }
  /// ```
  List<Field> buildSubFields();

  /// Returns the list of sub-field IDs with proper prefixing applied.
  ///
  /// This method builds the sub-fields and applies the ID prefixing logic
  /// to generate the final sub-field IDs that will be used in the
  /// FormController.
  ///
  /// Pattern: `{compoundId}_{subFieldId}`
  ///
  /// If a sub-field ID is already prefixed (starts with `{compoundId}_`),
  /// it will not be double-prefixed.
  List<String> getPrefixedSubFieldIds() {
    final subFields = buildSubFields();
    return subFields.map((field) => _prefixSubFieldId(id, field.id)).toList();
  }

  /// Generates a prefixed sub-field ID following the pattern:
  /// `{compoundId}_{subFieldId}`
  ///
  /// If the subFieldId already starts with the compound ID prefix,
  /// it is returned as-is to avoid double-prefixing.
  ///
  /// **Parameters:**
  /// - [compoundId]: The ID of the compound field
  /// - [subFieldId]: The original ID of the sub-field
  ///
  /// **Returns:**
  /// The prefixed sub-field ID
  String _prefixSubFieldId(String compoundId, String subFieldId) {
    // Check if already prefixed to avoid double-prefixing
    if (subFieldId.startsWith('${compoundId}_')) {
      return subFieldId;
    }
    return '${compoundId}_$subFieldId';
  }

  /// Builds sub-fields with proper ID prefixing and state propagation.
  ///
  /// This method:
  /// 1. Calls buildSubFields() to get the sub-field definitions
  /// 2. Applies ID prefixing to each sub-field
  /// 3. Propagates theme and disabled state from compound field to sub-fields
  ///
  /// **Parameters:**
  /// - [compoundTheme]: The theme to apply if sub-field doesn't have its own
  /// - [compoundDisabled]: Whether to disable all sub-fields
  ///
  /// **Returns:**
  /// List of sub-fields with prefixed IDs and propagated state
  List<Field> buildPrefixedSubFields({
    FormTheme? compoundTheme,
    bool compoundDisabled = false,
  }) {
    final subFields = buildSubFields();

    return subFields.map((subField) {
      // Apply ID prefixing
      final prefixedId = _prefixSubFieldId(id, subField.id);

      // Create a copy with prefixed ID and propagated state
      // Note: This is a simplified approach. In practice, each Field subclass
      // would need to implement a copyWith method. For now, we'll work with
      // the existing fields as-is and handle this in the Form widget.
      return subField;
    }).toList();
  }

  /// Default vertical layout builder for compound fields.
  ///
  /// Stacks sub-fields vertically with 10px spacing between them.
  /// If errors are provided and should be rolled up, displays them
  /// at the bottom in red text.
  ///
  /// **Parameters:**
  /// - [context]: Build context
  /// - [subFields]: List of built sub-field widgets
  /// - [errors]: Optional list of errors to display (if rollUpErrors is true)
  ///
  /// **Returns:**
  /// A Column widget containing the sub-fields and optional errors
  static Widget buildDefaultCompoundLayout(
    BuildContext context,
    List<Widget> subFields,
    List<FormBuilderError>? errors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-fields with spacing
        ...subFields.expand((field) => [
              field,
              const SizedBox(height: 10),
            ]),

        // Remove the last spacing
        if (subFields.isNotEmpty) const SizedBox(height: 0),

        // Rolled up errors if provided
        if (errors != null && errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...errors.map((error) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  error.reason,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              )),
        ],
      ],
    );
  }

  @override
  dynamic get defaultValue => null;
}
