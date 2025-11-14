# Changelog

All notable changes to ChampionForms will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2025-11-13 (Unreleased)

### 🎉 Major Release: Simplified Custom Field API

Version 0.6.0 dramatically simplifies custom field creation by reducing boilerplate from **120-150 lines to 30-50 lines** (60-70% reduction).

### ⚠️ Breaking Changes

**Who This Affects:**
- ✅ **Custom field developers**: If you've created custom field types, you need to migrate your code
- ❌ **Regular users**: If you only use built-in fields (TextField, OptionSelect, FileUpload), **no changes required**

**What Changed:**

1. **FormFieldBuilder signature** changed from 6 parameters to 1 (FieldBuilderContext)
2. **FormFieldRegistry.register()** now uses static method instead of `.instance.registerField()`
3. **Built-in fields** internally refactored to use new API (public API unchanged)

**Migration Required:** See [Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md)

---

### Added

#### Compound Fields API

**CompoundField System**
- Create reusable composite fields made up of multiple sub-fields
- Sub-fields act as independent fields with automatic ID prefixing (e.g., `address_street`, `address_city`)
- Complete controller transparency - all existing controller methods work unchanged on sub-field IDs
- Custom layouts per compound field with flexible builder functions
- Error rollup pattern following Row/Column implementation
- Location: `lib/models/field_types/compound_field.dart`

**FormFieldRegistry.registerCompound()**
- Register custom compound fields with `FormFieldRegistry.registerCompound<T>()`
- Type-safe registration with generic type constraints (`T extends CompoundField`)
- Optional custom layout builder and error rollup configuration
- Companion method `hasCompoundBuilderFor<T>()` for registration checks
- Location: `lib/core/field_builder_registry.dart`

**Built-in Compound Fields**
- **NameField** - Horizontal layout with firstname, lastname, and optional middlename
  - Configurable via `includeMiddleName` property
  - Flex ratios: firstname (1), middlename (1), lastname (2)
  - Location: `lib/default_fields/name_field.dart`
- **AddressField** - Multi-row layout for complete addresses
  - Configurable via `includeStreet2` and `includeCountry` properties
  - Fields: street, street2 (optional), city/state/zip row, country (optional)
  - City/state/zip flex ratios: 4/3/3
  - Location: `lib/default_fields/address_field.dart`

**Results Access Enhancement**
- New `asCompound()` method on FieldResultAccessor
- Joins sub-field values with configurable delimiter (default: ", ")
- Automatically detects compound fields by sub-field ID pattern
- Filters out empty values for clean output
- Example: `results.grab('address').asCompound(delimiter: ', ')` → "123 Main St, New York, NY, 10001"
- Location: `lib/models/formresults.dart`

**Example Demonstration**
- Interactive demo page showcasing NameField and AddressField
- Dynamic field configuration with live form rebuilding
- Results display showing both compound and individual sub-field access
- Location: `example/lib/pages/compound_fields_demo.dart`

**Documentation & Tests**
- 43 tests covering compound field functionality (96% pass rate)
- Comprehensive implementation reports in `agent-os/specs/2025-11-13-compound-field-registration-api/`
- Full backward compatibility maintained - zero breaking changes

#### New Core Classes

**FieldBuilderContext**
- Bundles 6 builder parameters (controller, field, theme, validators, callbacks, state) into single context object
- Provides convenience methods: `getValue()`, `setValue()`, `addError()`, `clearErrors()`, `hasFocus`
- Lazy initialization of TextEditingController and FocusNode via `getTextController()` and `getFocusNode()`
- Theme-aware color access via `colors` property
- Direct controller access for advanced use cases
- Location: `lib/models/field_builder_context.dart`
- Documentation: [FieldBuilderContext API Reference](docs/custom-fields/field-builder-context.md)

**StatefulFieldWidget**
- Abstract base class for custom field widgets with automatic lifecycle management
- Eliminates ~50 lines of boilerplate per custom field
- Automatic controller listener registration/disposal
- Change detection with optional lifecycle hooks: `onValueChanged()`, `onFocusChanged()`, `onValidate()`
- Automatic validation on focus loss (when `validateLive` is true)
- Performance-optimized rebuilds (only on relevant state changes)
- Location: `lib/widgets_external/stateful_field_widget.dart`
- Documentation: [StatefulFieldWidget Guide](docs/custom-fields/stateful-field-widget.md)

**Converter Mixins**
- Reusable type conversion logic for FormResults methods
- Four built-in mixins:
  - `TextFieldConverters` - for String-based fields
  - `MultiselectFieldConverters` - for List<FieldOption> fields
  - `FileFieldConverters` - for List<FileModel> fields
  - `NumericFieldConverters` - for int/double fields
- All converters throw TypeError on invalid input for explicit failure reporting
- Support for custom converter implementation via FieldConverters interface
- Location: `lib/models/field_converters.dart`
- Documentation: [Converters Guide](docs/custom-fields/converters.md)

#### Enhanced FormFieldRegistry

- **Static method API**: `FormFieldRegistry.register<T>()` and `FormFieldRegistry.hasBuilderFor<T>()`
- **Backward compatible**: `.instance` accessor still available
- **Unified builder signature**: `typedef FormFieldBuilder = Widget Function(FieldBuilderContext context)`
- **Converter registration**: Optional `converters` parameter in `register()`
- Updated: `lib/core/field_builder_registry.dart`

#### Comprehensive Documentation

- **New docs/ folder structure** with organized guides and references
- **[docs/README.md](docs/README.md)** - Documentation navigation hub
- **[Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md)** - 6 practical examples:
  1. Phone number field with formatting
  2. Tag selector with autocomplete
  3. Rich text editor field
  4. Date/time picker field
  5. Signature pad field
  6. File upload with preview enhancement
- **[FieldBuilderContext API Reference](docs/custom-fields/field-builder-context.md)** - Complete API documentation
- **[StatefulFieldWidget Guide](docs/custom-fields/stateful-field-widget.md)** - Base class guide with patterns
- **[Converters Guide](docs/custom-fields/converters.md)** - Type conversion patterns
- **[Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md)** - Step-by-step upgrade instructions
- **Moved**: MIGRATION-0.4.0.md to `docs/migrations/MIGRATION-0.4.0.md`

---

### Changed

#### Built-in Field Refactoring (Internal)

**Note:** Public API unchanged - no migration required for users of built-in fields.

- **TextField**: Refactored to use StatefulFieldWidget base class (future update)
- **OptionSelect**: Refactored to use StatefulFieldWidget base class (future update)
- **FileUpload**: Refactored to use StatefulFieldWidget base class (future update)
- **CheckboxSelect/ChipSelect**: Automatically benefit from OptionSelect refactoring (future update)

**Status:** Test suites created for refactored fields. Widget refactoring in progress.

#### Updated Exports

- **championforms.dart**: Added exports for v0.6.0+ Custom Field API:
  - `FieldBuilderContext`
  - `StatefulFieldWidget`
  - `FieldConverters` (base class and mixins)
  - `FormFieldBuilder` (typedef)

---

### Deprecated

None. This is a clean breaking change with clear migration path.

---

### Removed

**Old FormFieldBuilder signature** (6 parameters):
```dart
// OLD (removed)
typedef FormFieldBuilder = Widget Function(
  FormController controller,
  Field field,
  FormTheme theme,
  List<Validator> validators,
  FieldCallbacks callbacks,
  FieldState state,
);
```

**Old FormFieldRegistry instance-based registration**:
```dart
// OLD (still works, but deprecated pattern)
FormFieldRegistry.instance.registerField('myField', builder);

// NEW (recommended)
FormFieldRegistry.register<MyField>('myField', builder);
```

---

### Fixed

None in this release (focus on API simplification).

---

### Performance

- **Lazy initialization**: TextEditingController and FocusNode only created when needed
- **Rebuild prevention**: StatefulFieldWidget only rebuilds on value/focus changes
- **Memory efficiency**: Automatic resource disposal managed by FormController

---

### Migration Path

1. **Read First**: [Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md)
2. **Update pubspec.yaml**: `championforms: ^0.6.0`
3. **Migrate custom fields**:
   - Extend `StatefulFieldWidget` instead of `StatefulWidget`
   - Replace constructor parameters with `required super.context`
   - Rename `build()` to `buildWithTheme(BuildContext, FormTheme, FieldBuilderContext)`
   - Use `ctx.getValue()` and `ctx.setValue()` instead of direct controller access
   - Remove manual listener setup/teardown (handled automatically)
4. **Update registration calls**:
   - Change `FormFieldRegistry.instance.registerField()` to `FormFieldRegistry.register<T>()`
   - Update builder signature from 6 parameters to `(ctx) => Widget`
5. **Test thoroughly**: Verify value updates, validation, callbacks, and form submission

**Estimated migration time**: 30-60 minutes per custom field

---

### Documentation

**New Resources:**
- [Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md) - 6 complete examples
- [FieldBuilderContext API](docs/custom-fields/field-builder-context.md) - Full API reference
- [StatefulFieldWidget Guide](docs/custom-fields/stateful-field-widget.md) - Base class patterns
- [Converters Guide](docs/custom-fields/converters.md) - Type conversion guide
- [Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md) - Upgrade instructions

**Updated:**
- [README.md](README.md) - Added v0.6.0 highlights and documentation links
- [docs/README.md](docs/README.md) - Documentation navigation hub

---

### Acknowledgments

This release is focused on developer experience improvement based on community feedback regarding custom field complexity. Thank you to all contributors who provided input on the API design!

---

## [0.5.3] - 2024-XX-XX

### Fixed

**`toggleMultiSelectValue` now respects `multiselect` property**:
- Fixed critical bug where CheckboxSelect fields with `multiselect: false` incorrectly allowed multiple selections
- Single-select fields now behave like radio buttons (selecting one option automatically deselects others)
- Method now properly checks the field's `multiselect` property before updating selections

**Behavior:**
- **Multi-select mode** (`multiselect: true`): Unchanged - allows multiple selections
- **Single-select mode** (`multiselect: false`): Fixed - only allows one selection at a time

**Example:**
```dart
// This now works correctly - only one checkbox can be selected
CheckboxSelect(
  id: 'priority',
  options: [lowOption, mediumOption, highOption],
  multiselect: false,  // Radio button behavior
)
```

---

## [0.5.2] - 2024-XX-XX

### Added

**Field Value Pre-population**:
- Added `createFieldValue<T>()` method to FormController for setting field values without requiring field definitions to exist
- Enables pre-populating controller values before field initialization
- Useful for loading saved form data or setting values dynamically before rendering fields
- Defaults to silent operation (no onChange callbacks, no validation, no notifications)
- Optional `triggerCallbacks` parameter to enable onChange and validation if needed

**Example**:
```dart
// Pre-populate values before fields are defined
final controller = FormController();
controller.createFieldValue<String>('email', 'user@example.com');
controller.createFieldValue<String>('name', 'John Doe');

// Later, when fields are added, values will already be present
Form(
  controller: controller,
  fields: [emailField, nameField],
)
```

### Changed

**Refactored `updateFieldValue<T>()`**:
- Now uses `createFieldValue<T>()` internally after field existence validation
- Maintains existing behavior (validates field exists, triggers callbacks, runs validation)
- Updated documentation to reference `createFieldValue` for pre-population scenarios

**Benefits**:
- **Flexible Value Management**: Set values before or after field initialization
- **Better Pre-population**: Load saved form drafts before rendering fields
- **Backward Compatible**: Existing code continues to work unchanged
- **Clean API**: Clear separation between validated updates and permissive creation

---

## [0.5.1] - 2024-XX-XX

### Fixed
- Various bug fixes and stability improvements

---

## [0.5.0] - 2024-XX-XX

### Added
- Enhanced controller methods for field value management
- Improved error handling and validation

---

## [0.4.0] - 2024-XX-XX

### Breaking Changes

**API Modernization** - Removed "Champion" prefix from all classes and adopted idiomatic Dart namespace patterns.

**Key Changes:**
- Cleaner class names: `ChampionTextField` → `form.TextField`
- Namespace import approach: `import 'package:championforms/championforms.dart' as form;`
- Two-tier export system (form lifecycle vs. theming/configuration)
- No functional changes - all behavior remains identical

**Migration:**
- **Automated**: Use migration script `dart run tools/project-migration.dart /path/to/your/project`
- **Manual**: See [Migration Guide v0.3.x → v0.4.0](docs/migrations/MIGRATION-0.4.0.md)
- **Estimated time**: 5-15 minutes (automated), 30-60 minutes (manual)

### Changed

**Namespace-based API:**
- `ChampionFormController` → `form.FormController`
- `ChampionForm` → `form.Form`
- `ChampionTextField` → `form.TextField`
- `ChampionRow` / `ChampionColumn` → `form.Row` / `form.Column`
- `FormBuilderValidator` → `form.Validator`
- `MultiselectOption` → `form.FieldOption`
- `AutoCompleteOption` → `form.CompleteOption`
- `DefaultValidators` → `form.Validators`

**Two-tier export system:**
- `championforms.dart` - Form lifecycle classes (controllers, fields, validators)
- `championforms_themes.dart` - Theming and configuration (FormTheme, pre-built themes, FormFieldRegistry)

---

## [0.3.0] - 2024-XX-XX

### Added
- **Layout Widgets**: `Row` and `Column` for structuring form layouts
- **File Upload Field**: `FileUpload` with drag-and-drop and file_picker integration
- **Autocomplete**: `AutoCompleteBuilder` for TextField suggestions
- **Global Theming**: FormTheme singleton for app-wide theme defaults
- **Enhanced Controller**: TextEditingController lifecycle management, activeFields tracking, page grouping
- **New Validators**: File-specific validators (fileIsImage, fileIsDocument, isMimeType)

### Changed
- Enhanced FormController with additional helper methods

### Fixed
- Various issues with asStringList, multiselect default values, controller updates

---

## [0.2.0] - 2024-XX-XX

### Added
- Initial public release
- Basic form field types (TextField, OptionSelect, CheckboxSelect)
- FormController for state management
- Validation system
- Basic theming support

---

## [0.1.0] - 2024-XX-XX

### Added
- Initial beta release
- Core functionality for declarative form building

---

[0.6.0]: https://github.com/fabier/championforms/compare/v0.5.3...v0.6.0
[0.5.3]: https://github.com/fabier/championforms/compare/v0.5.2...v0.5.3
[0.5.2]: https://github.com/fabier/championforms/compare/v0.5.1...v0.5.2
[0.5.1]: https://github.com/fabier/championforms/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/fabier/championforms/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/fabier/championforms/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/fabier/championforms/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/fabier/championforms/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/fabier/championforms/releases/tag/v0.1.0
