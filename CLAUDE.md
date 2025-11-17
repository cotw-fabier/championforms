# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ChampionForms is a declarative Flutter form builder package focused on clean structure, validation, state management via a central controller, and customizable theming. The project uses a modern namespace-based API (v0.4.0+) where the package is imported as `import 'package:championforms/championforms.dart' as form;` to avoid naming conflicts with Flutter's built-in widgets.

## Essential Commands

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/form_controller_test.dart

# Run tests with expanded output
flutter test --reporter expanded

# Run example app tests
flutter test example/test/autocomplete_overlay_integration_test.dart
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Analyze specific file
flutter analyze lib/controllers/form_controller.dart

# Format code
flutter format lib/

# Run custom lints
dart run custom_lint
```

### Development
```bash
# Get dependencies
flutter pub get

# Run example app
cd example && flutter run

# Clean build artifacts
flutter clean

# Build documentation
dart doc
```

## Architecture Overview

### Two-Tier Export System

The library uses a two-tier export system for better organization:

1. **`championforms.dart`** - Form lifecycle classes (controllers, fields, validators, results)
   - Use: `import 'package:championforms/championforms.dart' as form;`
   - Contains: FormController, Form widget, field types (TextField, OptionSelect, FileUpload, etc.), validators, results handling

2. **`championforms_themes.dart`** - Theming and configuration
   - Use: `import 'package:championforms/championforms_themes.dart';`
   - Contains: FormTheme, FieldColorScheme, pre-built themes, FormFieldRegistry
   - Note: Theme classes DO NOT use the `form.` namespace prefix

### Core Directory Structure

```
lib/
├── championforms.dart              # Main export (lifecycle)
├── championforms_themes.dart       # Theme export (configuration)
├── controllers/
│   └── form_controller.dart        # Central state management
├── models/
│   ├── field_types/               # Field definitions (TextField, OptionSelect, etc.)
│   ├── formresults.dart           # Results access and conversion
│   ├── themes.dart                # Theme model
│   ├── validatorclass.dart        # Validator model
│   └── multiselect_option.dart    # FieldOption model
├── widgets_internal/              # Internal widgets (autocomplete, drag-drop)
│   ├── field_widgets/             # Field implementations
│   └── platform/                  # Platform-specific logic
├── widgets_external/              # Public widgets
│   ├── form.dart                  # Form widget
│   ├── field_builders/            # Field builder functions
│   └── field_layouts/             # Layout functions
├── functions/
│   └── defaultvalidators/         # Built-in validators (Validators class)
└── themes/                        # Pre-built themes
```

### Key Architectural Patterns

#### 1. Central State Management via FormController

The `FormController` (in `controllers/form_controller.dart`) is the single source of truth for:
- Field values (generic storage via `fieldValues` map)
- Validation errors (via `formErrors`)
- Focus states (via `focusListenable` map)
- TextEditingController lifecycle management
- Page grouping for multi-step forms

The controller extends `ChangeNotifier` and automatically notifies listeners on state changes (suppressible via `noNotify` parameter on most methods).

#### 2. Field Definition Hierarchy

```
FieldBase (abstract)
├── Field (concrete) - Standard fields
│   ├── TextField
│   ├── OptionSelect
│   │   ├── CheckboxSelect (convenience)
│   │   └── ChipSelect (convenience)
│   └── FileUpload
└── Layout types
    ├── Row (contains Columns)
    └── Column (contains Fields)
```

All field types share common properties defined in `FieldBase`:
- `id` (unique identifier)
- `validators` (List<Validator>)
- `defaultValue`
- `validateLive` (validate on blur)
- `onChange`/`onSubmit` callbacks
- `copyWith` method (required for all Field subclasses)

**IMPORTANT:** All custom field classes that extend `Field` or its subclasses (TextField, OptionSelect, FileUpload, etc.) **must** implement the `copyWith` method. This requirement was introduced to enable:
- Proper field copying for compound fields (e.g., AddressField, NameField)
- State propagation (themes, disabled state) from parent to child fields
- Field cloning with modified properties

The `copyWith` method must accept nullable parameters for ALL properties (both from the parent class and custom properties) and return a new instance with updated values using the `?? this.property` pattern. See [Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md#required-implementing-copywith-for-custom-field-classes) for implementation examples.

#### 3. Validation System

Validation happens at two points:
1. **On blur** (if `validateLive: true` on field)
2. **On result retrieval** (via `FormResults.getResults()`)

Validators use a simple function signature:
```dart
Validator(
  validator: (FieldResultAccessor results) => bool,
  reason: "Error message"
)
```

Built-in validators are in `functions/defaultvalidators/defaultvalidators.dart` and exposed as the `Validators` class (e.g., `Validators.isEmpty()`, `Validators.isEmail()`).

#### 4. Results Access Pattern

```dart
// 1. Get results (triggers validation)
final results = FormResults.getResults(controller: controller);

// 2. Check error state
if (results.errorState) {
  // Handle errors: results.formErrors
}

// 3. Access field values with type conversion
final name = results.grab("name").asString();
final files = results.grab("avatar").asFile();
final options = results.grab("country").asMultiselectList();
```

The `FieldResultAccessor` (in `formresults.dart`) provides type-safe conversion methods that automatically handle default values.

#### 5. Theme Hierarchy

Themes cascade from general to specific:
```
Default Theme → Global Theme (FormTheme.instance) → Form Theme → Field Theme
```

Each theme defines a `FormTheme` object with:
- `FieldColorScheme` for different states (normal, active, error, disabled, selected)
- `TextStyle` configurations
- `InputDecoration` builders

#### 6. Custom Field Registration

The `FormFieldRegistry` singleton (in `core/field_builder_registry.dart`) allows registration of custom field builders:
```dart
FormFieldRegistry.instance.registerField(
  'customFieldType',
  (field) => Widget buildCustomField(field)
);
```

## Important Development Considerations

### Namespace Usage

Always use the namespace import:
```dart
import 'package:championforms/championforms.dart' as form;
```

All lifecycle classes use the `form.` prefix (e.g., `form.FormController`, `form.TextField`), EXCEPT theme classes which are imported directly from `championforms_themes.dart`.

### Controller Disposal

The `FormController` manages many resources (TextEditingControllers, FocusNodes, ValueNotifiers) that MUST be disposed:
```dart
@override
void dispose() {
  controller.dispose();
  super.dispose();
}
```

### File Upload Platform Setup

`FileUpload` fields require platform-specific permissions. Users must configure:
- iOS: `Info.plist` (NSPhotoLibraryUsageDescription, etc.)
- Android: `AndroidManifest.xml` (READ_EXTERNAL_STORAGE)
- macOS: `*.entitlements` files

Refer to [file_picker documentation](https://pub.dev/packages/file_picker#setup).

### Test Organization

Tests are split between:
- `test/` - Unit tests for core functionality (e.g., `form_controller_test.dart`)
- `example/test/` - Integration tests and widget tests for specific features (autocomplete, file upload, drag-drop)

Run tests from repository root using `flutter test` or `flutter test example/test/<file>`.

### Migration from v0.3.x

The project underwent a breaking API change in v0.4.0. An automated migration script exists at `tools/project-migration.dart`. When helping users upgrade, reference `MIGRATION-0.4.0.md` for complete migration instructions.

Key changes:
- `ChampionTextField` → `form.TextField`
- `ChampionFormController` → `form.FormController`
- `FormBuilderValidator` → `form.Validator`
- `MultiselectOption` → `form.FieldOption`
- `DefaultValidators` → `form.Validators`

## Common Patterns

### Programmatic Field Updates

```dart
// Update text field
controller.updateTextFieldValue("fieldId", "new text");

// Toggle multiselect options
controller.toggleMultiSelectValue(
  "checkboxId",
  toggleOn: ["value1", "value2"],
  toggleOff: ["value3"]
);

// Clear multiselect
controller.removeMultiSelectOptions("fieldId");
```

### Autocomplete Implementation

Autocomplete is implemented via `AutoCompleteBuilder` on TextField:
```dart
form.TextField(
  id: "email",
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [form.CompleteOption(value: "example@test.com")],
    autoCompleteFetch: (input) async {
      // Fetch from API
      return results.map((r) => form.CompleteOption(value: r)).toList();
    },
    debounce: Duration(milliseconds: 300),
  ),
)
```

The overlay widget is in `widgets_internal/autocomplete_overlay_widget.dart`.

### Row/Column Layouts

Forms support flexible layouts:
```dart
form.Row(
  columns: [
    form.Column(fields: [...], columnFlex: 1),
    form.Column(fields: [...], columnFlex: 2),
  ],
  collapse: true, // Stack vertically on small screens
  rollUpErrors: true, // Show child errors below row
)
```

## Dependencies

Key dependencies:
- `file_picker` (^10.3.2) - File selection
- `desktop_drop` (^0.7.0) - Drag-and-drop for desktop platforms
- `email_validator` (^3.0.0) - Email validation
- `uuid` (^4.5.1) - Unique ID generation
- `mime` (^2.0.0) - MIME type detection

Minimum requirements:
- Dart SDK: >=3.0.5 <4.0.0
- Flutter SDK: >=3.35.0

## Package Publishing

This is a published package on pub.dev: https://pub.dev/packages/championforms

Current version: 0.5.3

When making changes, ensure:
1. Version is updated in `pubspec.yaml`
2. CHANGELOG.md is updated
3. Breaking changes are clearly documented
4. Migration guides are provided for API changes
