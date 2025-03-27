# ChampionForms

[![Pub Version](https://img.shields.io/pub/v/championforms)](https://pub.dev/packages/championforms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A declarative Flutter form builder focusing on clean structure, easy validation, state management via a central controller, and customizable theming. Designed to simplify form creation and management.

## Features

*   **Declarative Field Definition:** Define form fields using clear widget classes (`ChampionTextField`, `ChampionOptionSelect`, `ChampionCheckboxSelect`, `ChampionFileUpload`, etc.).
*   **Layout Control:** Structure forms visually using `ChampionRow` and `ChampionColumn` widgets for flexible layouts (responsive collapsing included).
*   **Centralized State Management:** Uses `ChampionFormController` to manage field values, focus, and validation state. Access and update form state from anywhere.
*   **Built-in Validation:** Add validators easily using `FormBuilderValidator` and leverage provided `DefaultValidators` (email, empty, length, numeric, files) or create custom ones. Live validation option available.
*   **Result Handling:** Simple API (`FormResults.getResults`, `results.grab(...)`) to retrieve formatted form data (`asString`, `asStringList`, `asMultiselectList`, `asFile`).
*   **Theming:** Customize the look and feel using `FormTheme`. Apply themes globally (`ChampionFormTheme` singleton), per-form, or per-field. Includes pre-built themes.
*   **Autocomplete:** Add autocomplete suggestions to `ChampionTextField` using `AutoCompleteBuilder`, supporting initial lists and asynchronous fetching.
*   **File Uploads:** `ChampionFileUpload` widget integrates with `file_picker` and supports drag-and-drop, file type restrictions (`allowedExtensions`), and validation.
*   **Controller Interaction:** Programmatically update field values (`updateTextFieldValue`, `toggleMultiSelectValue`) and clear selections (`removeMultiSelectOptions`).

## What's New in v0.0.5

*   **Layout Widgets:** Introduced `ChampionRow` and `ChampionColumn` for structuring form layouts. Columns can collapse vertically using the `collapse` flag.
*   **File Upload Field:** Added `ChampionFileUpload` with drag-and-drop, `file_picker` integration, `allowedExtensions` for filtering, and new `DefaultValidators` (`fileIsImage`, `fileIsDocument`, `isMimeType`).
    *   **Important:** Using `file_picker` (and thus `ChampionFileUpload`) requires adding platform-specific permissions (iOS `Info.plist`, Android `AndroidManifest.xml`, macOS `*.entitlements`). Please refer to the [`file_picker` documentation](https://pub.dev/packages/file_picker#setup) for details.
*   **Autocomplete:** Implemented `AutoCompleteBuilder` for `ChampionTextField` to provide input suggestions. Supports initial options, asynchronous fetching (e.g., from APIs), debouncing, and basic customization.
*   **Global Theming:** Added `ChampionFormTheme` singleton to set a default `FormTheme` for all `ChampionForm` instances in your app.
*   **Enhanced Controller:** `ChampionFormController` now manages `TextEditingController` lifecycles internally, tracks actively rendered fields (`activeFields`), supports field grouping by page (`pageName`, `getPageFields`), and includes new helper methods like `updateTextFieldValue`, `toggleMultiSelectValue`, and `removeMultiSelectOptions`.
*   **New Validators:** Added file-specific validators to `DefaultValidators`.
*   **Various Fixes:** Addressed issues with `asStringList`, multiselect default values, controller updates, and more.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.0.5 # Use the latest version
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

**Remember to configure platform permissions for `file_picker` if using `ChampionFileUpload`.**

## Basic Usage

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart';
// Import other needed types like Row, Column, FileUpload, etc.
import 'package:championforms/models/field_types/championrow.dart';
import 'package:championforms/models/field_types/championcolumn.dart';
import 'package:championforms/models/field_types/championfileupload.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/formresults.dart'; // For result handling

// 1. Define your Controller
final formController = ChampionFormController();

// Optional: Set a Global Theme (e.g., in main() or a root widget)
// Needs context, so often done within a build method or builder initially.
// ChampionFormTheme.instance.setTheme(softBlueColorTheme(context));

// 2. Define your Fields
final List<FormFieldBase> myFields = [
  ChampionRow(columns: [
      ChampionColumn(fields: [
          ChampionTextField(
            id: "name",
            textFieldTitle: "Name",
            validators: [
              FormBuilderValidator(validator: (r) => DefaultValidators().isEmpty(r), reason: "Name is required")
            ],
          ),
      ]),
      ChampionColumn(fields: [
          ChampionTextField(
            id: "email",
            textFieldTitle: "Email",
            autoComplete: AutoCompleteBuilder(initialOptions: [AutoCompleteOption(value:"suggestion@example.com")]),
            validators: [
              FormBuilderValidator(validator: (r) => DefaultValidators().isEmail(r), reason: "Invalid Email")
            ]
          ),
      ]),
  ]),
  ChampionFileUpload(
    id: "avatar",
    title: "Upload Avatar (PNG only)",
    allowedExtensions: ['png'],
    validators: [FormBuilderValidator(validator: (r) => DefaultValidators().fileIsImage(r), reason:"Must be an image")]
  ),
  // ... other fields (Dropdown, Checkbox, etc.)
];

// 3. Build the Form Widget
Widget build(BuildContext context) {
  return Scaffold(
    body: ChampionForm(
      controller: formController,
      fields: myFields,
      spacing: 10.0, // Optional spacing between fields
      // theme: myCustomTheme, // Optional: Override global theme
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: () {
        // 4. Get Results & Validate
        final FormResults results = FormResults.getResults(controller: formController);
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

## Form Controller (`ChampionFormController`)

The controller is the heart of state management.

*   **Initialization:** `final controller = ChampionFormController();`
*   **Disposal:** Crucial! Call `controller.dispose();` in your `StatefulWidget`'s `dispose` method.
*   **Getting Results:** Use `FormResults.getResults(controller: controller)` to trigger validation and get current values.
*   **Updating Values Programmatically:**
    *   `controller.updateTextFieldValue("fieldId", "new text");`
    *   `controller.toggleMultiSelectValue("checkboxFieldId", toggleOn: ["value1", "value2"], toggleOff: ["value3"]);` (Uses the `value` of `MultiselectOption`)
*   **Clearing Selections:**
    *   `controller.removeMultiSelectOptions("fileUploadId");` (Clears all selected files/options)
*   **Accessing State:**
    *   `controller.findTextFieldValue("fieldId")?.value;`
    *   `controller.findMultiselectValue("fieldId")?.values;` (Returns `List<MultiselectOption>`)
    *   `controller.isFieldFocused("fieldId");`
    *   `controller.findErrors("fieldId");`
*   **Page Management:**
    *   Fields can be assigned to a page using the `pageName` property on `ChampionForm`.
    *   `controller.getPageFields("pageName");` retrieves the `FormFieldDef` list for that page. Useful for partial validation or results.
*   **Active Fields:** `controller.activeFields` contains the list of `FormFieldDef` currently rendered by linked `ChampionForm` widgets.

## Field Types

### `ChampionTextField`

Standard text input.

*   `id`: Unique identifier.
*   `textFieldTitle`: Label text that animates to the border.
*   `hintText`: Placeholder text inside the field.
*   `description`: Text displayed above the field.
*   `maxLines`: Number of lines (1 for single line, `null` or >1 for multiline).
*   `password`: Obscures text if true.
*   `leading`/`trailing`/`icon`: Widgets for icons/buttons around the field.
*   `validateLive`: Validate field on focus loss.
*   `validators`: List of `FormBuilderValidator`.
*   `defaultValue`: Initial text value.
*   `onSubmit`: Callback triggered on Enter key press (if `maxLines` is 1 or `null`).
*   `onChange`: Callback triggered on every character change.
*   `autoComplete`: Instance of `AutoCompleteBuilder` to enable suggestions.

### `ChampionOptionSelect` (Base for Dropdown, Checkbox, etc.)

Base class for fields with multiple options.

*   `id`: Unique identifier.
*   `title`/`description`: Field labels.
*   `options`: `List<MultiselectOption>` defining the choices.
    *   `MultiselectOption(label: "Display Text", value: "submitted_value", additionalData: optionalObject)`
*   `multiselect`: Allow multiple selections if true.
*   `defaultValue`: `List<String>` of *values* to select by default.
*   `validators`, `validateLive`, `onSubmit`, `onChange`: Standard properties.
*   `fieldBuilder`: Function to build the actual UI (defaults to dropdown).

### `ChampionCheckboxSelect`

Convenience widget using `ChampionOptionSelect` with a checkbox builder.

*   Inherits properties from `ChampionOptionSelect`.
*   Renders options as a list of checkboxes.

### `ChampionFileUpload`

Specialized field for file uploads.

*   Inherits properties from `ChampionOptionSelect` (options list is unused internally).
*   `multiselect`: Allow multiple file uploads.
*   `allowedExtensions`: `List<String>` (e.g., `['pdf', 'docx']`) to filter files in the picker and during drag-and-drop.
*   `displayUploadedFiles`: Show previews/icons of uploaded files (default: true).
*   `dropDisplayWidget`: Customize the appearance of the drag-and-drop zone.
*   `validators`: Use `DefaultValidators().isEmpty`, `DefaultValidators().fileIsImage(results)`, `DefaultValidators().fileIsDocument(results)`, etc.
*   **Permissions:** Requires platform setup for `file_picker`.

### `ChampionRow` & `ChampionColumn`

Layout widgets.

*   **`ChampionRow`**: Arranges `ChampionColumn` widgets horizontally.
    *   `columns`: `List<ChampionColumn>`.
    *   `collapse`: If true, stacks columns vertically.
    *   `rollUpErrors`: If true, displays errors from all child fields below the row.
*   **`ChampionColumn`**: Arranges standard fields vertically.
    *   `fields`: `List<FormFieldBase>` (can include `ChampionTextField`, `ChampionRow`, etc.).
    *   `columnFlex`: `int` value for `Flexible` widget controlling width distribution within a `ChampionRow`.
    *   `rollUpErrors`: If true, displays errors from all child fields below the column.

## Validation

*   Assign a `List<FormBuilderValidator>` to the `validators` property of a field.
*   `FormBuilderValidator(validator: (results) => /* boolean logic */, reason: "Error message")`
*   `results` is a `FieldResults` object containing the current field value(s). Access data using `results.asString()`, `results.asMultiselectList()`, `results.asFile()`, etc.
*   Use `DefaultValidators()` for common checks:
    *   `isEmpty(results)`
    *   `isEmail(results)`
    *   `isInteger(results)`, `isDouble(results)` (and `OrNull` variants)
    *   `isMimeType(results, ['image/jpeg', 'image/png'])`
    *   `fileIsImage(results)`
    *   `fileIsCommonImage(results)`
    *   `fileIsDocument(results)`
*   Set `validateLive: true` to trigger validation when a field loses focus.
*   Validation is always run when `FormResults.getResults()` is called.

## Theming

ChampionForms uses a `FormTheme` object to control appearance.

*   **Hierarchy:** Default Theme -> Global Theme (Singleton) -> `ChampionForm` Theme -> Field Theme. Specific settings override general ones.
*   **`FormTheme` Properties:** Define `FieldColorScheme` for different states (normal, error, active, disabled, selected), `TextStyle`s (title, description, hint, chip), and `InputDecoration`.
*   **`FieldColorScheme`:** Defines colors (background, border, text, icon, hint) and gradients.
*   **Setting Global Theme:**
    ```dart
    // Somewhere early in your app (needs context)
    ChampionFormTheme.instance.setTheme(softBlueColorTheme(context));
    ```
*   **Setting Form Theme:**
    ```dart
    ChampionForm(
      theme: redAccentFormTheme(context), // Pass a theme object
      controller: controller,
      fields: fields,
    )
    ```
*   **Pre-built Themes:** `softBlueColorTheme`, `redAccentFormTheme`, `iconicColorTheme` are provided. Create your own by defining a `FormTheme` object.

## Getting Results

1.  Call `FormResults results = FormResults.getResults(controller: controller);`
2.  Check `results.errorState` (boolean).
3.  If no errors, access field data: `results.grab("fieldId")` returns `FieldResults`.
4.  Format the `FieldResults`:
    *   `.asString()`: Returns the value(s) as a single string.
    *   `.asStringList()`: Returns values as `List<String>`.
    *   `.asBool()` / `.asBoolMap()`: Interprets values as booleans.
    *   `.asMultiselectList()`: Returns selected options as `List<MultiselectOption>`.
    *   `.asMultiselectSingle()`: Returns the first selected option as `MultiselectOption?`.
    *   `.asFile()`: Returns uploaded files as `List<FileResultData>`, containing name, path, and `FileModel` (with bytes/stream/MIME details).

---

## Contributing

Contributions, issues, and feature requests are welcome!

## License

MIT License.
