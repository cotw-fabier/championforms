# Specification: ChampionFormController Cleanup Refactor

## 1. Overview

### Brief Description
This specification outlines a comprehensive refactor of the `ChampionFormController` class to improve code organization, add complete documentation, implement missing functionality, and establish consistent error handling patterns. The controller serves as the centralized state management hub for the ChampionForms package, managing field values, validation, focus states, and TextEditingController lifecycles.

### Goals and Objectives
1. **Improve Code Organization**: Restructure methods by visibility (public before private), then by functionality within each section
2. **Comprehensive Documentation**: Add dartdoc-style documentation to all public and private members with usage examples
3. **Add Missing Functionality**: Implement requested validation and field management helper methods
4. **Improve Error Handling**: Add try-catch blocks with clear, actionable error messages
5. **Remove Code Clutter**: Eliminate all commented-out code, debug statements, and dead code paths
6. **Consolidate Focus Management**: Simplify the focus-related API for better developer experience

### Success Criteria
- Code is organized logically with clear section delineation
- Every member has comprehensive dartdoc documentation
- All 8 new helper methods are implemented and tested
- Zero commented-out code blocks or debugPrint statements remain
- Focus management API is simplified and consolidated
- Error messages are clear and actionable for all public methods
- No breaking changes unless they significantly improve API consistency
- All existing integration points continue to work correctly

---

## 2. Current State Analysis

### Current Controller Structure
The `ChampionFormController` (789 lines) extends `ChangeNotifier` and manages:
- **Field Values**: Generic storage via `Map<String, dynamic> _fieldValues`
- **Field States**: Tracks states (normal/active/error/disabled) via `Map<String, FieldState> _fieldStates`
- **Field Definitions**: Stores field metadata via `Map<String, FormFieldDef> _fieldDefinitions`
- **Focus States**: Tracks focus via `Map<String, bool> _fieldFocusStates`
- **Controllers**: Manages TextEditingControllers and other controllers via `Map<String, dynamic> _fieldControllers`
- **Active Fields**: Tracks currently rendered fields via `List<FormFieldDef> activeFields`
- **Page Fields**: Groups fields by page name via `Map<String, List<FormFieldDef>> pageFields`
- **Validation Errors**: Stores errors via `List<FormBuilderError> formErrors`

### Identified Problems

#### 1. Poor Code Organization
- Methods are scattered without clear grouping
- No visibility-first organization (public and private methods mixed)
- Lifecycle methods (lines 99-187) are mixed with field management and validation
- Focus management has duplicate/overlapping methods across different sections
- No clear section headers or comments to guide navigation

#### 2. Incomplete Documentation
- Class-level documentation is absent (only inline comment at line 1)
- Many methods lack dartdoc comments (e.g., `getFieldState`, `updateActiveFields`, `addFields`)
- Properties lack documentation explaining their purpose (e.g., `_fieldValues`, `_fieldStates`, `_fieldDefinitions`)
- No usage examples for complex methods
- Documentation doesn't reference README patterns

#### 3. Code Clutter
- Commented-out code blocks:
  - Lines 33-38: Deprecated field declarations (`textFieldValues`)
  - Lines 42-43: Deprecated field (`fieldFocus`)
  - Lines 48-49: Deprecated field (`activeField`)
  - Lines 59-60: Deprecated field (`_textControllers`)
  - Lines 110-117: Commented collection clears in `dispose()`
- Multiple debugPrint statements throughout:
  - Lines 225-227, 376-377, 515-517, 687-688, 700, 715-716, 738-740, 743, 751-752, 760-762, 764-766

#### 4. Focus Management Confusion
Multiple overlapping methods for focus management:
- `addFocus(String fieldId)` (line 668): Sets focus, removes from others
- `removeFocus(String fieldId)` (line 693): Removes focus from field
- `setFieldFocus(String fieldId, bool isFocused)` (line 711): Called by field widgets
- `isFieldFocused(String fieldId)` (line 772): Check focus state
- `currentlyFocusedFieldId` getter (line 777): Get focused field ID

The API has redundancy and unclear responsibilities between these methods.

#### 5. Missing Functionality
The controller lacks several useful helper methods:

**Validation Methods**:
- No public way to validate all fields at once
- No public wrapper for `_validateField` (line 334 is private)
- No way to clear all errors at once
- No simple check for whether form/field has errors

**Field Management Methods**:
- No way to reset a field to its default value
- No way to reset entire form to defaults
- No check for whether a field has a non-default value set
- No public getter for a field's default value

#### 6. Error Handling Gaps
- Public methods lack try-catch blocks (e.g., `getFieldValue`, `updateFieldValue`)
- No error messages when:
  - Fields don't exist
  - Type mismatches occur
  - Operations are called on wrong field types
- Silent failures make debugging difficult
- No consistent error handling pattern across methods

#### 7. Inconsistent Patterns
- Some methods have `noNotify` parameter, others don't
- Some methods check field existence, others don't
- Inconsistent naming: `updateFieldValue` vs `updateMultiselectValues`
- `noOnChange` parameter exists in some methods but not consistently used

### Areas Needing Improvement
1. **Organization**: Implement visibility-first, then functionality-based grouping
2. **Documentation**: Add comprehensive dartdoc to every member
3. **API Completeness**: Add 8 missing helper methods
4. **Focus Clarity**: Consolidate to clear, minimal focus API
5. **Error Messages**: Add try-catch with actionable messages
6. **Code Quality**: Remove all clutter and dead code
7. **Consistency**: Standardize naming, parameters, and patterns

---

## 3. Proposed Changes

### 3.1 Code Organization

#### New Organization Structure
Organize the controller using **visibility-first**, then **functionality-based** grouping:

```
1. CLASS DOCUMENTATION & CONSTRUCTOR
   - Comprehensive class-level dartdoc
   - Constructor with parameters

2. PUBLIC PROPERTIES
   - id
   - fields
   - formErrors
   - activeFields
   - pageFields

3. PRIVATE PROPERTIES
   - _fieldValues
   - _fieldStates
   - _fieldDefinitions
   - _fieldFocusStates
   - _fieldControllers

4. PUBLIC LIFECYCLE METHODS
   - dispose()
   - addFields()
   - updateActiveFields()
   - removeActiveFields()
   - updatePageFields()
   - getPageFields()

5. PUBLIC FIELD VALUE METHODS
   - getFieldValue<T>()
   - updateFieldValue<T>()
   - getAllFieldValues() [NEW]
   - setFieldValues() [NEW]
   - getFieldDefaultValue() [NEW]
   - hasFieldValue() [NEW]

6. PUBLIC FIELD MANAGEMENT METHODS
   - updateField() [NEW]
   - removeField() [NEW]
   - hasField() [NEW]
   - resetField() [NEW]
   - resetAllFields() [NEW]
   - clearForm() [NEW]

7. PUBLIC MULTISELECT METHODS
   - getMultiselectValue()
   - updateMultiselectValues()
   - toggleMultiSelectValue()
   - removeMultiSelectOptions()
   - resetMultiselectChoices()

8. PUBLIC VALIDATION METHODS
   - validateForm() [NEW]
   - isFormValid [NEW getter]
   - validateField() [NEW - public wrapper]
   - validatePage() [NEW]
   - isPageValid() [NEW]
   - hasErrors() [NEW]
   - clearAllErrors() [NEW]

9. PUBLIC ERROR METHODS
   - findErrors()
   - clearErrors()
   - clearError()
   - addError()

10. PUBLIC FOCUS METHODS
    - focusField() [RENAMED from addFocus]
    - unfocusField() [RENAMED from removeFocus]
    - isFieldFocused()
    - currentlyFocusedFieldId [getter]
    - isDirty [NEW getter]

11. PUBLIC CONTROLLER METHODS
    - getFieldController<T>()
    - addFieldController<T>()
    - controllerExists()

12. PUBLIC STATE METHODS
    - getFieldState()

13. PRIVATE INTERNAL METHODS
    - _validateField()
    - _updateFieldState()
```

#### Method Grouping Strategy
- **Visibility First**: All public methods before private methods
- **Functionality Second**: Within public/private sections, group by purpose:
  - Lifecycle (setup/teardown)
  - Field values (get/set/batch operations)
  - Field management (add/remove/update/reset)
  - Multiselect operations
  - Validation operations
  - Error management
  - Focus management
  - Controller management
  - State queries
- **Related Methods Together**: Methods that work on the same data stay adjacent
- **Consistent Ordering**: Similar operations follow same order (get, set, check, clear)

#### Clear Section Headers
Add dartdoc-style section comments:

```dart
// =============================================================================
// PUBLIC LIFECYCLE METHODS
// =============================================================================
```

---

### 3.2 Documentation Requirements

#### Class-Level Documentation
Add comprehensive dartdoc at the class level (before `class ChampionFormController`):

```dart
/// Central state management controller for ChampionForms.
///
/// The [ChampionFormController] manages all aspects of form state including
/// field values, validation errors, focus states, and TextEditingController
/// lifecycles. It serves as the single source of truth for form data and
/// enables programmatic control over form fields.
///
/// ## Features
///
/// - **Centralized Value Storage**: Generic field value storage supporting
///   text, multiselect, file uploads, and custom types
/// - **Validation Management**: Run validators, track errors, clear errors
/// - **Focus Control**: Programmatically manage field focus states
/// - **Page Grouping**: Organize fields into pages for multi-step workflows
/// - **Lifecycle Management**: Automatic disposal of controllers and focus nodes
///
/// ## Basic Usage
///
/// ```dart
/// // 1. Create a controller
/// final controller = ChampionFormController();
///
/// // 2. Use in ChampionForm widget
/// ChampionForm(
///   controller: controller,
///   fields: myFields,
/// )
///
/// // 3. Access form data
/// final name = controller.getFieldValue<String>('name');
///
/// // 4. Validate form
/// if (controller.validateForm()) {
///   final results = FormResults.getResults(controller: controller);
///   // Process results...
/// }
///
/// // 5. Dispose when done
/// controller.dispose();
/// ```
///
/// ## Important Notes
///
/// - **Always call dispose()**: The controller manages many resources that
///   must be properly disposed to prevent memory leaks
/// - **ChangeNotifier**: Extends [ChangeNotifier], so listeners are notified
///   of state changes. Most methods accept a `noNotify` parameter to suppress
///   notifications during batch operations
/// - **Integration**: Designed to work seamlessly with [ChampionForm],
///   [FormFieldDef], and [FormResults]
///
/// See also:
/// - [ChampionForm] for the form widget
/// - [FormResults] for retrieving validated form data
/// - [FormFieldDef] for field definitions
class ChampionFormController extends ChangeNotifier {
  // ...
}
```

#### Method-Level Documentation Standards
Every method must have dartdoc including:

```dart
/// Brief one-sentence summary ending with period.
///
/// Longer description explaining behavior, edge cases, and usage patterns.
/// Multiple paragraphs if needed.
///
/// **Parameters:**
/// - [paramName]: Description of parameter and valid values
/// - [optionalParam]: Optional parameter with default behavior description
///
/// **Returns:**
/// Description of return value and possible values/types.
///
/// **Throws:**
/// - [ExceptionType]: When this exception is thrown
///
/// **Example:**
/// ```dart
/// final value = controller.getFieldValue<String>('email');
/// if (value != null) {
///   print('Email: $value');
/// }
/// ```
///
/// See also:
/// - [RelatedMethod] for related functionality
```

#### Property Documentation Standards
Every property must have dartdoc:

```dart
/// Brief description of property purpose.
///
/// Additional details about when/how it's populated and used.
/// For private properties, explain internal usage.
///
/// Example: `{'fieldId': 'value', 'anotherField': 123}`
final Map<String, dynamic> _fieldValues = {};
```

#### Usage Examples to Include
Complex methods should include code examples showing:
- Typical usage patterns
- Edge cases or special scenarios
- Integration with other controller methods
- Common pitfalls to avoid

Examples needed for:
- `addFields()` - Show multi-page form setup
- `getAllFieldValues()` / `setFieldValues()` - Show batch operations
- `validateForm()` - Show full validation flow
- `toggleMultiSelectValue()` - Show toggleOn/toggleOff usage
- `focusField()` / `unfocusField()` - Show focus management

---

### 3.3 New Functionality

#### 3.3.1 Validation Methods

##### `validateForm()`
```dart
/// Validates all active fields in the form.
///
/// Runs all validators for every field in [activeFields] and updates the
/// [formErrors] list. This method is typically called before retrieving
/// form results to ensure all data is valid.
///
/// **Returns:**
/// `true` if the form has no validation errors, `false` otherwise.
///
/// **Example:**
/// ```dart
/// if (controller.validateForm()) {
///   // Form is valid, proceed with submission
///   final results = FormResults.getResults(controller: controller);
///   submitData(results);
/// } else {
///   // Show errors to user
///   print('Form has ${controller.formErrors.length} errors');
/// }
/// ```
///
/// See also:
/// - [isFormValid] for a quick validity check without re-running validators
/// - [validateField] to validate a single field
/// - [validatePage] to validate fields on a specific page
bool validateForm() {
  // Implementation:
  // 1. Iterate through all activeFields
  // 2. Call _validateField() for each
  // 3. Return true if formErrors is empty after validation
}
```

##### `isFormValid` (getter)
```dart
/// Quick check for whether the form currently has any validation errors.
///
/// Unlike [validateForm], this getter does not re-run validators. It simply
/// checks if [formErrors] is currently empty. Use this for quick status checks
/// or to enable/disable submit buttons reactively.
///
/// **Returns:**
/// `true` if [formErrors] is empty, `false` otherwise.
///
/// **Example:**
/// ```dart
/// // In build method
/// ElevatedButton(
///   onPressed: controller.isFormValid ? _handleSubmit : null,
///   child: Text('Submit'),
/// )
/// ```
///
/// See also:
/// - [validateForm] to run validators and update error state
/// - [hasErrors] to check for errors on specific fields
bool get isFormValid => formErrors.isEmpty;
```

##### `validateField(String fieldId)`
```dart
/// Public wrapper to validate a specific field.
///
/// Runs all validators for the specified field and updates [formErrors].
/// Previously, field validation was only accessible internally via the
/// private [_validateField] method.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to validate
///
/// **Throws:**
/// - [ArgumentError]: If field with [fieldId] does not exist
///
/// **Example:**
/// ```dart
/// // Validate email field after user input
/// controller.validateField('email');
///
/// // Check for errors
/// final emailErrors = controller.findErrors('email');
/// if (emailErrors.isNotEmpty) {
///   print('Email is invalid: ${emailErrors.first.reason}');
/// }
/// ```
///
/// See also:
/// - [validateForm] to validate all fields at once
/// - [findErrors] to retrieve validation errors for a field
void validateField(String fieldId) {
  // Implementation:
  // 1. Check if field exists, throw ArgumentError if not
  // 2. Call _validateField(fieldId, notify: true)
}
```

##### `validatePage(String pageName)`
```dart
/// Validates all fields on a specific page.
///
/// Runs validators for all fields that were registered to the specified page
/// using the `pageName` parameter in [ChampionForm]. Useful for multi-step
/// forms where you want to validate one page at a time.
///
/// **Parameters:**
/// - [pageName]: The name of the page to validate
///
/// **Returns:**
/// `true` if all fields on the page are valid, `false` otherwise.
///
/// **Throws:**
/// - [ArgumentError]: If page with [pageName] does not exist
///
/// **Example:**
/// ```dart
/// // Multi-step form validation
/// if (controller.validatePage('personal-info')) {
///   // Move to next page
///   navigateToNextPage();
/// } else {
///   // Show errors on current page
///   showErrorMessage('Please fix errors before continuing');
/// }
/// ```
///
/// See also:
/// - [isPageValid] for a quick check without re-running validators
/// - [getPageFields] to retrieve fields on a page
/// - [validateForm] to validate entire form
bool validatePage(String pageName) {
  // Implementation:
  // 1. Get fields for page using getPageFields()
  // 2. Throw ArgumentError if page doesn't exist
  // 3. Run _validateField() for each field in page
  // 4. Return true if no errors found for those fields
}
```

##### `isPageValid(String pageName)`
```dart
/// Quick check for whether a specific page has validation errors.
///
/// Unlike [validatePage], this method does not re-run validators. It checks
/// if any fields on the specified page currently have errors in [formErrors].
///
/// **Parameters:**
/// - [pageName]: The name of the page to check
///
/// **Returns:**
/// `true` if no fields on the page have errors, `false` otherwise.
///
/// **Throws:**
/// - [ArgumentError]: If page with [pageName] does not exist
///
/// **Example:**
/// ```dart
/// // Check if user can proceed to next page
/// final canProceed = controller.isPageValid('step-1');
/// ```
///
/// See also:
/// - [validatePage] to run validators on page fields
/// - [isFormValid] to check entire form validity
bool isPageValid(String pageName) {
  // Implementation:
  // 1. Get fields for page using getPageFields()
  // 2. Throw ArgumentError if page doesn't exist
  // 3. Check if any field IDs from page appear in formErrors
  // 4. Return true if none found
}
```

##### `hasErrors(String? fieldId)`
```dart
/// Checks if the form or a specific field has validation errors.
///
/// When [fieldId] is provided, checks for errors on that specific field.
/// When [fieldId] is null, checks if the entire form has any errors.
///
/// **Parameters:**
/// - [fieldId]: Optional field ID to check. If null, checks entire form.
///
/// **Returns:**
/// `true` if errors exist, `false` otherwise.
///
/// **Example:**
/// ```dart
/// // Check specific field
/// if (controller.hasErrors('email')) {
///   showErrorIndicator();
/// }
///
/// // Check entire form
/// if (controller.hasErrors(null)) {
///   disableSubmitButton();
/// }
/// ```
///
/// See also:
/// - [findErrors] to retrieve the actual error objects
/// - [isFormValid] for checking form validity
bool hasErrors(String? fieldId) {
  // Implementation:
  // If fieldId is null, return formErrors.isNotEmpty
  // If fieldId provided, return formErrors.any((e) => e.fieldId == fieldId)
}
```

##### `clearAllErrors()`
```dart
/// Clears all validation errors from the form.
///
/// Removes all errors from [formErrors] and updates field states accordingly.
/// Notifies listeners unless [noNotify] is true.
///
/// **Parameters:**
/// - [noNotify]: If true, suppresses listener notification. Defaults to false.
///
/// **Example:**
/// ```dart
/// // Clear all errors when user starts fresh
/// controller.clearAllErrors();
///
/// // Or during batch operations
/// controller.clearAllErrors(noNotify: true);
/// // ... more operations
/// controller.notifyListeners();
/// ```
///
/// See also:
/// - [clearErrors] to clear errors for a specific field
/// - [validateForm] to re-run validation
void clearAllErrors({bool noNotify = false}) {
  // Implementation:
  // 1. Get list of unique field IDs with errors
  // 2. Clear formErrors list
  // 3. Update state for all affected fields using _updateFieldState()
  // 4. Notify listeners if !noNotify
}
```

#### 3.3.2 Field Management Methods

##### `updateField(FormFieldDef field)`
```dart
/// Dynamically updates or adds a field definition.
///
/// If a field with the same ID exists, replaces its definition. If not,
/// adds it as a new field. Updates field state after modification.
///
/// **Parameters:**
/// - [field]: The field definition to update or add
///
/// **Example:**
/// ```dart
/// // Dynamically disable a field
/// final updatedField = myField.copyWith(disabled: true);
/// controller.updateField(updatedField);
///
/// // Add a new field dynamically
/// controller.updateField(ChampionTextField(id: 'dynamic-field', ...));
/// ```
///
/// See also:
/// - [addFields] to add multiple fields at once
/// - [removeField] to remove a field
void updateField(FormFieldDef field) {
  // Implementation:
  // 1. Update _fieldDefinitions[field.id] = field
  // 2. Ensure _fieldFocusStates has entry for field
  // 3. Call _updateFieldState(field.id)
  // 4. Call notifyListeners()
}
```

##### `removeField(String fieldId)`
```dart
/// Removes a field from the controller.
///
/// Clears the field's value, errors, state, and definition. Disposes any
/// associated controller or focus node.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to remove
///
/// **Example:**
/// ```dart
/// // Conditionally remove a field based on user selection
/// if (userType == 'guest') {
///   controller.removeField('account-password');
/// }
/// ```
///
/// **Note:** This does not update [activeFields] or [pageFields]. Use
/// [removeActiveFields] for managing rendered fields.
///
/// See also:
/// - [updateField] to modify a field
/// - [clearForm] to clear all field values
void removeField(String fieldId) {
  // Implementation:
  // 1. Remove from _fieldDefinitions
  // 2. Remove from _fieldValues
  // 3. Remove from _fieldStates
  // 4. Remove from _fieldFocusStates
  // 5. Dispose and remove from _fieldControllers if exists
  // 6. Clear errors for field
  // 7. Notify listeners
}
```

##### `hasField(String fieldId)`
```dart
/// Checks if a field definition exists in the controller.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to check
///
/// **Returns:**
/// `true` if field exists, `false` otherwise.
///
/// **Example:**
/// ```dart
/// if (controller.hasField('optional-notes')) {
///   final notes = controller.getFieldValue<String>('optional-notes');
/// }
/// ```
bool hasField(String fieldId) {
  // Implementation: return _fieldDefinitions.containsKey(fieldId);
}
```

##### `resetField(String fieldId)`
```dart
/// Resets a field to its default value.
///
/// Sets the field's value back to its [FormFieldDef.defaultValue] and clears
/// any validation errors for that field.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to reset
///
/// **Throws:**
/// - [ArgumentError]: If field with [fieldId] does not exist
///
/// **Example:**
/// ```dart
/// // Reset field after error
/// controller.resetField('email');
/// ```
///
/// See also:
/// - [resetAllFields] to reset entire form
/// - [getFieldDefaultValue] to retrieve default without resetting
void resetField(String fieldId) {
  // Implementation:
  // 1. Check field exists, throw ArgumentError if not
  // 2. Get default value from _fieldDefinitions[fieldId]?.defaultValue
  // 3. Call updateFieldValue with default value
  // 4. Call clearErrors(fieldId)
}
```

##### `resetAllFields()`
```dart
/// Resets all fields to their default values.
///
/// Iterates through all field definitions and resets each to its
/// [FormFieldDef.defaultValue]. Clears all validation errors.
///
/// **Parameters:**
/// - [noNotify]: If true, suppresses listener notification. Defaults to false.
///
/// **Example:**
/// ```dart
/// // Reset form after submission
/// controller.resetAllFields();
///
/// // Or show confirmation dialog first
/// if (await confirmReset()) {
///   controller.resetAllFields();
/// }
/// ```
///
/// See also:
/// - [resetField] to reset a single field
/// - [clearForm] to clear all values without restoring defaults
void resetAllFields({bool noNotify = false}) {
  // Implementation:
  // 1. Iterate _fieldDefinitions.keys
  // 2. For each, call updateFieldValue with defaultValue (noNotify: true)
  // 3. Call clearAllErrors(noNotify: true)
  // 4. Call notifyListeners() if !noNotify
}
```

##### `clearForm()`
```dart
/// Clears all field values without restoring defaults.
///
/// Removes all entries from [_fieldValues], effectively setting all fields
/// to empty/null. Does not clear validation errors.
///
/// **Parameters:**
/// - [noNotify]: If true, suppresses listener notification. Defaults to false.
///
/// **Example:**
/// ```dart
/// // Start fresh form
/// controller.clearForm();
/// controller.clearAllErrors();
/// ```
///
/// See also:
/// - [resetAllFields] to reset to default values instead
/// - [clearAllErrors] to clear validation errors
void clearForm({bool noNotify = false}) {
  // Implementation:
  // 1. Clear _fieldValues map
  // 2. Update state for all fields that had values
  // 3. Notify listeners if !noNotify
}
```

##### `getAllFieldValues()`
```dart
/// Returns all field values as a Map.
///
/// Useful for debugging, serialization, or batch operations. Includes only
/// fields that have values set (not default values unless explicitly set).
///
/// **Returns:**
/// Map of field ID to field value. May be empty if no values set.
///
/// **Example:**
/// ```dart
/// final allValues = controller.getAllFieldValues();
/// print('Form data: $allValues');
///
/// // Save to local storage
/// await storage.write('form-draft', jsonEncode(allValues));
/// ```
///
/// See also:
/// - [setFieldValues] to batch set values
/// - [getFieldValue] to get a single value
Map<String, dynamic> getAllFieldValues() {
  // Implementation: return Map.from(_fieldValues);
}
```

##### `setFieldValues(Map<String, dynamic> values)`
```dart
/// Batch sets multiple field values at once.
///
/// Useful for loading saved form data or pre-populating forms. Suppresses
/// individual notifications and notifies once after all values are set.
///
/// **Parameters:**
/// - [values]: Map of field ID to value
/// - [noNotify]: If true, suppresses listener notification. Defaults to false.
///
/// **Example:**
/// ```dart
/// // Load saved draft
/// final savedData = await storage.read('form-draft');
/// controller.setFieldValues(jsonDecode(savedData));
///
/// // Pre-populate from user profile
/// controller.setFieldValues({
///   'name': user.name,
///   'email': user.email,
/// });
/// ```
///
/// **Note:** Only sets values for fields that exist. Ignores unknown field IDs.
///
/// See also:
/// - [getAllFieldValues] to retrieve all values
/// - [updateFieldValue] to set a single value
void setFieldValues(Map<String, dynamic> values, {bool noNotify = false}) {
  // Implementation:
  // 1. Iterate values.entries
  // 2. For each entry, check if field exists
  // 3. Call updateFieldValue with noNotify: true
  // 4. After loop, call notifyListeners() if !noNotify
}
```

##### `getFieldDefaultValue(String fieldId)`
```dart
/// Retrieves the default value for a field.
///
/// Returns the [FormFieldDef.defaultValue] specified in the field definition.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field
///
/// **Returns:**
/// The default value, or null if field doesn't exist or has no default.
///
/// **Example:**
/// ```dart
/// final defaultEmail = controller.getFieldDefaultValue('email');
/// print('Default: $defaultEmail');
/// ```
///
/// See also:
/// - [resetField] to reset field to default value
dynamic getFieldDefaultValue(String fieldId) {
  // Implementation: return _fieldDefinitions[fieldId]?.defaultValue;
}
```

##### `hasFieldValue(String fieldId)`
```dart
/// Checks if a field has a value explicitly set.
///
/// Returns `true` if the field has a value in [_fieldValues], even if that
/// value is empty or null. Returns `false` if the field has never been set
/// and is relying on its default value.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field
///
/// **Returns:**
/// `true` if field has an explicit value set, `false` otherwise.
///
/// **Example:**
/// ```dart
/// // Check if user has interacted with field
/// if (controller.hasFieldValue('email')) {
///   // User has entered something
/// }
/// ```
///
/// See also:
/// - [getFieldValue] to retrieve the value
bool hasFieldValue(String fieldId) {
  // Implementation: return _fieldValues.containsKey(fieldId);
}
```

##### `isDirty` (getter)
```dart
/// Checks if any field has been modified from its default value.
///
/// Returns `true` if any field in [_fieldValues] differs from its default,
/// or if any field has a value set when it has no default.
///
/// **Returns:**
/// `true` if form has been modified, `false` if pristine.
///
/// **Example:**
/// ```dart
/// // Warn before navigating away
/// if (controller.isDirty) {
///   showDialog(/* "You have unsaved changes" */);
/// }
/// ```
///
/// See also:
/// - [resetAllFields] to restore defaults
bool get isDirty {
  // Implementation:
  // 1. Iterate _fieldValues.entries
  // 2. For each, get defaultValue from _fieldDefinitions
  // 3. If current value != default, return true
  // 4. Return false if all match defaults
}
```

---

### 3.4 Focus Management Consolidation

#### Current Focus Management Approach
The controller currently has multiple methods for focus management with overlapping responsibilities:

1. **`addFocus(String fieldId)`** (line 668): Sets focus to a field, removes focus from others
2. **`removeFocus(String fieldId)`** (line 693): Removes focus from a field
3. **`setFieldFocus(String fieldId, bool isFocused)`** (line 711): Called by field widgets when focus changes
4. **`isFieldFocused(String fieldId)`** (line 772): Checks if field is focused
5. **`currentlyFocusedFieldId` getter** (line 777): Returns currently focused field ID

**Issues:**
- Unclear which method to use for programmatic focus control
- `setFieldFocus` should be the internal callback, but naming doesn't indicate this
- `addFocus`/`removeFocus` suggest adding to a list, not exclusive focus control

#### Proposed Consolidated Approach

**Public API (for developers using the controller):**

```dart
/// Sets focus to the specified field programmatically.
///
/// Removes focus from any other field and updates field states. Field widgets
/// will be notified through the [ChangeNotifier] mechanism.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to focus
///
/// **Throws:**
/// - [ArgumentError]: If field with [fieldId] does not exist
///
/// **Example:**
/// ```dart
/// // Focus email field to draw user attention
/// controller.focusField('email');
///
/// // Focus first error field
/// if (controller.formErrors.isNotEmpty) {
///   controller.focusField(controller.formErrors.first.fieldId);
/// }
/// ```
///
/// See also:
/// - [unfocusField] to remove focus from a field
/// - [currentlyFocusedFieldId] to get focused field
void focusField(String fieldId) {
  // Implementation: Same as current addFocus(), but with validation
}

/// Removes focus from the specified field programmatically.
///
/// Updates field state to reflect unfocused status. Field widgets will be
/// notified through the [ChangeNotifier] mechanism.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to unfocus
///
/// **Throws:**
/// - [ArgumentError]: If field with [fieldId] does not exist
///
/// **Example:**
/// ```dart
/// // Remove focus from current field
/// final focused = controller.currentlyFocusedFieldId;
/// if (focused != null) {
///   controller.unfocusField(focused);
/// }
/// ```
///
/// See also:
/// - [focusField] to set focus to a field
/// - [isFieldFocused] to check focus state
void unfocusField(String fieldId) {
  // Implementation: Same as current removeFocus(), but with validation
}

/// Checks if a specific field is currently focused.
///
/// **Parameters:**
/// - [fieldId]: The unique identifier of the field to check
///
/// **Returns:**
/// `true` if field is focused, `false` otherwise.
///
/// **Example:**
/// ```dart
/// if (controller.isFieldFocused('email')) {
///   showAutocompleteSuggestions();
/// }
/// ```
bool isFieldFocused(String fieldId) {
  // Keep existing implementation
}

/// Returns the ID of the currently focused field, if any.
///
/// **Returns:**
/// The field ID of the focused field, or null if no field is focused.
///
/// **Example:**
/// ```dart
/// final focused = controller.currentlyFocusedFieldId;
/// if (focused != null) {
///   print('Current field: $focused');
/// }
/// ```
String? get currentlyFocusedFieldId {
  // Keep existing implementation
}
```

**Internal API (for field widgets):**

```dart
/// Internal callback for field widgets to report focus changes.
///
/// Called by field widgets when their focus state changes. Manages the
/// internal focus map and updates field states. Not intended for direct use.
///
/// **Parameters:**
/// - [fieldId]: The field reporting focus change
/// - [isFocused]: Whether the field gained or lost focus
///
/// **Note:** For programmatic focus control, use [focusField] or [unfocusField]
/// instead.
void setFieldFocus(String fieldId, bool isFocused) {
  // Keep existing implementation with added error handling
}
```

#### Migration Path for Existing Code

**Breaking Changes:**
- Rename `addFocus()` to `focusField()`
- Rename `removeFocus()` to `unfocusField()`
- Make `setFieldFocus()` clearly documented as internal use only

**Migration Guide:**
```dart
// OLD
controller.addFocus('email');
controller.removeFocus('email');

// NEW
controller.focusField('email');
controller.unfocusField('email');
```

**Justification:**
- `focusField`/`unfocusField` are clearer and more intuitive names
- Matches common UI framework conventions (e.g., `.focus()`, `.blur()`)
- Makes the API's intent immediately obvious to new users
- Minimal breaking change impact (simple find-replace in consuming code)

---

### 3.5 Error Handling Improvements

#### Current Error Handling Issues
1. **No validation in public methods**: Methods like `getFieldValue`, `updateFieldValue` don't check if field exists
2. **Silent failures**: Type mismatches return null without warning
3. **No exception throwing**: Missing fields don't throw descriptive errors
4. **Inconsistent patterns**: Some methods check existence, others don't
5. **Poor debuggability**: No context in error messages

#### Proposed Error Reporting Mechanism
Implement consistent try-catch pattern with clear error messages:

```dart
/// Example pattern for field access methods
T? getFieldValue<T>(String fieldId) {
  try {
    // Validate field exists
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}'
      );
    }

    final value = _fieldValues[fieldId];

    // Type validation
    if (value != null && value is! T && T != dynamic) {
      throw TypeError(
        'Field "$fieldId" has type ${value.runtimeType} but requested type $T. '
        'Ensure field definition matches requested type.'
      );
    }

    if (value is T || T is dynamic) {
      return value;
    }

    // Return default value if no value set
    final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;
    if (defaultValue is T) {
      return defaultValue;
    }

    return null;
  } catch (e) {
    // Re-throw ArgumentError and TypeError
    if (e is ArgumentError || e is TypeError) {
      rethrow;
    }
    // Log unexpected errors
    debugPrint('Unexpected error in getFieldValue("$fieldId"): $e');
    return null;
  }
}
```

#### Error Handling by Method Category

**Field Access Methods** (`getFieldValue`, `updateFieldValue`, etc.):
- Throw `ArgumentError` if field doesn't exist
- Throw `TypeError` if type mismatch
- Include field ID and available fields in message
- Include expected vs actual types in message

**Field Management Methods** (`resetField`, `validateField`, etc.):
- Throw `ArgumentError` if field doesn't exist
- Include suggestion for correct usage
- List available fields when field not found

**Page Methods** (`validatePage`, `isPageValid`, etc.):
- Throw `ArgumentError` if page doesn't exist
- List available page names in error message

**Multiselect Methods** (`updateMultiselectValues`, `toggleMultiSelectValue`, etc.):
- Throw `ArgumentError` if field doesn't exist
- Throw `TypeError` if field is not `ChampionOptionSelect`
- Provide clear message about expected field type

**Example Error Messages:**
```
ArgumentError: Field "emial" does not exist in controller. Did you mean "email"? Available fields: name, email, phone

TypeError: Field "status" has type String but requested type List<MultiselectOption>. Ensure you're using the correct field access method.

ArgumentError: Cannot validate page "step-4". Page does not exist. Available pages: step-1, step-2, step-3

TypeError: Cannot toggle multiselect values on field "comments". Field is of type ChampionTextField, not ChampionOptionSelect.
```

#### Error Callback or Stream Design
Do not implement global error callback/stream in this refactor. Keep error handling localized to method calls with exceptions. Rationale:
- Simpler mental model for developers
- Exceptions are the Dart-idiomatic approach
- Allows call-site error handling flexibility
- Avoids complexity of global error management state
- Can be added later if needed without breaking changes

---

### 3.6 Code Cleanup

#### Commented Code to Remove

**Lines 33-38: Deprecated textFieldValues**
```dart
  /// Handle text field default values
  /// depreciated
  // List<TextFormFieldValueById> textFieldValues;
```
**Action:** Delete entirely

---

**Lines 42-43: Deprecated fieldFocus**
```dart
  /// Handle form focus controllers
  /// Depreciated
  // List<FieldFocus> fieldFocus;
```
**Action:** Delete entirely

---

**Lines 48-49: Deprecated activeField**
```dart
  /// Currently active field. This follows field focus
  /// DEPRECIATED? (Using currentlyFocusedFieldId getter now)
  // FormFieldDef? activeField;
```
**Action:** Delete entirely

---

**Lines 59-60: Deprecated _textControllers**
```dart
  /// List of texteditingcontrollers for direct access to text fields
  /// depreciated
  // final List<FieldController> _textControllers = [];
```
**Action:** Delete entirely

---

**Lines 110-117: Commented collection clears in dispose()**
```dart
    // _fieldControllers.clear();
    // _fieldStates.clear();
    // _fieldDefinitions.clear();
    // _fieldFocusStates.clear();
    // _fieldValues.clear();
    // formErrors.clear();
    // activeFields.clear();
    // pageFields.clear();
```
**Action:** Delete entirely. Garbage collection will handle cleanup after controller disposal.

---

#### Debug Statements to Remove

Remove all `debugPrint` statements:

**Line 225-227:**
```dart
      debugPrint(
          "Internal: Field '$fieldId' state calculated as $newState (was $oldState)");
```

**Line 376-377:**
```dart
        debugPrint(
            "Error running validator $i for field '$fieldId': $e. Ensure validator function type matches field value type (${value?.runtimeType}).");
```

**Line 515-517:**
```dart
      debugPrint(
          "Warning: Tried to toggle values on field '$fieldId', but it's not found or not a ChampionOptionSelect.");
```

**Line 687-688:**
```dart
    debugPrint(
        "Focus added to '$fieldId'. Previously focused: '$previouslyFocusedId'");
```

**Line 700:**
```dart
      debugPrint("Focus removed from '$fieldId'");
```

**Line 715-716:**
```dart
      debugPrint("Warning: setFieldFocus called for unknown field '$fieldId'");
```

**Line 738-740:**
```dart
        debugPrint(
            "Focus CHANGED to '$fieldId'. Previously: '$currentlyFocused'");
```

**Line 743:**
```dart
        debugPrint("Focus remained on '$fieldId'.");
```

**Line 751-752:**
```dart
        debugPrint("Focus REMOVED from '$fieldId'.");
```

**Line 760-762:**
```dart
          debugPrint(
              "Focus corrected (removed) for '$fieldId' which wasn't the primary focus.");
```

**Line 764-766:**
```dart
          debugPrint(
              "Blur event for '$fieldId', but it wasn't the actively focused field ('$currentlyFocused'). No state change needed based on focus.");
```

**Line 318:**
```dart
          debugPrint("Error executing onChange for field '$id': $e");
```

**Action for all:** Replace with proper error handling where appropriate (e.g., throw exceptions for validation errors), or remove entirely if informational only.

---

#### Dead Code to Eliminate

**Constructor parameter comments (lines 77-78):**
```dart
    // this.textFieldValues = const [],
    // this.multiselectValues = const [],
```
**Action:** Delete

---

**Unused inline comments that reference deprecated features:**
- Line 33: "depreciated" comment
- Line 42: "Depreciated" comment
- Line 48: "DEPRECIATED?" comment
- Line 59: "depreciated" comment

**Action:** Delete all deprecated field declarations and their comments

---

## 4. Breaking Changes

### 4.1 Focus Method Renames

**Change:**
- `addFocus(String fieldId)` → `focusField(String fieldId)`
- `removeFocus(String fieldId)` → `unfocusField(String fieldId)`

**Migration:**
```dart
// Before
controller.addFocus('email');
controller.removeFocus('email');

// After
controller.focusField('email');
controller.unfocusField('email');
```

**Rationale:**
- More intuitive naming that matches common UI framework conventions
- Clearer intent: "focus a field" vs "add focus" (add to what?)
- Better discoverability via autocomplete
- Aligns with getter name `isFieldFocused` (verb consistency)

---

### 4.2 Exception Throwing on Invalid Operations

**Change:**
Public methods now throw exceptions for invalid operations:
- `ArgumentError` when field doesn't exist
- `TypeError` when field type doesn't match operation

**Migration:**
```dart
// Before - silent failure
final value = controller.getFieldValue<String>('nonexistent');
// value is null, no error

// After - explicit error
try {
  final value = controller.getFieldValue<String>('nonexistent');
} catch (e) {
  if (e is ArgumentError) {
    print('Field not found: ${e.message}');
  }
}

// Or check first
if (controller.hasField('myField')) {
  final value = controller.getFieldValue<String>('myField');
}
```

**Rationale:**
- Fail-fast principle: catch bugs during development
- Clear error messages aid debugging
- Matches Dart best practices for invalid operations
- Optional: Use `hasField()` to check before access if needed

---

### 4.3 No Breaking Changes to Core API

**Preserved:**
- All existing getters remain unchanged
- `updateFieldValue`, `getFieldValue` signatures unchanged
- `updateMultiselectValues`, `toggleMultiSelectValue` unchanged
- `findErrors`, `clearErrors`, `addError` unchanged
- `activeFields`, `pageFields` remain public
- Constructor signature unchanged
- `dispose()` behavior unchanged

**Additions Only:**
- 8 new methods (non-breaking additions)
- New error handling (may expose previously silent bugs, but not breaking)

---

## 5. Implementation Approach

### Step-by-Step Implementation Strategy

#### Phase 1: Code Organization & Documentation (Priority 1-2)
**Goal:** Restructure code and add comprehensive documentation

1. **Reorganize file structure**
   - Group methods by visibility first, then functionality
   - Add section header comments
   - Reorder methods according to new structure
   - Ensure logical flow and discoverability

2. **Add class-level documentation**
   - Write comprehensive dartdoc for `ChampionFormController`
   - Include usage examples from README
   - Document lifecycle expectations
   - Add integration notes

3. **Add method documentation**
   - Document all public methods with dartdoc
   - Add parameter descriptions
   - Add return value descriptions
   - Include usage examples for complex methods
   - Add "See also" references

4. **Add property documentation**
   - Document all public properties
   - Document all private properties
   - Explain when/how each is populated
   - Add structure examples for maps

#### Phase 2: Add Missing Functionality (Priority 3)
**Goal:** Implement 8 new helper methods

5. **Implement validation methods**
   - `validateForm()` - iterate activeFields, run _validateField()
   - `isFormValid` getter - check formErrors.isEmpty
   - `validateField()` - public wrapper with error handling
   - `validatePage()` - get page fields, validate all
   - `isPageValid()` - check if page has errors
   - `hasErrors()` - check field or form errors
   - `clearAllErrors()` - clear all, update states

6. **Implement field management methods**
   - `updateField()` - update definition and state
   - `removeField()` - clear all data, dispose controllers
   - `hasField()` - check existence
   - `resetField()` - restore default value
   - `resetAllFields()` - restore all defaults
   - `clearForm()` - clear all values
   - `getAllFieldValues()` - return map copy
   - `setFieldValues()` - batch update
   - `getFieldDefaultValue()` - get default from definition
   - `hasFieldValue()` - check if explicitly set
   - `isDirty` getter - check if modified

#### Phase 3: Error Handling (Priority 4)
**Goal:** Add proper error handling throughout

7. **Add field existence validation**
   - Wrap field access in try-catch
   - Throw ArgumentError for missing fields
   - Include available fields in error message

8. **Add type validation**
   - Check types before casting
   - Throw TypeError for mismatches
   - Include expected vs actual type in message

9. **Add page validation**
   - Check page existence in page methods
   - Throw ArgumentError for missing pages
   - List available pages in error

10. **Improve multiselect error handling**
    - Validate field type is ChampionOptionSelect
    - Throw TypeError for wrong field type
    - Add helpful error messages

#### Phase 4: Code Cleanup (Priority 5)
**Goal:** Remove all clutter

11. **Remove commented code**
    - Delete deprecated field declarations (lines 33-38, 42-43, 48-49, 59-60)
    - Delete commented collection clears (lines 110-117)
    - Delete constructor comment lines (lines 77-78)

12. **Remove debug statements**
    - Remove all debugPrint calls (12 total)
    - Replace with proper error handling where appropriate

13. **Focus management consolidation**
    - Rename `addFocus` → `focusField`
    - Rename `removeFocus` → `unfocusField`
    - Update documentation to clarify internal vs public API
    - Add error handling to focus methods

#### Phase 5: Testing & Validation
**Goal:** Ensure nothing breaks

14. **Manual testing**
    - Test all new methods
    - Test error handling paths
    - Test focus consolidation
    - Verify no regression in existing functionality

15. **Integration testing**
    - Test with ChampionForm widget
    - Test with FormResults.getResults()
    - Test multiselect operations
    - Test file upload fields
    - Test page-based forms

16. **Documentation validation**
    - Run `dart doc` to generate documentation
    - Review generated docs for clarity
    - Verify all code examples compile
    - Check for broken "See also" references

### Dependencies Between Changes
- **Phase 1 can be done first** (organization/documentation)
- **Phase 2 depends on Phase 1** (new methods need organized structure)
- **Phase 3 can be done in parallel with Phase 2** (add error handling to existing + new)
- **Phase 4 can be done anytime** (cleanup is independent)
- **Phase 5 must be last** (validate everything works)

### Testing Strategy

**Unit Tests** (create if not present):
```dart
// Test new validation methods
test('validateForm returns true when form is valid', () { ... });
test('validateForm returns false when errors exist', () { ... });
test('validateField throws ArgumentError for missing field', () { ... });

// Test new field management methods
test('resetField restores default value', () { ... });
test('getAllFieldValues returns all values', () { ... });
test('hasFieldValue returns false for unset fields', () { ... });

// Test error handling
test('getFieldValue throws ArgumentError for missing field', () { ... });
test('updateField throws TypeError for wrong type', () { ... });

// Test focus consolidation
test('focusField sets focus and removes from others', () { ... });
test('unfocusField removes focus', () { ... });
```

**Integration Tests**:
- Test full form submission flow
- Test multi-page form validation
- Test multiselect toggling
- Test file upload handling
- Test focus management with real widgets

**Manual Testing Checklist**:
- [ ] Create form with text fields, multiselect, file uploads
- [ ] Test all new validation methods
- [ ] Test all new field management methods
- [ ] Test error scenarios (missing fields, wrong types)
- [ ] Test focus management
- [ ] Test page-based forms
- [ ] Verify error messages are clear
- [ ] Verify documentation is accurate

---

## 6. Acceptance Criteria

### Code Organization
- [ ] All public methods appear before private methods
- [ ] Methods within each visibility section are grouped by functionality
- [ ] Clear section header comments delineate functional groups
- [ ] Related methods are adjacent (e.g., get/set/clear for same data)
- [ ] Consistent method ordering (get, set, check, clear pattern)
- [ ] File is navigable and discoverable

### Documentation
- [ ] Class has comprehensive dartdoc with usage examples
- [ ] Every public method has dartdoc with parameters, returns, examples
- [ ] Every private method has dartdoc explaining internal purpose
- [ ] Every property (public and private) has dartdoc
- [ ] Complex methods include code examples
- [ ] Documentation references README patterns where applicable
- [ ] "See also" references connect related methods
- [ ] `dart doc` generates documentation without errors

### Code Cleanup
- [ ] Zero commented-out code blocks remain
- [ ] Zero debugPrint statements remain
- [ ] All deprecated field declarations removed
- [ ] No unused variables or dead code paths
- [ ] Constructor is clean (no commented parameters)
- [ ] `dispose()` method is clean and documented

### Focus Management
- [ ] `addFocus` renamed to `focusField`
- [ ] `removeFocus` renamed to `unfocusField`
- [ ] Focus methods have error handling
- [ ] `setFieldFocus` documented as internal callback
- [ ] Can programmatically focus a field
- [ ] Can programmatically unfocus a field
- [ ] Can query focus state
- [ ] Can get currently focused field ID

### New Validation Methods
- [ ] `validateForm()` implemented, documented, tested
- [ ] `isFormValid` getter implemented, documented, tested
- [ ] `validateField(String)` implemented, documented, tested
- [ ] `validatePage(String)` implemented, documented, tested
- [ ] `isPageValid(String)` implemented, documented, tested
- [ ] `hasErrors(String?)` implemented, documented, tested
- [ ] `clearAllErrors()` implemented, documented, tested

### New Field Management Methods
- [ ] `updateField(FormFieldDef)` implemented, documented, tested
- [ ] `removeField(String)` implemented, documented, tested
- [ ] `hasField(String)` implemented, documented, tested
- [ ] `resetField(String)` implemented, documented, tested
- [ ] `resetAllFields()` implemented, documented, tested
- [ ] `clearForm()` implemented, documented, tested
- [ ] `getAllFieldValues()` implemented, documented, tested
- [ ] `setFieldValues(Map)` implemented, documented, tested
- [ ] `getFieldDefaultValue(String)` implemented, documented, tested
- [ ] `hasFieldValue(String)` implemented, documented, tested
- [ ] `isDirty` getter implemented, documented, tested

### Error Handling
- [ ] Field access methods throw `ArgumentError` for missing fields
- [ ] Field access methods throw `TypeError` for type mismatches
- [ ] Error messages include field ID and available fields
- [ ] Error messages include expected vs actual types
- [ ] Page methods throw `ArgumentError` for missing pages
- [ ] Error messages include available page names
- [ ] Multiselect methods validate field type
- [ ] Error messages are clear and actionable

### Integration & Compatibility
- [ ] ChampionForm widget continues to work
- [ ] FormResults.getResults() continues to work
- [ ] Field widgets integrate correctly
- [ ] Page-based forms work correctly
- [ ] Multiselect operations work correctly
- [ ] File upload fields work correctly
- [ ] Focus management integrates with widgets
- [ ] No breaking changes beyond documented renames

### Quality Standards
- [ ] Code follows Dart style guide
- [ ] Code follows effective Dart guidelines
- [ ] Naming is consistent and descriptive
- [ ] Line length kept to 80 characters
- [ ] No null assertions (!) unless guaranteed non-null
- [ ] Null safety throughout
- [ ] No dead code or unused imports
- [ ] `dart format` applied

---

## 7. Constraints

### Must Maintain ChampionForm Ecosystem Integration
- **No changes to `ChampionForm` widget interface**: The controller must continue to work with existing form widgets without modification
- **No changes to `FormResults` interface**: Result retrieval must continue to work identically
- **No changes to field widget expectations**: Field definitions and field widgets must not require updates
- **Page grouping preserved**: The `pageName` parameter and `getPageFields()` functionality must remain intact
- **ChangeNotifier contract maintained**: Listener notification patterns must remain consistent

### Follow Standards from agent-os/standards/
- **Dart Coding Style** (coding-style.md):
  - Use `PascalCase` for classes, `camelCase` for methods/properties
  - Keep functions under 20 lines where possible
  - Use meaningful, descriptive names
  - Leverage null safety
  - Remove all dead code and commented blocks

- **Commenting Standards** (commenting.md):
  - Use `///` dartdoc style for all public APIs
  - Start with single-sentence summary
  - Explain *why*, not *what* (except for complex logic)
  - Include code examples for complex methods
  - Use backticks for code references

- **Error Handling** (error-handling.md):
  - Fail fast with clear exceptions
  - Use custom exception types (ArgumentError, TypeError)
  - Try-catch for error handling
  - Clear, actionable error messages
  - Proper resource cleanup in dispose()

- **Conventions** (conventions.md):
  - Apply SOLID principles
  - Favor composition over inheritance
  - Immutability where appropriate
  - Separation of concerns
  - Add documentation to all public APIs

### Focus on Current Functionality Only
- **No roadmap features**: Do not add infrastructure for future features like conditional logic, persistence, or performance optimizations
- **No architectural changes**: Keep the ChangeNotifier pattern and map-based storage
- **No new feature additions**: Only add the specifically requested helper methods
- **No changes to validation logic**: Only reorganize and expose, don't modify behavior
- **No state management refactors**: Keep the existing state management approach

### Be Conservative with Breaking Changes
- **Breaking changes only when necessary**: Only introduce breaking changes that significantly improve consistency or clarity
- **Document all breaking changes**: Provide clear migration guide for any breaking changes
- **Prefer additions over modifications**: Add new methods rather than modifying existing ones where possible
- **Minimize consumer impact**: Breaking changes should be simple find-replace operations
- **Two breaking changes acceptable**: Focus method renames and exception throwing are justified and documented

### Resource Management
- **Proper disposal required**: All TextEditingControllers and FocusNodes must be disposed
- **No memory leaks**: Ensure all listeners and subscriptions are cleaned up
- **Efficient storage**: Don't duplicate data unnecessarily

### Compatibility
- **Flutter compatibility**: Must work with current Flutter stable channel
- **Dart 3 null safety**: Full null safety compliance required
- **Package dependencies**: Don't introduce new package dependencies

---

## 8. Out of Scope

The following items are explicitly excluded from this refactor:

### Future Roadmap Features
- Conditional field logic based on other field values
- Form state persistence (save/restore form drafts)
- Undo/redo functionality
- Form history or change tracking
- Performance optimizations (e.g., memoization, lazy loading)
- Async validation support
- Field dependency graph management

### Architectural Changes
- Replacing ChangeNotifier with other state management
- Switching from Map-based storage to typed models
- Event sourcing or CQRS patterns
- Immutable state containers
- State snapshotting or time-travel debugging

### External Changes
- Modifications to `ChampionForm` widget
- Changes to field widget implementations
- Updates to `FormResults` class
- Changes to `FormFieldDef` or subclasses
- Theme system modifications
- Layout widget changes

### New Major Features
- Real-time collaboration support
- Form analytics or telemetry
- Accessibility enhancements beyond current scope
- Internationalization/localization support
- Custom field type registration system
- Plugin/extension architecture

### Testing Infrastructure
- Setting up new test frameworks
- Creating full test suites (though examples should be provided)
- Integration test harness
- Performance benchmarking

### Documentation Beyond Code
- External documentation website
- Video tutorials
- Migration guides for other versions
- API reference website
- Example applications repository

### User Interface
- Form preview or debugging UI
- Developer tools panel
- Visual form builder
- Drag-and-drop form designer

### Validation System Changes
- New validator types
- Async validators
- Cross-field validation
- Server-side validation integration
- Validation rule engine

### Focus Improvements Beyond Consolidation
- Keyboard navigation (tab order)
- Focus trapping for modals
- Auto-focus on first error
- Custom focus effects beyond state

---

## Summary

This specification provides a comprehensive plan to transform the `ChampionFormController` from a "haphazardly put together" state to a well-organized, thoroughly documented, feature-complete controller class. The refactor prioritizes:

1. **Organization** by restructuring methods visibility-first, then by functionality
2. **Documentation** by adding comprehensive dartdoc to every member
3. **Functionality** by implementing 8 missing helper methods for validation and field management
4. **Error Handling** by adding clear, actionable error messages with proper exception throwing
5. **Cleanup** by removing all commented code, debug statements, and dead code

The approach is conservative with breaking changes (only two justified renames), maintains all existing integrations, and follows project standards. The result will be a controller that is discoverable, maintainable, and a pleasure to work with for developers building forms with ChampionForms.
