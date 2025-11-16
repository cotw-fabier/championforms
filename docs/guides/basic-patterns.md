# Basic Patterns Guide

Essential patterns for working with ChampionForms.

## Table of Contents
- [Import Pattern](#import-pattern)
- [Controller Pattern](#controller-pattern)
- [Field Definition Pattern](#field-definition-pattern)
- [Validation Pattern](#validation-pattern)
- [Results Handling Pattern](#results-handling-pattern)
- [Programmatic Updates Pattern](#programmatic-updates-pattern)
- [Layout Patterns](#layout-patterns)
- [Theme Pattern](#theme-pattern)
- [Submit Pattern](#submit-pattern)
- [Common Patterns Summary](#common-patterns-summary)
- [Best Practices](#best-practices)
- [Complete Example](#complete-example)

## Import Pattern

### The Namespace Import

ChampionForms uses a namespace-based import pattern to avoid naming conflicts with Flutter's built-in widgets.

```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart'; // For themes
```

### Why 'as form'?

1. **Prevents Conflicts** - Flutter already has `Form`, `Row`, and `Column` widgets
2. **Clean Code** - Clear distinction between framework widgets and form fields
3. **Two-Tier System** - Lifecycle classes vs theming classes

### What's Available

**With `form.` prefix** (from `championforms.dart`):
- `form.FormController` - State management
- `form.Form` - Form widget
- `form.TextField`, `form.OptionSelect`, `form.FileUpload` - Field types
- `form.Row`, `form.Column` - Layout widgets
- `form.Validator`, `form.Validators` - Validation
- `form.FormResults`, `form.FieldResults` - Results handling
- `form.FieldOption`, `form.CompleteOption` - Data models

**Without prefix** (from `championforms_themes.dart`):
- `FormTheme` - Theme configuration
- `FieldColorScheme` - Color definitions
- `FormThemeSingleton` - Global theme management
- `softBlueColorTheme()`, `redAccentFormTheme()` - Pre-built themes
- `FormFieldRegistry` - Custom field registration

## Controller Pattern

### Lifecycle Management

The `FormController` is the heart of form state management and has a strict lifecycle that must be followed.

#### Initialization Pattern

Initialize the controller in `initState()`:

```dart
class _MyFormPageState extends State<MyFormPage> {
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
    // Optionally provide an ID for multi-form scenarios:
    // controller = form.FormController(id: "myFormId");
  }
```

#### Disposal Pattern (CRITICAL)

**Always dispose the controller** to prevent memory leaks:

```dart
  @override
  void dispose() {
    controller.dispose(); // MUST dispose!
    super.dispose();
  }
}
```

#### Why Disposal Matters

The controller manages many resources that need cleanup:
- `TextEditingController` instances for each text field
- `FocusNode` instances for focus tracking
- `ValueNotifier` instances for state updates
- Internal listeners and subscriptions

**Failing to dispose will cause memory leaks in production apps.**

### Controller as Single Source of Truth

The controller owns all form state:

- **Field Values** - Stored in `fieldValues` map (generic storage)
- **Focus States** - Tracked via `focusListenable` map
- **Validation Errors** - Maintained in `formErrors` list
- **TextEditingControllers** - Managed internally for text fields
- **Active Fields** - Tracks currently rendered fields

This centralization enables:
- Programmatic updates from anywhere
- Consistent validation behavior
- Easy form serialization/deserialization
- Multi-step form navigation

## Field Definition Pattern

### Basic Structure

Define fields as a list of `FormElement` objects:

```dart
final List<form.FormElement> fields = [
  form.TextField(id: 'email', ...),
  form.OptionSelect(id: 'country', ...),
  form.FileUpload(id: 'avatar', ...),
];
```

### Common Properties

Every field inherits these properties from `FieldBase`:

| Property | Type | Purpose |
|----------|------|---------|
| `id` | `String` | **Required.** Unique identifier for accessing field value |
| `title` / `description` | `String?` | Field labels and help text |
| `validators` | `List<Validator>` | Validation rules |
| `defaultValue` | `dynamic` | Initial value (type varies by field) |
| `validateLive` | `bool` | Validate on focus loss (default: `false`) |
| `onChange` | `Function?` | Callback on value change |
| `onSubmit` | `Function?` | Callback on Enter key (text fields) |

### Field Definition Examples

#### Text Field Pattern

```dart
form.TextField(
  id: "email",
  textFieldTitle: "Email Address",
  hintText: "Enter your email",
  description: "Your login email.",
  maxLines: 1,
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.stringIsNotEmpty(results),
      reason: "Email cannot be empty.",
    ),
    form.Validator(
      validator: (results) => form.Validators.isEmail(results),
      reason: "Please enter a valid email address.",
    ),
  ],
  leading: const Icon(Icons.email),
)
```

**Key properties:**
- `password: true` - Obscure text for passwords
- `maxLines: 1` - Single-line input (enables Enter key submit)
- `maxLines: null` or `> 1` - Multi-line text area
- `leading`, `trailing`, `icon` - Icons/widgets around field

#### Dropdown Pattern

```dart
form.OptionSelect(
  id: "country",
  title: "Select Country",
  description: "Choose your country.",
  defaultValue: [
    form.FieldOption(label: "United States", value: "US"),
  ],
  options: [
    form.FieldOption(label: "United States", value: "US"),
    form.FieldOption(label: "Canada", value: "CA"),
    form.FieldOption(label: "Mexico", value: "MX"),
  ],
)
```

**Key properties:**
- `multiselect: true` - Allow multiple selections
- `options` - List of `FieldOption` (label shown, value submitted)
- `defaultValue` - List of `FieldOption` instances

#### Checkbox Pattern

```dart
form.CheckboxSelect(
  id: "interests",
  title: "Choose Interests",
  description: "Select all that apply.",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (results) => form.Validators.listIsNotEmpty(results),
      reason: "Please select at least one option.",
    ),
  ],
  defaultValue: [
    form.FieldOption(value: "reading", label: "Reading"),
  ],
  options: [
    form.FieldOption(value: "reading", label: "Reading"),
    form.FieldOption(value: "sports", label: "Sports"),
    form.FieldOption(value: "music", label: "Music"),
  ],
)
```

**Note:** `CheckboxSelect` is a convenience wrapper around `OptionSelect` with a checkbox field builder.

#### File Upload Pattern

```dart
form.FileUpload(
  id: "documents",
  title: "Upload Documents",
  description: "Drag & drop or click to upload (PDF, DOCX only).",
  multiselect: true,
  validateLive: true,
  allowedExtensions: ['pdf', 'docx'],
  validators: [
    form.Validator(
      reason: "Only PDF or DOCX files allowed.",
      validator: (results) => form.Validators.fileIsDocument(results),
    ),
  ],
)
```

**Key properties:**
- `allowedExtensions` - Restrict file types (affects both picker and drag-drop)
- `displayUploadedFiles` - Show file previews (default: `true`)
- `clearOnUpload` - Clear previous files when new ones selected
- `dropDisplayWidget` - Customize drop zone appearance

**Platform Setup Required:** File uploads require platform permissions. See [file_picker documentation](https://pub.dev/packages/file_picker#setup) for iOS, Android, and macOS configuration.

## Validation Pattern

### Inline Validators

Validators are attached directly to field definitions:

```dart
validators: [
  form.Validator(
    validator: (results) => form.Validators.stringIsNotEmpty(results),
    reason: "Field is required",
  ),
  form.Validator(
    validator: (results) => results.asString().length >= 8,
    reason: "Must be at least 8 characters",
  ),
],
```

### Validator Anatomy

```dart
form.Validator(
  validator: (FieldResultAccessor results) {
    // Access field value
    final value = results.asString();
    // Return true if valid, false if invalid
    return value.isNotEmpty && value.length >= 3;
  },
  reason: "Error message shown to user when validation fails",
)
```

The `results` parameter provides type-safe access:
- `results.asString()` - Text field value
- `results.asMultiselectList()` - Selected options
- `results.asFileList()` - Uploaded files
- `results.asBool()` - Checkbox state

### Live vs Submit Validation

**Live Validation** (`validateLive: true`):
- Triggers when field loses focus (on blur)
- Provides immediate feedback
- Best for critical fields (email, password)

```dart
form.TextField(
  id: "email",
  validateLive: true, // Validate on blur
  validators: [...],
)
```

**Submit Validation** (default):
- Triggers when `FormResults.getResults()` is called
- Validates all fields at once
- Best for less critical fields

### Multiple Validators Pattern

Validators run in order. **Order matters** - put simple checks first:

```dart
validators: [
  // 1. Check if empty (fast, common failure)
  form.Validator(
    validator: (results) => form.Validators.stringIsNotEmpty(results),
    reason: "Email cannot be empty.",
  ),
  // 2. Check format (slower, runs only if not empty)
  form.Validator(
    validator: (results) => form.Validators.isEmail(results),
    reason: "Please enter a valid email address.",
  ),
],
```

### Built-in Validators

Use `form.Validators` for common checks:

**String validators:**
- `stringIsNotEmpty(results)` - Not empty or whitespace-only
- `isEmail(results)` - Valid email format
- `isInteger(results)` - Can parse as int
- `isDouble(results)` - Can parse as double

**List validators:**
- `listIsNotEmpty(results)` - At least one selection

**File validators:**
- `fileIsImage(results)` - All files are images
- `fileIsCommonImage(results)` - Common image types (JPG, PNG, GIF, WebP)
- `fileIsDocument(results)` - Common document types (PDF, DOC, TXT, etc.)
- `isMimeType(results, ['image/jpeg', 'image/png'])` - Specific MIME types

### Custom Validator Example

```dart
form.Validator(
  validator: (results) {
    final password = results.asString();
    // Custom logic: must contain a number
    return RegExp(r'\d').hasMatch(password);
  },
  reason: "Password must contain at least one number",
)
```

## Results Handling Pattern

### Standard Flow

The results flow follows these steps:

#### 1. Get Results (Triggers Validation)

```dart
void _handleSubmit() {
  final results = form.FormResults.getResults(controller: controller);
```

**This single call:**
- Validates all fields (runs all validators)
- Collects current field values
- Compiles error list
- Returns immutable snapshot

#### 2. Check Error State

```dart
  if (!results.errorState) {
    // No errors - process form
    _processSuccessfulSubmit(results);
  } else {
    // Has errors - show to user
    _showValidationErrors(results);
  }
}
```

#### 3. Access Values

```dart
void _processSuccessfulSubmit(form.FormResults results) {
  // Text fields
  final email = results.grab('email').asString();
  final bio = results.grab('bio').asString();

  // Dropdown/select fields
  final country = results.grab('country').asString();

  // Checkbox/multiselect fields
  final interests = results.grab('interests').asMultiselectList();
  final interestValues = interests.map((opt) => opt.value).toList();

  // File upload fields
  final files = results.grab('documents').asFileList();
  for (final file in files) {
    print('File: ${file.fileName}, MIME: ${file.mimeData?.mime}');
  }

  // Compound fields
  final fullName = results.grab('name').asCompound(delimiter: ' ');
  final firstName = results.grab('name_first').asString();
}
```

### Type-Safe Access Pattern

The `grab()` method returns a `FieldResultAccessor` with type conversion methods:

| Method | Return Type | Use For |
|--------|-------------|---------|
| `asString()` | `String` | Text fields, single selects |
| `asStringList()` | `List<String>` | Multiselect values only |
| `asBool()` | `bool` | Single checkbox |
| `asBoolMap()` | `Map<String, bool>` | Multiple checkboxes |
| `asMultiselectList()` | `List<FieldOption>` | Full option objects |
| `asMultiselectSingle()` | `FieldOption?` | First selected option |
| `asFileList()` | `List<FileResultData>` | Uploaded files |
| `asCompound()` | `String` | Compound field values joined |

### Handling Errors

```dart
void _showValidationErrors(form.FormResults results) {
  // Access all errors
  final errors = results.formErrors;

  // Iterate through errors
  for (final error in errors) {
    print('Field ${error.fieldId}: ${error.reason}');
  }

  // Show error dialog
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Validation Errors'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: errors.map((error) {
          return Text('${error.fieldId}: ${error.reason}');
        }).toList(),
      ),
    ),
  );
}
```

### Working with File Results

```dart
final fileResults = results.grab('avatar').asFileList();

if (fileResults.isNotEmpty) {
  for (final fileData in fileResults) {
    // Access file metadata
    print('Name: ${fileData.fileName}');
    print('MIME: ${fileData.mimeData?.mime ?? 'Unknown'}');

    // Access file bytes (may require async read)
    final bytes = await fileData.fileDetails?.getFileBytes();
    if (bytes != null) {
      print('Size: ${bytes.length} bytes');
    }

    // Access file stream (for large files)
    final stream = fileData.fileDetails?.getFileStream();
  }
}
```

## Programmatic Updates Pattern

The controller provides methods to update field values programmatically - useful for:
- Loading saved data
- Implementing "Clear Form" buttons
- Multi-step form navigation
- Conditional field population

### Updating Text Fields

```dart
void _loadSavedData() {
  controller.updateFieldValue('email', 'saved@example.com');
  controller.updateFieldValue('password', 'savedPassword123');
  controller.updateFieldValue('bio', 'Multi-line\ntext content');
}
```

**Alternative method:**
```dart
controller.updateTextFieldValue('email', 'saved@example.com');
```

Both work identically for text fields. Use `updateFieldValue()` for consistency across all field types.

### Toggling Multiselect Options

For dropdowns, checkboxes, and chip selects:

```dart
void _selectPreferences() {
  controller.toggleMultiSelectValue(
    'country',
    toggleOn: ['US'], // Select United States
  );

  controller.toggleMultiSelectValue(
    'interests',
    toggleOn: ['reading', 'music'],  // Check these
    toggleOff: ['sports'],           // Uncheck this
  );
}
```

**Important:** Use the `value` property of `FieldOption`, not the `label`.

### Clearing Selections

```dart
void _clearForm() {
  // Clear text fields
  controller.updateFieldValue('email', '');
  controller.updateFieldValue('password', '');

  // Clear multiselect fields
  controller.removeMultiSelectOptions('interests');
  controller.removeMultiSelectOptions('country');

  // Clear file uploads
  controller.removeMultiSelectOptions('documents');
}
```

### When to Use Programmatic Updates

**Good use cases:**
- Loading user profile data
- Implementing "Reset to Defaults" button
- Multi-step forms (next/back navigation)
- Auto-filling based on previous selections
- Testing and demos

**Avoid:**
- Don't bypass normal user input flow unnecessarily
- Don't update fields while user is actively editing them
- Don't use for validation error fixes (let user correct)

## Layout Patterns

ChampionForms provides `Row` and `Column` widgets for flexible form layouts.

### Row/Column Pattern

Create multi-column layouts with flexible width distribution:

```dart
form.Row(
  children: [
    form.Column(
      widthFactor: 2, // Takes 2/3 of available width
      children: [
        form.TextField(id: 'email', ...),
        form.TextField(id: 'bio', ...),
      ],
    ),
    form.Column(
      widthFactor: 1, // Takes 1/3 of available width
      children: [
        form.TextField(id: 'phone', ...),
        form.OptionSelect(id: 'country', ...),
      ],
    ),
  ],
)
```

**How widthFactor works:**
- Total flex = sum of all widthFactor values (2 + 1 = 3)
- Column 1 gets 2/3 width
- Column 2 gets 1/3 width

### Responsive Layout Pattern

Automatically stack columns vertically on small screens:

```dart
form.Row(
  collapse: true, // Stack vertically on mobile
  children: [
    form.Column(children: [...]),
    form.Column(children: [...]),
  ],
)
```

**When `collapse: true`:**
- Desktop/tablet: Columns display side-by-side
- Mobile/narrow screens: Columns stack vertically

### Error Rollup Pattern

Display child field errors below the row or column:

```dart
form.Row(
  rollUpErrors: true, // Show all child errors below row
  children: [
    form.Column(
      children: [
        form.TextField(id: 'firstName', validators: [...]),
        form.TextField(id: 'lastName', validators: [...]),
      ],
    ),
  ],
)
```

**Error display behavior:**
- Individual errors still show on each field
- Rolled-up errors also appear below the row/column
- Useful for complex nested layouts

### Nested Layouts

Rows and columns can be nested for complex structures:

```dart
form.Column(
  children: [
    form.Row(
      children: [
        form.Column(children: [form.TextField(...)]),
        form.Column(children: [form.TextField(...)]),
      ],
    ),
    form.TextField(...),
    form.Row(
      children: [
        form.Column(children: [form.OptionSelect(...)]),
        form.Column(children: [form.CheckboxSelect(...)]),
      ],
    ),
  ],
)
```

## Theme Pattern

ChampionForms supports theming at multiple levels with cascading precedence.

### Global Theme Setup

Set a theme that applies to all forms in your app:

```dart
import 'package:championforms/championforms_themes.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set global theme (requires context)
    final globalTheme = softBlueColorTheme(context);
    FormThemeSingleton.instance.setTheme(globalTheme);

    return MaterialApp(
      // ...
    );
  }
}
```

**Available pre-built themes:**
- `softBlueColorTheme(context)`
- `redAccentFormTheme(context)`
- `iconicColorTheme(context)`

### Form-Level Theme

Override the global theme for a specific form:

```dart
form.Form(
  theme: redAccentFormTheme(context), // Override global
  controller: controller,
  fields: fields,
)
```

### Field-Level Theme

Override theme for individual fields:

```dart
form.TextField(
  id: 'email',
  theme: customFieldTheme, // Override form theme
  // ...
)
```

### Theme Hierarchy

Themes cascade from general to specific:

```
Default Theme (built-in)
    ↓
Global Theme (FormThemeSingleton)
    ↓
Form Theme (form.Form widget)
    ↓
Field Theme (individual field)
```

**More specific themes override general ones.**

### Creating Custom Themes

Define a custom `FormTheme`:

```dart
FormTheme customTheme(BuildContext context) {
  return FormTheme(
    normalColors: FieldColorScheme(
      backgroundColor: Colors.white,
      borderColor: Colors.grey.shade300,
      textColor: Colors.black87,
      hintColor: Colors.grey.shade500,
      iconColor: Colors.grey.shade600,
    ),
    activeColors: FieldColorScheme(
      backgroundColor: Colors.blue.shade50,
      borderColor: Colors.blue,
      textColor: Colors.black,
      iconColor: Colors.blue,
    ),
    errorColors: FieldColorScheme(
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red,
      textColor: Colors.red.shade900,
      iconColor: Colors.red,
    ),
    // Additional color schemes and styles...
  );
}
```

## Submit Pattern

### Submit Button Pattern

Standard approach with external button:

```dart
ElevatedButton(
  onPressed: () {
    final results = form.FormResults.getResults(controller: controller);
    if (!results.errorState) {
      // Process successful submission
      _submitToBackend(results);
    } else {
      // Show errors to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fix validation errors')),
      );
    }
  },
  child: const Text('Submit'),
)
```

### onSubmit Callback Pattern

Enable form submission with Enter key on text fields:

```dart
form.TextField(
  id: 'password',
  maxLines: 1, // Required for Enter key to work
  onSubmit: (results) {
    // Called when user presses Enter
    _handleFormSubmit();
  },
)
```

**Use case:** Login forms where password field should submit on Enter.

### onChange Callback Pattern

React to field value changes:

```dart
form.TextField(
  id: 'email',
  onChange: (results) {
    // Called on every character change
    final email = results.grab('email').asString();
    print('Email changed to: $email');
  },
)
```

**Warning:** `onChange` fires frequently. Avoid heavy operations.

### Async Submit Pattern

Handle asynchronous operations (API calls, etc.):

```dart
Future<void> _handleFormSubmit() async {
  final results = form.FormResults.getResults(controller: controller);

  if (results.errorState) {
    _showErrors(results);
    return;
  }

  // Show loading indicator
  setState(() => _isSubmitting = true);

  try {
    // Make API call
    await _apiClient.submitForm({
      'email': results.grab('email').asString(),
      'name': results.grab('name').asString(),
    });

    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Form submitted successfully')),
    );
  } catch (error) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Submission failed: $error')),
    );
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

## Form Widget Pattern

### Basic Structure

The `form.Form` widget renders your field definitions:

```dart
form.Form(
  controller: controller,
  fields: fields,
  spacing: 12,
  fieldPadding: const EdgeInsets.symmetric(vertical: 8),
)
```

### All Properties

| Property | Type | Default | Purpose |
|----------|------|---------|---------|
| `controller` | `FormController` | Required | State management |
| `fields` | `List<FormElement>` | Required | Field definitions |
| `theme` | `FormTheme?` | `null` | Override global theme |
| `spacing` | `double?` | `8.0` | Space between fields |
| `fieldPadding` | `EdgeInsets?` | `EdgeInsets.zero` | Padding within field layouts |
| `pageName` | `String?` | `null` | For multi-step forms |

### Multi-Step Forms Pattern

Use `pageName` to group fields into pages:

```dart
// Page 1
form.Form(
  controller: controller,
  pageName: 'page1',
  fields: [
    form.TextField(id: 'name', ...),
    form.TextField(id: 'email', ...),
  ],
)

// Page 2
form.Form(
  controller: controller,
  pageName: 'page2',
  fields: [
    form.TextField(id: 'address', ...),
    form.TextField(id: 'city', ...),
  ],
)
```

Retrieve fields for specific page:

```dart
final page1Fields = controller.getPageFields('page1');
```

### Scrollable Form Pattern

Wrap in `SingleChildScrollView` for long forms:

```dart
SingleChildScrollView(
  padding: const EdgeInsets.all(16.0),
  child: form.Form(
    controller: controller,
    fields: fields,
  ),
)
```

## Common Patterns Summary

### 1. Form Lifecycle

```
initState() → Create controller
     ↓
build() → Build Form widget
     ↓
dispose() → Dispose controller
```

### 2. Validation Flow

```
Define validators → Set validateLive OR call getResults() → Check errorState → Grab values
```

### 3. Value Flow

```
User input → Controller storage → FormResults.getResults() → grab() → asType()
```

### 4. Update Flow

```
controller.updateFieldValue() → Controller notifies listeners → Widget rebuilds
```

## Best Practices

### 1. Always Dispose Controllers

```dart
@override
void dispose() {
  controller.dispose(); // CRITICAL
  super.dispose();
}
```

**Why:** Prevents memory leaks from undisposed resources.

### 2. Use Namespace Imports

```dart
import 'package:championforms/championforms.dart' as form;
```

**Why:** Avoids collisions with Flutter's built-in widgets.

### 3. Validate Early with validateLive

```dart
form.TextField(
  id: 'email',
  validateLive: true, // Validate on blur
  validators: [...],
)
```

**Why:** Provides immediate user feedback for important fields.

### 4. Use Type-Safe Access Methods

```dart
// Good
final email = results.grab('email').asString();
final files = results.grab('avatar').asFileList();

// Avoid
final email = controller.findTextFieldValue('email')?.value;
```

**Why:** Type-safe methods handle defaults and edge cases.

### 5. Use Unique Field IDs

```dart
// Good
form.TextField(id: 'user_email', ...)
form.TextField(id: 'billing_email', ...)

// Bad - ID collision
form.TextField(id: 'email', ...)
form.TextField(id: 'email', ...) // Same ID!
```

**Why:** Prevents value collisions and confusion.

### 6. Check errorState Before Processing

```dart
final results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  // Process form
}
```

**Why:** Prevents processing invalid data.

### 7. Use Layouts for Structure

```dart
// Good - organized with Row/Column
form.Row(
  children: [
    form.Column(children: [...]),
    form.Column(children: [...]),
  ],
)

// Acceptable - flat list for simple forms
[
  form.TextField(...),
  form.TextField(...),
]
```

**Why:** Layouts improve visual organization and responsiveness.

### 8. Theme Globally

```dart
FormThemeSingleton.instance.setTheme(softBlueColorTheme(context));
```

**Why:** Consistent look and feel across all forms.

## Complete Example

Here's a complete working example incorporating all patterns:

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set global theme
    final globalTheme = softBlueColorTheme(context);
    FormThemeSingleton.instance.setTheme(globalTheme);

    return MaterialApp(
      title: 'ChampionForms Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyFormPage(),
    );
  }
}

class MyFormPage extends StatefulWidget {
  const MyFormPage({super.key});

  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  // 1. Controller Pattern
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose(); // CRITICAL
    super.dispose();
  }

  // 2. Submit Pattern
  void _handleSubmit() {
    final results = form.FormResults.getResults(controller: controller);

    if (!results.errorState) {
      // Success - access results
      final email = results.grab('email').asString();
      final interests = results.grab('interests').asMultiselectList();

      debugPrint('Email: $email');
      debugPrint('Interests: ${interests.map((e) => e.value).join(", ")}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully!')),
      );
    } else {
      // Errors - show to user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix validation errors')),
      );
    }
  }

  // 3. Programmatic Updates Pattern
  void _loadSampleData() {
    controller.updateFieldValue('email', 'sample@example.com');
    controller.toggleMultiSelectValue(
      'interests',
      toggleOn: ['reading', 'music'],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4. Field Definition Pattern
    final fields = [
      // Layout Pattern
      form.Row(
        collapse: true,
        children: [
          form.Column(
            widthFactor: 2,
            children: [
              // Text Field Pattern
              form.TextField(
                id: 'email',
                textFieldTitle: 'Email Address',
                hintText: 'Enter your email',
                validateLive: true,
                // Validation Pattern
                validators: [
                  form.Validator(
                    validator: (r) => form.Validators.stringIsNotEmpty(r),
                    reason: 'Email is required',
                  ),
                  form.Validator(
                    validator: (r) => form.Validators.isEmail(r),
                    reason: 'Invalid email format',
                  ),
                ],
                leading: const Icon(Icons.email),
                onSubmit: (_) => _handleSubmit(),
              ),
            ],
          ),
          form.Column(
            widthFactor: 1,
            children: [
              form.TextField(
                id: 'password',
                textFieldTitle: 'Password',
                password: true,
                validateLive: true,
                validators: [
                  form.Validator(
                    validator: (r) => r.asString().length >= 8,
                    reason: 'Password must be at least 8 characters',
                  ),
                ],
                leading: const Icon(Icons.lock),
                onSubmit: (_) => _handleSubmit(),
              ),
            ],
          ),
        ],
      ),

      // Checkbox Pattern
      form.CheckboxSelect(
        id: 'interests',
        title: 'Interests',
        description: 'Select all that apply',
        options: [
          form.FieldOption(value: 'reading', label: 'Reading'),
          form.FieldOption(value: 'sports', label: 'Sports'),
          form.FieldOption(value: 'music', label: 'Music'),
        ],
        validators: [
          form.Validator(
            validator: (r) => form.Validators.listIsNotEmpty(r),
            reason: 'Please select at least one interest',
          ),
        ],
      ),

      // File Upload Pattern
      form.FileUpload(
        id: 'avatar',
        title: 'Profile Picture',
        description: 'Upload a profile picture (JPG, PNG)',
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        validators: [
          form.Validator(
            validator: (r) => form.Validators.fileIsImage(r),
            reason: 'Must be an image file',
          ),
        ],
      ),
    ];

    // Form Widget Pattern
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChampionForms Demo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            form.Form(
              controller: controller,
              fields: fields,
              spacing: 16,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _loadSampleData,
                  child: const Text('Load Sample Data'),
                ),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

## Related Documentation

- **[Quick Start Guide](quick-start.md)** - Simpler introduction for beginners
- **[Form Controller API](../api/form-controller.md)** - Complete controller reference
- **[Field Types API](../api/field-types.md)** - All field options and properties
- **[Validation API](../api/validation.md)** - All validators and custom validation
- **[Form Results API](../api/form-results.md)** - All conversion methods and error handling
- **[Theming Guide](theming.md)** - Advanced theming and customization
- **[Custom Fields Cookbook](../custom-fields/custom-field-cookbook.md)** - Creating custom field types
