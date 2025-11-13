import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_converters.dart';
import 'package:flutter/widgets.dart';

/// Data class that stores metadata for a registered compound field type.
///
/// This class holds all the information needed to process and render a
/// compound field, including:
/// - The sub-field builder function
/// - Optional custom layout builder
/// - Error rollup settings
/// - Optional custom field converters
///
/// Instances of this class are created during field registration via
/// [FormFieldRegistry.registerCompound] and stored in the registry for
/// later lookup when building forms.
///
/// See also:
/// - [FormFieldRegistry.registerCompound] for registration
/// - [CompoundField] for the base compound field class
class CompoundFieldRegistration {
  /// Unique identifier for this compound field type (for debugging).
  final String typeName;

  /// Function that builds the list of sub-fields for a compound field.
  ///
  /// This function receives the compound field instance and returns a list
  /// of Field instances that define the sub-fields.
  ///
  /// Example:
  /// ```dart
  /// (AddressField field) => [
  ///   TextField(id: 'street', title: 'Street'),
  ///   TextField(id: 'city', title: 'City'),
  ///   TextField(id: 'zip', title: 'ZIP'),
  /// ]
  /// ```
  final List<Field> Function(CompoundField) subFieldsBuilder;

  /// Optional custom layout builder for rendering the compound field.
  ///
  /// If provided, this function receives the built sub-field widgets and
  /// optional errors, and returns a widget that layouts the sub-fields.
  ///
  /// If null, the default vertical layout (Column) will be used.
  ///
  /// **Parameters:**
  /// - [context]: Build context
  /// - [subFields]: List of built sub-field widgets
  /// - [errors]: Optional list of validation errors (if rollUpErrors is true)
  ///
  /// Example:
  /// ```dart
  /// (context, subFields, errors) => Row(
  ///   children: subFields.map((f) => Expanded(child: f)).toList(),
  /// )
  /// ```
  final Widget Function(
    BuildContext context,
    List<Widget> subFields,
    List<FormBuilderError>? errors,
  )? layoutBuilder;

  /// If true, validation errors from all sub-fields will be collected
  /// and passed to the layout builder for consolidated display.
  ///
  /// If false (default), errors display inline with each sub-field.
  final bool rollUpErrors;

  /// Optional custom converters for value conversion.
  ///
  /// If provided, these converters will be used for converting field values
  /// to different types (String, List<String>, bool, etc.).
  ///
  /// If null, default converters will be used.
  final FieldConverters? converters;

  CompoundFieldRegistration({
    required this.typeName,
    required this.subFieldsBuilder,
    this.layoutBuilder,
    this.rollUpErrors = false,
    this.converters,
  });
}
