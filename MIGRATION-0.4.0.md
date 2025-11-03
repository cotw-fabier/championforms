# Migration Guide: v0.3.x → v0.4.0

This guide will help you upgrade from ChampionForms v0.3.x to v0.4.0.

## Overview

Version 0.4.0 is a **breaking change release** that modernizes the ChampionForms API by removing the "Champion" prefix from all classes and adopting idiomatic Dart namespace patterns. This results in a cleaner, more maintainable API that aligns with Dart best practices.

**Key Highlights:**
- ✨ Cleaner class names: `ChampionTextField` → `TextField`
- ✨ Cleaner validator names: `FormBuilderValidator` → `Validator`
- ✨ Clearer option names: `MultiselectOption` → `FieldOption`
- ✨ Simplified autocomplete: `AutoCompleteOption` → `CompleteOption`
- ✨ Concise helper class: `DefaultValidators` → `Validators`
- 📦 Namespace import approach to avoid collisions with Flutter widgets
- 🎨 Two-tier export system for better organization
- 🔧 Automated migration script to ease transition
- ⚡ No functional changes - all behavior remains identical

**Migration Time Estimate:** 5-15 minutes with automated script, 30-60 minutes manually

---

## Why We Changed

### The Problem with "Champion" Prefix

The "Champion" prefix was originally added to avoid naming conflicts with Flutter's built-in widgets like `Row`, `Column`, and `Form`. However, this approach resulted in verbose code:

```dart
ChampionFormController controller = ChampionFormController();
ChampionForm(
  controller: controller,
  fields: [
    ChampionTextField(id: 'email', textFieldTitle: 'Email'),
    ChampionRow(columns: [...]),
  ],
)
```

### The Solution: Idiomatic Dart Namespace Pattern

Modern Dart/Flutter libraries handle namespace collisions using import aliases. This is the recommended approach in the Dart style guide and used extensively throughout the Flutter ecosystem.

**Benefits of v0.4.0:**
1. **Shorter, cleaner code**: `form.TextField()` vs `ChampionTextField()`
2. **Idiomatic Dart**: Follows established Dart/Flutter patterns
3. **Better organization**: Explicit namespace makes it clear where classes come from
4. **Future-proof**: Easier to extend and maintain
5. **No collisions**: Works seamlessly alongside Flutter's built-in widgets

---

## Before/After Examples

### Import Statements

#### Before (v0.3.x)
```dart
import 'package:championforms/championforms.dart';
```

#### After (v0.4.0)
```dart
// For form lifecycle (most common)
import 'package:championforms/championforms.dart' as form;

// For theming and custom field registration (typically once in main.dart)
import 'package:championforms/championforms_themes.dart';
```

**Note:** The `as form` namespace alias is **required** to avoid conflicts with Flutter's built-in `Row`, `Column`, and `Form` widgets.

---

### Controller Initialization

#### Before (v0.3.x)
```dart
final ChampionFormController controller = ChampionFormController();
```

#### After (v0.4.0)
```dart
final form.FormController controller = form.FormController();
```

---

### Basic Form with Text Fields

#### Before (v0.3.x)
```dart
ChampionForm(
  controller: controller,
  fields: [
    ChampionTextField(
      id: 'name',
      textFieldTitle: 'Full Name',
      validators: [
        FormBuilderValidator(
          validator: (r) => DefaultValidators().isEmpty(r),
          reason: 'Name is required'
        )
      ],
    ),
    ChampionTextField(
      id: 'email',
      textFieldTitle: 'Email Address',
      validators: [
        FormBuilderValidator(
          validator: (r) => DefaultValidators().isEmail(r),
          reason: 'Invalid email'
        )
      ],
    ),
  ],
)
```

#### After (v0.4.0)
```dart
form.Form(
  controller: controller,
  fields: [
    form.TextField(
      id: 'name',
      textFieldTitle: 'Full Name',
      validators: [
        form.Validator(
          validator: (r) => form.Validators.isEmpty(r),
          reason: 'Name is required'
        )
      ],
    ),
    form.TextField(
      id: 'email',
      textFieldTitle: 'Email Address',
      validators: [
        form.Validator(
          validator: (r) => form.Validators.isEmail(r),
          reason: 'Invalid email'
        )
      ],
    ),
  ],
)
```

---

### Row/Column Layout

#### Before (v0.3.x)
```dart
ChampionRow(
  columns: [
    ChampionColumn(
      fields: [
        ChampionTextField(id: 'firstName', textFieldTitle: 'First Name'),
      ],
    ),
    ChampionColumn(
      fields: [
        ChampionTextField(id: 'lastName', textFieldTitle: 'Last Name'),
      ],
    ),
  ],
)
```

#### After (v0.4.0)
```dart
form.Row(
  columns: [
    form.Column(
      fields: [
        form.TextField(id: 'firstName', textFieldTitle: 'First Name'),
      ],
    ),
    form.Column(
      fields: [
        form.TextField(id: 'lastName', textFieldTitle: 'Last Name'),
      ],
    ),
  ],
)
```

---

### Field Types (Dropdowns, Checkboxes, File Uploads)

#### Before (v0.3.x)
```dart
ChampionOptionSelect(
  id: 'country',
  title: 'Select Country',
  options: [
    MultiselectOption(label: 'USA', value: 'us'),
    MultiselectOption(label: 'Canada', value: 'ca'),
  ],
),
ChampionCheckboxSelect(
  id: 'interests',
  title: 'Interests',
  multiselect: true,
  options: [
    MultiselectOption(label: 'Sports', value: 'sports'),
    MultiselectOption(label: 'Music', value: 'music'),
  ],
),
ChampionFileUpload(
  id: 'avatar',
  title: 'Upload Photo',
  allowedExtensions: ['jpg', 'png'],
),
```

#### After (v0.4.0)
```dart
form.OptionSelect(
  id: 'country',
  title: 'Select Country',
  options: [
    form.FieldOption(label: 'USA', value: 'us'),
    form.FieldOption(label: 'Canada', value: 'ca'),
  ],
),
form.CheckboxSelect(
  id: 'interests',
  title: 'Interests',
  multiselect: true,
  options: [
    form.FieldOption(label: 'Sports', value: 'sports'),
    form.FieldOption(label: 'Music', value: 'music'),
  ],
),
form.FileUpload(
  id: 'avatar',
  title: 'Upload Photo',
  allowedExtensions: ['jpg', 'png'],
),
```

---

### Autocomplete Fields

#### Before (v0.3.x)
```dart
ChampionTextField(
  id: 'email',
  textFieldTitle: 'Email',
  autoComplete: AutoCompleteBuilder(
    initialOptions: [
      AutoCompleteOption(value: "test@example.com"),
      AutoCompleteOption(value: "user@domain.com"),
    ],
  ),
)
```

#### After (v0.4.0)
```dart
form.TextField(
  id: 'email',
  textFieldTitle: 'Email',
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: "test@example.com"),
      form.CompleteOption(value: "user@domain.com"),
    ],
  ),
)
```

---

### Getting Form Results

#### Before (v0.3.x)
```dart
final FormResults results = FormResults.getResults(controller: controller);
if (!results.errorState) {
  print('Name: ${results.grab("name").asString()}');
  print('Email: ${results.grab("email").asString()}');
}
```

#### After (v0.4.0)
```dart
final form.FormResults results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  print('Name: ${results.grab("name").asString()}');
  print('Email: ${results.grab("email").asString()}');
}
```

---

### Theme Initialization

#### Before (v0.3.x)
```dart
import 'package:championforms/championforms.dart';

// In your app initialization
ChampionFormTheme.instance.setTheme(softBlueColorTheme(context));
```

#### After (v0.4.0)
```dart
import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';

// In your app initialization
FormTheme.instance.setTheme(softBlueColorTheme(context));
```

**Note:** Theme classes (`FormTheme`, pre-built themes, `FormFieldRegistry`) are now in the separate `championforms_themes.dart` export file and don't need the `form.` namespace prefix.

---

### Complete Working Example

#### Before (v0.3.x)
```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart';

class MyFormPage extends StatefulWidget {
  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final ChampionFormController _controller = ChampionFormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitForm() {
    final FormResults results = FormResults.getResults(controller: _controller);
    if (!results.errorState) {
      print('Form submitted: ${results.grab("email").asString()}');
    } else {
      print('Validation errors: ${results.formErrors}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Form')),
      body: ChampionForm(
        controller: _controller,
        fields: [
          ChampionTextField(
            id: 'email',
            textFieldTitle: 'Email',
            validators: [
              FormBuilderValidator(
                validator: (r) => DefaultValidators().isEmail(r),
                reason: 'Invalid email'
              )
            ],
          ),
          ChampionRow(
            columns: [
              ChampionColumn(
                fields: [
                  ChampionTextField(id: 'firstName', textFieldTitle: 'First'),
                ],
              ),
              ChampionColumn(
                fields: [
                  ChampionTextField(id: 'lastName', textFieldTitle: 'Last'),
                ],
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitForm,
        child: Icon(Icons.check),
      ),
    );
  }
}
```

#### After (v0.4.0)
```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class MyFormPage extends StatefulWidget {
  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  final form.FormController _controller = form.FormController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submitForm() {
    final form.FormResults results = form.FormResults.getResults(controller: _controller);
    if (!results.errorState) {
      print('Form submitted: ${results.grab("email").asString()}');
    } else {
      print('Validation errors: ${results.formErrors}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Form')),
      body: form.Form(
        controller: _controller,
        fields: [
          form.TextField(
            id: 'email',
            textFieldTitle: 'Email',
            validators: [
              form.Validator(
                validator: (r) => form.Validators.isEmail(r),
                reason: 'Invalid email'
              )
            ],
          ),
          form.Row(
            columns: [
              form.Column(
                fields: [
                  form.TextField(id: 'firstName', textFieldTitle: 'First'),
                ],
              ),
              form.Column(
                fields: [
                  form.TextField(id: 'lastName', textFieldTitle: 'Last'),
                ],
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitForm,
        child: Icon(Icons.check),
      ),
    );
  }
}
```

---

## Find-and-Replace Reference Table

Use this table to update your code. All classes with `form.` prefix require the namespace import.

| Old Name (v0.3.x) | New Name (v0.4.0) | Category | Notes |
|-------------------|-------------------|----------|-------|
| `ChampionTextField` | `form.TextField` | Field Type | Namespace required |
| `ChampionOptionSelect` | `form.OptionSelect` | Field Type | Namespace required |
| `ChampionFileUpload` | `form.FileUpload` | Field Type | Namespace required |
| `ChampionCheckboxSelect` | `form.CheckboxSelect` | Field Type | Namespace required |
| `ChampionChipSelect` | `form.ChipSelect` | Field Type | Namespace required |
| `ChampionRow` | `form.Row` | Layout | Namespace required |
| `ChampionColumn` | `form.Column` | Layout | Namespace required |
| `ChampionForm` | `form.Form` | Widget | Namespace required |
| `ChampionFormController` | `form.FormController` | Controller | Namespace required |
| `ChampionFormElement` | `form.FormElement` | Base Class | Namespace required |
| `FormFieldBase` | `form.FieldBase` | Base Class | Namespace required |
| `FormFieldDef` | `form.Field` | Base Class | Namespace required |
| `FormFieldNull` | `form.NullField` | Base Class | Namespace required |
| `ChampionAutocompleteWrapper` | `form.AutocompleteWrapper` | Internal | Namespace required |
| `ChampionFormTheme` | `FormTheme` | Theme | **NO namespace** - from themes import |
| `ChampionFormFieldRegistry` | `FormFieldRegistry` | Registry | **NO namespace** - from themes import |
| `FormBuilderValidator` | `form.Validator` | Validation | Namespace required |
| `MultiselectOption` | `form.FieldOption` | Model | Namespace required |
| `AutoCompleteOption` | `form.CompleteOption` | Feature | Namespace required |
| `DefaultValidators` | `form.Validators` | Validation | Namespace required |
| `FormResults` | `form.FormResults` | Results | Namespace required |
| `FieldResults` | `form.FieldResults` | Results | Namespace required |
| `AutoCompleteBuilder` | `form.AutoCompleteBuilder` | Feature | Namespace required |

### Important Notes on the Table

1. **Classes with `form.` prefix** require: `import 'package:championforms/championforms.dart' as form;`
2. **Theme-related classes** (FormTheme, FormFieldRegistry, pre-built themes) require: `import 'package:championforms/championforms_themes.dart';`
3. Pre-built themes (`softBlueColorTheme`, `redAccentFormTheme`, `iconicColorTheme`) are now exported from `championforms_themes.dart`
4. **Generic type parameters** must also be updated:
   - `List<ChampionFormElement>` → `List<form.FormElement>`
   - `List<FormFieldBase>` → `List<form.FieldBase>`

---

## Step-by-Step Manual Migration

Follow these steps to manually migrate your project:

### Step 1: Update Import Statements

**Find all championforms imports in your project:**
```bash
# Search for imports
grep -r "import 'package:championforms" lib/
```

**Update each import:**

For files that use form fields, controller, or validation:
```dart
// OLD
import 'package:championforms/championforms.dart';

// NEW
import 'package:championforms/championforms.dart' as form;
```

For files that configure themes or register custom fields (usually just main.dart):
```dart
// ADD (in addition to the above)
import 'package:championforms/championforms_themes.dart';
```

### Step 2: Add Namespace Prefix to All Classes

Use your IDE's find-and-replace feature with **word boundary matching**.

**Example replacements** (use regex for word boundaries):

| Find | Replace |
|------|---------|
| `\bChampionFormController\b` | `form.FormController` |
| `\bChampionForm\b` | `form.Form` |
| `\bChampionTextField\b` | `form.TextField` |
| `\bChampionOptionSelect\b` | `form.OptionSelect` |
| `\bChampionFileUpload\b` | `form.FileUpload` |
| `\bChampionCheckboxSelect\b` | `form.CheckboxSelect` |
| `\bChampionChipSelect\b` | `form.ChipSelect` |
| `\bChampionRow\b` | `form.Row` |
| `\bChampionColumn\b` | `form.Column` |
| `\bChampionFormElement\b` | `form.FormElement` |
| `\bFormBuilderValidator\b` | `form.Validator` |
| `\bMultiselectOption\b` | `form.FieldOption` |
| `\bAutoCompleteOption\b` | `form.CompleteOption` |
| `\bDefaultValidators\b` | `form.Validators` |

**Important:** Use **word boundary** matching (`\b`) to avoid replacing "Champion" in strings, comments, or variable names.

### Step 3: Update Theme References

For theme-related classes, do NOT add the `form.` namespace:

```dart
// These classes are from championforms_themes.dart
// and do NOT use the namespace prefix
FormTheme.instance.setTheme(softBlueColorTheme(context));
FormFieldRegistry.instance.registerField(...);
```

### Step 4: Update Type Annotations

Update variable declarations and function signatures:

```dart
// OLD
final ChampionFormController controller = ChampionFormController();
final List<FormFieldBase> fields = [...];

// NEW
final form.FormController controller = form.FormController();
final List<form.FieldBase> fields = [...];
```

### Step 5: Update Generic Type Parameters

Find and update generic types:

```dart
// OLD
List<ChampionFormElement> elements = [...];
List<FormFieldBase> fields = [...];

// NEW
List<form.FormElement> elements = [...];
List<form.FieldBase> fields = [...];
```

### Step 6: Update Base Class References

If you're extending or implementing base classes:

```dart
// OLD
class MyCustomField extends FormFieldDef { ... }

// NEW
class MyCustomField extends form.Field { ... }
```

### Step 7: Verify Compilation

Run Flutter's analyzer:
```bash
flutter analyze
```

Fix any remaining errors. Common issues:
- Missing `form.` prefix on a class
- Incorrect namespace on theme classes
- Generic type parameters not updated

### Step 8: Test Your Application

1. Run your app: `flutter run`
2. Test all forms in your application
3. Verify field input works correctly
4. Test validation triggers
5. Test form submission
6. Verify theming still applies correctly

### Step 9: Final Sweep

Search for any remaining "Champion" references:

```bash
# Find any remaining "Champion" class references
grep -r "Champion" lib/ --include="*.dart"
```

Ignore matches in:
- String literals (e.g., `"Welcome Champion User"`)
- Comments (e.g., `// Uses Champion pattern`)
- Variable names (e.g., `championCount`)

Only update class names.

---

## Automated Migration Script

We've provided an automated Dart script to handle the migration for you.

### Prerequisites

- Dart SDK installed (comes with Flutter)
- Your project backed up or committed to git

### Usage

1. Navigate to your ChampionForms package directory:
```bash
cd /path/to/championforms/package
```

2. Run the migration script on your project:
```bash
dart run tools/project-migration.dart /path/to/your/flutter/project
```

### What the Script Does

1. **Scans** your project recursively for all `.dart` files
2. **Detects** championforms import statements
3. **Updates** imports to use namespace alias (`as form`)
4. **Replaces** all class name references with namespaced versions
5. **Creates** `.backup` files before modifying originals
6. **Generates** a summary report of all changes

### Example Output

```
ChampionForms Migration Tool v0.4.0
===================================
Scanning: /Users/you/projects/myapp

Found 47 Dart files to analyze...

Analyzing files...
✓ lib/main.dart - Modified (3 imports, 12 class references)
✓ lib/screens/login.dart - Modified (1 import, 8 class references)
✓ lib/screens/profile.dart - Modified (1 import, 15 class references)
✓ lib/widgets/custom_form.dart - Modified (2 imports, 6 class references)
- lib/models/user.dart - No changes needed

Summary:
  Files scanned: 47
  Files modified: 23
  Files skipped: 24 (no championforms imports)
  Backups created: 23

✓ Migration complete!

Next steps:
  1. Review changes using git diff
  2. Run: flutter pub get
  3. Run: flutter analyze
  4. Test your application thoroughly
  5. If everything works, delete .backup files
```

### Script Options

```bash
# Dry run (preview changes without modifying files)
dart run tools/project-migration.dart /path/to/project --dry-run

# Skip backup creation (not recommended)
dart run tools/project-migration.dart /path/to/project --no-backup

# Use custom namespace (default is 'form')
dart run tools/project-migration.dart /path/to/project --namespace cf

# Combine options
dart run tools/project-migration.dart /path/to/project --namespace myforms --dry-run

# Show help
dart run tools/project-migration.dart --help
```

**Custom Namespace Option:**

By default, the migration script uses `form` as the namespace alias (e.g., `form.TextField`). If you prefer a different namespace, use the `--namespace` option:

```dart
// Default: uses 'form' namespace
import 'package:championforms/championforms.dart' as form;
form.TextField(...)

// Custom: uses your chosen namespace
import 'package:championforms/championforms.dart' as cf;
cf.TextField(...)
```

The namespace must be a valid Dart identifier (start with letter or underscore, contain only letters, numbers, and underscores).

### Rollback from Backups

If something goes wrong, restore from backup files:

```bash
# Find all backup files
find /path/to/project -name "*.backup"

# Restore a specific file
mv lib/main.dart.backup lib/main.dart

# Or restore all files with a script:
find /path/to/project -name "*.backup" -exec sh -c 'mv "$1" "${1%.backup}"' _ {} \;
```

---

## Common Issues & FAQ

### Q: Why am I getting "The name 'TextField' is defined in the libraries" error?

**A:** You're experiencing a namespace collision between ChampionForms' `TextField` and Flutter's built-in `TextField` widget.

**Solution:** Use the namespace alias:
```dart
// This causes conflict
import 'package:championforms/championforms.dart';
TextField(...) // Ambiguous!

// This resolves it
import 'package:championforms/championforms.dart' as form;
form.TextField(...) // Clear!
```

### Q: Can I use both ChampionForms' Form and Flutter's Form widget in the same file?

**A:** Yes! That's the beauty of the namespace approach:

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

// Flutter's Form
Form(
  key: _formKey,
  child: TextFormField(...),
)

// ChampionForms' Form
form.Form(
  controller: _controller,
  fields: [form.TextField(...)],
)
```

### Q: Why use namespace instead of just choosing different class names?

**A:** Several reasons:

1. **Idiomatic Dart**: This is the recommended approach in the Dart style guide
2. **Flexibility**: You can choose your own namespace alias if you prefer (e.g., `as cf`, `as forms`)
3. **Clarity**: Makes it explicit where classes come from
4. **Future-proof**: Easier to avoid conflicts as the library grows
5. **Ecosystem alignment**: Matches how other Flutter packages handle this

### Q: Will this affect my existing data or form state?

**A:** **No.** This is purely a code refactoring - only class names changed. All functionality, data handling, validation logic, and form behavior remain identical to v0.3.x.

### Q: Do I need to migrate all at once, or can I do it gradually?

**A:** You must migrate all at once. This is a breaking change, and partial migration is not supported. You cannot mix v0.3.x and v0.4.0 class names in the same project.

**Recommendation:** Use the automated migration script, then review and test thoroughly before committing.

### Q: What if I have custom field types registered with FormFieldRegistry?

**A:** Update your custom field registration:

```dart
// OLD (v0.3.x)
ChampionFormFieldRegistry.instance.registerField(
  'myCustomField',
  (field) => buildMyCustomField(field),
);

// NEW (v0.4.0)
import 'package:championforms/championforms_themes.dart';

FormFieldRegistry.instance.registerField(
  'myCustomField',
  (field) => buildMyCustomField(field),
);
```

Note: `FormFieldRegistry` is in `championforms_themes.dart` and doesn't use the `form.` namespace.

### Q: I'm getting errors about "form.TextField" not being found

**A:** Check that you've added the namespace alias to your import:

```dart
// Missing namespace alias - won't work
import 'package:championforms/championforms.dart';

// Correct - includes namespace alias
import 'package:championforms/championforms.dart' as form;
```

### Q: Why use `FieldOption` instead of just `Option`?

**A:** `Option` is too generic and commonly conflicts with other packages. `FieldOption` maintains context (form field options) while being concise and descriptive.

### Q: Why abbreviate `AutoCompleteOption` to `CompleteOption`?

**A:** We shortened it while maintaining clarity. "Complete" still conveys the autocomplete context, and the namespace `form.CompleteOption` makes the purpose clear.

### Q: The migration script isn't available in my version

**A:** The migration script is part of the ChampionForms v0.4.0 package. Make sure you've:

1. Updated your pubspec.yaml: `championforms: ^0.4.0`
2. Run `flutter pub get`
3. The script is at `tools/project-migration.dart` in the package directory

### Q: Can I use a different namespace alias besides "form"?

**A:** Yes! You can use any valid Dart identifier:

```dart
import 'package:championforms/championforms.dart' as cf;
// Then use: cf.TextField, cf.Form, cf.FormController, etc.

import 'package:championforms/championforms.dart' as forms;
// Then use: forms.TextField, forms.Form, etc.
```

**With the automated migration script**, you can specify your preferred namespace:

```bash
dart run tools/project-migration.dart /path/to/project --namespace cf
```

This will automatically use your custom namespace throughout the migration instead of the default 'form'.

However, we recommend `form` as it's short, clear, and used in all our documentation.

### Q: What about third-party packages that depend on ChampionForms?

**A:** Third-party packages that depend on ChampionForms will need to update to v0.4.0 as well. Check with the package maintainer for an updated version compatible with v0.4.0.

If you maintain a package that depends on ChampionForms, use this migration guide to update your package code.

### Q: My tests are failing after migration

**A:** Update your test files the same way as your app code:

```dart
// test/widget_test.dart

// OLD
import 'package:championforms/championforms.dart';
testWidgets('form test', (tester) async {
  final controller = ChampionFormController();
  await tester.pumpWidget(ChampionForm(...));
});

// NEW
import 'package:championforms/championforms.dart' as form;
testWidgets('form test', (tester) async {
  final controller = form.FormController();
  await tester.pumpWidget(form.Form(...));
});
```

### Q: Can I stay on v0.3.x?

**A:** Yes, v0.3.x will remain available on pub.dev. However, new features and bug fixes will only be added to v0.4.0+. We strongly recommend upgrading to benefit from future improvements.

To stay on v0.3.x, pin your version in pubspec.yaml:
```yaml
dependencies:
  championforms: ^0.3.0
```

---

## Version Checklist

Use this checklist to verify your migration:

- [ ] All `import 'package:championforms/championforms.dart'` updated to include `as form`
- [ ] Theme-related code imports `championforms_themes.dart` where needed
- [ ] All `Champion*` class references updated to `form.*` (or removed prefix for themes)
- [ ] Controller declarations updated: `form.FormController`
- [ ] Form widget updated: `form.Form`
- [ ] All field types updated: `form.TextField`, `form.OptionSelect`, etc.
- [ ] Layout widgets updated: `form.Row`, `form.Column`
- [ ] Base class references updated: `form.FormElement`, `form.FieldBase`, `form.Field`
- [ ] Type annotations updated in variables and functions
- [ ] Generic type parameters updated: `List<form.FormElement>`
- [ ] Result handling updated: `form.FormResults`, `form.FieldResults`
- [ ] Validator classes updated: `form.Validator`, `form.Validators`
- [ ] Option classes updated: `form.FieldOption`, `form.CompleteOption`
- [ ] Theme references use `FormTheme` (no namespace prefix)
- [ ] Project runs `flutter analyze` with zero errors
- [ ] Project runs `flutter run` successfully
- [ ] All forms render correctly
- [ ] Form validation works as expected
- [ ] Form submission works as expected
- [ ] Themes apply correctly
- [ ] All tests pass (if applicable)
- [ ] Backup files deleted (after confirming everything works)

---

## Need Help?

- **Issues**: Report problems at https://github.com/cotw-fabier/championforms/issues
- **Documentation**: Check the updated README.md for detailed examples
- **Source Code**: Review the example app for complete working examples
- **Questions**: Open a discussion on GitHub

---

## Summary

### What Changed
- All class names lost their "Champion" prefix
- Imports now require namespace alias (`as form`)
- Two-tier export system (lifecycle vs. themes)
- Base classes renamed for clarity (`FormFieldDef` → `Field`, etc.)
- Validator classes renamed (`FormBuilderValidator` → `Validator`, `DefaultValidators` → `Validators`)
- Option classes renamed (`MultiselectOption` → `FieldOption`, `AutoCompleteOption` → `CompleteOption`)

### What Stayed the Same
- All functionality and behavior
- All field types and their properties
- Validation system
- Theme system
- Controller API (methods and properties)
- Form state management
- Result handling

### Migration Options
1. **Automated** (Recommended): Run `dart run tools/project-migration.dart` (~5-15 minutes)
2. **Manual**: Follow step-by-step guide above (~30-60 minutes)

### Why Upgrade?
- Cleaner, more readable code
- Aligns with Dart/Flutter best practices
- Future-proof architecture
- Better namespace management
- Easier to maintain and extend

---

**Welcome to ChampionForms v0.4.0!** 🎉

Thank you for upgrading. We believe this change makes ChampionForms more professional, maintainable, and enjoyable to use.
