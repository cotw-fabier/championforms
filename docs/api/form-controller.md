# FormController API Reference

The `FormController` is the central state management system in ChampionForms. It serves as the single source of truth for all form data, managing field values, validation errors, focus states, and TextEditingController lifecycles. Every ChampionForms implementation requires a controller instance to function.

## Table of Contents

- [Overview](#overview)
- [Initialization](#initialization)
- [Lifecycle Management](#lifecycle-management)
- [Value Management Methods](#value-management-methods)
- [Multiselect Methods](#multiselect-methods)
- [Focus Management Methods](#focus-management-methods)
- [Validation Methods](#validation-methods)
- [Error Management Methods](#error-management-methods)
- [Page Management](#page-management)
- [Field Management Methods](#field-management-methods)
- [Controller Methods](#controller-methods)
- [State Methods](#state-methods)
- [Active Fields](#active-fields)
- [TextEditingController Lifecycle](#texteditingcontroller-lifecycle)
- [Best Practices](#best-practices)
- [Complete Example](#complete-example)

---

## Overview

### What is FormController?

The `FormController` extends Flutter's `ChangeNotifier` and manages:

- **Field Values**: Generic storage for text, options, files, and custom field types
- **Validation State**: Runs validators, tracks errors, and manages error display
- **Focus State**: Tracks which field is currently focused and manages focus transitions
- **Page Grouping**: Organizes fields into pages for multi-step form workflows
- **Automatic Resource Management**: Handles TextEditingController and FocusNode lifecycle

### Why Does It Exist?

Forms are stateful by nature. Instead of scattering state across multiple widgets, ChampionForms centralizes all form state in a single controller. This provides:

- **Programmatic Control**: Update field values, trigger validation, manage focus from anywhere in your code
- **Reactive UI**: The controller notifies listeners on state changes, automatically rebuilding form widgets
- **Clean Architecture**: Separates form logic from UI presentation
- **Resource Safety**: Automatic disposal prevents memory leaks

---

## Initialization

### Basic Initialization

```dart
final controller = form.FormController();
```

Creates a controller with an automatically generated UUID identifier.

### Initialization with Custom ID

```dart
final controller = form.FormController(id: "userProfileForm");
```

**When to use custom IDs:**
- Managing multiple forms in the same widget tree
- Debugging and logging (easier to identify which form has errors)
- Form persistence (saving/loading form state by ID)

**Parameters:**
- `id` (String?, optional): Unique identifier for the controller. Auto-generated if not provided.
- `fields` (List<Field>, optional): Initial field definitions. Rarely used; fields are typically added via the `Form` widget.
- `formErrors` (List<FormBuilderError>, optional): Initial errors. Rarely used.
- `activeFields` (List<Field>, optional): Currently rendered fields. Managed automatically by `Form` widget.
- `pageFields` (Map<String, List<Field>>?, optional): Page groupings. Managed automatically.

---

## Lifecycle Management

### initState() Pattern

Initialize the controller in your widget's `initState()` method:

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
  Widget build(BuildContext context) {
    return form.Form(
      controller: controller,
      fields: myFields,
    );
  }
}
```

### dispose() - CRITICAL

**WARNING:** You MUST call `controller.dispose()` in your widget's `dispose()` method. Failure to dispose the controller will cause memory leaks as TextEditingControllers, FocusNodes, and other resources are never cleaned up.

```dart
@override
void dispose() {
  controller.dispose();  // ALWAYS call this
  super.dispose();
}
```

**What gets cleaned up:**
- All TextEditingController instances
- All FocusNode instances
- All ValueNotifier instances
- ChangeNotifier listener subscriptions

**Example from main.dart (lines 72-78):**

```dart
@override
void initState() {
  super.initState();
  // Initialize the controller
  controller = form.FormController();
}

@override
void dispose() {
  // --- IMPORTANT: Dispose the controller ---
  // This cleans up internal resources like TextEditingControllers.
  controller.dispose();
  super.dispose();
}
```

---

## Value Management Methods

### getFieldValue\<T\>()

Retrieves the current value for a field with type-safe casting.

**Method Signature:**
```dart
T? getFieldValue<T>(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- The field's current value cast to type `T`, or the field's default value if no value has been set, or `null` if neither exist.

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist
- `TypeError`: If stored value type doesn't match requested type `T`

**Examples:**

```dart
// Get text field value
final name = controller.getFieldValue<String>('name');

// Get multiselect value
final skills = controller.getFieldValue<List<form.FieldOption>>('skills');

// Check if value exists
final email = controller.getFieldValue<String>('email');
if (email != null) {
  print('Email: $email');
}
```

---

### updateFieldValue\<T\>()

Updates the value for a field, triggering `onChange` callbacks and live validation if enabled.

**Method Signature:**
```dart
void updateFieldValue<T>(String id, T? newValue, {bool noNotify = false})
```

**Parameters:**
- `id` (String): The unique identifier of the field
- `newValue` (T?): The new value to set, or `null` to clear
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Throws:**
- `ArgumentError`: If field with `id` does not exist

**Behavior:**
- Sets the field's value to `newValue`
- Triggers the field's `onChange` callback if value changed
- Runs validation if `validateLive: true` on the field
- Notifies listeners unless `noNotify: true`

**Examples from main.dart (lines 136-137):**

```dart
// Update text fields
controller.updateFieldValue("Email", "programmatic@example.com");
controller.updateFieldValue("Password", "newPassword123");

// Clear a field (revert to default)
controller.updateFieldValue<String>('email', null);

// Batch updates without notifications
controller.updateFieldValue<String>('name', 'John', noNotify: true);
controller.updateFieldValue<String>('email', 'john@example.com', noNotify: true);
controller.notifyListeners();
```

---

### createFieldValue\<T\>()

Creates or overwrites a field value WITHOUT requiring the field definition to exist. Useful for pre-populating values before field initialization.

**Method Signature:**
```dart
void createFieldValue<T>(
  String id,
  T? newValue,
  {bool noNotify = true, bool triggerCallbacks = false}
)
```

**Parameters:**
- `id` (String): The unique identifier for the field value
- `newValue` (T?): The value to set, or `null` to remove
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `true`
- `triggerCallbacks` (bool, optional): If `true`, runs `onChange` and validation. Default: `false`

**Difference from updateFieldValue:**
- Does NOT validate field existence
- Does NOT trigger callbacks by default (silent operation)
- Ideal for pre-population scenarios

**Examples:**

```dart
// Pre-populate values before fields are defined
controller.createFieldValue<String>('email', 'user@example.com');
controller.createFieldValue<String>('name', 'John Doe');

// Later, when fields are added, values will already be present
form.Form(controller: controller, fields: [emailField, nameField]);

// Create value with callbacks enabled
controller.createFieldValue<String>(
  'phone',
  '555-1234',
  triggerCallbacks: true,
);
```

---

### getAllFieldValues()

Returns all field values as a Map. Useful for debugging, serialization, or batch operations.

**Method Signature:**
```dart
Map<String, dynamic> getAllFieldValues()
```

**Returns:**
- Map of field ID to field value. May be empty if no values set.

**Example:**

```dart
final allValues = controller.getAllFieldValues();
print('Form data: $allValues');

// Save to local storage
await storage.write('form-draft', jsonEncode(allValues));
```

---

### setFieldValues()

Batch sets multiple field values at once. Suppresses individual notifications and notifies once after all values are set.

**Method Signature:**
```dart
void setFieldValues(Map<String, dynamic> values, {bool noNotify = false})
```

**Parameters:**
- `values` (Map<String, dynamic>): Map of field ID to value
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Note:** Only sets values for fields that exist. Ignores unknown field IDs.

**Example:**

```dart
// Load saved draft
final savedData = await storage.read('form-draft');
controller.setFieldValues(jsonDecode(savedData));

// Pre-populate from user profile
controller.setFieldValues({
  'name': user.name,
  'email': user.email,
});
```

---

### getFieldDefaultValue()

Retrieves the default value specified in the field definition.

**Method Signature:**
```dart
dynamic getFieldDefaultValue(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- The default value, or `null` if field doesn't exist or has no default.

**Example:**

```dart
final defaultEmail = controller.getFieldDefaultValue('email');
print('Default: $defaultEmail');
```

---

### hasFieldValue()

Checks if a field has a value explicitly set (even if that value is empty or null).

**Method Signature:**
```dart
bool hasFieldValue(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- `true` if field has an explicit value set, `false` otherwise.

**Example:**

```dart
// Check if user has interacted with field
if (controller.hasFieldValue('email')) {
  // User has entered something
}
```

---

### hasFieldDefinition()

Checks if a field definition exists in the controller.

**Method Signature:**
```dart
bool hasFieldDefinition(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- `true` if field has been registered, `false` otherwise.

**Example:**

```dart
if (controller.hasFieldDefinition('optional-notes')) {
  final notes = controller.getFieldValue<String>('optional-notes');
}
```

---

### isDirty

Checks if any field has been modified from its default value.

**Property:**
```dart
bool get isDirty
```

**Returns:**
- `true` if form has been modified, `false` if pristine.

**Example:**

```dart
// Warn before navigating away
if (controller.isDirty) {
  showDialog(/* "You have unsaved changes" */);
}
```

---

## Multiselect Methods

Methods specifically for managing multiselect and option-based fields (OptionSelect, CheckboxSelect, FileUpload).

### getMultiselectValue()

Retrieves the currently selected options for a multiselect field.

**Method Signature:**
```dart
List<form.FieldOption>? getMultiselectValue(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the multiselect field

**Returns:**
- List of selected options, empty list if none selected, or `null` if field has no value set.

**Example:**

```dart
// Get selected options
final selected = controller.getMultiselectValue('skills');
if (selected != null && selected.isNotEmpty) {
  print('Selected skills: ${selected.map((o) => o.label).join(", ")}');
}
```

---

### toggleMultiSelectValue()

Toggles specific options on or off for a multiselect or single-select field. This is the most convenient method for programmatically updating selections.

**Method Signature:**
```dart
void toggleMultiSelectValue(
  String fieldId,
  {List<String> toggleOn = const [],
   List<String> toggleOff = const [],
   bool noNotify = false}
)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field
- `toggleOn` (List<String>, optional): List of option **values** to ensure are selected
- `toggleOff` (List<String>, optional): List of option **values** to ensure are deselected
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist
- `TypeError`: If field is not an OptionSelect

**Behavior:**
- **Multi-select fields** (`multiselect: true`): Adds all toggleOn values and removes all toggleOff values
- **Single-select fields** (`multiselect: false`): Clears all selections and sets only the first toggleOn value (radio button behavior)

**IMPORTANT:** Uses the `value` property of `FieldOption`, NOT the label.

**Examples from main.dart (lines 141-150):**

```dart
// Multi-select: Select multiple options
controller.toggleMultiSelectValue(
  'skills',
  toggleOn: ['dart', 'flutter'],
);

// Deselect some options
controller.toggleMultiSelectValue(
  'skills',
  toggleOff: ['java', 'kotlin'],
);

// Combine toggleOn and toggleOff
controller.toggleMultiSelectValue(
  "SelectBox",
  toggleOn: ["Hi", "Yoz"], // Ensure "Hi" and "Yoz" are selected
  toggleOff: ["Hiya"],     // Ensure "Hiya" is deselected
);

// Single-select: Behaves like radio button (only one selected)
controller.toggleMultiSelectValue(
  'priority',  // multiselect: false
  toggleOn: ['high'],  // Clears other selections, only 'high' selected
);
```

---

### updateMultiselectValues()

Updates the selected value(s) for a multiselect or option field with more granular control than `toggleMultiSelectValue()`.

**Method Signature:**
```dart
void updateMultiselectValues(
  String id,
  List<form.FieldOption> newValue,
  {bool? multiselect,
   bool overwrite = false,
   bool noNotify = false,
   bool noOnChange = false}
)
```

**Parameters:**
- `id` (String): The unique identifier of the field
- `newValue` (List<FieldOption>): List of options to set or toggle
- `multiselect` (bool?, optional): If `true`, allows multiple selections. If `null`, infers from field definition
- `overwrite` (bool, optional): If `true`, replaces all selections. If `false`, toggles options. Default: `false`
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`
- `noOnChange` (bool, optional): If `true`, suppresses onChange callback. Default: `false`

**Throws:**
- `ArgumentError`: If field with `id` does not exist
- `TypeError`: If field is not an OptionSelect

**Examples:**

```dart
// Overwrite selections
controller.updateMultiselectValues(
  'skills',
  [option1, option2],
  overwrite: true,
);

// Toggle selections (add if not present, remove if present)
controller.updateMultiselectValues(
  'skills',
  [option3],
  overwrite: false,
);
```

---

### removeMultiSelectOptions()

Clears all selected options for a multiselect field.

**Method Signature:**
```dart
void removeMultiSelectOptions(
  String fieldId,
  {bool noNotify = false, bool noOnChange = false}
)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`
- `noOnChange` (bool, optional): If `true`, suppresses onChange callback. Default: `false`

**Example from main.dart (line 155):**

```dart
// Clear all file uploads
controller.removeMultiSelectOptions('attachments');

// Clear selections without notification
controller.removeMultiSelectOptions('skills', noNotify: true);
```

---

### resetMultiselectChoices()

Resets a multiselect field by clearing its selected values. Equivalent to `removeMultiSelectOptions()`.

**Method Signature:**
```dart
void resetMultiselectChoices(
  String fieldId,
  {bool noNotify = false, bool noOnChange = false}
)
```

---

## Focus Management Methods

### focusField()

Sets focus to the specified field programmatically.

**Method Signature:**
```dart
void focusField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to focus

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist

**Behavior:**
- Removes focus from any other field
- Updates field states (previously focused field becomes normal, new field becomes active)
- Notifies listeners
- Does nothing if field is already focused

**Examples:**

```dart
// Focus email field to draw user attention
controller.focusField('email');

// Focus first error field
if (controller.formErrors.isNotEmpty) {
  controller.focusField(controller.formErrors.first.fieldId);
}
```

---

### unfocusField()

Removes focus from the specified field programmatically.

**Method Signature:**
```dart
void unfocusField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to unfocus

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist

**Example:**

```dart
// Remove focus from current field
final focused = controller.currentlyFocusedFieldId;
if (focused != null) {
  controller.unfocusField(focused);
}
```

---

### setFieldFocus()

**Internal callback for field widgets to report focus changes.** Not intended for direct use by application code. Use `focusField()` or `unfocusField()` instead.

**Method Signature:**
```dart
void setFieldFocus(String fieldId, bool isFocused)
```

---

### isFieldFocused()

Checks if a specific field is currently focused.

**Method Signature:**
```dart
bool isFieldFocused(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to check

**Returns:**
- `true` if the field is focused, `false` otherwise.

**Example:**

```dart
if (controller.isFieldFocused('email')) {
  showAutocompleteSuggestions();
}
```

---

### currentlyFocusedFieldId

Returns the ID of the currently focused field, if any.

**Property:**
```dart
String? get currentlyFocusedFieldId
```

**Returns:**
- The field ID of the focused field, or `null` if no field is focused.

**Example:**

```dart
final focused = controller.currentlyFocusedFieldId;
if (focused != null) {
  print('Current field: $focused');
}
```

---

## Validation Methods

### validateForm()

Validates all active fields in the form. Runs all validators for every field in `activeFields` and updates the `formErrors` list.

**Method Signature:**
```dart
bool validateForm()
```

**Returns:**
- `true` if the form has no validation errors, `false` otherwise.

**Example:**

```dart
if (controller.validateForm()) {
  // Form is valid, proceed with submission
  final results = form.FormResults.getResults(controller: controller);
  submitData(results);
} else {
  // Show errors to user
  print('Form has ${controller.formErrors.length} errors');
}
```

---

### isFormValid

Quick check for whether the form currently has any validation errors. Does NOT re-run validators.

**Property:**
```dart
bool get isFormValid
```

**Returns:**
- `true` if `formErrors` is empty, `false` otherwise.

**Example:**

```dart
// In build method
ElevatedButton(
  onPressed: controller.isFormValid ? _handleSubmit : null,
  child: Text('Submit'),
)
```

---

### validateField()

Runs all validators for a specific field and updates `formErrors`.

**Method Signature:**
```dart
void validateField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to validate

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist

**Example:**

```dart
// Validate email field after user input
controller.validateField('email');

// Check for errors
final emailErrors = controller.findErrors('email');
if (emailErrors.isNotEmpty) {
  print('Email is invalid: ${emailErrors.first.reason}');
}
```

---

### validatePage()

Validates all fields on a specific page. Useful for multi-step forms.

**Method Signature:**
```dart
bool validatePage(String pageName)
```

**Parameters:**
- `pageName` (String): The name of the page to validate

**Returns:**
- `true` if all fields on the page are valid, `false` otherwise.

**Throws:**
- `ArgumentError`: If page with `pageName` does not exist

**Example:**

```dart
// Multi-step form validation
if (controller.validatePage('personal-info')) {
  // Move to next page
  navigateToNextPage();
} else {
  // Show errors on current page
  showErrorMessage('Please fix errors before continuing');
}
```

---

### isPageValid()

Quick check for whether a specific page has validation errors. Does NOT re-run validators.

**Method Signature:**
```dart
bool isPageValid(String pageName)
```

**Parameters:**
- `pageName` (String): The name of the page to check

**Returns:**
- `true` if no fields on the page have errors, `false` otherwise.

**Throws:**
- `ArgumentError`: If page with `pageName` does not exist

**Example:**

```dart
// Check if user can proceed to next page
final canProceed = controller.isPageValid('step-1');
```

---

### hasErrors()

Checks if the form or a specific field has validation errors.

**Method Signature:**
```dart
bool hasErrors(String? fieldId)
```

**Parameters:**
- `fieldId` (String?, optional): Field ID to check. If `null`, checks entire form.

**Returns:**
- `true` if errors exist, `false` otherwise.

**Examples:**

```dart
// Check specific field
if (controller.hasErrors('email')) {
  showErrorIndicator();
}

// Check entire form
if (controller.hasErrors(null)) {
  disableSubmitButton();
}
```

---

## Error Management Methods

### findErrors()

Finds all validation errors for a specific field.

**Method Signature:**
```dart
List<FormBuilderError> findErrors(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- List of errors for the field, or empty list if no errors exist.

**Example:**

```dart
// Check for field errors
final emailErrors = controller.findErrors('email');
if (emailErrors.isNotEmpty) {
  print('Email errors: ${emailErrors.map((e) => e.reason).join(", ")}');
}
```

---

### clearErrors()

Clears all validation errors for a specific field.

**Method Signature:**
```dart
void clearErrors(String fieldId, {bool noNotify = false})
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Clear errors when user starts correcting input
controller.clearErrors('email');

// Clear errors during batch operations
controller.clearErrors('name', noNotify: true);
controller.clearErrors('email', noNotify: true);
controller.notifyListeners();
```

---

### clearAllErrors()

Clears all validation errors from the form.

**Method Signature:**
```dart
void clearAllErrors({bool noNotify = false})
```

**Parameters:**
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Clear all errors when user starts fresh
controller.clearAllErrors();

// Or during batch operations
controller.clearAllErrors(noNotify: true);
// ... more operations
controller.notifyListeners();
```

---

### clearError()

Clears a specific validation error by its validator position. Less commonly used than `clearErrors()`.

**Method Signature:**
```dart
void clearError(
  String fieldId,
  int errorPosition,
  {bool noNotify = false}
)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field
- `errorPosition` (int): The index of the validator that generated the error
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Clear only the first validator's error
controller.clearError('email', 0);
```

---

### addError()

Manually adds a validation error to the form.

**Method Signature:**
```dart
void addError(FormBuilderError error, {bool noNotify = false})
```

**Parameters:**
- `error` (FormBuilderError): The error object to add
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Add a custom error
controller.addError(
  FormBuilderError(
    fieldId: 'username',
    reason: 'Username already taken',
    validatorPosition: 0,
  ),
);
```

---

## Page Management

Methods for organizing fields into pages for multi-step form workflows.

### updatePageFields()

Adds field definitions to a named page group.

**Method Signature:**
```dart
void updatePageFields(String pageName, List<Field> fields)
```

**Parameters:**
- `pageName` (String): Unique identifier for the page
- `fields` (List<Field>): List of field definitions to add to the page

**Note:** This is typically called automatically by the `Form` widget when `pageName` is specified.

**Example:**

```dart
// Manually organize fields into pages
controller.updatePageFields('personal-info', [nameField, emailField]);
controller.updatePageFields('address', [streetField, cityField]);

// Or let Form do it automatically:
form.Form(
  controller: controller,
  pageName: 'personal-info',
  fields: [nameField, emailField],
)
```

---

### getPageFields()

Retrieves all field definitions for a specific page.

**Method Signature:**
```dart
List<Field> getPageFields(String pageName)
```

**Parameters:**
- `pageName` (String): The unique identifier of the page

**Returns:**
- List of field definitions for the page, or empty list if page not found.

**Example:**

```dart
// Get fields for a specific page
final step1Fields = controller.getPageFields('step-1');

// Validate only fields on current page
final pageResults = form.FormResults.getResults(
  controller: controller,
  fields: controller.getPageFields('step-1'),
);
```

---

## Field Management Methods

Methods for dynamically managing field definitions.

### addFields()

Registers field definitions with this controller.

**Method Signature:**
```dart
void addFields(List<Field> newFields, {bool noNotify = false})
```

**Parameters:**
- `newFields` (List<Field>): List of field definitions to register
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Note:** This is typically called automatically by the `Form` widget. Manual use is for prepopulating multi-page forms.

**Example:**

```dart
// Multi-page form: prepopulate controller with all pages
controller.addFields([...page1Fields, ...page2Fields, ...page3Fields]);

// Then use the controller with different Form widgets
form.Form(controller: controller, fields: page1Fields)
```

---

### updateField()

Dynamically updates or adds a field definition.

**Method Signature:**
```dart
void updateField(Field field)
```

**Parameters:**
- `field` (Field): The field definition to update or add

**Example:**

```dart
// Dynamically disable a field
final updatedField = myField.copyWith(disabled: true);
controller.updateField(updatedField);

// Add a new field dynamically
controller.updateField(form.TextField(id: 'dynamic-field', ...));
```

---

### removeField()

Removes a field from the controller. Clears the field's value, errors, state, and definition. Disposes any associated controller or focus node.

**Method Signature:**
```dart
void removeField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to remove

**Example:**

```dart
// Conditionally remove a field based on user selection
if (userType == 'guest') {
  controller.removeField('account-password');
}
```

---

### hasField()

Checks if a field definition exists in the controller.

**Method Signature:**
```dart
bool hasField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to check

**Returns:**
- `true` if field exists, `false` otherwise.

**Example:**

```dart
if (controller.hasField('optional-notes')) {
  final notes = controller.getFieldValue<String>('optional-notes');
}
```

---

### resetField()

Resets a field to its default value and clears validation errors.

**Method Signature:**
```dart
void resetField(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field to reset

**Throws:**
- `ArgumentError`: If field with `fieldId` does not exist

**Example:**

```dart
// Reset field after error
controller.resetField('email');
```

---

### resetAllFields()

Resets all fields to their default values and clears all validation errors.

**Method Signature:**
```dart
void resetAllFields({bool noNotify = false})
```

**Parameters:**
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Reset form after submission
controller.resetAllFields();

// Or show confirmation dialog first
if (await confirmReset()) {
  controller.resetAllFields();
}
```

---

### clearForm()

Clears all field values without restoring defaults. Does not clear validation errors.

**Method Signature:**
```dart
void clearForm({bool noNotify = false})
```

**Parameters:**
- `noNotify` (bool, optional): If `true`, suppresses listener notification. Default: `false`

**Example:**

```dart
// Start fresh form
controller.clearForm();
controller.clearAllErrors();
```

---

### updateActiveFields()

Updates the list of currently rendered fields. Automatically called by the `Form` widget during its build lifecycle.

**Method Signature:**
```dart
void updateActiveFields(List<Field> fields, {bool noNotify = false})
```

**Note:** Not typically called directly by application code.

---

### removeActiveFields()

Removes fields from the active fields list. Automatically called by `Form` when the widget is torn down.

**Method Signature:**
```dart
void removeActiveFields(List<Field> fields, {bool noNotify = false})
```

**Note:** Not typically called directly by application code.

---

## Controller Methods

Methods for managing TextEditingController and FocusNode instances.

### controllerExists()

Checks if a TextEditingController exists for a field.

**Method Signature:**
```dart
bool controllerExists(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- `true` if a controller exists, `false` otherwise.

**Example:**

```dart
if (controller.controllerExists('description')) {
  // Controller is available
}
```

---

### getFieldController\<T\>()

Retrieves a controller for a specific field. Useful for advanced operations like cursor positioning.

**Method Signature:**
```dart
T? getFieldController<T>(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- The controller cast to type `T`, or `null` if not found or wrong type.

**Warning:** Direct controller manipulation may desync values. Generally prefer using `updateFieldValue()`.

**Example:**

```dart
// Get TextEditingController for advanced operations
final textController = controller.getFieldController<TextEditingController>('bio');
if (textController != null) {
  // Move cursor to end
  textController.selection = TextSelection.collapsed(
    offset: textController.text.length,
  );
}
```

---

### addFieldController\<T\>()

Stores a controller for a specific field. The controller will be automatically disposed when the form controller is disposed.

**Method Signature:**
```dart
void addFieldController<T>(String fieldId, T controller)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field
- `controller` (T): The controller instance to store

**Example:**

```dart
// Store a custom TextEditingController
final customController = TextEditingController(text: 'Initial value');
controller.addFieldController('description', customController);
```

---

## State Methods

### getFieldState()

Retrieves the current state of a field (normal, active, error, disabled).

**Method Signature:**
```dart
FieldState getFieldState(String fieldId)
```

**Parameters:**
- `fieldId` (String): The unique identifier of the field

**Returns:**
- The current `FieldState` for the field. Returns `FieldState.normal` if field not found.

**State Precedence (highest to lowest):**
1. Disabled (if `field.disabled` is true)
2. Error (if field has validation errors)
3. Active (if field is focused)
4. Normal (default state)

**Example:**

```dart
final state = controller.getFieldState('email');
if (state == FieldState.error) {
  // Show error indicator
}
```

---

## Active Fields

### activeFields Property

Contains the list of currently rendered field definitions. Automatically maintained by the `Form` widget lifecycle methods.

**Property:**
```dart
List<Field> activeFields
```

**What it contains:**
- Field objects currently being displayed in `Form` widgets
- Differs from `fields` which contains all registered fields

**When it updates:**
- When a `Form` widget builds
- When a `Form` widget is torn down

**Use cases:**
- Validating only currently visible fields
- Debugging which fields are rendered
- Conditional logic based on active form state

**Example:**

```dart
// Check if any fields are currently rendered
if (controller.activeFields.isNotEmpty) {
  print('Form is active with ${controller.activeFields.length} fields');
}

// Get list of active field IDs
final activeIds = controller.activeFields.map((f) => f.id).toList();
```

---

## TextEditingController Lifecycle

The FormController automatically manages TextEditingController instances for text fields, eliminating boilerplate and preventing memory leaks.

### How It Works

**Lazy Creation:**
- TextEditingControllers are created on-demand when text fields are first rendered
- Controllers are stored in an internal map using composite keys (fieldId + type)

**Automatic Registration:**
- Field widgets register their controllers with the FormController
- FormController tracks all controllers for proper disposal

**Automatic Disposal:**
- When `controller.dispose()` is called, all TextEditingControllers are disposed
- FocusNodes and other ChangeNotifier instances are also disposed

### Why You Shouldn't Create Them Manually

**Don't do this:**
```dart
// BAD: Manual controller creation
final nameController = TextEditingController();
controller.addFieldController('name', nameController);
```

**Do this instead:**
```dart
// GOOD: Let FormController manage it automatically
form.TextField(
  id: 'name',
  textFieldTitle: 'Name',
  // FormController creates and manages the TextEditingController
)
```

**Reasons:**
- FormController handles disposal automatically
- Prevents memory leaks
- Reduces boilerplate code
- Maintains consistency across field types

### When Manual Control Is Acceptable

Only create manual controllers for advanced use cases:
- Custom text manipulation (e.g., formatted input)
- Special cursor positioning logic
- Integration with third-party packages

Even then, register them using `addFieldController()` for automatic disposal.

---

## Best Practices

### 1. Always Dispose the Controller

**Critical:** Failure to dispose causes memory leaks.

```dart
@override
void dispose() {
  controller.dispose();  // ALWAYS
  super.dispose();
}
```

### 2. One Controller Per Form (Usually)

Each logical form should have its own controller. Don't share controllers across unrelated forms.

**Exception:** Multi-page forms can share a controller if all pages are part of the same logical form.

### 3. When to Use Controller IDs

Use custom IDs when:
- Managing multiple forms in one widget tree
- Debugging/logging form behavior
- Implementing form persistence

Skip custom IDs for simple single-form pages.

### 4. Accessing vs Storing Field Values

**Prefer accessing values from controller:**
```dart
// GOOD: Access from controller
final email = controller.getFieldValue<String>('email');
```

**Avoid storing field values separately:**
```dart
// BAD: Duplicate state management
String _email = '';
controller.updateFieldValue('email', _email); // Now you have two sources of truth
```

The controller IS your source of truth.

### 5. Performance Considerations

**Batch operations to avoid multiple rebuilds:**
```dart
// GOOD: Batch updates
controller.updateFieldValue('name', 'John', noNotify: true);
controller.updateFieldValue('email', 'john@example.com', noNotify: true);
controller.notifyListeners(); // Single rebuild

// BAD: Multiple rebuilds
controller.updateFieldValue('name', 'John');       // Rebuild 1
controller.updateFieldValue('email', 'john@example.com'); // Rebuild 2
```

**Use `noNotify: true` during:**
- Form initialization
- Batch value updates
- Programmatic pre-population

### 6. Validation Best Practices

**Run validation before form submission:**
```dart
final results = form.FormResults.getResults(controller: controller);
if (!results.errorState) {
  // Safe to proceed
}
```

**Use `validateLive: true` for critical fields:**
```dart
form.TextField(
  id: 'email',
  validateLive: true,  // Validate on blur
  validators: [emailValidator],
)
```

**Clear errors when user starts correcting:**
```dart
form.TextField(
  id: 'email',
  onChange: (results) {
    controller.clearErrors('email');  // Clear on change
  },
)
```

---

## Complete Example

Here's a full working example showing initialization, disposal, value management, validation, and programmatic interaction:

```dart
import 'package:flutter/material.dart';
import 'package:championforms/championforms.dart' as form;

class UserProfileForm extends StatefulWidget {
  const UserProfileForm({super.key});

  @override
  State<UserProfileForm> createState() => _UserProfileFormState();
}

class _UserProfileFormState extends State<UserProfileForm> {
  // 1. INITIALIZATION
  late form.FormController controller;

  @override
  void initState() {
    super.initState();
    controller = form.FormController(id: "userProfile");

    // Pre-populate from user data
    _loadUserData();
  }

  // 2. DISPOSAL (CRITICAL)
  @override
  void dispose() {
    controller.dispose();  // Always dispose
    super.dispose();
  }

  // 3. VALUE MANAGEMENT
  void _loadUserData() async {
    final userData = await fetchUserData();

    // Batch updates without notifications
    controller.setFieldValues({
      'name': userData.name,
      'email': userData.email,
      'bio': userData.bio,
    });
  }

  // 4. PROGRAMMATIC INTERACTION
  void _setDefaultValues() {
    controller.updateFieldValue('name', 'John Doe', noNotify: true);
    controller.updateFieldValue('email', 'john@example.com', noNotify: true);
    controller.toggleMultiSelectValue(
      'interests',
      toggleOn: ['flutter', 'dart'],
      noNotify: true,
    );
    controller.notifyListeners();
  }

  // 5. VALIDATION & SUBMISSION
  void _handleSubmit() async {
    // Validate form
    final results = form.FormResults.getResults(controller: controller);

    if (results.errorState) {
      // Show errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fix ${results.formErrors.length} error(s)',
          ),
        ),
      );

      // Focus first error field
      if (results.formErrors.isNotEmpty) {
        controller.focusField(results.formErrors.first.fieldId);
      }
      return;
    }

    // Extract values
    final name = results.grab('name').asString();
    final email = results.grab('email').asString();
    final bio = results.grab('bio').asString();
    final interests = results.grab('interests')
        .asMultiselectList()
        .map((opt) => opt.value)
        .toList();

    // Submit
    await submitProfile(name, email, bio, interests);

    // Reset form
    controller.resetAllFields();
  }

  @override
  Widget build(BuildContext context) {
    final fields = [
      form.TextField(
        id: 'name',
        textFieldTitle: 'Full Name',
        validateLive: true,
        validators: [
          form.Validator(
            validator: (r) => form.Validators.stringIsNotEmpty(r),
            reason: 'Name is required',
          ),
        ],
      ),
      form.TextField(
        id: 'email',
        textFieldTitle: 'Email Address',
        validateLive: true,
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
      ),
      form.TextField(
        id: 'bio',
        textFieldTitle: 'Bio',
        maxLines: 4,
        validators: [
          form.Validator(
            validator: (r) {
              final text = r.asString();
              return text.length <= 500;
            },
            reason: 'Bio must be 500 characters or less',
          ),
        ],
      ),
      form.CheckboxSelect(
        id: 'interests',
        title: 'Interests',
        options: [
          form.FieldOption(label: 'Flutter', value: 'flutter'),
          form.FieldOption(label: 'Dart', value: 'dart'),
          form.FieldOption(label: 'Firebase', value: 'firebase'),
          form.FieldOption(label: 'Design', value: 'design'),
        ],
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            form.Form(
              controller: controller,
              fields: fields,
              spacing: 12,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _setDefaultValues,
                  child: const Text('Set Defaults'),
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

---

## Related Documentation

- [Form Widget API](./form-widget.md) - Using the Form widget with controllers
- [FormResults API](./form-results.md) - Retrieving and validating form data
- [Field Types](../guides/field-types.md) - Available field types and their properties
- [Validation Guide](../guides/validation.md) - Creating and using validators
- [Multi-Step Forms Guide](../guides/multi-step-forms.md) - Using page management for wizards

---

## Version History

- **v0.6.0**: Added `createFieldValue()` for pre-population
- **v0.5.0**: Added compound field support
- **v0.4.0**: API modernization with namespace imports
- **v0.3.0**: Added page management, file upload support
- **v0.2.0**: Initial controller implementation

---

**Last Updated:** 2025-11-16
**Package Version:** 0.5.3
