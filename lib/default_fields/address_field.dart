import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/validatorclass.dart';

/// Built-in compound field for collecting address information.
///
/// The [AddressField] is a convenience compound field that creates sub-fields
/// for street address, city, state, ZIP code, and optionally street 2 (apt/suite)
/// and country. It provides a consistent, reusable way to collect address
/// information across your forms.
///
/// ## Sub-fields
///
/// The AddressField generates the following sub-fields with automatic ID prefixing:
/// - `{id}_street`: Street address text field
/// - `{id}_street2`: Apartment/suite text field (optional, based on [includeStreet2])
/// - `{id}_city`: City text field
/// - `{id}_state`: State text field
/// - `{id}_zip`: ZIP code text field
/// - `{id}_country`: Country text field (optional, based on [includeCountry])
///
/// ## Default Layout
///
/// The default layout arranges sub-fields in a multi-row vertical layout:
/// - Row 1: Street (full width)
/// - Row 2: Street 2 (full width, if [includeStreet2] is true)
/// - Row 3: City (flex: 4), State (flex: 3), ZIP (flex: 3) in horizontal Row
/// - Row 4: Country (full width, if [includeCountry] is true)
/// - 10px vertical spacing between rows
///
/// ## Usage
///
/// ```dart
/// import 'package:championforms/championforms.dart' as form;
///
/// form.Form(
///   controller: controller,
///   fields: [
///     form.AddressField(
///       id: 'billing_address',
///       title: 'Billing Address',
///       includeStreet2: true,
///       includeCountry: false,
///     ),
///   ],
/// )
/// ```
///
/// ## Accessing Values
///
/// ```dart
/// // Get full address as combined string
/// final fullAddress = results.grab("billing_address").asCompound(delimiter: ", ");
///
/// // Get individual sub-field values
/// final street = results.grab("billing_address_street").asString();
/// final city = results.grab("billing_address_city").asString();
/// final state = results.grab("billing_address_state").asString();
/// final zip = results.grab("billing_address_zip").asString();
/// ```
///
/// See also:
/// - [CompoundField] for the base compound field class
/// - [NameField] for another built-in compound field example
class AddressField extends CompoundField {
  /// Whether to include a second street address line (apartment/suite).
  ///
  /// If true (default), the AddressField will include a street2 sub-field
  /// for apartment, suite, or other secondary address information.
  final bool includeStreet2;

  /// Whether to include a country field.
  ///
  /// If true, the AddressField will include a country sub-field at the end.
  /// Default is false (no country field).
  final bool includeCountry;

  /// Creates an AddressField compound field.
  ///
  /// **Parameters:**
  /// - [id]: Unique identifier for this field (required)
  /// - [includeStreet2]: Whether to include apartment/suite field (default: true)
  /// - [includeCountry]: Whether to include country field (default: false)
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
  AddressField({
    required String id,
    this.includeStreet2 = true,
    this.includeCountry = false,
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
        id: 'street',
        title: 'Street Address',
        hintText: '123 Main St',
      ),
    ];

    // Add street2 field if enabled
    if (includeStreet2) {
      fields.add(
        TextField(
          id: 'street2',
          title: 'Apartment, suite, etc.',
          hintText: 'Apt 4B',
        ),
      );
    }

    // Add city, state, zip
    fields.addAll([
      TextField(
        id: 'city',
        title: 'City',
        hintText: 'City',
      ),
      TextField(
        id: 'state',
        title: 'State',
        hintText: 'State',
      ),
      TextField(
        id: 'zip',
        title: 'ZIP Code',
        hintText: '12345',
      ),
    ]);

    // Add country field if enabled
    if (includeCountry) {
      fields.add(
        TextField(
          id: 'country',
          title: 'Country',
          hintText: 'Country',
        ),
      );
    }

    return fields;
  }
}
