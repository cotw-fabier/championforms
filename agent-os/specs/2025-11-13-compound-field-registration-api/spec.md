# Specification: Compound Field Registration API

## Goal

Extend the existing FormFieldRegistry system to support compound fields - composite fields made up of multiple sub-fields that function as independent fields from the controller's perspective while providing a convenient registration and layout API for developers. This enables developers to create reusable, pre-configured field groups like AddressField and NameField that maintain full compatibility with the existing ChampionForms architecture.

## User Stories

- As a form developer, I want to register compound fields like "Address" once and reuse them across multiple forms so that I don't have to repeatedly define the same field combinations.
- As a form developer, I want each sub-field in a compound field to behave exactly like a normal field so that I can use all existing controller methods and validation logic without special handling.
- As a form developer, I want automatic ID prefixing for sub-fields so that I don't have naming conflicts when using multiple compound fields in the same form.
- As a form developer, I want to access compound field values as a joined string or as individual sub-field values so that I have flexibility in how I retrieve and use the data.
- As a form developer, I want to apply validation to individual sub-fields and optionally roll up errors to the compound field level so that I can control error display patterns.
- As a form developer, I want to customize the layout of compound fields for specific instances while having sensible defaults so that I balance convenience with flexibility.

## Core Requirements

### Functional Requirements

- Registration API via `FormFieldRegistry.registerCompound<T>()` that accepts sub-field definitions and optional layout builder
- Automatic sub-field ID prefixing using pattern `{compoundId}_{subFieldId}` with developer override capability
- Sub-fields act as fully independent fields in FormController - transparent to all existing controller methods
- Error rollup pattern following Row/Column implementation with `rollUpErrors` boolean flag
- Default vertical layout (Column-style) with custom builder override at registration and per-instance levels
- New `asCompound()` results accessor method that joins sub-field values with configurable delimiter
- Built-in compound field examples: `NameField` (firstname, middlename, lastname) and `AddressField` (street, street2, city, state, zip, country)
- Theme and disabled state propagation from compound field to all sub-fields
- Full compatibility with existing field lifecycle including TextEditingController and FocusNode management

### Non-Functional Requirements

- No performance degradation compared to manually defining individual fields
- Registration happens once at app initialization (no runtime registration overhead)
- Maintain backward compatibility with all existing Field types and controller methods
- Follow existing architectural patterns: singleton registry, type-safe generics, builder pattern
- Zero additional dependencies - leverage existing ChampionForms infrastructure
- Clear debugging output for compound field registration and ID generation

## Visual Design

No visual assets provided. Layout behavior follows existing Row/Column patterns:
- Default: Vertical stack of sub-fields similar to Column layout
- Error display: Inline with each sub-field (default) or rolled up to bottom of compound field if `rollUpErrors: true`
- Custom layouts: Developer-controlled via builder function with full access to sub-field widgets

## Reusable Components

### Existing Code to Leverage

**FormFieldRegistry Pattern** (`/home/fabier/Documents/code/championforms/lib/core/field_builder_registry.dart`):
- Singleton pattern with static methods `register<T>()` and `hasBuilderFor<T>()`
- Type-based builder storage using `Map<Type, Function>`
- `_registerInternal<T>()` method for registration logic
- Debug output pattern for registration confirmation
- Follow same registration workflow for `registerCompound<T>()`

**Row/Column Error Rollup Logic** (`/home/fabier/Documents/code/championforms/lib/models/field_types/row.dart` and `/home/fabier/Documents/code/championforms/lib/models/field_types/column.dart`):
- `rollUpErrors` boolean property pattern
- `hideField` property for hiding entire layout containers
- Error collection mechanism from child fields
- Display errors together at bottom when `rollUpErrors: true`
- Apply same pattern to compound field error handling

**FieldResultAccessor Pattern** (`/home/fabier/Documents/code/championforms/lib/models/formresults.dart`):
- Accessor methods: `asString()`, `asStringList()`, `asBool()`, `asFile()`, `asFileList()`, `asMultiselectList()`
- Fallback parameter pattern for safe value retrieval
- Type conversion with error handling via `_logConversionError()`
- `_getValueForConversion()` helper that handles default values
- Add new `asCompound()` method following same pattern with delimiter parameter

**Field Base Classes** (`/home/fabier/Documents/code/championforms/lib/models/field_types/formfieldbase.dart` and `/home/fabier/Documents/code/championforms/lib/models/field_types/formfieldclass.dart`):
- `FormElement` abstract base class for all form elements
- `FieldBase` abstract class with `id`, `title`, `description` properties
- `Field` abstract class with full field properties: `validators`, `disabled`, `hideField`, `theme`, `onChange`, `onSubmit`, `validateLive`
- Converter function getters: `asStringConverter`, `asStringListConverter`, `asBoolConverter`, `asFileListConverter`
- New `CompoundField` class extends `Field` with sub-field management

**FieldBuilderContext** (`/home/fabier/Documents/code/championforms/lib/models/field_builder_context.dart`):
- Single-parameter builder signature `FormFieldBuilder = Widget Function(FieldBuilderContext context)`
- Bundled dependencies: `controller`, `field`, `theme`, `state`, `colors`
- Convenience methods: `getValue<T>()`, `setValue<T>()`, `addError()`, `clearErrors()`, `hasFocus`
- Lazy resource initialization: `getTextController()`, `getFocusNode()`
- Use same pattern for compound field builders to maintain API consistency

### New Components Required

**CompoundField Base Class**:
- Extends `Field` abstract class
- Adds compound-specific properties: `subFieldDefinitions`, `layoutBuilder`, `rollUpErrors`
- Manages sub-field ID generation and prefixing logic
- Cannot reuse existing classes because compound fields require sub-field management capabilities not present in standard Field types

**CompoundFieldBuilder Function Type**:
- New typedef for compound layout builders
- Signature: `Widget Function(BuildContext context, List<Widget> subFieldWidgets, List<FormBuilderError>? errors)`
- Provides built sub-field widgets and optional rolled-up errors to layout builder
- Cannot reuse `FormFieldBuilder` because compound fields need access to multiple sub-field widgets

**Sub-field ID Management Logic**:
- Function to generate prefixed IDs: `String _generateSubFieldId(String compoundId, String subFieldId)`
- Pattern: `{compoundId}_{subFieldId}`
- Developer override via explicit ID specification on sub-field definitions
- New logic required - no existing pattern for hierarchical field ID management

**Default Vertical Layout Builder**:
- Simple Column-like vertical stacking of sub-fields
- Spacing between sub-fields
- Optional error rollup display at bottom
- New component - existing Column layout is for form structure, not compound field internal layout

## Technical Approach

### Registration Architecture

**New Registration Method**:
```dart
static void registerCompound<T extends CompoundField>(
  String typeName,
  List<Field> Function(T compoundField) subFieldsBuilder,
  Widget Function(BuildContext context, List<Widget> subFields, List<FormBuilderError>? errors)? layoutBuilder,
  {
    bool rollUpErrors = false,
    FieldConverters? converters,
  }
)
```

- Stored in new `Map<Type, CompoundFieldRegistration>` alongside existing `_builders` map
- `CompoundFieldRegistration` class holds: `typeName`, `subFieldsBuilder`, `layoutBuilder`, `rollUpErrors`, `converters`
- Static method follows existing `register<T>()` API pattern for consistency
- Type parameter `T extends CompoundField` enforces type safety

**Sub-field ID Generation**:
```dart
String _prefixSubFieldId(String compoundId, String subFieldId) {
  // Allow developer override if subFieldId already contains the prefix
  if (subFieldId.startsWith('$compoundId_')) {
    return subFieldId;
  }
  return '${compoundId}_$subFieldId';
}
```

- Applied during sub-field list generation from registration builder
- Each sub-field's ID is automatically prefixed unless already prefixed
- Original sub-field ID stored as metadata for results access

### Controller Integration

**Controller Transparency**:
- Sub-fields are registered with FormController as individual, independent fields during form construction
- No compound field awareness required in FormController
- All existing methods work unchanged: `getFieldValue()`, `updateFieldValue()`, `validateField()`, `setFieldFocus()`, etc.
- TextEditingController and FocusNode management handled per sub-field via existing lifecycle

**Field Registration Flow**:
1. Form widget encounters CompoundField in fields list
2. Looks up compound registration via `FormFieldRegistry`
3. Calls `subFieldsBuilder(compoundField)` to generate sub-field list
4. Prefixes all sub-field IDs with compound field ID
5. Registers each sub-field individually with FormController
6. Builds layout using `layoutBuilder` or default vertical layout
7. Controller treats all sub-fields as normal fields

### Validation and Error Handling

**Sub-field Validation**:
- Each sub-field has its own `validators` list defined in registration builder
- Validators execute on individual sub-fields independently via existing validation infrastructure
- Validation errors stored in FormController under sub-field IDs: `controller.formErrors['{compoundId}_{subFieldId}']`

**Error Rollup Pattern**:
```dart
if (compoundField.rollUpErrors) {
  // Collect all errors from sub-fields
  final subFieldErrors = compoundField.subFieldIds
      .map((id) => controller.getFieldErrors(id))
      .expand((errors) => errors)
      .toList();

  // Pass to layout builder for display at compound level
  layoutBuilder(context, subFieldWidgets, subFieldErrors);
} else {
  // Errors display inline with each sub-field (default)
  layoutBuilder(context, subFieldWidgets, null);
}
```

- Follow Row/Column pattern: errors collected from all sub-fields
- If `rollUpErrors: true`, errors passed to layout builder for consolidated display
- If `rollUpErrors: false`, errors display inline with each sub-field via existing field error display

### Results Access

**New asCompound() Accessor**:
```dart
// In FieldResultAccessor class
String asCompound({String delimiter = ", ", String fallback = ""}) {
  // Detect compound field by checking if this ID has associated sub-fields
  final compoundId = _id;
  final subFieldIds = _getSubFieldIds(compoundId);

  if (subFieldIds.isEmpty) {
    debugPrint("asCompound called on non-compound field '$compoundId'. Returning fallback.");
    return fallback;
  }

  // Collect sub-field string values
  final subValues = subFieldIds
      .map((subId) => grab(subId).asString())
      .where((value) => value.isNotEmpty)
      .toList();

  // Join with delimiter
  return subValues.join(delimiter);
}

// Helper to get sub-field IDs for a compound field
List<String> _getSubFieldIds(String compoundId) {
  // Check field definitions map for fields starting with "{compoundId}_"
  return fieldDefinitions.keys
      .where((id) => id.startsWith('${compoundId}_'))
      .toList();
}
```

**Individual Sub-field Access**:
```dart
// Access full compound value
final address = results.grab("address").asCompound(delimiter: ", ");
// Result: "123 Main St, Apt 4, New York, NY, 10001"

// Access individual sub-fields
final street = results.grab("address_street").asString();
final city = results.grab("address_city").asString();
final zip = results.grab("address_zip").asString();
```

### Layout System

**Default Vertical Layout**:
```dart
Widget _buildDefaultCompoundLayout(
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
        SizedBox(height: 10),
      ]).toList()..removeLast(),

      // Rolled up errors if provided
      if (errors != null && errors.isNotEmpty) ...[
        SizedBox(height: 8),
        ...errors.map((error) => Text(
          error.reason,
          style: TextStyle(color: Colors.red, fontSize: 12),
        )),
      ],
    ],
  );
}
```

**Custom Layout Override**:
```dart
// At registration
FormFieldRegistry.registerCompound<AddressField>(
  'address',
  (field) => [...subFields...],
  (context, subFields, errors) => CustomAddressLayout(
    street: subFields[0],
    city: subFields[1],
    state: subFields[2],
    errors: errors,
  ),
);

// Per-instance override via field property
AddressField(
  id: 'billing_address',
  customLayoutBuilder: (context, subFields, errors) => CustomLayout(...),
)
```

### Built-in Compound Fields

**NameField Implementation**:
```dart
class NameField extends CompoundField {
  final bool includeMiddleName;

  NameField({
    required String id,
    this.includeMiddleName = true,
    // ... other Field properties
  }) : super(id: id);

  @override
  List<Field> buildSubFields() {
    final fields = [
      TextField(id: 'firstname', title: 'First Name'),
      TextField(id: 'lastname', title: 'Last Name'),
    ];

    if (includeMiddleName) {
      fields.insert(1, TextField(id: 'middlename', title: 'Middle Name'));
    }

    return fields;
  }
}

// Registration
FormFieldRegistry.registerCompound<NameField>(
  'name',
  (field) => field.buildSubFields(),
  (context, subFields, errors) => Row(
    children: [
      Expanded(flex: 1, child: subFields[0]), // First
      SizedBox(width: 10),
      if (subFields.length > 2) ...[
        Expanded(flex: 1, child: subFields[1]), // Middle
        SizedBox(width: 10),
      ],
      Expanded(flex: 2, child: subFields[subFields.length - 1]), // Last
    ],
  ),
);
```

**AddressField Implementation**:
```dart
class AddressField extends CompoundField {
  final bool includeStreet2;
  final bool includeCountry;

  AddressField({
    required String id,
    this.includeStreet2 = true,
    this.includeCountry = false,
    // ... other Field properties
  }) : super(id: id);

  @override
  List<Field> buildSubFields() {
    final fields = [
      TextField(id: 'street', title: 'Street Address'),
      TextField(id: 'city', title: 'City'),
      TextField(id: 'state', title: 'State'),
      TextField(id: 'zip', title: 'ZIP Code'),
    ];

    if (includeStreet2) {
      fields.insert(1, TextField(id: 'street2', title: 'Apt/Suite'));
    }

    if (includeCountry) {
      fields.add(TextField(id: 'country', title: 'Country'));
    }

    return fields;
  }
}

// Registration with custom layout
FormFieldRegistry.registerCompound<AddressField>(
  'address',
  (field) => field.buildSubFields(),
  (context, subFields, errors) {
    // Extract sub-fields for layout
    final hasStreet2 = subFields.length > 4;
    final hasCountry = subFields.length > (hasStreet2 ? 5 : 4);

    int idx = 0;
    final street = subFields[idx++];
    final street2 = hasStreet2 ? subFields[idx++] : null;
    final city = subFields[idx++];
    final state = subFields[idx++];
    final zip = subFields[idx++];
    final country = hasCountry ? subFields[idx++] : null;

    return Column(
      children: [
        street,
        if (street2 != null) ...[SizedBox(height: 10), street2],
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(flex: 4, child: city),
            SizedBox(width: 10),
            Expanded(flex: 3, child: state),
            SizedBox(width: 10),
            Expanded(flex: 3, child: zip),
          ],
        ),
        if (country != null) ...[SizedBox(height: 10), country],
        if (errors != null && errors.isNotEmpty) ...[
          SizedBox(height: 8),
          ...errors.map((e) => Text(e.reason, style: TextStyle(color: Colors.red))),
        ],
      ],
    );
  },
  rollUpErrors: false, // Display errors inline by default
);
```

### Theme and State Propagation

**Theme Cascading**:
```dart
// When building sub-fields from compound field
final compoundTheme = compoundField.theme;
final subFields = registration.subFieldsBuilder(compoundField).map((subField) {
  // Apply compound theme to sub-field if sub-field doesn't have its own theme
  if (subField.theme == null && compoundTheme != null) {
    subField = subField.copyWith(theme: compoundTheme);
  }
  return subField;
}).toList();
```

**Disabled State Propagation**:
```dart
// When building sub-fields
if (compoundField.disabled) {
  subFields = subFields.map((subField) =>
    subField.copyWith(disabled: true)
  ).toList();
}
```

## Out of Scope

**Future Enhancements**:
- Nested compound fields (compound field containing another compound field) - Requires recursive sub-field resolution
- Dynamic sub-field addition/removal at runtime - Complex state management beyond initial scope
- Automatic form generation from data models - Separate feature on roadmap
- Conditional sub-field display based on other field values - Covered by existing conditional logic feature
- Advanced layout templates library - Developers can create via custom builders
- Internationalization of built-in compound fields - Covered by existing i18n roadmap
- Compound field value serialization formats beyond string join - Can be added with additional converter methods
- Drag-and-drop reordering of sub-fields - Not required for MVP

**Explicitly Excluded**:
- Server-side validation integration - Separate feature
- Breaking changes to existing Field API - Must maintain full backward compatibility
- Automatic migration of manually-defined field groups - Developers opt-in to compound fields

## Success Criteria

**Functionality**:
- Developers can register custom compound fields with 10 lines of code or less
- Sub-fields behave identically to manually-defined fields in all FormController operations
- Zero breaking changes to existing ChampionForms API - full backward compatibility maintained
- NameField and AddressField available as built-in examples with production-ready implementations

**Performance**:
- No measurable overhead compared to manually defining sub-fields individually
- Registration happens once at initialization - zero runtime registration cost
- Layout building performance equivalent to manual Row/Column construction

**Developer Experience**:
- Clear debug output showing compound field registration and sub-field ID generation
- Comprehensive documentation with code examples for custom compound field creation
- Built-in examples serve as reference implementations
- Error messages clearly indicate compound field context when debugging

**Testing Coverage**:
- Unit tests: Sub-field ID generation, error rollup logic, results accessor `asCompound()`
- Widget tests: Built-in NameField and AddressField with various configurations
- Integration tests: Full form with compound fields, validation, and results retrieval
- Example app demonstration: NameField and AddressField usage with custom layouts
