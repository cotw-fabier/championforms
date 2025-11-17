import 'package:championforms/championforms.dart';
import 'package:championforms/default_fields/checkboxselect.dart';
import 'package:championforms/default_fields/chipselect.dart';
import 'package:championforms/default_fields/fileupload.dart';
import 'package:championforms/default_fields/optionselect.dart';
import 'package:championforms/default_fields/textfield.dart';
import 'package:championforms/models/field_types/compound_field_registration.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';

// ===========================================================================
// LEGACY BUILDER SIGNATURE (For Backward Compatibility)
// ===========================================================================

/// Legacy builder function type with 6 parameters.
///
/// **Deprecated:** This signature is maintained for backward compatibility only.
/// New custom fields should use the simplified [FormFieldBuilder] signature
/// that accepts a single [FieldBuilderContext] parameter.
///
/// This typedef will be removed in a future version. Migrate to the new API:
/// ```dart
/// // Old API (deprecated)
/// Widget myBuilder(
///   BuildContext context,
///   FormController controller,
///   MyField field,
///   FieldState state,
///   FieldColorScheme colors,
///   Function(bool) updateFocus,
/// ) { ... }
///
/// // New API (recommended)
/// Widget myBuilder(FieldBuilderContext context) {
///   // Access all parameters via context
///   final field = context.field;
///   final controller = context.controller;
///   // ...
/// }
/// ```
///
/// See also:
/// - [FormFieldBuilder] for the new simplified signature
/// - [FieldBuilderContext] for bundled parameters
@Deprecated('Use FormFieldBuilder with FieldBuilderContext instead')
typedef LegacyFormFieldBuilder<T extends Field> = flutter.Widget Function(
  flutter.BuildContext context,
  FormController controller,
  T field,
  FieldState currentState,
  FieldColorScheme currentColors,
  Function(bool focused) updateFocus,
);

// ===========================================================================
// NEW UNIFIED BUILDER SIGNATURE (v0.6.0+)
// ===========================================================================

/// Unified builder function type for custom fields (v0.6.0+).
///
/// The simplified field builder signature accepts a single [FieldBuilderContext]
/// parameter that bundles all necessary dependencies. This dramatically reduces
/// boilerplate in custom field implementations.
///
/// ## Usage
///
/// **Custom Field Widget:**
/// ```dart
/// class MyCustomField extends StatelessWidget {
///   final FieldBuilderContext context;
///
///   const MyCustomField({required this.context});
///
///   @override
///   Widget build(BuildContext buildContext) {
///     return TextField(
///       controller: context.getTextController(),
///       focusNode: context.getFocusNode(),
///       decoration: InputDecoration(
///         labelText: context.field.title,
///       ),
///       onChanged: (value) => context.setValue(value),
///     );
///   }
/// }
/// ```
///
/// **Registration:**
/// ```dart
/// // Register globally
/// FormFieldRegistry.register<MyCustomFieldType>(
///   'myCustomField',
///   (context) => MyCustomField(context: context),
/// );
///
/// // Or use inline on a field
/// final field = MyCustomFieldType(
///   id: 'field_id',
///   fieldBuilder: (context) => MyCustomField(context: context),
/// );
/// ```
///
/// ## Context Properties
///
/// The [FieldBuilderContext] provides access to:
/// - `controller`: [FormController] instance
/// - `field`: Field definition (typed as specific field type)
/// - `theme`: Resolved [FormTheme]
/// - `state`: Current [FieldState]
/// - `colors`: Current [FieldColorScheme]
///
/// ## Context Methods
///
/// Convenience methods for common operations:
/// - `getValue<T>()`: Get field value
/// - `setValue<T>(T value)`: Update field value
/// - `addError(String reason)`: Add validation error
/// - `clearErrors()`: Clear field errors
/// - `hasFocus`: Check focus state
/// - `getTextController()`: Get/create TextEditingController
/// - `getFocusNode()`: Get/create FocusNode
///
/// ## Migration from Old API
///
/// ```dart
/// // OLD: 6-parameter signature
/// Widget builder(
///   BuildContext context,
///   FormController controller,
///   MyField field,
///   FieldState state,
///   FieldColorScheme colors,
///   Function(bool) updateFocus,
/// ) {
///   final textController = controller.getTextEditingController(field.id);
///   // ...
/// }
///
/// // NEW: Single context parameter
/// Widget builder(FieldBuilderContext context) {
///   final textController = context.getTextController();
///   // All other parameters available via context properties
/// }
/// ```
///
/// See also:
/// - [FieldBuilderContext] for detailed context API documentation
/// - [FormFieldRegistry.register] for field registration
/// - [StatefulFieldWidget] for stateful field base class
typedef FormFieldBuilder = flutter.Widget Function(
  FieldBuilderContext context,
);

// ===========================================================================
// FORM FIELD REGISTRY
// ===========================================================================

/// Central registry for custom field type builders.
///
/// The [FormFieldRegistry] provides a singleton registry where custom field
/// builders can be registered and looked up by field type. This enables the
/// [Form] widget to dynamically build the appropriate widget for each field.
///
/// ## New API (v0.6.0+): Static Methods
///
/// The simplified API provides static methods for registration:
///
/// ```dart
/// // Register a custom field type
/// FormFieldRegistry.register<RatingField>(
///   'rating',
///   (context) => RatingFieldWidget(context: context),
/// );
///
/// // Check if a builder is registered
/// if (FormFieldRegistry.hasBuilderFor<RatingField>()) {
///   // Builder exists
/// }
/// ```
///
/// ## Legacy API: Instance Methods
///
/// The original instance-based API is still supported for backward compatibility:
///
/// ```dart
/// // Register via instance (legacy)
/// FormFieldRegistry.instance.registerBuilder<TextField>(
///   (context, controller, field, state, colors, updateFocus) {
///     return TextFieldWidget(...);
///   },
/// );
/// ```
///
/// ## Custom Converters
///
/// You can optionally provide custom [FieldConverters] when registering a field:
///
/// ```dart
/// class RatingConverters with NumericFieldConverters {}
///
/// FormFieldRegistry.register<RatingField>(
///   'rating',
///   (context) => RatingFieldWidget(context: context),
///   converters: RatingConverters(),
/// );
/// ```
///
/// ## Built-in Fields
///
/// ChampionForms automatically registers builders for built-in field types:
/// - [TextField]
/// - [OptionSelect]
/// - [CheckboxSelect]
/// - [ChipSelect]
/// - [FileUpload]
///
/// These are registered via [registerCoreBuilders] when the package initializes.
///
/// ## Architecture
///
/// The registry uses a singleton pattern internally but exposes static methods
/// for a cleaner API. The [instance] accessor is maintained for backward
/// compatibility.
///
/// See also:
/// - [FormFieldBuilder] for the builder function signature
/// - [FieldBuilderContext] for the context parameter
/// - [FieldConverters] for value conversion
class FormFieldRegistry {
  // ===========================================================================
  // PRIVATE SINGLETON INSTANCE
  // ===========================================================================

  /// Private singleton instance.
  static final FormFieldRegistry _instance = FormFieldRegistry._internal();

  /// Private constructor for singleton pattern.
  FormFieldRegistry._internal();

  // ===========================================================================
  // PUBLIC PROPERTIES
  // ===========================================================================

  /// Whether the core builders have been initialized.
  ///
  /// Set to true when [registerCoreBuilders] is called.
  bool initialized = false;

  /// Public instance accessor for backward compatibility.
  ///
  /// **Deprecated:** Prefer using static methods [register] and [hasBuilderFor].
  ///
  /// ```dart
  /// // Old API (still works)
  /// FormFieldRegistry.instance.registerBuilder<MyField>(builder);
  ///
  /// // New API (recommended)
  /// FormFieldRegistry.register<MyField>('myField', builder);
  /// ```
  static FormFieldRegistry get instance => _instance;

  /// Returns whether core builders have been initialized.
  bool get isInitialized => initialized;

  // ===========================================================================
  // PRIVATE STORAGE
  // ===========================================================================

  /// Internal storage for builders indexed by field type.
  final Map<Type, Function> _builders = {};

  /// Internal storage for converters indexed by field type.
  final Map<Type, FieldConverters> _converters = {};

  /// Internal storage for compound field registrations indexed by field type.
  final Map<Type, CompoundFieldRegistration> _compoundRegistrations = {};

  // ===========================================================================
  // NEW STATIC API (v0.6.0+)
  // ===========================================================================

  /// Registers a builder function for a custom field type (static method).
  ///
  /// This is the recommended way to register custom fields in v0.6.0+.
  /// The builder receives a single [FieldBuilderContext] parameter containing
  /// all necessary dependencies.
  ///
  /// **Type Parameter:**
  /// - `T`: The field type to register (must extend [Field])
  ///
  /// **Parameters:**
  /// - [typeName]: A unique identifier for this field type (for debugging)
  /// - [builder]: The builder function (receives [FieldBuilderContext])
  /// - [converters]: Optional custom converters for value conversion
  ///
  /// **Example:**
  /// ```dart
  /// // Register a custom rating field
  /// FormFieldRegistry.register<RatingField>(
  ///   'rating',
  ///   (context) => RatingFieldWidget(context: context),
  /// );
  ///
  /// // Register with custom converters
  /// FormFieldRegistry.register<RatingField>(
  ///   'rating',
  ///   (context) => RatingFieldWidget(context: context),
  ///   converters: RatingFieldConverters(),
  /// );
  /// ```
  ///
  /// **Overwriting:**
  /// If a builder is already registered for type `T`, it will be overwritten
  /// with a debug warning.
  ///
  /// See also:
  /// - [hasBuilderFor] to check if a builder is registered
  /// - [FormFieldBuilder] for the builder signature
  /// - [FieldConverters] for custom converter implementation
  static void register<T extends Field>(
    String typeName,
    FormFieldBuilder builder, {
    FieldConverters? converters,
  }) {
    _instance._registerInternal<T>(typeName, builder, converters);
  }

  /// Checks if a builder is registered for a specific field type (static method).
  ///
  /// **Type Parameter:**
  /// - `T`: The field type to check (must extend [Field])
  ///
  /// **Returns:**
  /// `true` if a builder is registered for type `T`, `false` otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (FormFieldRegistry.hasBuilderFor<RatingField>()) {
  ///   print('Rating field builder is registered');
  /// } else {
  ///   print('No builder for rating field');
  /// }
  /// ```
  ///
  /// See also:
  /// - [register] to register a builder
  static bool hasBuilderFor<T extends Field>() {
    return _instance._builders.containsKey(T);
  }

  // ===========================================================================
  // COMPOUND FIELD API
  // ===========================================================================

  /// Registers a compound field type with sub-field builder and layout (static method).
  ///
  /// Compound fields are composite fields made up of multiple sub-fields that
  /// function as independent fields from the controller's perspective while
  /// providing a convenient registration and layout API.
  ///
  /// **Type Parameter:**
  /// - `T`: The compound field type to register (must extend [CompoundField])
  ///
  /// **Parameters:**
  /// - [typeName]: A unique identifier for this compound field type (for debugging)
  /// - [subFieldsBuilder]: Function that builds the list of sub-fields
  /// - [layoutBuilder]: Optional custom layout builder for rendering sub-fields
  /// - [rollUpErrors]: If true, errors from sub-fields are rolled up and displayed together
  /// - [converters]: Optional custom converters for value conversion
  ///
  /// **Example:**
  /// ```dart
  /// FormFieldRegistry.registerCompound<NameField>(
  ///   'name',
  ///   (field) => field.buildSubFields(),
  ///   (context, subFields, errors) => Row(
  ///     children: subFields.map((f) => Expanded(child: f)).toList(),
  ///   ),
  ///   rollUpErrors: false,
  /// );
  /// ```
  ///
  /// See also:
  /// - [CompoundField] for the base compound field class
  /// - [CompoundFieldRegistration] for registration metadata
  /// - [hasCompoundBuilderFor] to check if a compound builder is registered
  static void registerCompound<T extends CompoundField>(
    String typeName,
    List<Field> Function(T) subFieldsBuilder,
    flutter.Widget Function(
      flutter.BuildContext context,
      List<flutter.Widget> subFields,
      List<FormBuilderError>? errors,
    )? layoutBuilder, {
    bool rollUpErrors = false,
    FieldConverters? converters,
  }) {
    _instance._registerCompoundInternal<T>(
      typeName,
      subFieldsBuilder,
      layoutBuilder,
      rollUpErrors,
      converters,
    );
  }

  /// Checks if a compound builder is registered for a specific field type (static method).
  ///
  /// **Type Parameter:**
  /// - `T`: The compound field type to check (must extend [CompoundField])
  ///
  /// **Returns:**
  /// `true` if a compound builder is registered for type `T`, `false` otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (FormFieldRegistry.hasCompoundBuilderFor<NameField>()) {
  ///   print('Name field compound builder is registered');
  /// }
  /// ```
  ///
  /// See also:
  /// - [registerCompound] to register a compound field
  static bool hasCompoundBuilderFor<T extends CompoundField>() {
    return _instance._compoundRegistrations.containsKey(T);
  }

  // ===========================================================================
  // INTERNAL IMPLEMENTATION
  // ===========================================================================

  /// Internal implementation of builder registration.
  ///
  /// This method handles the actual registration logic for both the new
  /// static API and the legacy instance API.
  void _registerInternal<T extends Field>(
    String typeName,
    FormFieldBuilder builder,
    FieldConverters? converters,
  ) {
    if (_builders.containsKey(T)) {
      flutter.debugPrint('Warning: Overwriting builder for type $T');
    }
    _builders[T] = builder;
    if (converters != null) {
      _converters[T] = converters;
    }
    flutter.debugPrint('Registered builder for type $T ($typeName)');
  }

  /// Internal implementation of compound field registration.
  ///
  /// This method handles the actual registration logic for compound fields.
  void _registerCompoundInternal<T extends CompoundField>(
    String typeName,
    List<Field> Function(T) subFieldsBuilder,
    flutter.Widget Function(
      flutter.BuildContext context,
      List<flutter.Widget> subFields,
      List<FormBuilderError>? errors,
    )? layoutBuilder,
    bool rollUpErrors,
    FieldConverters? converters,
  ) {
    if (_compoundRegistrations.containsKey(T)) {
      flutter.debugPrint('Warning: Overwriting compound field for type $T');
    }

    // Create registration with properly typed builder
    final registration = CompoundFieldRegistration(
      typeName: typeName,
      subFieldsBuilder: (CompoundField field) => subFieldsBuilder(field as T),
      layoutBuilder: layoutBuilder,
      rollUpErrors: rollUpErrors,
      converters: converters,
    );

    _compoundRegistrations[T] = registration;

    if (converters != null) {
      _converters[T] = converters;
    }

    flutter.debugPrint('Registered compound field for type $T ($typeName)');
  }

  /// Retrieves the compound field registration for a given type.
  ///
  /// Used internally by the Form widget to process compound fields.
  ///
  /// **Type Parameter:**
  /// - `T`: The compound field type (must extend [CompoundField])
  ///
  /// **Returns:**
  /// The [CompoundFieldRegistration] for type `T`, or null if not registered.
  CompoundFieldRegistration?
      getCompoundRegistration<T extends CompoundField>() {
    return _compoundRegistrations[T];
  }

  ///
  /// Retrieves the compound field registration by runtime type.
  ///
  /// Used internally by the Form widget to look up registrations for
  /// compound field instances when the specific type parameter is not available.
  ///
  /// **Parameters:**
  /// - [fieldType]: The runtime type of the compound field
  ///
  /// **Returns:**
  /// The [CompoundFieldRegistration] for the type, or null if not registered.
  CompoundFieldRegistration? getCompoundRegistrationByType(Type fieldType) {
    return _compoundRegistrations[fieldType];
  }

  /// Clears all compound field registrations.
  ///
  /// Used for testing purposes to reset state between tests.
  void clearCompoundRegistrations() {
    _compoundRegistrations.clear();
  }

  // ===========================================================================
  // LEGACY INSTANCE API (Backward Compatibility)
  // ===========================================================================

  /// Registers a builder function for a specific Field type (legacy API).
  ///
  /// **Deprecated:** This method uses the old 6-parameter builder signature.
  /// Use the static [register] method with [FormFieldBuilder] instead.
  ///
  /// **Example (legacy):**
  /// ```dart
  /// FormFieldRegistry.instance.registerBuilder<TextField>(
  ///   (context, controller, field, state, colors, updateFocus) {
  ///     return TextFieldWidget(...);
  ///   },
  /// );
  /// ```
  ///
  /// **Migration:**
  /// ```dart
  /// FormFieldRegistry.register<TextField>(
  ///   'textField',
  ///   (context) => TextFieldWidget(context: context),
  /// );
  /// ```
  @Deprecated('Use FormFieldRegistry.register<T>() static method instead')
  void registerBuilder<T extends Field>(LegacyFormFieldBuilder<T> builder) {
    if (_builders.containsKey(T)) {
      flutter.debugPrint('Warning: Overwriting builder for type $T');
    }
    _builders[T] = builder;
    flutter.debugPrint('Registered builder for type $T (legacy API)');
  }

  /// Looks up and executes the builder for a given field definition.
  ///
  /// Called internally by the [Form] widget to build each field.
  /// Handles both new [FormFieldBuilder] and legacy [LegacyFormFieldBuilder]
  /// signatures for backward compatibility.
  ///
  /// **Parameters:**
  /// - [context]: Build context
  /// - [controller]: Form controller
  /// - [field]: Field definition
  /// - [currentState]: Current field state
  /// - [currentColors]: Current field colors
  /// - [updateFocus]: Focus update callback
  ///
  /// **Returns:**
  /// The built widget for the field, or an error placeholder if the builder
  /// fails or is not registered.
  flutter.Widget buildField(
    flutter.BuildContext context,
    FormController controller,
    Field field,
    FieldState currentState,
    FieldColorScheme currentColors,
    Function(bool focused) updateFocus,
  ) {
    final fieldType = field.runtimeType;
    final builder = _builders[fieldType];

    if (builder != null) {
      try {
        // Check if this is a new FormFieldBuilder or legacy LegacyFormFieldBuilder
        // by checking the number of parameters (reflection not available, so we
        // try the new API first and fall back to legacy)
        try {
          // Try new API: Single FieldBuilderContext parameter
          if (builder is FormFieldBuilder) {
            final builderContext = FieldBuilderContext(
              controller: controller,
              field: field,
              theme: FormTheme(), // TODO: Get resolved theme
              state: currentState,
              colors: currentColors,
            );
            return builder(builderContext);
          }
        } catch (e) {
          // If new API fails, fall through to legacy API
        }

        // Fall back to legacy API: 6 parameters
        return builder(
          context,
          controller,
          field,
          currentState,
          currentColors,
          updateFocus,
        );
      } catch (e, stackTrace) {
        flutter.debugPrint(
            'Error executing builder for type $fieldType: $e\n$stackTrace');
        return _buildErrorPlaceholder(fieldType, 'Builder execution error');
      }
    } else {
      flutter.debugPrint('Error: No builder registered for type $fieldType');
      return _buildErrorPlaceholder(fieldType, 'Builder not registered');
    }
  }

  /// Builds an error placeholder widget when a field cannot be rendered.
  flutter.Widget _buildErrorPlaceholder(Type fieldType, String message) {
    return flutter.Container(
      padding: const flutter.EdgeInsets.all(8),
      color: flutter.Colors.red.withValues(alpha: 0.1),
      child: flutter.Text(
        'Error building field ($fieldType): $message',
        style: const flutter.TextStyle(color: flutter.Colors.red, fontSize: 12),
      ),
    );
  }

  /// Checks if a builder is registered for a specific type (legacy API).
  ///
  /// **Parameters:**
  /// - [type]: The field type to check
  ///
  /// **Returns:**
  /// `true` if a builder is registered, `false` otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (FormFieldRegistry.instance.hasBuilderFor(TextField)) {
  ///   // Builder exists
  /// }
  /// ```
  bool hasBuilderForType(Type type) {
    return _builders.containsKey(type);
  }

  // ===========================================================================
  // CORE BUILDER INITIALIZATION
  // ===========================================================================

  /// Registers builders for all built-in field types.
  ///
  /// Called internally by ChampionForms to register the default field builders:
  /// - [TextField]
  /// - [OptionSelect]
  /// - [CheckboxSelect]
  /// - [ChipSelect]
  /// - [FileUpload]
  /// - [NameField] (compound)
  /// - [AddressField] (compound)
  ///
  /// This method should only be called once during package initialization.
  void registerCoreBuilders() {
    initialized = true;

    // Register standard fields with new StatefulFieldWidget API
    FormFieldRegistry.register<TextField>('textField', buildTextField);
    FormFieldRegistry.register<OptionSelect>('optionSelect', buildOptionSelect);
    FormFieldRegistry.register<CheckboxSelect>(
        'checkboxSelect', buildCheckboxSelect);
    FormFieldRegistry.register<ChipSelect>('chipSelect', buildChipSelect);
    FormFieldRegistry.register<FileUpload>('fileUpload', buildFileUpload);

    // Register built-in compound fields with custom layouts
    _registerNameField();
    _registerAddressField();
  }

  /// Registers the NameField compound field with custom horizontal layout.
  ///
  /// Layout:
  /// - Row with Expanded widgets
  /// - Flex ratios: firstname (flex: 1), middlename (flex: 1), lastname (flex: 2)
  /// - 10px spacing between fields
  void _registerNameField() {
    FormFieldRegistry.registerCompound<NameField>(
      'name',
      (field) => field.buildSubFields(),
      (context, subFields, errors) {
        // Build horizontal layout with flex ratios
        return flutter.Column(
          crossAxisAlignment: flutter.CrossAxisAlignment.start,
          children: [
            flutter.Row(
              children: [
                // First name: flex 1
                flutter.Expanded(
                  flex: 1,
                  child: subFields[0],
                ),
                const flutter.SizedBox(width: 10),

                // Middle name (if present): flex 1
                if (subFields.length > 2) ...[
                  flutter.Expanded(
                    flex: 1,
                    child: subFields[1],
                  ),
                  const flutter.SizedBox(width: 10),
                ],

                // Last name: flex 2
                flutter.Expanded(
                  flex: 2,
                  child: subFields[subFields.length > 2 ? 2 : 1],
                ),
              ],
            ),

            // Error display if errors are rolled up
            if (errors != null && errors.isNotEmpty) ...[
              const flutter.SizedBox(height: 8),
              ...errors.map((error) => flutter.Padding(
                    padding: const flutter.EdgeInsets.only(bottom: 4),
                    child: flutter.Text(
                      error.reason,
                      style: const flutter.TextStyle(
                        color: flutter.Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  )),
            ],
          ],
        );
      },
      rollUpErrors: false,
    );
  }

  /// Registers the AddressField compound field with custom multi-row layout.
  ///
  /// Layout:
  /// - Row 1: street (full width)
  /// - Row 2: street2 (full width, if includeStreet2)
  /// - Row 3: city (flex: 4), state (flex: 3), zip (flex: 3) in horizontal Row
  /// - Row 4: country (full width, if includeCountry)
  /// - Error display at bottom if rollUpErrors
  /// - 10px vertical spacing between rows
  void _registerAddressField() {
    FormFieldRegistry.registerCompound<AddressField>(
      'address',
      (field) => field.buildSubFields(),
      (context, subFields, errors) {
        // Determine which optional fields are present
        // Sub-fields are in order: street, [street2], city, state, zip, [country]
        final hasStreet2 = subFields.length > 4;
        final hasCountry =
            subFields.length == 6 || (subFields.length == 5 && !hasStreet2);

        int idx = 0;
        final street = subFields[idx++];
        final street2 = hasStreet2 ? subFields[idx++] : null;
        final city = subFields[idx++];
        final state = subFields[idx++];
        final zip = subFields[idx++];
        final country = (idx < subFields.length) ? subFields[idx++] : null;

        return flutter.Column(
          crossAxisAlignment: flutter.CrossAxisAlignment.start,
          children: [
            // Row 1: Street (full width)
            street,

            // Row 2: Street 2 (full width, if present)
            if (street2 != null) ...[
              const flutter.SizedBox(height: 10),
              street2,
            ],

            const flutter.SizedBox(height: 10),

            // Row 3: City, State, ZIP in horizontal row
            flutter.Row(
              children: [
                flutter.Expanded(
                  flex: 4,
                  child: city,
                ),
                const flutter.SizedBox(width: 10),
                flutter.Expanded(
                  flex: 3,
                  child: state,
                ),
                const flutter.SizedBox(width: 10),
                flutter.Expanded(
                  flex: 3,
                  child: zip,
                ),
              ],
            ),

            // Row 4: Country (full width, if present)
            if (country != null) ...[
              const flutter.SizedBox(height: 10),
              country,
            ],

            // Error display if errors are rolled up
            if (errors != null && errors.isNotEmpty) ...[
              const flutter.SizedBox(height: 8),
              ...errors.map((error) => flutter.Padding(
                    padding: const flutter.EdgeInsets.only(bottom: 4),
                    child: flutter.Text(
                      error.reason,
                      style: const flutter.TextStyle(
                        color: flutter.Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  )),
            ],
          ],
        );
      },
      rollUpErrors: false,
    );
  }
}
