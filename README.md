# ChampionForms

[![Pub Version](https://img.shields.io/pub/v/championforms)](https://pub.dev/packages/championforms)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A declarative Flutter form builder focusing on clean structure, easy validation, state management via a central controller, and customizable theming. Designed to simplify form creation and management.

## Documentation

📚 **[Complete Documentation](docs/README.md)** - Comprehensive guides, API references, and examples

### Quick Links
- **[Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md)** - 6 practical examples for creating custom fields
- **[Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md)** - Upgrade to simplified custom field API
- **[Migration Guide v0.3.x → v0.4.0](docs/migrations/MIGRATION-0.4.0.md)** - Upgrade to namespace-based API

## Features

*   **Declarative Field Definition:** Define form fields using clear widget classes (`form.TextField`, `form.OptionSelect`, `form.CheckboxSelect`, `form.FileUpload`, etc.).
*   **Layout Control:** Structure forms visually using `form.Row` and `form.Column` widgets for flexible layouts (responsive collapsing included).
*   **Centralized State Management:** Uses `form.FormController` to manage field values, focus, and validation state. Access and update form state from anywhere.
*   **Built-in Validation:** Add validators easily using `form.Validator` and leverage provided `form.Validators` (email, empty, length, numeric, files) or create custom ones. Live validation option available.
*   **Result Handling:** Simple API (`form.FormResults.getResults`, `results.grab(...)`) to retrieve formatted form data (`asString`, `asStringList`, `asMultiselectList`, `asFile`, `asCompound`).
*   **Theming:** Customize the look and feel using `FormTheme`. Apply themes globally (`FormTheme` singleton), per-form, or per-field. Includes pre-built themes.
*   **Autocomplete:** Add autocomplete suggestions to `form.TextField` using `form.AutoCompleteBuilder`, supporting initial lists and asynchronous fetching.
*   **File Uploads:** `form.FileUpload` widget integrates with `file_picker` and supports drag-and-drop, file type restrictions (`allowedExtensions`), and validation.
*   **Controller Interaction:** Programmatically update field values (`updateTextFieldValue`, `toggleMultiSelectValue`) and clear selections (`removeMultiSelectOptions`).
*   **🆕 Compound Fields:** Create reusable composite fields (like `form.NameField`, `form.AddressField`) that group multiple sub-fields with custom layouts. Sub-fields act as independent fields with automatic ID prefixing.
*   **🆕 Simplified Custom Fields (v0.6.0+):** Create custom fields with 60-70% less boilerplate using `StatefulFieldWidget` and `FieldBuilderContext`.

## What's New

### Compound Fields - Reusable Field Groups (Latest)

ChampionForms now supports **compound fields** - composite fields made up of multiple sub-fields that work together as a cohesive unit while maintaining full controller transparency.

**Key Features:**
- **Built-in Fields:** `form.NameField` and `form.AddressField` ready to use out of the box
- **Automatic ID Prefixing:** Sub-fields get prefixed IDs (e.g., `address_street`, `address_city`) to prevent conflicts
- **Controller Transparency:** Sub-fields behave like normal fields - all existing controller methods work unchanged
- **Custom Layouts:** Each compound field can have its own layout (horizontal, multi-row, etc.)
- **Flexible Results Access:** Access compound values as joined strings or individual sub-field values

**Example Usage:**
```dart
// Use built-in NameField
form.NameField(
  id: 'customer_name',
  title: 'Full Name',
  includeMiddleName: true, // Optional middle name field
)

// Use built-in AddressField
form.AddressField(
  id: 'shipping_address',
  title: 'Shipping Address',
  includeStreet2: true,    // Optional apt/suite field
  includeCountry: false,   // Optional country field
)

// Access results
final fullName = results.grab('customer_name').asCompound(delimiter: ' ');
final street = results.grab('shipping_address_street').asString();
final fullAddress = results.grab('shipping_address').asCompound(delimiter: ', ');
```

**Create Custom Compound Fields:**
Register your own reusable compound fields with custom sub-field definitions and layouts:

```dart
FormFieldRegistry.registerCompound<MyCustomField>(
  'custom',
  (field) => [
    form.TextField(id: 'sub1'),
    form.TextField(id: 'sub2'),
  ],
  (context, subFields, errors) => Row(
    children: subFields.map((f) => Expanded(child: f)).toList(),
  ),
);
```

See the [example app's compound fields demo](example/lib/pages/compound_fields_demo.dart) for a complete interactive demonstration.

### v0.6.0 - Simplified Custom Field API (Breaking Changes)

Version 0.6.0 dramatically simplifies custom field creation by reducing boilerplate from **120-150 lines to 30-50 lines** (60-70% reduction).

**New Features:**
- **FieldBuilderContext** - Bundles 6 parameters into one clean context object
- **StatefulFieldWidget** - Abstract base class with automatic lifecycle management
- **Converter Mixins** - Reusable type conversion logic
- **Simplified FormFieldRegistry** - Static registration methods

**Who This Affects:**
- ✅ **Custom field developers**: If you've created custom field types, you need to migrate
- ❌ **Regular users**: If you only use built-in fields (TextField, OptionSelect, FileUpload), **no changes required**

**Migration:**
- **[Migration Guide v0.5.x → v0.6.0](docs/migrations/MIGRATION-0.6.0.md)** - Complete upgrade instructions
- **[Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md)** - Updated examples using new API
- **[StatefulFieldWidget Guide](docs/custom-fields/stateful-field-widget.md)** - Learn the base class pattern
- **[FieldBuilderContext API](docs/custom-fields/field-builder-context.md)** - Context object reference

### v0.4.0 - API Modernization (Breaking Changes)

Version 0.4.0 modernizes the ChampionForms API by removing the "Champion" prefix from all classes and adopting idiomatic Dart namespace patterns.

**Key Changes:**
*   Cleaner class names: `ChampionTextField` → `form.TextField`
*   Namespace import approach to avoid collisions with Flutter widgets
*   Two-tier export system (form lifecycle vs. theming/configuration)
*   No functional changes - all behavior remains identical

**Migration Required:** If you're upgrading from v0.3.x, please see the **[Migration Guide v0.3.x → v0.4.0](docs/migrations/MIGRATION-0.4.0.md)**.

### v0.3.x Features

*   **Layout Widgets:** Introduced `form.Row` and `form.Column` for structuring form layouts. Columns can collapse vertically using the `collapse` flag.
*   **File Upload Field:** Added `form.FileUpload` with drag-and-drop, `file_picker` integration, `allowedExtensions` for filtering, and new `form.Validators` methods (`fileIsImage`, `fileIsDocument`, `isMimeType`).
    *   **Important:** Using `file_picker` (and thus `form.FileUpload`) requires adding platform-specific permissions (iOS `Info.plist`, Android `AndroidManifest.xml`, macOS `*.entitlements`). Please refer to the [`file_picker` documentation](https://pub.dev/packages/file_picker#setup) for details.
*   **Autocomplete:** Implemented `form.AutoCompleteBuilder` for `form.TextField` to provide input suggestions. Supports initial options, asynchronous fetching (e.g., from APIs), debouncing, and basic customization.
*   **Global Theming:** Added `FormTheme` singleton to set a default `FormTheme` for all `form.Form` instances in your app.
*   **Enhanced Controller:** `form.FormController` now manages `TextEditingController` lifecycles internally, tracks actively rendered fields (`activeFields`), supports field grouping by page (`pageName`, `getPageFields`), and includes new helper methods like `updateTextFieldValue`, `toggleMultiSelectValue`, and `removeMultiSelectOptions`.
*   **New Validators:** Added file-specific validators to `form.Validators`.
*   **Various Fixes:** Addressed issues with `asStringList`, multiselect default values, controller updates, and more.

## Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.6.0 # Use the latest version
  flutter:
    sdk: flutter
  # Required for File Uploads:
  file_picker: ^10.0.0 # Or latest compatible version
  desktop_drop: ^0.7.0 # Or latest compatible version (for drag-and-drop on desktop)
  mime: ^2.0.0 # Or latest compatible version

  # Other dependencies if needed (e.g., email_validator for default email check)
  email_validator: ^3.0.0
```

Then run `flutter pub get`.

**Important:** ChampionForms v0.4.0+ uses a namespace import approach. Import the library as:

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
              form.Validator(
                validator: (r) => form.Validators.isEmpty(r),
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
              initialOptions: [form.CompleteOption(value:"suggestion@example.com")]
            ),
            validators: [
              form.Validator(
                validator: (r) => form.Validators.isEmail(r),
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
      form.Validator(
        validator: (r) => form.Validators.fileIsImage(r),
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

## Custom Fields (v0.6.0+)

Creating custom fields is now dramatically simpler with the v0.6.0 API:

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class RatingFieldWidget extends form.StatefulFieldWidget {
  const RatingFieldWidget({required super.context});

  @override
  Widget buildWithTheme(
    BuildContext buildContext,
    FormTheme theme,
    form.FieldBuilderContext ctx,
  ) {
    final rating = ctx.getValue<int>() ?? 0;

    return Row(
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < rating ? Icons.star : Icons.star_border,
            color: ctx.colors.iconColor,
          ),
          onPressed: () => ctx.setValue<int>(index + 1),
        );
      }),
    );
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    if (context.field.onChange != null) {
      final results = form.FormResults.getResults(controller: context.controller);
      context.field.onChange!(results);
    }
  }
}
```

**That's it!** ~30 lines vs ~120 lines in the old API.

For more examples, see the **[Custom Field Cookbook](docs/custom-fields/custom-field-cookbook.md)** with 6 complete, working examples:
1. Phone number field with formatting
2. Tag selector with autocomplete
3. Rich text editor field
4. Date/time picker field
5. Signature pad field
6. File upload with preview enhancement

## Form Controller (`form.FormController`)

The controller is the heart of state management.

*   **Initialization:** `final controller = form.FormController();`
*   **Disposal:** Crucial! Call `controller.dispose();` in your `StatefulWidget`'s `dispose` method.
*   **Getting Results:** Use `form.FormResults.getResults(controller: controller)` to trigger validation and get current values.
*   **Updating Values Programmatically:**
    *   `controller.updateTextFieldValue("fieldId", "new text");`
    *   `controller.toggleMultiSelectValue("checkboxFieldId", toggleOn: ["value1", "value2"], toggleOff: ["value3"]);` (Uses the `value` of `form.FieldOption`)
*   **Clearing Selections:**
    *   `controller.removeMultiSelectOptions("fileUploadId");` (Clears all selected files/options)
*   **Accessing State:**
    *   `controller.findTextFieldValue("fieldId")?.value;`
    *   `controller.findMultiselectValue("fieldId")?.values;` (Returns `List<form.FieldOption>`)
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
*   `validators`: List of `form.Validator`.
*   `defaultValue`: Initial text value.
*   `onSubmit`: Callback triggered on Enter key press (if `maxLines` is 1 or `null`).
*   `onChange`: Callback triggered on every character change.
*   `autoComplete`: Instance of `form.AutoCompleteBuilder` to enable suggestions.

### `form.OptionSelect` (Base for Dropdown, Checkbox, etc.)

Base class for fields with multiple options.

*   `id`: Unique identifier.
*   `title`/`description`: Field labels.
*   `options`: `List<form.FieldOption>` defining the choices.
    *   `form.FieldOption(label: "Display Text", value: "submitted_value", additionalData: optionalObject)`
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
*   `validators`: Use `form.Validators.isEmpty`, `form.Validators.fileIsImage(results)`, `form.Validators.fileIsDocument(results)`, etc.
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

*   Assign a `List<form.Validator>` to the `validators` property of a field.
*   `form.Validator(validator: (results) => /* boolean logic */, reason: "Error message")`
*   `results` is a `form.FieldResults` object containing the current field value(s). Access data using `results.asString()`, `results.asMultiselectList()`, `results.asFile()`, etc.
*   Use `form.Validators` for common checks:
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
    *   `.asMultiselectList()`: Returns selected options as `List<form.FieldOption>`.
    *   `.asMultiselectSingle()`: Returns the first selected option as `form.FieldOption?`.
    *   `.asFile()`: Returns uploaded files as `List<form.FileResultData>`, containing name, path, and `FileModel` (with bytes/stream/MIME details).

## Contributing

Contributions, issues, and feature requests are welcome!

## License

MIT License.
