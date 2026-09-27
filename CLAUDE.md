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

# Run an app's macOS integration tests (use this, not `flutter test -d macos`)
tool/macos_integration_test.sh packages/championforms_clipboard/example
tool/macos_integration_test.sh packages/championforms_clipboard/example integration_test/ffi_clipboard_test.dart
```

After `flutter test -d macos` terminates the test app, macOS intermittently
relaunches it (a new launchd-parented process, no arguments), leaving a stray
window. This reproduces in a clean app with no native assets, so it is not our
Rust code. Always run macOS integration tests through
`tool/macos_integration_test.sh`. It closes any leftover process
of that app (matched by its `build/macos/` path only) and keeps flutter's exit
status.

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Analyze specific file
flutter analyze lib/controllers/form_controller.dart

# Format code
dart format lib/
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

## Monorepo / Pub Workspace Layout

The repository is a [pub workspace](https://dart.dev/tools/pub/workspaces).
**The `championforms` package stays at the repository root** (so existing
`path:` and `git:` consumers keep working); sibling packages live under
`packages/`:

```
championforms/                             # repo root == championforms package
├── pubspec.yaml                           # workspace: [...] members listed here
├── pubspec.lock                           # the ONLY lockfile (untracked; library)
├── .pubignore                             # replaces .gitignore for pub; excludes packages/
├── lib/ test/ example/ docs/ tool/        # championforms itself (unchanged)
├── packages/
│   ├── championforms_clipboard/           # multi-format clipboard (no championforms dep)
│   │   └── example/                       # championforms_clipboard_example
│   └── championforms_documents/           # document builder (super_editor based)
│       └── example/                       # championforms_documents_example (trial app)
└── .github/workflows/ci.yaml
```

Every member has `resolution: workspace`, so a single `flutter pub get` at the
root resolves everything. Member lockfiles and `.dart_tool/` are never
committed. Members depend on each other by version constraint (e.g.
`championforms: ^0.8.0-dev.1`), which the workspace satisfies with the local
package. `packages/**` is excluded from the root `analysis_options.yaml`;
each member has its own.

### Per-package commands

```bash
flutter pub get                                   # at the root: whole workspace

# championforms (root) and its example
flutter analyze && flutter test
(cd example && flutter analyze && flutter test)

# championforms_clipboard and its example
(cd packages/championforms_clipboard && flutter analyze && flutter test)
(cd packages/championforms_clipboard/example && flutter run -d macos)

# championforms_documents and its trial app
(cd packages/championforms_documents && flutter analyze && flutter test)
(cd packages/championforms_documents/example && flutter run -d macos)
```

Run `flutter test` only where a `test/` directory exists. CI
(`.github/workflows/ci.yaml`) runs the same loop on Linux, macOS and Windows,
builds the clipboard example for each desktop OS (plus web on Linux) and runs
`dart pub publish --dry-run` for all three packages.

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
- `colors` (`FieldColors` emphasis — see below; defaults to `FieldColors.normal`)
- `animateValidationErrors` (nullable per-field validation-wiggle toggle — see below)
- `copyWith` method (required for all Field subclasses)

#### Field emphasis colors (`colors` / `FieldColors`)

Every base-library field accepts a `colors` parameter of type `FieldColors`
(enum: `normal`, `destructive`). Default is `FieldColors.normal`. A field set
to `FieldColors.destructive` renders in the theme's ERROR palette **while it is
empty and unfocused**, to draw attention to a required or dangerous field
before the user interacts with it. It reverts to normal styling once the field
is focused and/or filled, and a real validation error always takes precedence.
This is additive and non-breaking: the base `Field` defaults `colors` to
`FieldColors.normal`, and custom field subclasses opt in by forwarding `colors`
through their constructor and `copyWith`.

#### Validation wiggle animation

When a field transitions into a real validation-error state (on submit via
`FormResults.getResults()` and on live/on-blur validation), it plays a subtle
horizontal "wiggle" to draw the eye. This is automatic and library-level — no
per-field wiring required. It is **visibility-gated**: an on-screen field
wiggles immediately, while a field scrolled off screen defers its wiggle until
it scrolls into view (playing a beat after it settles). Visibility is tracked
by the reusable internal utility `ChampionVisibilityDetector`
(`lib/widgets_internal/visibility/champion_visibility_detector.dart`). The
animation respects the OS "reduce motion" accessibility setting.

**IMPORTANT:** All custom field classes that extend `Field` or its subclasses (TextField, OptionSelect, FileUpload, etc.) **must** implement the `copyWith` method. This requirement was introduced to enable:
- Proper field copying for compound fields (e.g., AddressField, NameField)
- State propagation (themes, disabled state) from parent to child fields
- Field cloning with modified properties

The `copyWith` method must accept nullable parameters for ALL properties (both from the parent class and custom properties) and return a new instance with updated values using the `?? this.property` pattern. See [Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md#required-implementing-copywith-for-custom-field-classes) for implementation examples.

**Sensible-default convention for field behavior flags.** When adding a new "should this field do X by default?" flag (e.g. `spellCheck`, `autocorrect`), follow the three-layer pattern established by `FormFieldDefaults`:

1. **Default ON in the package.** Pick the value a typical consumer would want and hard-code it as the package fallback. Don't make consumers opt in to common-sense behavior.
2. **Nullable field-level parameter.** Declare the field property as `bool?` (not `bool`) with no default value in the constructor. `null` means "fall through"; `true`/`false` means "explicit override for this field."
3. **Mutable global default in `FormFieldDefaults`.** Add a plain mutable field to the `FormFieldDefaults` singleton (`lib/models/field_defaults_singleton.dart`) so consumers can flip the default app-wide with one line in `main()`.
4. **Resolution chain in the widget layer.** In the field's widget (e.g. `textfieldwidget.dart`), resolve with `field.flag ?? FormFieldDefaults.instance.flag`. Never bake the package default into the model — only the singleton and the widget layer know about it.
5. **Semantic constructors override explicitly.** Named constructors like `.email`/`.password`/`.url` should pass explicit values for behavior flags that don't match their field type (e.g. `spellCheck: false` on `.email`).
6. **Platform gating if the underlying Flutter feature requires it.** If the feature only works on some platforms (e.g. spellcheck only on iOS/Android), add a platform check in the widget so the flag is silently no-op elsewhere rather than throwing.

This pattern keeps the field API small, gives consumers single-line escape hatches at two levels (per-field and app-wide), and avoids polluting every field construction with boilerplate.

`animateValidationErrors` (the validation-wiggle toggle) is another instance of
this exact pattern: it is a nullable `bool?` field-level parameter that falls
through to the mutable `FormFieldDefaults.instance.animateValidationErrors`
singleton default (package default `true`, reduce-motion aware), resolved in
the widget layer with `field.animateValidationErrors ?? FormFieldDefaults.instance.animateValidationErrors`.
The `colors` / `FieldColors` emphasis parameter follows the same spirit but is
non-nullable with an enum default (`FieldColors.normal`) rather than a
`FormFieldDefaults` singleton, since emphasis is inherently a per-field opt-in
rather than an app-wide behavior default.

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

The project underwent a breaking API change in v0.4.0. An automated migration script exists at `tool/project-migration.dart`. When helping users upgrade, reference `MIGRATION-0.4.0.md` for complete migration instructions.

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
- `file_picker` (^13.1.0) - File selection
- `desktop_drop` (^0.8.4) - Drag-and-drop for desktop platforms
- `email_validator` (^3.0.0) - Email validation
- `uuid` (^4.6.0) - Unique ID generation
- `mime` (^2.1.0) - MIME type detection

Minimum requirements:
- Dart SDK: >=3.10.0 <4.0.0
- Flutter SDK: >=3.38.0

## Package Publishing

This is a published package on pub.dev: https://pub.dev/packages/championforms

Current version: 0.8.0-dev.1 (development version; latest release 0.7.2). The
final 0.8.0 is set at release time.

When making changes, ensure:
1. Version is updated in `pubspec.yaml`
2. CHANGELOG.md is updated
3. Breaking changes are clearly documented
4. Migration guides are provided for API changes

Release tags are per package: `championforms-vX.Y.Z`,
`championforms_clipboard-vX.Y.Z`, `championforms_documents-vX.Y.Z`.

Always check the archive before publishing:
```bash
# championforms (repo root). The root .pubignore replaces .gitignore for pub
# and excludes packages/, .github/ and .claude/; keep it in sync with .gitignore.
dart pub publish --dry-run

# Workspace members: hide the enclosing git repo from pub, otherwise the root
# .pubignore rule `packages/` hides the member's own files ("The pubspec is
# hidden"). Each member has its own .pubignore for build outputs.
cd packages/championforms_documents
GIT_CEILING_DIRECTORIES="$(cd .. && pwd)" dart pub publish --dry-run
```
