# Quick Start Guide

Get up and running with ChampionForms in 5 minutes.

## Prerequisites

- Flutter SDK >= 3.35.0
- Dart SDK >= 3.0.5

## Installation

### 1. Add Dependency

Add ChampionForms to your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.6.0
  flutter:
    sdk: flutter
```

Then run:

```bash
flutter pub get
```

### 2. Import the Package

ChampionForms uses a namespace import pattern to avoid conflicts with Flutter's built-in widgets:

```dart
import 'package:championforms/championforms.dart' as form;
```

All form-related classes use the `form.` prefix (e.g., `form.TextField`, `form.FormController`).

## Your First Form

Let's build a simple login form with email and password fields.

### Step 1: Create a Controller

The `FormController` manages all form state (values, validation, focus):

```dart
class MyFormPage extends StatefulWidget {
  @override
  State<MyFormPage> createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose(); // IMPORTANT: Always dispose!
    super.dispose();
  }

  // ... rest of widget
}
```

### Step 2: Define Fields

Create a list of form fields with validation:

```dart
final fields = [
  form.TextField(
    id: "email",
    textFieldTitle: "Email",
    hintText: "Enter your email",
    validators: [
      form.Validator(
        validator: (results) => form.Validators.stringIsNotEmpty(results),
        reason: "Email cannot be empty",
      ),
      form.Validator(
        validator: (results) => form.Validators.isEmail(results),
        reason: "Please enter a valid email",
      ),
    ],
  ),
  form.TextField(
    id: "password",
    textFieldTitle: "Password",
    password: true, // Obscures text
    validators: [
      form.Validator(
        validator: (results) => form.Validators.stringIsNotEmpty(results),
        reason: "Password cannot be empty",
      ),
    ],
  ),
];
```

### Step 3: Build the Form Widget

Add the `form.Form` widget to your UI:

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text("Login")),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          form.Form(
            controller: controller,
            fields: fields,
            spacing: 12.0,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _handleSubmit,
            child: Text("Login"),
          ),
        ],
      ),
    ),
  );
}
```

### Step 4: Handle Form Submission

Retrieve and validate form data when the user submits:

```dart
void _handleSubmit() {
  // Get results and trigger validation
  final results = form.FormResults.getResults(controller: controller);

  // Check if there are any errors
  if (results.errorState) {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please fix form errors")),
    );
    return;
  }

  // Access field values
  final email = results.grab("email").asString();
  final password = results.grab("password").asString();

  // Process login
  print("Email: $email");
  print("Password: $password");
  // TODO: Call your authentication API
}
```

### Complete Example

Here's the full working code in one place:

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final results = form.FormResults.getResults(controller: controller);

    if (results.errorState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fix form errors")),
      );
      return;
    }

    final email = results.grab("email").asString();
    final password = results.grab("password").asString();

    print("Login with: $email");
    // TODO: Call your authentication API
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      form.TextField(
        id: "email",
        textFieldTitle: "Email",
        validators: [
          form.Validator(
            validator: (r) => form.Validators.stringIsNotEmpty(r),
            reason: "Email cannot be empty",
          ),
          form.Validator(
            validator: (r) => form.Validators.isEmail(r),
            reason: "Invalid email format",
          ),
        ],
      ),
      form.TextField(
        id: "password",
        textFieldTitle: "Password",
        password: true,
        validators: [
          form.Validator(
            validator: (r) => form.Validators.stringIsNotEmpty(r),
            reason: "Password cannot be empty",
          ),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            form.Form(
              controller: controller,
              fields: fields,
              spacing: 12.0,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleSubmit,
              child: Text("Login"),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Next Steps

Now that you have a basic form working, explore more features:

- **[Field Types API](../api/field-types.md)** - Learn about all available field types (checkboxes, dropdowns, file uploads, etc.)
- **[Validation API](../api/validators.md)** - Explore built-in validators and create custom ones
- **[Compound Fields Guide](compound-fields.md)** - Use pre-built composite fields like NameField and AddressField
- **[Pages Guide](pages.md)** - Build multi-step forms with page navigation
- **[Custom Field Cookbook](../custom-fields/custom-field-cookbook.md)** - Create your own custom field types

## Common First Questions

### Q: Why use `as form` import?

ChampionForms includes widgets named `Form`, `Row`, and `Column` - the same names as Flutter's built-in widgets. The namespace pattern prevents naming conflicts:

```dart
import 'package:championforms/championforms.dart' as form;

// Now you can use both:
form.TextField(...)     // ChampionForms text field
TextField(...)          // Flutter's built-in TextField
```

### Q: Do I need to dispose the controller?

**YES!** This is critical. The controller manages internal resources like `TextEditingController` instances and focus nodes. Always call `controller.dispose()` in your widget's `dispose()` method to prevent memory leaks.

### Q: How do I add validation?

Add a `validators` list to any field:

```dart
form.TextField(
  id: "age",
  validators: [
    form.Validator(
      validator: (results) => form.Validators.isInteger(results),
      reason: "Must be a whole number",
    ),
  ],
)
```

Validation runs automatically when you call `FormResults.getResults()`.

### Q: How do I get field values?

Use the results API with type-safe accessors:

```dart
final results = form.FormResults.getResults(controller: controller);

// For text fields
final name = results.grab("name").asString();

// For multi-select (checkboxes, dropdowns with multiselect)
final selectedOptions = results.grab("interests").asMultiselectList();

// For file uploads
final files = results.grab("avatar").asFileList();
```

### Q: Can I update field values programmatically?

Yes! The controller provides methods to update values:

```dart
// Update text field
controller.updateFieldValue("email", "user@example.com");

// Toggle multiselect options
controller.toggleMultiSelectValue(
  "interests",
  toggleOn: ["coding", "design"],
  toggleOff: ["sports"],
);
```

## Troubleshooting

### Import errors

**Problem:** `The name 'TextField' is defined in the libraries 'package:flutter/material.dart' and 'package:championforms/championforms.dart'`

**Solution:** Use the namespace import pattern:
```dart
import 'package:championforms/championforms.dart' as form;
```

### Controller not updating UI

**Problem:** Form doesn't update when I change values programmatically.

**Solution:** The controller extends `ChangeNotifier` and automatically notifies listeners. Make sure:
1. You're passing the same `controller` instance to the `form.Form` widget
2. The `form.Form` widget is listening to the controller (this is automatic)

### Validation not triggering

**Problem:** Validators don't run when I expect them to.

**Solutions:**
- Validation automatically runs when you call `FormResults.getResults()`
- For live validation (on blur), set `validateLive: true` on the field:
  ```dart
  form.TextField(
    id: "email",
    validateLive: true,  // Validates when field loses focus
    validators: [...],
  )
  ```

### Field IDs must be unique

**Problem:** Multiple fields with the same ID cause unexpected behavior.

**Solution:** Ensure every field has a unique `id` within the form. The controller uses these IDs to track field state.

## What You've Learned

You now know how to:
- Install and import ChampionForms
- Create a FormController and manage its lifecycle
- Define fields with validation
- Build a Form widget
- Handle form submission and access results

## What's Next?

Explore more advanced features:

1. **More Field Types:**
   - `form.OptionSelect` - Dropdowns and select fields
   - `form.CheckboxSelect` - Checkbox lists
   - `form.FileUpload` - File picker with drag-and-drop
   - `form.NameField` / `form.AddressField` - Compound fields

2. **Layout Control:**
   - Use `form.Row` and `form.Column` for complex layouts
   - Responsive design with the `collapse` property

3. **Advanced Features:**
   - Autocomplete on text fields
   - Custom theming
   - Multi-page forms
   - Custom field types

Check the [API documentation](../api/) and [guides](../guides/) for detailed information on each topic.

Happy form building!
