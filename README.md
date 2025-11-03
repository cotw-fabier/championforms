# ChampionForms

[![Pub Version](https://img.shields.io/pub/v/championforms)](https://pub.dev/packages/championforms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A declarative Flutter form builder focusing on clean structure, easy validation, state management via a central controller, and customizable theming. Designed to simplify form creation and management.

## Features

*   **Declarative Field Definition:** Define form fields using clear widget classes (`form.TextField`, `form.OptionSelect`, `form.CheckboxSelect`, `form.FileUpload`, etc.).
*   **Layout Control:** Structure forms visually using `form.Row` and `form.Column` widgets for flexible layouts (responsive collapsing included).
*   **Centralized State Management:** Uses `form.FormController` to manage field values, focus, and validation state. Access and update form state from anywhere.
*   **Built-in Validation:** Add validators easily using `form.FormBuilderValidator` and leverage provided `form.DefaultValidators` (email, empty, length, numeric, files) or create custom ones. Live validation option available.
*   **Result Handling:** Simple API (`form.FormResults.getResults`, `results.grab(...)`) to retrieve formatted form data (`asString`, `asStringList`, `asMultiselectList`, `asFile`).
*   **Theming:** Customize the look and feel using `FormTheme`. Apply themes globally (`FormTheme` singleton), per-form, or per-field. Includes pre-built themes.
*   **Autocomplete:** Add autocomplete suggestions to `form.TextField` using `form.AutoCompleteBuilder`, supporting initial lists and asynchronous fetching.
*   **File Uploads:** `form.FileUpload` widget integrates with `file_picker` and supports drag-and-drop, file type restrictions (`allowedExtensions`), and validation.
*   **Controller Interaction:** Programmatically update field values (`updateTextFieldValue`, `toggleMultiSelectValue`) and clear selections (`removeMultiSelectOptions`).

## What's New

### v0.4.0 - API Modernization (Breaking Changes)

Version 0.4.0 modernizes the ChampionForms API by removing the "Champion" prefix from all classes and adopting idiomatic Dart namespace patterns.

**Key Changes:**
*   Cleaner class names: `ChampionTextField` → `form.TextField`
*   Namespace import approach to avoid collisions with Flutter widgets
*   Two-tier export system (form lifecycle vs. theming/configuration)
*   No functional changes - all behavior remains identical

**Migration Required:** If you're upgrading from v0.3.x, please see the [Migration from v0.3.x](#migration-from-v03x) section below.

### v0.3.x Features

*   **Layout Widgets:** Introduced `form.Row` and `form.Column` for structuring form layouts. Columns can collapse vertically using the `collapse` flag.
*   **File Upload Field:** Added `form.FileUpload` with drag-and-drop, `file_picker` integration, `allowedExtensions` for filtering, and new `form.DefaultValidators` (`fileIsImage`, `fileIsDocument`, `isMimeType`).
    *   **Important:** Using `file_picker` (and thus `form.FileUpload`) requires adding platform-specific permissions (iOS `Info.plist`, Android `AndroidManifest.xml`, macOS `*.entitlements`). Please refer to the [`file_picker` documentation](https://pub.dev/packages/file_picker#setup) for details.
*   **Autocomplete:** Implemented `form.AutoCompleteBuilder` for `form.TextField` to provide input suggestions. Supports initial options, asynchronous fetching (e.g., from APIs), debouncing, and basic customization.
*   **Global Theming:** Added `FormTheme` singleton to set a default `FormTheme` for all `form.Form` instances in your app.
*   **Enhanced Controller:** `form.FormController` now manages `TextEditingController` lifecycles internally, tracks actively rendered fields (`activeFields`), supports field grouping by page (`pageName`, `getPageFields`), and includes new helper methods like `updateTextFieldValue`, `toggleMultiSelectValue`, and `removeMultiSelectOptions`.
*   **New Validators:** Added file-specific validators to `form.DefaultValidators`.
*   **Various Fixes:** Addressed issues with `asStringList`, multiselect default values, controller updates, and more.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.4.0 # Use the latest version
  flutter:
    sdk: flutter
  # Required for File Uploads:
  file_picker: ^9.0.0 # Or latest compatible version
  super_drag_and_drop: ^0.9.0 # Or latest compatible version
  super_clipboard: ^0.8.7 # Or latest compatible version
  mime: ^1.0.5 # Or latest compatible version

  # Other dependencies if needed (e.g., email_validator for default email check)
  email_validator: ^2.1.17
```

Then run `flutter pub get`.

**Important:** ChampionForms v0.4.0 uses a namespace import approach. Import the library as:

```dart
import 'package:championforms/championforms.dart' as form;
```

This prevents naming collisions with Flutter's built-in `Form`, `Row`, and `Column` widgets.

**Remember to configure platform permissions for `file_picker` if using `form.FileUpload`.**

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;
// For theming (typically once in main.dart):
// import 'package:championforms/championforms_themes.dart';

// 1. Define your Controller
final formController = form.FormController();

// Optional: Set a Global Theme (e.g., in main() or a root widget)
// Needs context, so often done within a build method or builder initially.
// FormTheme.instance.setTheme(softBlueColorTheme(context));

// 2. Define your Fields
final List<form.FieldBase> myFields = [
  form.Row(columns: [
      form.Column(fields: [
          form.TextField(
            id: "name",
            textFieldTitle: "Name",
            validators: [
              form.FormBuilderValidator(
                validator: (r) => form.DefaultValidators().isEmpty(r),
                reason: "Name is required"
              )
            ],
          ),
      ]),
      form.Column(fields: [
          form.TextField(
            id: "email",
            textFieldTitle: "Email",
            autoComplete: form.AutoCompleteBuilder(
              initialOptions: [form.AutoCompleteOption(value:"suggestion@example.com")]
            ),
            validators: [
              form.FormBuilderValidator(
                validator: (r) => form.DefaultValidators().isEmail(r),
                reason: "Invalid Email"
              )
            ]
          ),
      ]),
  ]),
  form.FileUpload(
    id: "avatar",
    title: "Upload Avatar (PNG only)",
    allowedExtensions: ['png'],
    validators: [
      form.FormBuilderValidator(
        validator: (r) => form.DefaultValidators().fileIsImage(r),
        reason:"Must be an image"
      )
    ]
  ),
  // ... other fields (Dropdown, Checkbox, etc.)
];

// 3. Build the Form Widget
Widget build(BuildContext context) {
  return Scaffold(
    body: form.Form(
      controller: formController,
      fields: myFields,
      spacing: 10.0, // Optional spacing between fields
      // theme: myCustomTheme, // Optional: Override global theme
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        // 4. Get Results & Validate
        final form.FormResults results = form.FormResults.getResults(controller: formController);
        if (!results.errorState) {
          print("Name: ${results.grab("name").asString()}");
          print("Email: ${results.grab("email").asString()}");
          final files = results.grab("avatar").asFile();
          if(files.isNotEmpty) print("Avatar filename: ${files.first.name}");
        } else {
          print("Form has errors: ${results.formErrors}");
        }
      },
      child: Icon(Icons.check),
    ),
  );
}
```

## Form Controller (`form.FormController`)

The controller is the heart of state management.

*   **Initialization:** `final controller = form.FormController();`
*   **Disposal:** Crucial! Call `controller.dispose();` in your `StatefulWidget`'s `dispose` method.
*   **Getting Results:** Use `form.FormResults.getResults(controller: controller)` to trigger validation and get current values.
*   **Updating Values Programmatically:**
    *   `controller.updateTextFieldValue("fieldId", "new text");`
    *   `controller.toggleMultiSelectValue("checkboxFieldId", toggleOn: ["value1", "value2"], toggleOff: ["value3"]);` (Uses the `value` of `form.MultiselectOption`)
*   **Clearing Selections:**
    *   `controller.removeMultiSelectOptions("fileUploadId");` (Clears all selected files/options)
*   **Accessing State:**
    *   `controller.findTextFieldValue("fieldId")?.value;`
    *   `controller.findMultiselectValue("fieldId")?.values;` (Returns `List<form.MultiselectOption>`)
    *   `controller.isFieldFocused("fieldId");`
    *   `controller.findErrors("fieldId");`
*   **Page Management:**
    *   Fields can be assigned to a page using the `pageName` property on `form.Form`.
    *   `controller.getPageFields("pageName");` retrieves the `form.Field` list for that page. Useful for partial validation or results.
*   **Active Fields:** `controller.activeFields` contains the list of `form.Field` currently rendered by linked `form.Form` widgets.

## Field Types

### `form.TextField`

Standard text input.

*   `id`: Unique identifier.
*   `textFieldTitle`: Label text that animates to the border.
*   `hintText`: Placeholder text inside the field.
*   `description`: Text displayed above the field.
*   `maxLines`: Number of lines (1 for single line, `null` or >1 for multiline).
*   `password`: Obscures text if true.
*   `leading`/`trailing`/`icon`: Widgets for icons/buttons around the field.
*   `validateLive`: Validate field on focus loss.
*   `validators`: List of `form.FormBuilderValidator`.
*   `defaultValue`: Initial text value.
*   `onSubmit`: Callback triggered on Enter key press (if `maxLines` is 1 or `null`).
*   `onChange`: Callback triggered on every character change.
*   `autoComplete`: Instance of `form.AutoCompleteBuilder` to enable suggestions.

### `form.OptionSelect` (Base for Dropdown, Checkbox, etc.)

Base class for fields with multiple options.

*   `id`: Unique identifier.
*   `title`/`description`: Field labels.
*   `options`: `List<form.MultiselectOption>` defining the choices.
    *   `form.MultiselectOption(label: "Display Text", value: "submitted_value", additionalData: optionalObject)`
*   `multiselect`: Allow multiple selections if true.
*   `defaultValue`: `List<String>` of *values* to select by default.
*   `validators`, `validateLive`, `onSubmit`, `onChange`: Standard properties.
*   `fieldBuilder`: Function to build the actual UI (defaults to dropdown).

### `form.CheckboxSelect`

Convenience widget using `form.OptionSelect` with a checkbox builder.

*   Inherits properties from `form.OptionSelect`.
*   Renders options as a list of checkboxes.

### `form.FileUpload`

Specialized field for file uploads.

*   Inherits properties from `form.OptionSelect` (options list is unused internally).
*   `multiselect`: Allow multiple file uploads.
*   `allowedExtensions`: `List<String>` (e.g., `['pdf', 'docx']`) to filter files in the picker and during drag-and-drop.
*   `displayUploadedFiles`: Show previews/icons of uploaded files (default: true).
*   `dropDisplayWidget`: Customize the appearance of the drag-and-drop zone.
*   `validators`: Use `form.DefaultValidators().isEmpty`, `form.DefaultValidators().fileIsImage(results)`, `form.DefaultValidators().fileIsDocument(results)`, etc.
*   **Permissions:** Requires platform setup for `file_picker`.

### `form.Row` & `form.Column`

Layout widgets.

*   **`form.Row`**: Arranges `form.Column` widgets horizontally.
    *   `columns`: `List<form.Column>`.
    *   `collapse`: If true, stacks columns vertically.
    *   `rollUpErrors`: If true, displays errors from all child fields below the row.
*   **`form.Column`**: Arranges standard fields vertically.
    *   `fields`: `List<form.FieldBase>` (can include `form.TextField`, `form.Row`, etc.).
    *   `columnFlex`: `int` value for `Flexible` widget controlling width distribution within a `form.Row`.
    *   `rollUpErrors`: If true, displays errors from all child fields below the column.

## Validation

*   Assign a `List<form.FormBuilderValidator>` to the `validators` property of a field.
*   `form.FormBuilderValidator(validator: (results) => /* boolean logic */, reason: "Error message")`
*   `results` is a `form.FieldResults` object containing the current field value(s). Access data using `results.asString()`, `results.asMultiselectList()`, `results.asFile()`, etc.
*   Use `form.DefaultValidators()` for common checks:
    *   `isEmpty(results)`
    *   `isEmail(results)`
    *   `isInteger(results)`, `isDouble(results)` (and `OrNull` variants)
    *   `isMimeType(results, ['image/jpeg', 'image/png'])`
    *   `fileIsImage(results)`
    *   `fileIsCommonImage(results)`
    *   `fileIsDocument(results)`
*   Set `validateLive: true` to trigger validation when a field loses focus.
*   Validation is always run when `form.FormResults.getResults()` is called.

## Theming

ChampionForms uses a `FormTheme` object to control appearance.

*   **Hierarchy:** Default Theme -> Global Theme (Singleton) -> `form.Form` Theme -> Field Theme. Specific settings override general ones.
*   **`FormTheme` Properties:** Define `FieldColorScheme` for different states (normal, error, active, disabled, selected), `TextStyle`s (title, description, hint, chip), and `InputDecoration`.
*   **`FieldColorScheme`:** Defines colors (background, border, text, icon, hint) and gradients.
*   **Setting Global Theme:**
    ```dart
    // Import the themes export file
    import 'package:championforms/championforms_themes.dart';

    // Somewhere early in your app (needs context)
    FormTheme.instance.setTheme(softBlueColorTheme(context));
    ```
*   **Setting Form Theme:**
    ```dart
    // Import the themes export file
    import 'package:championforms/championforms_themes.dart';

    form.Form(
      theme: redAccentFormTheme(context), // Pass a theme object
      controller: controller,
      fields: fields,
    )
    ```
*   **Pre-built Themes:** `softBlueColorTheme`, `redAccentFormTheme`, `iconicColorTheme` are provided. Create your own by defining a `FormTheme` object.

**Note:** Theme-related classes (`FormTheme`, pre-built themes, `FormFieldRegistry`) are exported from `package:championforms/championforms_themes.dart` and don't use the `form.` namespace prefix.

## Getting Results

1.  Call `form.FormResults results = form.FormResults.getResults(controller: controller);`
2.  Check `results.errorState` (boolean).
3.  If no errors, access field data: `results.grab("fieldId")` returns `form.FieldResults`.
4.  Format the `form.FieldResults`:
    *   `.asString()`: Returns the value(s) as a single string.
    *   `.asStringList()`: Returns values as `List<String>`.
    *   `.asBool()` / `.asBoolMap()`: Interprets values as booleans.
    *   `.asMultiselectList()`: Returns selected options as `List<form.MultiselectOption>`.
    *   `.asMultiselectSingle()`: Returns the first selected option as `form.MultiselectOption?`.
    *   `.asFile()`: Returns uploaded files as `List<form.FileResultData>`, containing name, path, and `FileModel` (with bytes/stream/MIME details).

## Migration from v0.3.x

Version 0.4.0 is a **breaking change release**. If you're upgrading from v0.3.x, you need to migrate your code to use the new namespace approach.

### Quick Migration Overview

**What Changed:**
- All class names lost their "Champion" prefix
- Imports now require namespace alias (`as form`)
- Two-tier export system (lifecycle vs. themes)

**What Stayed the Same:**
- All functionality and behavior
- All field types and their properties
- Validation system, theme system, controller API
- Form state management and result handling

### Migration Options

1. **Automated Migration (Recommended):** Use the provided migration script (~5-15 minutes)
   ```bash
   dart run tools/project-migration.dart /path/to/your/flutter/project
   ```

2. **Manual Migration:** Follow the step-by-step guide in [MIGRATION-0.4.0.md](MIGRATION-0.4.0.md) (~30-60 minutes)

### Quick Example

**Before (v0.3.x):**
```dart
import 'package:championforms/championforms.dart';

ChampionFormController controller = ChampionFormController();
ChampionForm(
  controller: controller,
  fields: [
    ChampionTextField(id: 'email', textFieldTitle: 'Email'),
  ],
)
```

**After (v0.4.0):**
```dart
import 'package:championforms/championforms.dart' as form;

form.FormController controller = form.FormController();
form.Form(
  controller: controller,
  fields: [
    form.TextField(id: 'email', textFieldTitle: 'Email'),
  ],
)
```

### Full Migration Guide

For complete migration instructions, before/after examples, common issues, and FAQ, please see:

**[MIGRATION-0.4.0.md](MIGRATION-0.4.0.md)**

The migration guide covers:
- Why we changed the API
- Comprehensive before/after examples
- Find-and-replace reference table
- Step-by-step manual migration instructions
- Automated migration script usage
- Common issues and FAQ
- Version checklist

## Advanced Usage

### Custom Field Registration

If you're creating custom field types, you can register them with the `FormFieldRegistry`:

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

// Register your custom field builder
FormFieldRegistry.instance.registerField(
  'myCustomField',
  (field) => buildMyCustomField(field),
);
```

### Controller Extensions

The `TextFieldController` extension on `form.FormController` provides convenient methods for text field manipulation:

```dart
import 'package:championforms/championforms.dart' as form;

final controller = form.FormController();

// Update a text field value
controller.updateTextFieldValue("fieldId", "new value");

// Toggle multiselect options
controller.toggleMultiSelectValue(
  "checkboxId",
  toggleOn: ["option1", "option2"],
  toggleOff: ["option3"],
);

// Clear all multiselect options
controller.removeMultiSelectOptions("fieldId");
```

---

## Contributing

Contributions, issues, and feature requests are welcome!

## License

MIT License.
