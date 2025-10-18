# Migration Guide: v0.2.0 → v0.3.0

This guide will help you upgrade from ChampionForms v0.2.0 to v0.3.0.

## Overview

Version 0.3.0 includes a major refactor of `ChampionFormController` that improves developer experience, adds 18 new utility methods, and introduces better error handling. While most of your code will continue to work, there are **two breaking changes** you'll need to address.

## Breaking Changes

### 1. Focus Method Renames

The focus management methods have been renamed for better clarity and consistency.

#### Before (v0.2.0)
```dart
controller.addFocus('email');
controller.removeFocus('email');
```

#### After (v0.3.0)
```dart
controller.focusField('email');
controller.unfocusField('email');
```

**Migration Steps:**
1. Search your codebase for `addFocus(` and replace with `focusField(`
2. Search your codebase for `removeFocus(` and replace with `unfocusField(`

**Command Line:**
```bash
# Find all usages
grep -r "addFocus\|removeFocus" lib/

# Or use your IDE's find-and-replace feature
```

### 2. Enhanced Error Handling

Methods now throw exceptions instead of silently returning `null` for invalid inputs.

#### Before (v0.2.0)
```dart
// Silent failure - returns null if field doesn't exist
final value = controller.getFieldValue<String>('nonexistent');
// value is null, no error
```

#### After (v0.3.0)
```dart
// Throws ArgumentError if field doesn't exist
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

**Affected Methods:**
- `getFieldValue()` - Throws `ArgumentError` for missing fields, `TypeError` for type mismatches
- `updateFieldValue()` - Throws `ArgumentError` for missing fields
- `focusField()` / `unfocusField()` - Throws `ArgumentError` for missing fields
- `validateField()` - Throws `ArgumentError` for missing fields
- `validatePage()` / `isPageValid()` - Throws `ArgumentError` for missing pages
- `updateMultiselectValues()` / `toggleMultiSelectValue()` - Throws `ArgumentError` for missing fields, `TypeError` for wrong field types

**Migration Strategies:**

**Option 1: Add Try-Catch** (when errors are expected)
```dart
try {
  controller.updateFieldValue('dynamicField', newValue);
} on ArgumentError catch (e) {
  // Handle missing field gracefully
  print('Field does not exist: $e');
}
```

**Option 2: Check Before Use** (recommended for most cases)
```dart
if (controller.hasField('optionalField')) {
  controller.updateFieldValue('optionalField', newValue);
}
```

**Option 3: Use New Validation Helpers**
```dart
// NEW: Check if field exists first
if (controller.hasField('email')) {
  final email = controller.getFieldValue<String>('email');
}

// NEW: Check if value is set
if (controller.hasFieldValue('email')) {
  // Field has an explicit value
}
```

## New Features You Can Use

### Validation Helpers

```dart
// Validate entire form
final isValid = controller.validateForm();
if (!isValid) {
  print('Form has errors');
}

// Quick validity check (doesn't re-run validators)
if (controller.isFormValid) {
  // Submit form
}

// Validate specific field
controller.validateField('email');

// Check for errors
if (controller.hasErrors()) {
  // Form has errors
}
if (controller.hasErrors('email')) {
  // Email field has errors
}

// Clear all errors
controller.clearAllErrors();
```

### Page-Based Validation (for multi-step forms)

```dart
// Validate specific page
final pageValid = controller.validatePage('personalInfo');
if (pageValid) {
  // Move to next page
}

// Quick page validity check
if (controller.isPageValid('personalInfo')) {
  // Page is valid
}
```

### Field Management Helpers

```dart
// Check if field exists
if (controller.hasField('email')) {
  // Field is registered
}

// Reset single field to default
controller.resetField('email');

// Reset all fields
controller.resetAllFields();

// Clear form values (doesn't reset to defaults)
controller.clearForm();

// Get all values as Map
final allValues = controller.getAllFieldValues();

// Batch set values (great for loading saved data)
controller.setFieldValues({
  'name': 'John Doe',
  'email': 'john@example.com',
  'age': 25,
});

// Check if form has been modified
if (controller.isDirty) {
  // Show "unsaved changes" warning
}

// Dynamically update field definition
controller.updateField(updatedFieldDef);

// Remove field completely
controller.removeField('temporaryField');
```

## Testing Your Migration

After migrating, verify:

1. **Focus Management**: Test that `focusField()` and `unfocusField()` work correctly
2. **Error Handling**: Ensure your app handles `ArgumentError` and `TypeError` appropriately
3. **Field Operations**: Test getting/setting field values with both valid and invalid field IDs
4. **Validation**: Test form validation with the new helper methods
5. **Multi-Step Forms**: If using pages, test page-based validation

## Rollback Plan

If you encounter issues, you can temporarily stay on v0.2.0:

**pubspec.yaml**
```yaml
dependencies:
  championforms: 0.2.0
```

Then run:
```bash
flutter pub get
```

## Need Help?

- **Issues**: Report problems at https://github.com/cotw-fabier/championforms/issues
- **Documentation**: Check the updated dartdoc for detailed method documentation
- **Examples**: See the example app for usage patterns

## Summary

**Required Changes:**
1. ✅ Rename `addFocus` → `focusField`
2. ✅ Rename `removeFocus` → `unfocusField`
3. ✅ Add error handling for field operations (try-catch or existence checks)

**Optional Improvements:**
- Use new validation helpers (`validateForm`, `isFormValid`, etc.)
- Use new field management utilities (`resetField`, `clearForm`, `isDirty`, etc.)
- Leverage page-based validation for multi-step forms

**Estimated Migration Time:** 15-30 minutes for most projects

Welcome to v0.3.0! 🎉
