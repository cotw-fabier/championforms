# FormResults API Reference

Complete reference guide for accessing and handling form results in ChampionForms.

## Table of Contents

- [Overview](#overview)
- [Getting Results](#getting-results)
- [FormResults Class](#formresults-class)
- [FieldResultAccessor](#fieldresultaccessor)
- [Type Conversion Methods](#type-conversion-methods)
  - [String Conversion](#string-conversion)
  - [Boolean Conversion](#boolean-conversion)
  - [Multiselect Conversion](#multiselect-conversion)
  - [File Conversion](#file-conversion)
  - [Numeric Conversion](#numeric-conversion)
  - [Compound Field Conversion](#compound-field-conversion)
  - [Raw Value Access](#raw-value-access)
- [Error Handling](#error-handling)
- [Best Practices](#best-practices)
- [Complete Examples](#complete-examples)
- [Type Conversion Reference](#type-conversion-reference)
- [Related Documentation](#related-documentation)

## Overview

The FormResults system in ChampionForms provides type-safe access to form data with automatic conversion and validation. It's designed to:

- **Trigger validation** when you request results
- **Collect all field values** in a type-safe manner
- **Convert values** to appropriate types (String, List, bool, etc.)
- **Handle defaults** gracefully when values are null
- **Provide error information** for failed validation

### Key Concepts

**FormResults** is the main container returned by `FormResults.getResults()`. It contains:
- All field values from the form
- Validation errors (if any)
- Field definitions for type conversion

**FieldResultAccessor** is what you get when you call `results.grab("fieldId")`. It provides:
- Type conversion methods (`asString()`, `asMultiselectList()`, etc.)
- Default value handling
- Safe access to potentially null values

### When to Get Results

You typically get results:
- **On form submission** - Validate and retrieve all data
- **On button click** - Process user input
- **On page change** - Validate current page in multi-step forms
- **For partial validation** - Check specific fields before proceeding

## Getting Results

### Basic Pattern

```dart
final results = FormResults.getResults(controller: controller);
```

### Complete Signature

```dart
FormResults.getResults({
  required FormController controller,  // The form controller managing state
  bool checkForErrors = true,          // Whether to run validation
  List<Field>? fields,                 // Optional: Process only specific fields
})
```

### What Happens When You Call getResults()

1. **Field Collection**: Gathers all active fields from the controller
2. **Value Retrieval**: Extracts current values for each field
3. **Validation Execution**: Runs validators on all fields (if `checkForErrors` is true)
4. **Error Aggregation**: Collects validation failures
5. **Results Construction**: Creates FormResults with values, definitions, and errors

### Usage Examples

```dart
// Standard usage - validate everything
final results = FormResults.getResults(controller: controller);

// Skip validation - just get values
final results = FormResults.getResults(
  controller: controller,
  checkForErrors: false,
);

// Process only specific fields
final results = FormResults.getResults(
  controller: controller,
  fields: controller.getPageFields('page1'),
);
```

## FormResults Class

The main results container with error state and field access.

### Properties

#### errorState

```dart
bool errorState
```

Quick boolean check if any validation failed.

**Returns**: `true` if validation errors exist, `false` otherwise

**Example**:
```dart
final results = FormResults.getResults(controller: controller);
if (results.errorState) {
  // Show error message to user
  print("Please fix form errors before continuing");
} else {
  // Process valid data
  submitToServer(results);
}
```

#### formErrors

```dart
List<FormBuilderError> formErrors
```

Complete list of all validation errors.

**Structure of FormBuilderError**:
```dart
class FormBuilderError {
  final String reason;          // Error message
  final String fieldId;         // Which field failed
  final int validatorPosition;  // Which validator in the list failed
}
```

**Example**:
```dart
if (results.errorState) {
  for (var error in results.formErrors) {
    print('Field "${error.fieldId}": ${error.reason}');
  }
}

// Example output:
// Field "email": Please enter a valid email address.
// Field "password": Password must be at least 8 characters.
```

### Methods

#### grab(String fieldId)

```dart
FieldResultAccessor grab(String fieldId)
```

Access a specific field's value with type conversion methods.

**Parameters**:
- `fieldId`: The unique identifier of the field

**Returns**: `FieldResultAccessor` with conversion methods

**Example**:
```dart
// Get string value
final name = results.grab("name").asString();

// Get multiselect options
final countries = results.grab("countries").asMultiselectList();

// Get uploaded files
final files = results.grab("avatar").asFileList();
```

**Note**: If the field doesn't exist, returns a dummy accessor that provides default values. Check `hasField()` if you need to verify field existence.

#### hasField(String fieldId)

```dart
bool hasField(String fieldId)
```

Check if a field definition exists for the given ID.

**Parameters**:
- `fieldId`: The unique identifier to check

**Returns**: `true` if field exists, `false` otherwise

**Example**:
```dart
if (results.hasField("optional_field")) {
  final value = results.grab("optional_field").asString();
  print("Optional field value: $value");
}
```

#### getAsRaw<T>(String fieldId)

```dart
T? getAsRaw<T>(String fieldId)
```

Get the raw value cast to type T without conversion.

**Parameters**:
- `fieldId`: The unique identifier of the field
- `T`: The expected type

**Returns**: Value cast to type T, or `null` if field doesn't exist or type doesn't match

**Example**:
```dart
// Get raw int from custom field
final rating = results.getAsRaw<int>("rating");

// Get raw List<FieldOption>
final options = results.getAsRaw<List<FieldOption>>("checkboxes");
```

## FieldResultAccessor

The object returned by `grab()` that provides type-safe conversion methods.

All conversion methods handle default values automatically:
- If the field value is `null`, returns the field's `defaultValue`
- If both are `null`, returns the method's fallback value
- Empty values are filtered appropriately (e.g., empty strings in compound fields)

## Type Conversion Methods

### String Conversion

#### asString()

```dart
String asString({String fallback = ""})
```

Convert field value to a String.

**Parameters**:
- `fallback`: Value to return if conversion fails (default: `""`)

**Returns**: String representation of the field value

**Use for**:
- TextField values
- Single-select OptionSelect (returns the selected option's value)
- Any field that stores string data

**Examples**:
```dart
// Text field
final email = results.grab("email").asString();
// Result: "user@example.com"

// Dropdown (single-select)
final country = results.grab("country").asString();
// Result: "USA" (the value, not the label)

// With custom fallback
final optional = results.grab("middle_name").asString(fallback: "N/A");
// Result: "N/A" if field is empty
```

From example app (main.dart line 92):
```dart
debugPrint("Email: ${results.grab("Email").asString()}");
```

#### asStringList()

```dart
List<String> asStringList({List<String> fallback = const []})
```

Convert field value to a List of Strings.

**Parameters**:
- `fallback`: Value to return if conversion fails (default: `[]`)

**Returns**: List of string values

**Use for**:
- Multiselect OptionSelect fields
- CheckboxSelect fields
- Any field storing multiple string values

**Examples**:
```dart
// Checkbox selection (extracts values from FieldOptions)
final selectedValues = results.grab("interests").asStringList();
// Result: ["sports", "music", "reading"]

// Empty multiselect
final empty = results.grab("optional_multiselect").asStringList();
// Result: [] (empty list, not null)
```

**Note**: This method extracts the `value` property from FieldOption objects, not the `label`.

### Boolean Conversion

#### asBool()

```dart
bool asBool({bool fallback = false})
```

Convert field value to a boolean.

**Parameters**:
- `fallback`: Value to return if conversion fails (default: `false`)

**Returns**: Boolean representation of the field value

**Conversion Rules**:
- `true`, `"true"`, `"1"`, `1` → `true`
- Everything else → `false`

**Use for**:
- Single checkbox fields
- Toggle/switch fields
- Boolean flags

**Examples**:
```dart
// Single checkbox
final agreedToTerms = results.grab("terms_checkbox").asBool();
// Result: true or false

// Switch field
final notifications = results.grab("enable_notifications").asBool();
// Result: true or false
```

#### asBoolMap()

```dart
Map<String, bool> asBoolMap()
```

Convert multiselect field to a map of option values to boolean states.

**Returns**: Map where keys are FieldOption values and values are true/false

**Use for**:
- Multiple checkboxes where you need individual state
- Feature toggles
- Permission settings

**Examples**:
```dart
// Multiple checkboxes
final permissions = results.grab("permissions").asBoolMap();
// Result: {
//   "read": true,
//   "write": false,
//   "delete": true,
// }

// Check specific permission
if (permissions["admin"] == true) {
  // User has admin permission
}
```

### Multiselect Conversion

#### asMultiselectList()

```dart
List<FieldOption> asMultiselectList()
```

Get selected options as a list of complete FieldOption objects.

**Returns**: List of FieldOption objects (default: `[]`)

**Use for**:
- Accessing full option data (value, label, additionalData)
- Multiselect dropdowns
- CheckboxSelect fields
- ChipSelect fields

**FieldOption Structure**:
```dart
class FieldOption {
  final String value;           // The submitted value
  final String label;           // Display text
  final String? hintText;       // Optional hint
  final Object? additionalData; // Custom data payload
}
```

**Examples**:
```dart
// Get all selected options
final options = results.grab("countries").asMultiselectList();

for (var option in options) {
  print("Value: ${option.value}");
  print("Label: ${option.label}");

  // Access custom data if available
  if (option.additionalData != null) {
    final countryCode = option.additionalData as String;
    print("Country code: $countryCode");
  }
}
```

From example app (main.dart line 97):
```dart
debugPrint(
  "Checkboxes: ${results.grab("SelectBox").asMultiselectList()
    .map((field) => field.value)
    .join(", ")}"
);
```

**Note**: Only works with OptionSelect-based fields. Returns empty list for other field types.

#### asMultiselectSingle()

```dart
FieldOption? asMultiselect(String optionValue)
```

Get a specific FieldOption by its value from the selected options.

**Parameters**:
- `optionValue`: The value to search for

**Returns**: Matching FieldOption or `null` if not found

**Use for**:
- Finding a specific selection
- Checking if a value is selected
- Accessing additionalData for a specific option

**Examples**:
```dart
// Check if specific option is selected
final usaOption = results.grab("countries").asMultiselect("USA");
if (usaOption != null) {
  print("USA is selected: ${usaOption.label}");
}

// Get custom data for selection
final option = results.grab("products").asMultiselect("prod_123");
if (option?.additionalData != null) {
  final productDetails = option!.additionalData as Map<String, dynamic>;
  print("Price: ${productDetails['price']}");
}
```

### File Conversion

#### asFileList()

```dart
List<FileModel> asFileList({List<FileModel> fallback = const []})
```

Get uploaded files as a list of FileModel objects.

**Parameters**:
- `fallback`: Value to return if conversion fails (default: `[]`)

**Returns**: List of FileModel objects

**Use for**:
- FileUpload fields with `multiselect: true`
- Processing uploaded files
- File validation

**FileModel Structure**:
```dart
class FileModel {
  final String fileName;        // Original filename
  final Uint8List? fileBytes;   // Complete file in memory
  final MimeData? mimeData;     // MIME type info
  final String? uploadExtension; // File extension (e.g., "pdf")

  Future<Uint8List?> getFileBytes() async // Get bytes asynchronously
  Future<MimeData> readMimeData() async   // Detect MIME type
}
```

**MimeData Structure**:
```dart
class MimeData {
  final String mime;       // MIME type (e.g., "image/png")
  final String extension;  // Extension (e.g., "png")
}
```

**Examples**:
```dart
// Get all uploaded files
final files = results.grab("attachments").asFileList();

for (var file in files) {
  print("Filename: ${file.fileName}");
  print("Size: ${file.fileBytes?.length ?? 0} bytes");
  print("MIME: ${file.mimeData?.mime ?? 'unknown'}");
  print("Extension: ${file.uploadExtension}");

  // Upload to server
  if (file.fileBytes != null) {
    await uploadToServer(file.fileName, file.fileBytes!);
  }
}
```

From example app (main.dart lines 107-123):
```dart
final fileResults = results.grab("fileUpload").asFileList();
if (fileResults.isNotEmpty) {
  debugPrint("Uploaded Files (${fileResults.length}):");
  for (final fileData in fileResults) {
    debugPrint(
      "  - Name: ${fileData.fileName}, "
      "Mime: ${fileData.mimeData?.mime ?? 'N/A'}"
    );

    // Access file bytes
    Uint8List? bytes = await fileData.getFileBytes();
    debugPrint("    Bytes length: ${bytes?.length ?? 'Not loaded'}");
  }
}
```

**Memory Warning**: FileModel stores entire files in memory. For large files (> 50MB), consider:
- Implementing `maxFileSize` validation
- Displaying size warnings to users
- Using streaming uploads for very large files

#### asFile()

```dart
FileModel? asFile()
```

Get the first uploaded file, or null if no files.

**Returns**: First FileModel or `null`

**Use for**:
- FileUpload fields with `multiselect: false`
- Single file uploads
- Avatar/profile picture uploads

**Examples**:
```dart
// Single file upload
final avatar = results.grab("profile_picture").asFile();
if (avatar != null) {
  print("Uploaded: ${avatar.fileName}");

  // Display image preview
  if (avatar.fileBytes != null) {
    Image.memory(avatar.fileBytes!);
  }
}
```

### Numeric Conversion

ChampionForms doesn't include built-in `asInt()` or `asDouble()` methods because field values are stored according to their type. For custom numeric fields:

#### Getting Numeric Values

```dart
// Option 1: Use asRaw<T> for custom numeric fields
final rating = results.getAsRaw<int>("rating");
// Result: 5 (or null if not set)

final price = results.getAsRaw<double>("price");
// Result: 29.99 (or null if not set)

// Option 2: Parse from string fields
final ageString = results.grab("age").asString();
final age = int.tryParse(ageString) ?? 0;

final priceString = results.grab("price").asString();
final price = double.tryParse(priceString) ?? 0.0;
```

**Best Practice**: Custom numeric fields should store their values as `int` or `double` in the controller, then use `getAsRaw<T>()` to retrieve them.

### Compound Field Conversion

#### asCompound()

```dart
String asCompound({
  String delimiter = ", ",
  String fallback = ""
})
```

Get compound field value as a joined string from all sub-fields.

**Parameters**:
- `delimiter`: String used to join sub-field values (default: `", "`)
- `fallback`: Value to return if no sub-fields found or all empty (default: `""`)

**Returns**: Joined string of all non-empty sub-field values

**How It Works**:
1. Detects compound fields by looking for sub-fields with pattern `{fieldId}_*`
2. Collects string values from each sub-field using `asString()`
3. Filters out empty values
4. Joins remaining values with the delimiter

**Use for**:
- NameField (firstName, middleName, lastName)
- AddressField (street, city, state, zip)
- Custom compound fields

**Examples**:

```dart
// NameField with default delimiter
final fullName = results.grab('customer_name').asCompound();
// Sub-fields: name_firstname="John", name_middlename="", name_lastname="Doe"
// Result: "John, Doe" (middlename filtered out because empty)

// NameField with space delimiter
final fullNameSpaced = results.grab('customer_name').asCompound(delimiter: ' ');
// Result: "John Doe"

// AddressField with default delimiter
final fullAddress = results.grab('shipping_address').asCompound();
// Sub-fields: address_street="123 Main St", address_city="Springfield",
//             address_state="IL", address_zip="62701"
// Result: "123 Main St, Springfield, IL, 62701"

// AddressField with newline delimiter for display
final addressBlock = results.grab('billing_address').asCompound(delimiter: '\n');
// Result: "456 Oak Ave
//          Apt 4
//          Chicago
//          IL
//          60601"
```

From compound field test (compound_field_results_test.dart):
```dart
final fullName = results.grab('name').asCompound();
// Result: "John, Michael, Doe"

final fullNameSpaced = results.grab('name').asCompound(delimiter: ' ');
// Result: "John Michael Doe"
```

**Accessing Individual Sub-Fields**:

You can still access sub-fields directly:

```dart
// Get individual values
final firstName = results.grab('name_firstName').asString();
final lastName = results.grab('name_lastName').asString();

final street = results.grab('address_street').asString();
final city = results.grab('address_city').asString();
final state = results.grab('address_state').asString();
final zip = results.grab('address_zip').asString();

// Or get compound value
final fullName = results.grab('name').asCompound(delimiter: ' ');
final fullAddress = results.grab('address').asCompound(delimiter: ', ');
```

**Error Handling**:

If called on a non-compound field (no sub-fields found), returns the fallback:

```dart
// "email" has no sub-fields
final result = results.grab('email').asCompound(fallback: 'NOT_COMPOUND');
// Result: "NOT_COMPOUND"
// Debug message: "asCompound called on field 'email' which has no sub-fields."
```

### Raw Value Access

#### value (property)

```dart
dynamic value
```

The raw field value without any conversion.

**Returns**: The actual value stored in the controller (type depends on field)

**Use for**:
- Custom handling not covered by conversion methods
- Debugging
- Advanced type checking

**Example**:
```dart
final accessor = results.grab("custom_field");
final rawValue = accessor.value;

if (rawValue is Map<String, dynamic>) {
  // Custom handling for complex data
  processCustomData(rawValue);
}
```

**Note**: Prefer typed conversion methods over raw access when possible for type safety.

## Error Handling

### Checking for Errors

Always check `errorState` before processing results:

```dart
final results = FormResults.getResults(controller: controller);

if (results.errorState) {
  // Validation failed - handle errors
  handleErrors(results.formErrors);
} else {
  // Validation passed - process data
  submitForm(results);
}
```

### Accessing Errors

#### From FormResults

```dart
if (results.errorState) {
  for (var error in results.formErrors) {
    print('Field ${error.fieldId}: ${error.reason}');
  }
}
```

#### From Controller

```dart
// Get errors for specific field
final emailErrors = controller.findErrors('email');
for (var error in emailErrors) {
  print('Email error: ${error.reason}');
}

// Check if specific field has errors
if (controller.findErrors('password').isNotEmpty) {
  print('Password validation failed');
}
```

### Error Display

The Form widget displays errors automatically below fields, but you can also show them manually:

```dart
// Show errors in a dialog
if (results.errorState) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Form Errors'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: results.formErrors.map((error) =>
          Text('${error.fieldId}: ${error.reason}')
        ).toList(),
      ),
    ),
  );
}
```

From example app (main.dart lines 124-130):
```dart
else {
  debugPrint("The form had errors:");
  debugPrint(results.formErrors
    .map((error) => "Field '${error.fieldId}' Error: ${error.reason}")
    .join("\n"));
}
```

### Field-Specific Error Checking

```dart
// Check before submitting
final results = FormResults.getResults(controller: controller);

if (results.errorState) {
  // Find which fields have errors
  final fieldsWithErrors = results.formErrors
    .map((e) => e.fieldId)
    .toSet()
    .toList();

  print('Please fix: ${fieldsWithErrors.join(", ")}');
}
```

## Best Practices

### 1. Always Check errorState First

```dart
// GOOD: Check errors before processing
final results = FormResults.getResults(controller: controller);
if (!results.errorState) {
  final name = results.grab("name").asString();
  submitToServer(name);
}

// BAD: Processing without checking errors
final results = FormResults.getResults(controller: controller);
final name = results.grab("name").asString(); // Might be invalid!
submitToServer(name);
```

### 2. Use Appropriate Conversion Methods

Choose the right conversion method for your field type:

```dart
// Text fields → asString()
final email = results.grab("email").asString();

// Multiselect → asMultiselectList()
final countries = results.grab("countries").asMultiselectList();

// Files → asFileList()
final files = results.grab("uploads").asFileList();

// Compound fields → asCompound()
final fullName = results.grab("name").asCompound();

// Custom numeric → getAsRaw<T>()
final rating = results.getAsRaw<int>("rating");
```

### 3. Handle Default Values

All conversion methods provide safe defaults. Understand what they return:

```dart
// Strings default to ""
final name = results.grab("name").asString();
// Returns "" if null, not null itself

// Lists default to []
final items = results.grab("items").asStringList();
// Returns [], never null

// Numbers need manual defaults
final age = int.tryParse(results.grab("age").asString()) ?? 0;

// Custom defaults
final status = results.grab("status").asString(fallback: "pending");
```

### 4. Access Sub-Fields for Compound Fields

You have two options for compound fields:

```dart
// Option 1: Get compound value
final fullName = results.grab('name').asCompound(delimiter: ' ');
// "John Michael Doe"

// Option 2: Access individual sub-fields
final firstName = results.grab('name_firstName').asString();
final middleName = results.grab('name_middleName').asString();
final lastName = results.grab('name_lastName').asString();

// Choose based on your needs:
// - Compound: For display or storage as single string
// - Individual: For separate processing or validation
```

### 5. File Upload Handling

Process files safely with proper checks:

```dart
final files = results.grab('upload').asFileList();

for (var file in files) {
  // Check file exists and has bytes
  if (file.fileBytes == null) {
    print('Warning: ${file.fileName} has no data');
    continue;
  }

  // Check file size (prevent memory issues)
  if (file.fileBytes!.length > 50 * 1024 * 1024) { // 50MB
    print('Warning: ${file.fileName} is too large');
    continue;
  }

  // Validate MIME type
  if (file.mimeData?.mime?.startsWith('image/') != true) {
    print('Warning: ${file.fileName} is not an image');
    continue;
  }

  // Process file
  await uploadToServer(file.fileName, file.fileBytes!);
}
```

### 6. Validation Before Submission

Validate incrementally for better UX:

```dart
// Validate on page change (multi-step forms)
void onNextPage() {
  final pageFields = controller.getPageFields('page1');
  final results = FormResults.getResults(
    controller: controller,
    fields: pageFields,
  );

  if (!results.errorState) {
    // Proceed to next page
    goToPage2();
  }
}

// Validate on final submit
void onSubmit() {
  final results = FormResults.getResults(controller: controller);

  if (!results.errorState) {
    // All pages valid - submit
    submitForm(results);
  }
}
```

### 7. Type Safety with Custom Fields

For custom fields storing complex types:

```dart
// Define strongly-typed accessor
class RatingAccessor {
  final FormResults results;
  RatingAccessor(this.results);

  int getRating(String fieldId) {
    return results.getAsRaw<int>(fieldId) ?? 0;
  }
}

// Use it
final accessor = RatingAccessor(results);
final rating = accessor.getRating("satisfaction");
```

## Complete Examples

### Example 1: Simple Form Submission

Basic email/password form with error handling:

```dart
void _handleLogin() {
  // Get results and trigger validation
  final results = FormResults.getResults(controller: controller);

  // Check error state
  if (!results.errorState) {
    // Validation passed - access values
    final email = results.grab("email").asString();
    final password = results.grab("password").asString();

    print("Logging in with email: $email");

    // Submit to server
    loginToServer(email, password);
  } else {
    // Validation failed - show errors
    print("Please fix the following errors:");
    for (var error in results.formErrors) {
      print("  - ${error.fieldId}: ${error.reason}");
    }
  }
}
```

From example app (main.dart lines 81-95):
```dart
void _executeLogin() {
  final form.FormResults results =
    form.FormResults.getResults(controller: controller);

  final errors = results.errorState;
  debugPrint("Current Error State is: $errors");

  if (!errors) {
    debugPrint("Email: ${results.grab("Email").asString()}");
    debugPrint("Password Set: ${results.grab("Password").asString().isNotEmpty}");
    debugPrint("Dropdown: ${results.grab("DropdownField").asString()}");
  }
}
```

### Example 2: Multiselect Processing

Handling checkbox selections:

```dart
void _processPreferences() {
  final results = FormResults.getResults(controller: controller);

  if (!results.errorState) {
    // Get selected options as FieldOption objects
    final interests = results.grab("interests").asMultiselectList();

    print("User selected ${interests.length} interests:");
    for (var option in interests) {
      print("  - ${option.label} (value: ${option.value})");

      // Access custom data if available
      if (option.additionalData != null) {
        final category = option.additionalData as String;
        print("    Category: $category");
      }
    }

    // Get just the values as strings
    final interestValues = results.grab("interests").asStringList();
    print("Values: ${interestValues.join(', ')}");

    // Save to database
    savePreferences(interestValues);
  }
}
```

From example app (main.dart line 96-97):
```dart
debugPrint(
  "Checkboxes: ${results.grab("SelectBox").asMultiselectList()
    .map((field) => field.value)
    .join(", ")}"
);
```

### Example 3: File Upload Processing

Complete file handling with validation:

```dart
Future<void> _handleFileUpload() async {
  final results = FormResults.getResults(controller: controller);

  if (!results.errorState) {
    final files = results.grab("attachments").asFileList();

    if (files.isEmpty) {
      print("No files uploaded");
      return;
    }

    print("Processing ${files.length} files:");

    for (var file in files) {
      // Display file info
      print("  File: ${file.fileName}");
      print("  Extension: ${file.uploadExtension}");
      print("  MIME: ${file.mimeData?.mime ?? 'unknown'}");

      // Get file bytes
      final bytes = await file.getFileBytes();
      if (bytes != null) {
        print("  Size: ${bytes.length} bytes");

        // Validate size
        if (bytes.length > 10 * 1024 * 1024) { // 10MB
          print("  ERROR: File too large!");
          continue;
        }

        // Upload to server
        try {
          await uploadFile(file.fileName, bytes);
          print("  ✓ Uploaded successfully");
        } catch (e) {
          print("  ✗ Upload failed: $e");
        }
      }
    }
  }
}
```

From example app (main.dart lines 106-123):
```dart
final fileResults = results.grab("fileUpload").asFileList();
if (fileResults.isNotEmpty) {
  debugPrint("Uploaded Files (${fileResults.length}):");
  for (final fileData in fileResults) {
    debugPrint(
      "  - Name: ${fileData.fileName}, "
      "Mime: ${fileData.mimeData?.mime ?? 'N/A'}"
    );

    // Access file bytes
    Uint8List? bytes = await fileData.getFileBytes();
    debugPrint("    Bytes length: ${bytes?.length ?? 'Not loaded'}");
  }
} else {
  debugPrint("No files uploaded.");
}
```

### Example 4: Error Handling and Display

Comprehensive error feedback:

```dart
void _validateAndSubmit() {
  final results = FormResults.getResults(controller: controller);

  if (results.errorState) {
    // Group errors by field for display
    final errorMap = <String, List<String>>{};
    for (var error in results.formErrors) {
      errorMap.putIfAbsent(error.fieldId, () => []);
      errorMap[error.fieldId]!.add(error.reason);
    }

    // Show errors in dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Please Fix Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errorMap.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...entry.value.map((reason) => Text('  • $reason')),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  } else {
    // Submit form
    submitForm(results);
  }
}
```

From example app (main.dart lines 124-130):
```dart
else {
  debugPrint("The form had errors:");
  debugPrint(results.formErrors
    .map((error) => "Field '${error.fieldId}' Error: ${error.reason}")
    .join("\n"));
}
```

### Example 5: Compound Field Results

NameField and AddressField access patterns:

```dart
void _processRegistration() {
  final results = FormResults.getResults(controller: controller);

  if (!results.errorState) {
    // Option 1: Get compound value as single string
    final fullName = results.grab('customer_name').asCompound(delimiter: ' ');
    print("Full name: $fullName");
    // Output: "John Michael Doe"

    // Option 2: Access individual sub-fields
    final firstName = results.grab('customer_name_firstName').asString();
    final middleName = results.grab('customer_name_middleName').asString();
    final lastName = results.grab('customer_name_lastName').asString();

    print("First: $firstName, Middle: $middleName, Last: $lastName");
    // Output: "First: John, Middle: Michael, Last: Doe"

    // AddressField - compound value
    final fullAddress = results.grab('shipping_address').asCompound(delimiter: ', ');
    print("Address: $fullAddress");
    // Output: "123 Main St, Apt 4, Springfield, IL, 62701"

    // AddressField - individual fields
    final street = results.grab('shipping_address_street').asString();
    final street2 = results.grab('shipping_address_street2').asString();
    final city = results.grab('shipping_address_city').asString();
    final state = results.grab('shipping_address_state').asString();
    final zip = results.grab('shipping_address_zip').asString();

    // Format for display
    final addressBlock = [
      street,
      if (street2.isNotEmpty) street2,
      '$city, $state $zip',
    ].join('\n');

    print("Formatted address:\n$addressBlock");
    // Output:
    // 123 Main St
    // Apt 4
    // Springfield, IL 62701

    // Save to database
    await saveCustomer(
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      fullName: fullName,
      address: fullAddress,
    );
  }
}
```

### Example 6: Multi-Step Form Validation

Validate pages incrementally:

```dart
class MultiStepFormController {
  final FormController controller;
  int currentPage = 0;

  MultiStepFormController(this.controller);

  Future<bool> validateCurrentPage() async {
    // Get fields for current page
    final pageFields = controller.getPageFields('page$currentPage');

    // Validate only current page
    final results = FormResults.getResults(
      controller: controller,
      fields: pageFields,
    );

    if (results.errorState) {
      // Show page-specific errors
      showErrors(results.formErrors);
      return false;
    }

    return true;
  }

  Future<void> nextPage() async {
    if (await validateCurrentPage()) {
      currentPage++;
      // Navigate to next page
    }
  }

  Future<void> submitForm() async {
    // Validate all pages
    final results = FormResults.getResults(controller: controller);

    if (!results.errorState) {
      // Extract data from all pages
      final personalInfo = _getPersonalInfo(results);
      final preferences = _getPreferences(results);
      final uploads = _getUploads(results);

      // Submit complete form
      await submitToServer({
        'personal': personalInfo,
        'preferences': preferences,
        'uploads': uploads,
      });
    }
  }

  Map<String, dynamic> _getPersonalInfo(FormResults results) {
    return {
      'name': results.grab('name').asCompound(delimiter: ' '),
      'email': results.grab('email').asString(),
      'phone': results.grab('phone').asString(),
    };
  }

  Map<String, dynamic> _getPreferences(FormResults results) {
    return {
      'interests': results.grab('interests').asStringList(),
      'newsletter': results.grab('newsletter').asBool(),
    };
  }

  List<String> _getUploads(FormResults results) {
    return results.grab('documents').asFileList()
      .map((f) => f.fileName)
      .toList();
  }
}
```

## Type Conversion Reference

Quick reference table for all conversion methods:

| Method | Return Type | Default | Use For | Example |
|--------|-------------|---------|---------|---------|
| `asString()` | String | `""` | Text fields, single select | `results.grab("email").asString()` |
| `asStringList()` | List\<String\> | `[]` | Multiselect values only | `results.grab("countries").asStringList()` |
| `asBool()` | bool | `false` | Checkbox, switch | `results.grab("terms").asBool()` |
| `asBoolMap()` | Map\<String, bool\> | `{}` | Multiple checkbox states | `results.grab("permissions").asBoolMap()` |
| `asMultiselectList()` | List\<FieldOption\> | `[]` | Full option objects | `results.grab("items").asMultiselectList()` |
| `asMultiselect()` | FieldOption? | `null` | Find specific option | `results.grab("items").asMultiselect("id")` |
| `asFileList()` | List\<FileModel\> | `[]` | File uploads | `results.grab("uploads").asFileList()` |
| `asFile()` | FileModel? | `null` | Single file upload | `results.grab("avatar").asFile()` |
| `asCompound()` | String | `""` | Compound fields joined | `results.grab("name").asCompound()` |
| `getAsRaw<T>()` | T? | `null` | Custom types | `results.getAsRaw<int>("rating")` |

### Fallback Parameters

Most conversion methods accept a custom fallback value:

```dart
// String with custom fallback
final status = results.grab("status").asString(fallback: "pending");

// List with custom fallback
final items = results.grab("items").asStringList(fallback: ["default"]);

// Bool with custom fallback
final enabled = results.grab("enabled").asBool(fallback: true);

// Compound with custom fallback
final name = results.grab("name").asCompound(
  delimiter: " ",
  fallback: "Anonymous"
);
```

## Related Documentation

- **[FormController Guide](../guides/form-controller.md)** - Managing form state and field values
- **[Validation Guide](../guides/validation.md)** - Creating validators and handling validation
- **[Field Types Reference](field-types.md)** - All available field types and their properties
- **[Compound Fields Guide](../guides/compound-fields.md)** - Creating and using compound fields like NameField and AddressField
- **[Custom Field Cookbook](../custom-fields/custom-field-cookbook.md)** - Creating custom field types with proper result handling
- **[Multi-Step Forms Guide](../guides/pages.md)** - Building paginated forms with partial validation
