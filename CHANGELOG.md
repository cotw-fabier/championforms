## 0.3.0

**Major Controller Refactor - Enhanced Developer Experience**

### Breaking Changes

- **Focus Methods Renamed** (more intuitive naming):
  - `addFocus()` → `focusField()`
  - `removeFocus()` → `unfocusField()`

- **Enhanced Error Handling** (fail-fast philosophy):
  - Methods now throw `ArgumentError` for missing fields/pages instead of silently returning null
  - Methods throw `TypeError` for type mismatches with clear error messages
  - All error messages include helpful context (e.g., list of available fields)

### New Features

**Validation Methods** (7 new helpers):
- `validateForm()` - Validate all active fields at once
- `isFormValid` getter - Quick validity check without re-running validators
- `validateField(String fieldId)` - Validate a single field
- `validatePage(String pageName)` - Validate all fields on a specific page
- `isPageValid(String pageName)` - Check page validity without re-validation
- `hasErrors([String? fieldId])` - Check for errors (form-wide or field-specific)
- `clearAllErrors()` - Clear all validation errors

**Field Management Methods** (11 new utilities):
- `updateField(FormFieldDef field)` - Dynamically update field definitions
- `removeField(String fieldId)` - Remove fields with proper cleanup
- `hasField(String fieldId)` - Check if field exists
- `resetField(String fieldId)` - Reset single field to default value
- `resetAllFields()` - Reset all fields to defaults
- `clearForm()` - Clear all field values
- `getAllFieldValues()` - Get all values as a Map
- `setFieldValues(Map<String, dynamic>)` - Batch set multiple values
- `getFieldDefaultValue(String fieldId)` - Get field's default value
- `hasFieldValue(String fieldId)` - Check if value is explicitly set
- `isDirty` getter - Detect if form has been modified

### Improvements

- **Complete Documentation**: Added comprehensive dartdoc to all 68 class members (100% coverage)
- **Better Organization**: Reorganized all methods by visibility-first, then functionality
- **Cleaner Codebase**: Removed all commented-out code and debug statements
- **Consistent Error Handling**: All methods now validate inputs and provide helpful error messages
- **45+ Code Examples**: Practical usage examples throughout the documentation

### Migration Guide

See `MIGRATION-0.3.0.md` for detailed upgrade instructions.

## 0.2.0

- Stripped out the generics implementation. Dart just isn't up to the task of strongly typing input from form files using the field<Type> syntax. We went back to dynamic dispatch and then rely on validator functions to make sure output is appropriate for the use case.

- Updated example application to properly utilize the default validators.

- Pushed dependency version numbers to latest releases.

## 0.0.4

Killed Riverpod as a dependency for this library. I love Riverpod, but it wasn't being used correctly here.
Now the library can function with any (or no) state management using the new ChampionFormController.

Removed formIds since we have a controller serving that purpose.

Most things should continue to operate the same, just no more need for riverpod.

Fixing the readme. It needs a little bit of love to fix a few errors.

## 0.0.3

Major overhaul of the entire library. Open sourced (yay!).

Library launches with support for text fields / text areas. As well as option select in the form of dropdown and checkboxes.

Added themes as well as having it default to app theme colors from Material widget.

This is a brand new release and is still very much an alpha product.


## 0.0.1

* TODO: Describe initial release.
