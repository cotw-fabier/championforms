# Validation API Reference

ChampionForms provides a comprehensive validation system that runs automatically at two key points: when a field loses focus (if live validation is enabled) and when you retrieve form results. This reference covers the complete validation API, including the `Validator` class, built-in validators, and patterns for creating custom validators.

## Table of Contents

- [Overview](#overview)
- [Validator Class](#validator-class)
- [Built-in Validators](#built-in-validators)
  - [String Validators](#string-validators)
  - [Numeric Validators](#numeric-validators)
  - [List Validators](#list-validators)
  - [File Validators](#file-validators)
- [Custom Validators](#custom-validators)
- [Live Validation](#live-validation)
- [Submit Validation](#submit-validation)
- [Multi-Field Validation](#multi-field-validation)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)

## Overview

### When Validation Runs

Validation in ChampionForms occurs at two distinct points:

1. **On Blur (Live Validation)**: When a field has `validateLive: true` and loses focus
2. **On Submit**: When `FormResults.getResults()` is called (always runs)

### How Validators Work

Validators are simple boolean functions that receive the field's current value and return:
- `true` - Validation passes
- `false` - Validation fails, error is displayed

Each validator includes a `reason` string that displays to the user when validation fails.

### Validation Flow

```
User Input → Field Value → Validator Function → Boolean Result → Error Display (if false)
```

When multiple validators are assigned to a field, they execute in order. All validators run even if earlier ones fail, allowing multiple error messages to be collected.

## Validator Class

The `Validator` class is the foundation of the validation system. It wraps a validation function with an error message.

### Constructor

```dart
Validator({
  required bool Function(dynamic value) validator,
  required String reason,
})
```

### Properties

- **validator**: `bool Function(dynamic value)` - Function that performs validation logic
- **reason**: `String` - Error message displayed when validation fails

### Basic Example

```dart
form.Validator(
  validator: (value) => form.Validators.stringIsNotEmpty(value),
  reason: "Field cannot be empty",
)
```

### Understanding the Value Parameter

The `validator` function receives the raw field value as a `dynamic` type. The actual type depends on the field:

- **TextField**: `String` or `null`
- **OptionSelect**: `List<FieldOption>` or `null`
- **FileUpload**: `List<FieldOption>` or `null` (where each option contains a `FileModel`)
- **Custom Fields**: Depends on field implementation (e.g., `int` for RatingField)

Built-in validators handle type checking and conversion automatically, providing safety against type mismatches.

## Built-in Validators

The `form.Validators` class provides static methods for common validation scenarios. These validators are designed to safely handle type conversion and return `false` instead of throwing errors on type mismatches.

### String Validators

#### stringIsNotEmpty()

**Signature:** `static bool stringIsNotEmpty(dynamic value)`

**Description:** Checks if a value is a non-empty string. Converts any non-null value to a string and checks if it has content after trimming.

**Returns:** `true` if the resulting string has content, `false` for `null` or empty strings

**Example:**
```dart
form.TextField(
  id: "username",
  textFieldTitle: "Username",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.stringIsNotEmpty(value),
      reason: "Username is required",
    ),
  ],
)
```

**Note:** This validator is deprecated in favor of `isEmpty()` / `isNotEmpty()` patterns. Use for backward compatibility.

---

#### stringIsEmpty()

**Signature:** `static bool stringIsEmpty(dynamic value)`

**Description:** Checks if a value is `null` or an empty string.

**Returns:** `true` if value is `null` or results in an empty string, `false` otherwise

**Example:**
```dart
form.Validator(
  validator: (value) => !form.Validators.stringIsEmpty(value),
  reason: "This field cannot be empty",
)
```

**Note:** This validator is deprecated. Use `isEmpty()` for the current API.

---

#### stringLengthInRange()

**Signature:** `bool stringLengthInRange(dynamic value)`

**Description:** Checks if a string's trimmed length falls within a specified range. Requires instantiation of `Validators` class with `minLength` and/or `maxLength` parameters.

**Returns:** `true` if length is within range, `false` otherwise

**Example:**
```dart
form.TextField(
  id: "bio",
  textFieldTitle: "Bio",
  validators: [
    form.Validator(
      validator: form.Validators(minLength: 10, maxLength: 500).stringLengthInRange,
      reason: "Bio must be between 10 and 500 characters",
    ),
  ],
)
```

**Alternative Example (minimum only):**
```dart
form.Validator(
  validator: form.Validators(minLength: 8).stringLengthInRange,
  reason: "Must be at least 8 characters",
)
```

### Numeric Validators

#### isInteger()

**Signature:** `static bool isInteger(dynamic value)`

**Description:** Checks if a value can be interpreted as an `int`. Returns `true` if the value is already an `int` or is a `String` that can be parsed into an `int`.

**Returns:** `true` if value is or can be converted to an integer, `false` otherwise

**Example:**
```dart
form.TextField(
  id: "age",
  textFieldTitle: "Age",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isInteger(value),
      reason: "Age must be a whole number",
    ),
  ],
)
```

---

#### isIntegerOrNull()

**Signature:** `static bool isIntegerOrNull(dynamic value)`

**Description:** Checks if a value is `null`, empty string, or can be interpreted as an `int`. Useful for optional numeric fields.

**Returns:** `true` if value is `null`, empty, or a valid integer, `false` otherwise

**Example:**
```dart
form.TextField(
  id: "optional_code",
  textFieldTitle: "Optional Code",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isIntegerOrNull(value),
      reason: "If provided, code must be numeric",
    ),
  ],
)
```

---

#### isDouble()

**Signature:** `static bool isDouble(dynamic value)`

**Description:** Checks if a value can be interpreted as a `double`. Returns `true` if the value is a number (`int` or `double`) or a `String` that can be parsed into a `double`.

**Returns:** `true` if value is or can be converted to a double, `false` otherwise

**Example:**
```dart
form.TextField(
  id: "price",
  textFieldTitle: "Price",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isDouble(value),
      reason: "Price must be a valid number",
    ),
  ],
)
```

---

#### isDoubleOrNull()

**Signature:** `static bool isDoubleOrNull(dynamic value)`

**Description:** Checks if a value is `null`, empty string, or can be interpreted as a `double`.

**Returns:** `true` if value is `null`, empty, or a valid double, `false` otherwise

### Format Validators

#### isEmail()

**Signature:** `static bool isEmail(dynamic value)`

**Description:** Checks if a string value is a valid email format using the `email_validator` package. The value must be a `String` to be evaluated.

**Returns:** `true` if value is a valid email format, `false` for non-string types or invalid formats

**Example:**
```dart
form.TextField(
  id: "Email",
  textFieldTitle: "Email Address",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) => form.Validators.stringIsNotEmpty(value),
      reason: "Email cannot be empty.",
    ),
    form.Validator(
      validator: (value) => form.Validators.isEmail(value),
      reason: "Please enter a valid email address.",
    ),
  ],
)
```

---

#### isEmailOrNull()

**Signature:** `static bool isEmailOrNull(dynamic value)`

**Description:** Checks if a string value is `null`, empty, or a valid email format.

**Returns:** `true` if value is `null`, empty, or valid email, `false` otherwise

**Example:**
```dart
form.TextField(
  id: "alternate_email",
  textFieldTitle: "Alternate Email (Optional)",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isEmailOrNull(value),
      reason: "If provided, must be a valid email",
    ),
  ],
)
```

### List Validators

List validators work with multiselect fields like `OptionSelect`, `CheckboxSelect`, and `ChipSelect`.

#### listIsNotEmpty()

**Signature:** `static bool listIsNotEmpty(dynamic value)`

**Description:** Checks if a value is a non-empty list. Returns `true` only if the value is a `List` and has at least one item.

**Returns:** `true` if value is a non-empty list, `false` otherwise

**Example:**
```dart
form.CheckboxSelect(
  id: "SelectBox",
  title: "Choose Multiple",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: "Please select at least one option.",
    ),
  ],
  options: [
    form.FieldOption(value: "Hi", label: "Hello"),
    form.FieldOption(value: "Hiya", label: "Wat"),
    form.FieldOption(value: "Yoz", label: "Sup"),
  ],
)
```

---

#### listIsEmpty()

**Signature:** `static bool listIsEmpty(dynamic value)`

**Description:** Checks if a value is `null` or an empty list.

**Returns:** `true` if value is `null` or an empty list, `false` otherwise

**Example:**
```dart
form.Validator(
  validator: (value) => !form.Validators.listIsEmpty(value),
  reason: "At least one selection is required",
)
```

### File Validators

File validators operate on `List<FieldOption>` where each option contains a `FileModel` in its `additionalData` property. They are designed for use with `FileUpload` fields.

#### fileIsImage()

**Signature:** `static bool fileIsImage(dynamic value)`

**Description:** Checks if all uploaded files are images (MIME type starts with "image/").

**Returns:** `true` if all files are images or no files uploaded, `false` if any file is not an image

**Example:**
```dart
form.FileUpload(
  id: "fileUpload",
  title: "Upload Images",
  multiselect: true,
  validateLive: true,
  allowedExtensions: ['jpg', 'jpeg', 'png'],
  validators: [
    form.Validator(
      reason: "Only image files are allowed.",
      validator: (value) => form.Validators.fileIsImage(value),
    ),
  ],
)
```

---

#### fileIsCommonImage()

**Signature:** `static bool fileIsCommonImage(dynamic value)`

**Description:** Checks if all uploaded files are common image types (JPEG, PNG, SVG, GIF, WebP).

**Returns:** `true` if all files match common image MIME types, `false` otherwise

**Example:**
```dart
form.FileUpload(
  id: "avatar",
  title: "Profile Picture",
  validators: [
    form.Validator(
      reason: "Only JPG, PNG, or GIF images allowed.",
      validator: (value) => form.Validators.fileIsCommonImage(value),
    ),
  ],
)
```

---

#### fileIsDocument()

**Signature:** `static bool fileIsDocument(dynamic value)`

**Description:** Checks if all uploaded files are common document types (Word, PDF, TXT, RTF, ODT).

**Returns:** `true` if all files are documents, `false` otherwise

**Example:**
```dart
form.FileUpload(
  id: "resume",
  title: "Upload Resume",
  allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
  validators: [
    form.Validator(
      reason: "Only document files are allowed.",
      validator: (value) => form.Validators.fileIsDocument(value),
    ),
  ],
)
```

---

#### fileIsMimeType()

**Signature:** `static bool fileIsMimeType(dynamic value, List<String> matchStrings)`

**Description:** Checks if all uploaded files match a given set of MIME types. Supports partial matching (e.g., "image/" matches all image types).

**Returns:** `true` if all files match at least one MIME pattern, `false` otherwise

**Example:**
```dart
form.FileUpload(
  id: "media",
  title: "Upload Media",
  validators: [
    form.Validator(
      reason: "Only images and videos allowed.",
      validator: (value) => form.Validators.fileIsMimeType(
        value,
        ["image/", "video/mp4", "video/quicktime"],
      ),
    ),
  ],
)
```

## Custom Validators

### Creating Custom Validators

Custom validators give you complete control over validation logic. They follow the same pattern as built-in validators but implement your specific business rules.

#### Simple Custom Validator

```dart
form.TextField(
  id: "password",
  textFieldTitle: "Password",
  password: true,
  validators: [
    form.Validator(
      validator: (value) {
        if (value == null || value is! String) return false;
        return value.length >= 8;
      },
      reason: "Password must be at least 8 characters",
    ),
  ],
)
```

#### Complex Custom Validator

Example checking password strength with multiple requirements:

```dart
form.TextField(
  id: "secure_password",
  textFieldTitle: "Secure Password",
  password: true,
  validators: [
    form.Validator(
      validator: (value) {
        if (value == null || value is! String) return false;
        final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
        final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
        final hasNumber = RegExp(r'[0-9]').hasMatch(value);
        final hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);
        return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
      },
      reason: "Password must contain uppercase, lowercase, number, and special character",
    ),
  ],
)
```

#### Custom Validator from Example (Rating Field)

From `example/lib/main.dart` (lines 366-375), validating a custom field type:

```dart
RatingField(
  id: "satisfaction_rating",
  title: "Rate Your Experience",
  maxStars: 5,
  defaultValue: 0,
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) {
        // Validator receives raw field value (int for RatingField)
        if (value == null) return false;
        if (value is int) return value >= 3;
        return false;
      },
      reason: "Please rate at least 3 stars",
    ),
  ],
)
```

### Type Safety in Custom Validators

Always check the type of the value before performing operations:

```dart
form.Validator(
  validator: (value) {
    // Type check first
    if (value == null || value is! String) {
      return false;
    }

    // Now safe to use String methods
    final trimmed = value.trim();
    return trimmed.length >= 5 && trimmed.length <= 20;
  },
  reason: "Must be between 5 and 20 characters",
)
```

### Validators with External Data

You can create validators that check against external data sources:

```dart
form.TextField(
  id: "username",
  textFieldTitle: "Username",
  validators: [
    form.Validator(
      validator: (value) async {
        if (value == null || value is! String) return false;
        // Note: Validators are not async, so you'd need to check
        // availability separately or use a different pattern
        return value.length >= 3;
      },
      reason: "Username must be at least 3 characters",
    ),
  ],
)
```

**Note:** Validators are synchronous. For async validation (like checking username availability), perform the check separately and update field values or show errors programmatically.

## Live Validation

Live validation runs when a field loses focus (on blur), providing immediate feedback to users.

### Enabling Live Validation

Set `validateLive: true` on any field:

```dart
form.TextField(
  id: "email",
  textFieldTitle: "Email",
  validateLive: true,  // Validates when field loses focus
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isEmail(value),
      reason: "Invalid email format",
    ),
  ],
)
```

### When It Triggers

Live validation triggers when:
1. User enters text in the field
2. User clicks/taps outside the field (blur event)
3. Validator runs and updates error display immediately

### Use Cases

**Best for:**
- Email fields (immediate format feedback)
- Password fields (strength requirements)
- Required fields (can't be empty)
- Format-specific inputs (phone numbers, credit cards)

**Avoid for:**
- Submit-only validation (cross-field dependencies)
- Expensive validation operations
- Fields where errors during typing are annoying

### Example from main.dart

Email field with live validation (lines 177, 205-216):

```dart
form.TextField(
  id: "Email",
  textFieldTitle: "Email Address",
  hintText: "Enter your email",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) => form.Validators.stringIsNotEmpty(value),
      reason: "Email cannot be empty.",
    ),
    form.Validator(
      validator: (value) => form.Validators.isEmail(value),
      reason: "Please enter a valid email address.",
    ),
  ],
)
```

## Submit Validation

Submit validation runs when you call `FormResults.getResults()`, typically when the user submits the form. This validation always runs, regardless of the `validateLive` setting.

### How It Works

```dart
void _executeLogin() {
  // Trigger validation by creating FormResults instance
  final form.FormResults results = form.FormResults.getResults(
    controller: controller,
  );

  // Check for errors
  if (results.errorState) {
    // Handle validation errors
    debugPrint("Form has errors:");
    for (final error in results.formErrors) {
      debugPrint("${error.fieldId}: ${error.reason}");
    }
  } else {
    // Process valid form data
    final email = results.grab("Email").asString();
    final password = results.grab("Password").asString();
    // Submit to API...
  }
}
```

### Validation Process

When `FormResults.getResults()` is called:

1. **Collection Phase**: Gathers values from all active fields
2. **Validation Phase**: Runs all validators for each field in order
3. **Error Collection**: Collects all failed validations into `formErrors`
4. **State Update**: Sets `errorState` to `true` if any validation failed
5. **Return Results**: Returns `FormResults` object with values and errors

### Accessing Errors

The `FormResults` object provides two properties for error handling:

#### errorState

Boolean indicating if any validation failed:

```dart
final results = FormResults.getResults(controller: controller);

if (results.errorState) {
  // At least one validation failed
  showErrorDialog("Please fix the errors and try again");
}
```

#### formErrors

List of all validation errors:

```dart
for (final error in results.formErrors) {
  debugPrint("Field: ${error.fieldId}");
  debugPrint("Error: ${error.reason}");
  debugPrint("Validator Position: ${error.validatorPosition}");
}
```

Each `FormBuilderError` contains:
- `fieldId`: ID of the field that failed validation
- `reason`: Error message from the validator
- `validatorPosition`: Index of the validator that failed (useful when multiple validators exist)

### Example from main.dart

Complete submission handler (lines 81-130):

```dart
void _executeLogin() {
  final form.FormResults results = form.FormResults.getResults(
    controller: controller,
  );

  final errors = results.errorState;
  debugPrint("Current Error State is: $errors");

  if (!errors) {
    // Success - access form values
    debugPrint("Email: ${results.grab("Email").asString()}");
    debugPrint("Password Set: ${results.grab("Password").asString().isNotEmpty}");

    // Process file uploads
    final fileResults = results.grab("fileUpload").asFileList();
    if (fileResults.isNotEmpty) {
      debugPrint("Uploaded Files (${fileResults.length}):");
      for (final fileData in fileResults) {
        debugPrint("  - Name: ${fileData.fileName}");
      }
    }
  } else {
    // Errors - display to user
    debugPrint("The form had errors:");
    debugPrint(results.formErrors
        .map((error) => "Field '${error.fieldId}' Error: ${error.reason}")
        .join("\n"));
  }
}
```

## Multi-Field Validation

Multi-field validation allows validators to access values from other fields, useful for scenarios like password confirmation or dependent field logic.

### Accessing Other Fields via Controller

Use the controller to access other field values within a validator:

```dart
form.TextField(
  id: "password",
  textFieldTitle: "Password",
  password: true,
),

form.TextField(
  id: "password_confirm",
  textFieldTitle: "Confirm Password",
  password: true,
  validators: [
    form.Validator(
      validator: (value) {
        // Access password field via controller
        final password = controller.getFieldValue<String>('password');
        final confirm = value is String ? value : '';
        return password == confirm;
      },
      reason: "Passwords do not match",
    ),
  ],
)
```

### Cross-Field Dependencies

When one field's validation depends on another:

```dart
form.TextField(
  id: "age",
  textFieldTitle: "Age",
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isInteger(value),
      reason: "Age must be a number",
    ),
  ],
),

form.CheckboxSelect(
  id: "consent",
  title: "I agree to terms",
  validators: [
    form.Validator(
      validator: (value) {
        final age = controller.getFieldValue<String>('age');
        final ageInt = int.tryParse(age ?? '0') ?? 0;

        // Only require consent if age >= 18
        if (ageInt >= 18) {
          return value is List && value.isNotEmpty;
        }
        return true; // Skip validation for minors
      },
      reason: "You must agree to the terms",
    ),
  ],
  options: [
    form.FieldOption(value: "agree", label: "I agree"),
  ],
)
```

### Limitations

**Important Considerations:**

1. **Validation Order**: Fields validate in the order they appear in the form. Earlier fields complete validation before later ones.

2. **Live Validation Timing**: When using `validateLive: true` with cross-field validation, ensure the dependent field exists and has a value when the validator runs.

3. **Null Safety**: Always check if the other field's value is null or of the expected type:

```dart
form.Validator(
  validator: (value) {
    final otherValue = controller.getFieldValue<String>('other_field');
    if (otherValue == null) return true; // Skip if other field empty
    // Validate against otherValue
    return true;
  },
  reason: "Validation error",
)
```

### Compound Field Validation

Compound fields (like `NameField` or `AddressField`) can validate based on their sub-field values:

```dart
NameField(
  id: "customer_name",
  title: "Full Name",
  validators: [
    form.Validator(
      validator: (results) {
        // For compound fields, validator receives FormResults
        final firstName = results.grab('customer_name_firstname').asString();
        final lastName = results.grab('customer_name_lastname').asString();
        return firstName.isNotEmpty && lastName.isNotEmpty;
      },
      reason: "First and last name are required",
    ),
  ],
)
```

**Note:** Compound field validators receive a `FormResults` object instead of a raw value, allowing access to all sub-fields via `results.grab()`.

## Error Handling

### Error Display

The `Form` widget automatically displays validation errors below each field. No additional code is required for basic error display.

#### Automatic Error Display

```dart
form.Form(
  controller: controller,
  fields: [
    form.TextField(
      id: "email",
      validators: [
        form.Validator(
          validator: (value) => form.Validators.isEmail(value),
          reason: "Invalid email format",  // Displays automatically when validation fails
        ),
      ],
    ),
  ],
)
```

#### Error Rollup (Row/Column)

When using `Row` and `Column` layouts, set `rollUpErrors: true` to display child field errors below the row:

```dart
form.Row(
  rollUpErrors: true,  // Show all child errors below the row
  children: [
    form.Column(
      children: [
        form.TextField(id: "firstName", /* ... */),
      ],
    ),
    form.Column(
      children: [
        form.TextField(id: "lastName", /* ... */),
      ],
    ),
  ],
)
```

### Error State

Access error information through the `FormResults` object:

#### errorState Property

Boolean indicating if any validation failed:

```dart
final results = FormResults.getResults(controller: controller);

if (results.errorState) {
  // Show error banner
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Please fix the errors")),
  );
}
```

#### formErrors Property

List of all validation errors with detailed information:

```dart
final results = FormResults.getResults(controller: controller);

for (final error in results.formErrors) {
  debugPrint("Field ID: ${error.fieldId}");
  debugPrint("Error Message: ${error.reason}");
  debugPrint("Validator Index: ${error.validatorPosition}");
}
```

The `FormBuilderError` class contains:
- `fieldId` (String): ID of the field that failed
- `reason` (String): Error message from the validator
- `validatorPosition` (int): Index of the validator in the field's validators list

### Finding Errors for Specific Field

```dart
final results = FormResults.getResults(controller: controller);

// Get all errors for a specific field
final emailErrors = results.formErrors
    .where((error) => error.fieldId == 'email')
    .toList();

if (emailErrors.isNotEmpty) {
  debugPrint("Email field has ${emailErrors.length} error(s):");
  for (final error in emailErrors) {
    debugPrint("  - ${error.reason}");
  }
}
```

### Clearing Errors

Errors are automatically cleared in several scenarios:

#### Automatic Clearing

1. **On Value Change**: When a field's value changes, its errors are cleared
2. **On Re-validation**: When `FormResults.getResults()` is called, old errors are cleared before new validation runs
3. **On Field Update**: When using `controller.updateFieldValue()`, errors for that field are cleared

#### Manual Clearing

Clear errors for a specific field:

```dart
controller.clearErrors("email");
```

Clear all errors:

```dart
// Clear errors for all fields
for (final field in controller.activeFields) {
  controller.clearErrors(field.id);
}
```

### Custom Error Display

For custom error UI, access errors through the results object:

```dart
final results = FormResults.getResults(controller: controller);

if (results.errorState) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("Validation Errors"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: results.formErrors.map((error) =>
          ListTile(
            leading: Icon(Icons.error, color: Colors.red),
            title: Text(error.reason),
            subtitle: Text("Field: ${error.fieldId}"),
          )
        ).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("OK"),
        ),
      ],
    ),
  );
}
```

## Best Practices

### 1. Use Built-in Validators First

Prefer built-in validators over custom regex or logic when possible. They are well-tested, handle edge cases, and provide consistent behavior.

**Good:**
```dart
form.Validator(
  validator: (value) => form.Validators.isEmail(value),
  reason: "Invalid email format",
)
```

**Avoid:**
```dart
form.Validator(
  validator: (value) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    return value is String && emailRegex.hasMatch(value);
  },
  reason: "Invalid email format",
)
```

### 2. Clear, User-Actionable Error Messages

Write error messages that tell users exactly what they need to fix.

**Good:**
- "Email is required"
- "Password must be at least 8 characters"
- "Please select at least one option"

**Avoid:**
- "Invalid input"
- "Error"
- "Validation failed"

### 3. Combine Validators Thoughtfully

When using multiple validators, order matters. Check for empty/null values first before checking format or other rules.

**Good:**
```dart
validators: [
  form.Validator(
    validator: (value) => form.Validators.stringIsNotEmpty(value),
    reason: "Password is required",
  ),
  form.Validator(
    validator: (value) {
      if (value is! String) return false;
      return value.length >= 8;
    },
    reason: "Password must be at least 8 characters",
  ),
]
```

**Avoid:**
```dart
validators: [
  // Will fail with cryptic error if value is null
  form.Validator(
    validator: (value) => (value as String).length >= 8,
    reason: "Password must be at least 8 characters",
  ),
  form.Validator(
    validator: (value) => form.Validators.stringIsNotEmpty(value),
    reason: "Password is required",
  ),
]
```

### 4. Use Live Validation Sparingly

While `validateLive: true` provides immediate feedback, it can be annoying if overused. Use it for:
- Important fields (email, password)
- Format-specific inputs
- Required fields with simple validation

Avoid live validation for:
- Fields with complex cross-field dependencies
- Fields where errors during typing distract users
- Every single field in a long form

**Good:**
```dart
form.TextField(
  id: "email",
  validateLive: true,  // Immediate format feedback is helpful
  validators: [
    form.Validator(
      validator: (value) => form.Validators.isEmail(value),
      reason: "Invalid email format",
    ),
  ],
)
```

### 5. Custom Validators for Business Logic

Use custom validators when built-in validators don't cover your specific requirements:

- Username availability (with note about async limitations)
- Credit card validation
- Domain-specific rules (e.g., employee ID format)
- Complex multi-field business rules

```dart
form.Validator(
  validator: (value) {
    if (value is! String) return false;
    // Custom employee ID format: EMP-XXXX-YYYY
    final pattern = RegExp(r'^EMP-\d{4}-\d{4}$');
    return pattern.hasMatch(value);
  },
  reason: "Employee ID must be in format EMP-XXXX-YYYY",
)
```

### 6. Type-Safe Value Access

Always check the type before performing operations, especially in custom validators:

**Good:**
```dart
form.Validator(
  validator: (value) {
    if (value == null || value is! String) return false;
    return value.trim().length >= 5;
  },
  reason: "Must be at least 5 characters",
)
```

**Avoid:**
```dart
form.Validator(
  validator: (value) {
    // Crashes if value is null or not String
    return value.trim().length >= 5;
  },
  reason: "Must be at least 5 characters",
)
```

### 7. Handle Null Cases Explicitly

Decide how validators should handle null values based on whether the field is required:

**Required field:**
```dart
form.Validator(
  validator: (value) => value != null && value is String && value.isNotEmpty,
  reason: "This field is required",
)
```

**Optional field:**
```dart
form.Validator(
  validator: (value) {
    if (value == null || (value is String && value.isEmpty)) {
      return true; // Valid if empty
    }
    return form.Validators.isEmail(value);
  },
  reason: "If provided, must be a valid email",
)
```

### 8. Provide Context in Error Messages

When validating against specific criteria, include the criteria in the error message:

**Good:**
```dart
form.Validator(
  validator: form.Validators(minLength: 8, maxLength: 20).stringLengthInRange,
  reason: "Password must be 8-20 characters",
)
```

**Avoid:**
```dart
form.Validator(
  validator: form.Validators(minLength: 8, maxLength: 20).stringLengthInRange,
  reason: "Password length is invalid",
)
```

## Complete Examples

### Example 1: Email Field with Multiple Validators

From `example/lib/main.dart` (lines 171-218):

```dart
form.TextField(
  id: "Email",
  textFieldTitle: "Email Address",
  hintText: "Enter your email",
  description: "Your login email.",
  maxLines: 1,
  validateLive: true,
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: "test1@example.com"),
      form.CompleteOption(value: "test2@example.com"),
    ],
    updateOptions: (searchValue) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return [
        form.CompleteOption(value: "test1@example.com"),
        form.CompleteOption(value: "test2@example.com"),
      ].where((opt) =>
        opt.value.toLowerCase().contains(searchValue.toLowerCase())
      ).toList();
    },
    debounceWait: const Duration(milliseconds: 250),
  ),
  validators: [
    form.Validator(
      validator: (value) => form.Validators.stringIsNotEmpty(value),
      reason: "Email cannot be empty.",
    ),
    form.Validator(
      validator: (value) => form.Validators.isEmail(value),
      reason: "Please enter a valid email address.",
    ),
  ],
  leading: const Icon(Icons.email),
)
```

**Key Points:**
- Two validators: non-empty check and email format
- Live validation enabled for immediate feedback
- Clear, specific error messages
- Validators run in order (empty check first)

### Example 2: Password Field

From `example/lib/main.dart` (lines 224-241):

```dart
form.TextField(
  id: "Password",
  textFieldTitle: "Password",
  description: "Enter your password",
  maxLines: 1,
  password: true,
  validateLive: true,
  onSubmit: (value) => _executeLogin(),
  validators: [
    form.Validator(
      validator: (value) => form.Validators.stringIsNotEmpty(value),
      reason: "Password cannot be empty.",
    ),
  ],
  leading: const Icon(Icons.lock),
)
```

**Key Points:**
- Obscured text with `password: true`
- Live validation for immediate feedback
- Submit handler triggers on Enter key
- Single validator checking for non-empty value

### Example 3: Checkbox Required Validation

From `example/lib/main.dart` (lines 266-288):

```dart
form.CheckboxSelect(
  id: "SelectBox",
  title: "Choose Multiple",
  description: "Select all that apply.",
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) => form.Validators.listIsNotEmpty(value),
      reason: "Please select at least one option.",
    ),
  ],
  defaultValue: [
    form.FieldOption(value: "Hiya", label: "Wat"),
  ],
  options: [
    form.FieldOption(value: "Hi", label: "Hello"),
    form.FieldOption(value: "Hiya", label: "Wat"),
    form.FieldOption(value: "Yoz", label: "Sup"),
  ],
)
```

**Key Points:**
- Uses `listIsNotEmpty` validator for multiselect
- Requires at least one selection
- Default value pre-selects one option
- Live validation updates on selection change

### Example 4: File Upload Validation

From `example/lib/main.dart` (lines 291-322):

```dart
form.FileUpload(
  id: "fileUpload",
  title: "Upload Images",
  description: "Drag & drop or click to upload (JPG, PNG only).",
  multiselect: true,
  validateLive: true,
  clearOnUpload: true,
  allowedExtensions: ['jpg', 'jpeg', 'png'],
  validators: [
    form.Validator(
      reason: "Only image files (JPG, PNG) are allowed.",
      validator: (value) => form.Validators.fileIsImage(value),
    ),
  ],
)
```

**Key Points:**
- File type validation with `fileIsImage`
- Restricted to specific extensions at picker level
- Validation confirms MIME type is image
- Supports multiple file uploads
- Clear indication of allowed file types

### Example 5: Custom Field Validation (Rating)

From `example/lib/main.dart` (lines 358-376):

```dart
RatingField(
  id: "satisfaction_rating",
  title: "Rate Your Experience",
  description: "Tap stars to rate (custom field example)",
  maxStars: 5,
  defaultValue: 0,
  validateLive: true,
  validators: [
    form.Validator(
      validator: (value) {
        // Validator receives raw field value (int for RatingField)
        if (value == null) return false;
        if (value is int) return value >= 3;
        return false;
      },
      reason: "Please rate at least 3 stars",
    ),
  ],
)
```

**Key Points:**
- Custom field type with integer value
- Type checking before validation logic
- Business rule: minimum 3-star rating
- Live validation on star selection
- Clear requirement in error message

### Example 6: Password Confirmation

Complete example with cross-field validation:

```dart
final List<form.FormElement> fields = [
  form.TextField(
    id: "password",
    textFieldTitle: "Password",
    password: true,
    validateLive: true,
    validators: [
      form.Validator(
        validator: (value) => form.Validators.stringIsNotEmpty(value),
        reason: "Password is required",
      ),
      form.Validator(
        validator: (value) {
          if (value is! String) return false;
          return value.length >= 8;
        },
        reason: "Password must be at least 8 characters",
      ),
    ],
  ),

  form.TextField(
    id: "password_confirm",
    textFieldTitle: "Confirm Password",
    password: true,
    validateLive: true,
    validators: [
      form.Validator(
        validator: (value) => form.Validators.stringIsNotEmpty(value),
        reason: "Please confirm your password",
      ),
      form.Validator(
        validator: (value) {
          final password = controller.getFieldValue<String>('password');
          final confirm = value is String ? value : '';
          return password == confirm;
        },
        reason: "Passwords do not match",
      ),
    ],
  ),
];
```

**Key Points:**
- Two separate fields with related validation
- Password field validates format
- Confirmation field validates match via controller
- Both use live validation for immediate feedback
- Cross-field validation accesses other field value

## Related Documentation

- [Form Results API](form-results.md) - Accessing and converting field values
- [Form Controller API](form-controller.md) - Managing form state and errors
- [Field Types](field-types.md) - Field-specific validation properties
- [Custom Fields](custom-fields.md) - Creating fields with custom validation logic
