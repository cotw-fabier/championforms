## 0.3.1

**File Upload and Autocomplete Enhancements**

### New Features

**ChampionFileUpload**:
- **`clearOnUpload` flag** - New optional boolean property to control file upload behavior
  - When `true`: Clears previously uploaded files before adding new selections
  - When `false` (default): Maintains existing "running tally" behavior
  - Works consistently across all file selection methods (file picker, drag-and-drop)
  - Supports both single-file and multi-file upload modes
  - Maintains backward compatibility (defaults to `false`)

**Autocomplete Dropdown Visual Feedback**:
- **Keyboard navigation visual feedback** - Options now highlight when navigating with Tab/Arrow keys
  - Options display visual highlight when focused via keyboard
  - Highlight color uses field's `textBackgroundColor` from `FieldColorScheme` (with theme fallback)
  - Fully honors field color scheme: `surfaceBackground`, `surfaceText`, and `textBackgroundColor`
  - Falls back to theme colors when field color scheme is not provided
  - Works with both light and dark themes
  - Improves accessibility by providing clear visual indication of focused option
  - Complies with project's accessibility standards (WCAG 2.1)

### Use Cases

The `clearOnUpload` flag is useful when you want to:
- Replace files instead of accumulating them
- Implement "single selection" workflows in multi-file mode
- Clear previous uploads when user makes a new selection
- Simplify file management for forms where only the latest selection matters

### Example

```dart
ChampionFileUpload(
  id: 'documents',
  label: 'Upload Documents',
  multiselect: true,
  clearOnUpload: true,  // New files replace previous ones
)
```

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
