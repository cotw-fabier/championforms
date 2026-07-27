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
// JSON FACTORY SIGNATURE (v0.7.0+)
// ===========================================================================

/// Builds a [Field] from its JSON map.
///
/// Registered per field type through [FormFieldRegistry.register]'s `fromJson`
/// parameter, and dispatched to by [FormFieldRegistry.fieldFromJson].
///
/// The map is the *whole* field object, including the `type` key that selected
/// this factory. A factory is free to read it, and `TextField.fromJson` does,
/// because several logical types (`email`, `password`, `tel`, `number`) are one
/// Dart class configured differently.
///
/// See `FieldJson` for readers covering the properties every field has, so a
/// factory only parses what is specific to its own type.
typedef FieldFromJson = Field Function(Map<String, dynamic> json);

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

  /// Reverse index: the `typeName` passed to [register] -> the `Type` it was
  /// registered for.
  ///
  /// Without this map there is no path from a string in a serialized document
  /// (`"textField"`) to a registered builder — [register] accepted the name but
  /// only ever used it for a debug print, while every lookup was keyed by
  /// [Type]. Any decoder living outside this package therefore had to hard-code
  /// a switch over every field type, which defeats the point of a registry.
  final Map<String, Type> _typesByName = {};

  /// Forward index: `Type` -> the `typeName` it was registered under.
  ///
  /// Kept alongside [_typesByName] rather than derived from it, because
  /// serializing a field needs the name for a type it is holding, and searching
  /// the reverse map for every write would be O(n) per field.
  final Map<Type, String> _namesByType = {};

  /// JSON factories, keyed by `typeName`.
  final Map<String, FieldFromJson> _fromJson = {};

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
    FieldFromJson? fromJson,
  }) {
    _instance._registerInternal<T>(typeName, builder, converters, fromJson);
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
  // TYPE NAME INDEX (v0.7.0+)
  // ===========================================================================

  /// Resolves the `typeName` a field type was registered under to its [Type].
  ///
  /// This is the entry point for anything that receives a field as *data* —
  /// a form stored in a database row, a schema fetched from a server, a
  /// document written by a visual builder. Such a document can only name a
  /// field type as a string; this turns that string back into something the
  /// registry can act on.
  ///
  /// Returns `null` if no field type has been registered under [typeName].
  ///
  /// ```dart
  /// FormFieldRegistry.ensureInitialized();
  /// FormFieldRegistry.typeForName('textField'); // TextField
  /// FormFieldRegistry.typeForName('nope');      // null
  /// ```
  ///
  /// See also:
  /// - [nameForType] for the inverse
  /// - [fieldFromJson] which uses this index to build a field from a map
  static Type? typeForName(String typeName) => _instance._typesByName[typeName];

  /// Returns the `typeName` [type] was registered under, or `null`.
  ///
  /// The inverse of [typeForName]. Useful when serializing: a writer holds a
  /// `Field` and needs the stable string a reader will use to find it again.
  ///
  /// ```dart
  /// FormFieldRegistry.nameForType(TextField); // 'textField'
  /// ```
  static String? nameForType(Type type) => _instance._namesByType[type];

  /// Every `typeName` currently registered, in registration order.
  ///
  /// Includes compound field types registered through [registerCompound].
  static Iterable<String> get registeredTypeNames =>
      _instance._typesByName.keys;

  /// Whether a builder is registered under the string [typeName].
  ///
  /// The string-keyed counterpart of [hasBuilderFor]. A decoder uses this to
  /// tell "this document names a type I have never heard of" (a legible,
  /// one-field failure) from "this document is malformed".
  static bool hasBuilderForName(String typeName) =>
      _instance._typesByName.containsKey(typeName);

  /// Registers the built-in field builders if they have not been registered.
  ///
  /// The [Form] widget does this on its first build, which is enough for a
  /// hand-written form but not for a decoder: anything that resolves a
  /// `typeName` *before* a form is on screen — parsing a stored document,
  /// validating a schema in a test — would find an empty registry. Calling this
  /// is idempotent and cheap.
  static void ensureInitialized() {
    if (!_instance.initialized) {
      _instance.registerCoreBuilders();
    }
  }

  // ===========================================================================
  // JSON DECODING (v0.7.0+)
  // ===========================================================================

  /// Builds a [Field] from [json], dispatching on its `"type"` key.
  ///
  /// This is the whole point of the type-name index: a decoder outside this
  /// package no longer needs to switch over every field type and know every
  /// constructor. It hands the map over and gets a field back.
  ///
  /// ```dart
  /// FormFieldRegistry.ensureInitialized();
  /// ValidatorRegistry.ensureInitialized();
  ///
  /// final field = FormFieldRegistry.fieldFromJson({
  ///   'id': 'email',
  ///   'type': 'email',
  ///   'title': 'Email',
  ///   'validators': [
  ///     'required',
  ///     {'name': 'maxLength', 'params': {'max': 254}},
  ///   ],
  /// });
  /// ```
  ///
  /// Returns `null` when `type` is absent or names a type with no registered
  /// factory. **Null, not an exception**, because a document is data that can
  /// outlive the build reading it — a form saved a year ago, a schema written
  /// by a newer server — and a caller that gets null can render a placeholder
  /// for one field it does not understand. Throwing would take the whole form
  /// down over a single unknown type, which is strictly worse. Errors *within*
  /// a recognised field (a missing `id`, a `validators` that is not a list, an
  /// unknown validator name) still throw, because those are malformed rather
  /// than merely unfamiliar.
  static Field? fieldFromJson(Map<String, dynamic> json) {
    final typeName = json['type'];
    if (typeName is! String) return null;
    return fieldFromJsonNamed(typeName, json);
  }

  /// [fieldFromJson] with the type named explicitly.
  ///
  /// For documents that carry the type somewhere other than a `type` key —
  /// a map keyed by type name, say — so they need not synthesise one.
  static Field? fieldFromJsonNamed(String typeName, Map<String, dynamic> json) {
    final factory = _instance._fromJson[typeName];
    if (factory == null) return null;
    return factory(json);
  }

  /// Whether a JSON factory is registered under [typeName].
  ///
  /// Distinct from [hasBuilderForName]: a type may be renderable without being
  /// decodable, which is the normal state for a custom field whose author has
  /// not needed serialization.
  static bool hasFromJsonFor(String typeName) =>
      _instance._fromJson.containsKey(typeName);

  /// Every `typeName` that can be decoded from JSON.
  static Iterable<String> get decodableTypeNames => _instance._fromJson.keys;

  /// Registers an additional `typeName` that decodes and renders as `T`.
  ///
  /// The vocabulary a document uses and the set of Dart classes that implement
  /// it are not the same size. `email`, `password`, `tel`, `url`, `number`,
  /// `text` and `textarea` are seven type names and one [TextField]; `select`
  /// and `optionSelect` are the same widget under the name each audience
  /// reaches for first.
  ///
  /// An alias resolves through [typeForName] and [fieldFromJson] like any other
  /// name, but it does **not** become the type's canonical name — [nameForType]
  /// keeps answering with the name the type was registered under, so
  /// serializing a field still produces one stable, predictable string rather
  /// than whichever alias happened to be registered last.
  static void registerJsonAlias<T extends Field>(
    String typeName,
    FieldFromJson fromJson,
  ) {
    _instance._fromJson[typeName] = fromJson;
    _instance._typesByName[typeName] = T;
  }

  /// The type-name vocabulary the built-in fields answer to beyond their
  /// canonical names.
  void _registerCoreAliases() {
    // One TextField, several keyboards. `TextField.fromJson` reads `type` and
    // configures itself, which is why they can all share a factory.
    for (final name in const [
      'text',
      'textarea',
      'email',
      'password',
      'tel',
      'url',
      'number',
    ]) {
      FormFieldRegistry.registerJsonAlias<TextField>(name, TextField.fromJson);
    }

    FormFieldRegistry.registerJsonAlias<OptionSelect>(
      'select',
      OptionSelect.fromJson,
    );
    // A single-select checkbox group. `CheckboxSelect.fromJson` reads `type`
    // to decide whether `multiselect` defaults on or off.
    FormFieldRegistry.registerJsonAlias<CheckboxSelect>(
      'checkbox',
      CheckboxSelect.fromJson,
    );
    FormFieldRegistry.registerJsonAlias<ChipSelect>(
      'chips',
      ChipSelect.fromJson,
    );
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
      FieldBuilderContext ctx,
      List<flutter.Widget> subFields,
      List<FormBuilderError>? errors,
    )? layoutBuilder, {
    bool rollUpErrors = false,
    FieldConverters? converters,
    FieldFromJson? fromJson,
  }) {
    _instance._registerCompoundInternal<T>(
      typeName,
      subFieldsBuilder,
      layoutBuilder,
      rollUpErrors,
      converters,
      fromJson,
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
    FieldFromJson? fromJson,
  ) {
    if (_builders.containsKey(T)) {
      flutter.debugPrint('Warning: Overwriting builder for type $T');
    }
    _builders[T] = builder;
    if (converters != null) {
      _converters[T] = converters;
    }
    if (fromJson != null) {
      // Keyed by NAME, not by Type: one Dart class legitimately serves several
      // type names (`email` and `password` are both `TextField`), and each of
      // them needs its own entry pointing at the same factory. Keying by Type
      // would let only one of them through.
      _fromJson[typeName] = fromJson;
    }
    _indexTypeName<T>(typeName);
    flutter.debugPrint('Registered builder for type $T ($typeName)');
  }

  /// Records both directions of the `typeName` <-> `Type` index.
  ///
  /// Re-registering a type under a *different* name drops the old name, so the
  /// index never answers a name the caller has since replaced. Registering two
  /// different types under the same name is a programming error rather than a
  /// configuration one — the second silently shadowing the first would make a
  /// stored document decode to the wrong widget — so it warns loudly and the
  /// last registration wins, matching how [_builders] itself behaves.
  void _indexTypeName<T>(String typeName) {
    final previousName = _namesByType[T];
    if (previousName != null && previousName != typeName) {
      _typesByName.remove(previousName);
    }
    final previousType = _typesByName[typeName];
    if (previousType != null && previousType != T) {
      flutter.debugPrint(
        'Warning: type name "$typeName" was registered for $previousType and is '
        'now being registered for $T. A serialized field naming "$typeName" '
        'will decode as $T from here on.',
      );
    }
    _typesByName[typeName] = T;
    _namesByType[T] = typeName;
  }

  /// Internal implementation of compound field registration.
  ///
  /// This method handles the actual registration logic for compound fields.
  void _registerCompoundInternal<T extends CompoundField>(
    String typeName,
    List<Field> Function(T) subFieldsBuilder,
    flutter.Widget Function(
      FieldBuilderContext ctx,
      List<flutter.Widget> subFields,
      List<FormBuilderError>? errors,
    )? layoutBuilder,
    bool rollUpErrors,
    FieldConverters? converters,
    FieldFromJson? fromJson,
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
    if (fromJson != null) {
      _fromJson[typeName] = fromJson;
    }
    _indexTypeName<T>(typeName);

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
    FormFieldRegistry.register<TextField>(
      'textField',
      buildTextField,
      fromJson: TextField.fromJson,
    );
    FormFieldRegistry.register<OptionSelect>(
      'optionSelect',
      buildOptionSelect,
      fromJson: OptionSelect.fromJson,
    );
    FormFieldRegistry.register<CheckboxSelect>(
      'checkboxSelect',
      buildCheckboxSelect,
      fromJson: CheckboxSelect.fromJson,
    );
    FormFieldRegistry.register<ChipSelect>(
      'chipSelect',
      buildChipSelect,
      fromJson: ChipSelect.fromJson,
    );
    FormFieldRegistry.register<FileUpload>('fileUpload', buildFileUpload);

    _registerCoreAliases();

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
