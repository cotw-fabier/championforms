import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';

/// Built-in compound field for collecting name information.
///
/// The [NameField] is a convenience compound field that creates sub-fields
/// for first name, last name, and optionally middle name. It provides a
/// consistent, reusable way to collect name information across your forms.
///
/// ## Sub-fields
///
/// The NameField generates the following sub-fields with automatic ID prefixing:
/// - `{id}_firstname`: First name text field
/// - `{id}_middlename`: Middle name text field (optional, based on [includeMiddleName])
/// - `{id}_lastname`: Last name text field
///
/// ## Default Layout
///
/// The default layout arranges sub-fields horizontally in a Row with:
/// - First name: flex 1
/// - Middle name: flex 1 (if included)
/// - Last name: flex 2
/// - 10px spacing between fields
///
/// ## Usage
///
/// ```dart
/// import 'package:championforms/championforms.dart' as form;
///
/// form.Form(
///   controller: controller,
///   fields: [
///     form.NameField(
///       id: 'customer_name',
///       title: 'Customer Name',
///       includeMiddleName: true,
///     ),
///   ],
/// )
/// ```
///
/// ## Accessing Values
///
/// ```dart
/// // Get full name as combined string
/// final fullName = results.grab("customer_name").asCompound(delimiter: " ");
///
/// // Get individual sub-field values
/// final firstName = results.grab("customer_name_firstname").asString();
/// final middleName = results.grab("customer_name_middlename").asString();
/// final lastName = results.grab("customer_name_lastname").asString();
/// ```
///
/// See also:
/// - [CompoundField] for the base compound field class
/// - [AddressField] for another built-in compound field example
class NameField extends CompoundField {
  /// Whether to include a middle name field.
  ///
  /// If true (default), the NameField will generate three sub-fields:
  /// firstname, middlename, and lastname.
  ///
  /// If false, only firstname and lastname will be generated.
  final bool includeMiddleName;

  /// Creates a NameField compound field.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for this field (required)
  /// - [includeMiddleName]: Whether to include middle name field (default: true)
  /// - [title]: Title/label for the field group
  /// - [description]: Optional description text
  /// - [disabled]: Whether all sub-fields should be disabled (default: false)
  /// - [hideField]: Whether to hide the entire field group (default: false)
  /// - [rollUpErrors]: Whether to roll up validation errors (default: false)
  /// - [theme]: Custom theme for all sub-fields
  /// - [validators]: List of validators to apply
  /// - [validateLive]: Whether to validate on blur (default: false)
  /// - [onSubmit]: Callback when form is submitted
  /// - [onChange]: Callback when any sub-field value changes
  NameField({
    required String id,
    this.includeMiddleName = true,
    String? title,
    String? description,
    bool disabled = false,
    bool hideField = false,
    bool rollUpErrors = false,
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
          rollUpErrors: rollUpErrors,
          theme: theme,
          validators: validators,
          validateLive: validateLive,
          onSubmit: onSubmit,
          onChange: onChange,
        );

  @override
  List<Field> buildSubFields() {
    final fields = <Field>[
      TextField(
        id: 'firstname',
        title: 'First Name',
        hintText: 'First',
      ),
      TextField(
        id: 'lastname',
        title: 'Last Name',
        hintText: 'Last',
      ),
    ];

    // Insert middle name field between first and last if enabled
    if (includeMiddleName) {
      fields.insert(
        1,
        TextField(
          id: 'middlename',
          title: 'Middle Name',
          hintText: 'Middle',
        ),
      );
    }

    return fields;
  }
}
