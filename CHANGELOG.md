## 0.5.3

**Bug Fix - CheckboxSelect Single-Select Mode**

### Fixed

**`toggleMultiSelectValue` now respects `multiselect` property**:
- Fixed critical bug where CheckboxSelect fields with `multiselect: false` incorrectly allowed multiple selections
- Single-select fields now behave like radio buttons (selecting one option automatically deselects others)
- Method now properly checks the field's `multiselect` property before updating selections

**Behavior:**
- **Multi-select mode** (`multiselect: true`): Unchanged - allows multiple selections
- **Single-select mode** (`multiselect: false`): Fixed - only allows one selection at a time

**Example:**
```dart
// This now works correctly - only one checkbox can be selected
CheckboxSelect(
  id: 'priority',
  options: [lowOption, mediumOption, highOption],
  multiselect: false,  // Radio button behavior
)
```

### Migration

**No changes required!** Just update your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.5.3
```

If you were working around this bug by manually clearing selections, you can now remove that workaround code.

---

## 0.5.2

**Field Value Pre-population - Create Values Before Field Initialization**

### Breaking Changes

**None** - This is a backward-compatible enhancement. All existing code continues to work without modification.

### New Features

**`createFieldValue<T>()` Method**:
- Added `createFieldValue<T>()` method to FormController for setting field values without requiring field definitions to exist
- Enables pre-populating controller values before field initialization
- Useful for loading saved form data or setting values dynamically before rendering fields
- Defaults to silent operation (no onChange callbacks, no validation, no notifications)
- Optional `triggerCallbacks` parameter to enable onChange and validation if needed

**Example**:
```dart
// Pre-populate values before fields are defined
final controller = FormController();
controller.createFieldValue<String>('email', 'user@example.com');
controller.createFieldValue<String>('name', 'John Doe');

// Later, when fields are added, values will already be present
Form(
  controller: controller,
  fields: [emailField, nameField],
)
```

### What Changed

**Refactored `updateFieldValue<T>()`**:
- Now uses `createFieldValue<T>()` internally after field existence validation
- Maintains existing behavior (validates field exists, triggers callbacks, runs validation)
- Updated documentation to reference `createFieldValue` for pre-population scenarios

**Benefits**:
- **Flexible Value Management**: Set values before or after field initialization
- **Better Pre-population**: Load saved form drafts before rendering fields
- **Backward Compatible**: Existing code continues to work unchanged
- **Clean API**: Clear separation between validated updates and permissive creation

### Migration

**No changes required!** This is a new optional feature. Just update your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.5.2
```

Then run:
```bash
flutter pub upgrade
```

**Optional**: Use `createFieldValue` for pre-populating form data:
```dart
// Load saved draft before creating form
final savedData = await loadDraft();
savedData.forEach((key, value) {
  controller.createFieldValue(key, value);
});
```

---

## 0.5.1

**Desktop_Drop Integration - Unified Cross-Platform Drag-and-Drop**

### Breaking Changes

**None** - This is a seamless upgrade with no API changes. All existing code continues to work without modification.

### New Features

**File Size Validation**:
- Added `maxFileSize` property to `FileUpload` field
- Default: 52428800 bytes (50 MB) to prevent OutOfMemory errors
- Set to `null` to allow unlimited file sizes (not recommended)
- Files exceeding the limit are rejected with user-friendly error messages
- Validation occurs before reading file bytes to prevent memory issues

**Example**:
```dart
form.FileUpload(
  id: 'documents',
  title: 'Upload Documents',
  maxFileSize: 10485760,  // 10 MB limit
  allowedExtensions: ['pdf', 'docx'],
)
```

### What Changed

**Replaced Platform-Specific Code**:
- Removed custom web implementation (JavaScript interop + HtmlElementView)
- Removed non-functional desktop stub
- Integrated `desktop_drop` package for unified cross-platform support
- **Removed ~1,100 lines of platform-specific code**

**Dependencies**:
- Added `desktop_drop: ^0.4.4` - Mature, actively maintained drag-drop package
- Removed `web: ^1.1.0` - No longer needed for drag-drop
- Removed `lib/assets/file_drag_drop.js` - No longer needed

**Desktop Drag-Drop Now Works**:
- ✅ **macOS**: Drag files from Finder (now functional!)
- ✅ **Windows**: Drag files from Explorer (now functional!)
- ✅ **Linux**: Drag files from file manager (now functional!)
- ✅ **Web**: Browser drag-drop continues to work
- ✅ **Android**: Basic file drag support

**Note**: The 0.5.0 desktop implementation was a non-functional stub. Version 0.5.1 adds real OS-level drag-drop support for desktop platforms using the `desktop_drop` package.

### Benefits

- **Single Codebase**: One implementation for all platforms (simpler maintenance)
- **Desktop Works**: Drag-drop from Finder/Explorer now fully functional
- **File Size Protection**: Prevents OutOfMemory errors from large files
- **Better UX**: User-friendly error messages for rejected files
- **Less Code**: Removed 1,100+ lines of complex platform-specific code
- **Active Maintenance**: desktop_drop is actively maintained (unlike previous custom implementation)

### Migration

**No changes required!** Just update your `pubspec.yaml`:

```yaml
dependencies:
  championforms: ^0.5.1
```

Then run:
```bash
flutter pub upgrade
```

**Optional**: Add `maxFileSize` validation to your file upload fields:
```dart
form.FileUpload(
  id: 'profile_photo',
  maxFileSize: 5242880,  // 5 MB
)
```

### Technical Details

**Architecture Simplification**:
- Single `FileDragTarget` widget using `desktop_drop.DropTarget`
- Works directly with `XFile` (no custom abstraction layer)
- File extension validation handled in unified widget
- Consistent behavior across all platforms

**File Size Validation**:
- Checks file size before reading bytes into memory
- Displays formatted error messages (B, KB, MB)
- Prevents expensive read operations for oversized files
- Configurable per field via `maxFileSize` property

**Memory Safety**:
- Files still loaded entirely into memory (no streaming yet)
- Default 50 MB limit prevents most OutOfMemory issues
- Recommended limits: Mobile (10 MB), Desktop (50 MB), Web (25 MB)

### Testing

All existing tests pass without modification. The package includes comprehensive test coverage for:
- File upload widget rendering
- Multiple file selection
- Clear on upload behavior
- File extension filtering
- Focus handling
- Callback wiring

---

## 0.5.0

**Native Flutter Drag-and-Drop Migration**

### Breaking Changes

**Removed Dependencies:**
- Removed `super_clipboard` v0.9.1 (unmaintained, compilation issues)
- Removed `super_drag_and_drop` v0.9.1 (unmaintained, compilation issues)

**Flutter SDK Requirement:**
- Minimum Flutter SDK version increased to **3.35.0**
- Required to support native drag-and-drop functionality

### Migration Impact

**Zero Developer-Facing API Changes:**
This is a **seamless upgrade** for package consumers. All existing code continues to work without modification:

- `FormResults.grab("fieldId").asFile()` - Works identically
- `FormResults.grab("fieldId").asFileList()` - Works identically
- `FileModel` properties (`fileName`, `fileBytes`, `mimeData`, `uploadExtension`) - Unchanged
- `FileUpload` field configuration (`multiselect`, `clearOnUpload`, `allowedExtensions`, `displayUploadedFiles`) - Unchanged
- Visual design and UX - Unchanged

**What Changed Internally:**
- Replaced unmaintained drag-drop dependencies with native Flutter implementation
- Web implementation uses HtmlElementView + JavaScript with dart:js_interop
- Desktop implementation uses native Flutter DragTarget
- FileModel simplified (removed internal `fileReader` and `fileStream` properties)

### Platform Support

**Web (Primary Platform):**
- Drag files from desktop into browser
- Tested on Chrome, Firefox, Safari
- Uses browser's native dataTransfer API
- MIME type filtering in JavaScript layer

**Desktop (macOS/Windows):**
- Drag files from Finder/File Explorer into application
- Native Flutter DragTarget implementation
- MIME type filtering using mime package

**File Picker:**
- Dialog-based file selection unchanged
- Works identically across all platforms

### Technical Details

**New Internal Architecture:**
- Platform interface abstraction (`FileDragDropInterface`)
- Cross-platform file abstraction (`FileDragDropFile`)
- Conditional exports for web vs desktop implementations
- Event-based architecture with StreamController

**Memory Considerations:**
- Files loaded fully into memory (no streaming)
- Recommended file size limit: < 50MB per file
- Large files (> 50MB) may cause OutOfMemory issues
- Consider implementing `maxFileSize` validation for production use

**Performance:**
- Small files (< 1MB): Excellent performance
- Medium files (1-10MB): Good performance
- Large files (10-50MB): Acceptable performance, monitor memory usage
- Very large files (> 50MB): Not recommended without streaming support

### Migration Steps

1. Update `pubspec.yaml`:
   ```yaml
   dependencies:
     championforms: ^0.5.0

   environment:
     sdk: ">=3.0.5 <4.0.0"
     flutter: ">=3.35.0"  # Updated minimum version
   ```

2. Run `flutter pub upgrade`

3. No code changes required - existing file upload code works identically

4. Test drag-and-drop functionality on your target platforms

### Benefits

- **Compilation on Latest Flutter:** Package now compiles on Flutter 3.35.0 stable
- **Reduced Dependencies:** Two fewer unmaintained dependencies
- **Better Maintainability:** Native Flutter implementation is easier to maintain and debug
- **Same User Experience:** Visual design and interaction patterns unchanged
- **Future-Proof:** Foundation for future enhancements (streaming, progress indicators, etc.)

### Future Enhancements (Out of Scope for 0.5.0)

- File streaming for large files
- Upload progress indicators
- Image preview thumbnails
- Clipboard paste functionality
- File drag-and-drop reordering

---

## 0.4.0

**API Modernization - Namespace Pattern Adoption**

### Breaking Changes

This release modernizes the ChampionForms API by removing the "Champion" prefix from all classes and adopting idiomatic Dart namespace patterns. This is a **clean break** with no deprecation period.

**All public classes renamed** (requires namespace import):
- `ChampionTextField` → `form.TextField`
- `ChampionOptionSelect` → `form.OptionSelect`
- `ChampionFileUpload` → `form.FileUpload`
- `ChampionCheckboxSelect` → `form.CheckboxSelect`
- `ChampionChipSelect` → `form.ChipSelect`
- `ChampionRow` → `form.Row`
- `ChampionColumn` → `form.Column`
- `ChampionForm` → `form.Form`
- `ChampionFormController` → `form.FormController`
- `ChampionFormTheme` → `FormTheme` (from separate themes import)
- `ChampionFormElement` → `form.FormElement`
- `FormFieldBase` → `form.FieldBase`
- `FormFieldDef` → `form.Field`
- `FormFieldNull` → `form.NullField`
- `ChampionAutocompleteWrapper` → `form.AutocompleteWrapper`
- `ChampionFormFieldRegistry` → `FormFieldRegistry` (from separate themes import)
- `FormBuilderValidator` → `form.Validator`
- `MultiselectOption` → `form.FieldOption`
- `AutoCompleteOption` → `form.CompleteOption`
- `DefaultValidators` → `form.Validators`

**Builder functions renamed**:
- `buildChampionTextField` → `buildTextField`
- `buildChampionOptionSelect` → `buildOptionSelect`
- `buildChampionCheckboxSelect` → `buildCheckboxSelect`
- `buildChampionFileUpload` → `buildFileUpload`
- `buildChampionChipSelect` → `buildChipSelect`

**Extension renamed**:
- `ChampionTextFieldController` → `TextFieldController`

### Namespace Strategy

To avoid namespace collisions with Flutter's built-in `Form`, `Row`, and `Column` widgets, ChampionForms now adopts the idiomatic Dart namespace import pattern:

```dart
// Required import pattern
import 'package:championforms/championforms.dart' as form;

// Usage with namespace prefix
form.FormController controller = form.FormController();
form.Form(
  controller: controller,
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
    form.OptionSelect(
      options: [
        form.FieldOption(label: 'Option 1', value: 'val1'),
      ],
    ),
    form.Row(
      columns: [
        form.Column(fields: [...]),
        form.Column(fields: [...]),
      ],
    ),
  ],
)
```

**Two-tier export system** for better organization:
- `championforms.dart` - Form lifecycle classes (import as `form`)
- `championforms_themes.dart` - Theme configuration and field registry (import without namespace)

Theme-related classes now in separate import:
```dart
import 'package:championforms/championforms_themes.dart';

FormTheme.instance.setTheme(softBlueColorTheme(context));
FormFieldRegistry.instance.registerField(...);
```

### Migration

**Comprehensive migration resources available**:
- **Migration Guide**: See `MIGRATION-0.4.0.md` for complete before/after examples and step-by-step instructions
- **Automated Script**: Run `dart run tools/project-migration.dart /path/to/your/project` to automatically update your codebase
- **Find-and-Replace Table**: Reference table in migration guide lists all class name changes

**Migration time estimate**: 5-15 minutes with automated script, 30-60 minutes manually

This is a **breaking change** with no backward compatibility. All users on v0.3.x must migrate to use v0.4.0. The automated migration script creates backup files and provides a detailed summary of changes.

### Why This Change

**Moving to idiomatic Dart patterns**:
- Aligns with Dart style guide recommendations for namespace collision handling
- Follows established patterns used throughout the Flutter ecosystem
- Cleaner, more readable code: `form.TextField()` vs `ChampionTextField()`
- Better explicit namespace control
- Future-proof architecture that's easier to maintain and extend

**Benefits**:
- Shorter, cleaner class names
- No more verbose "Champion" prefix
- Works seamlessly alongside Flutter's built-in widgets
- Explicit namespace makes code intent clearer
- More professional, maintainable API

**No functional changes**: All field types, validation logic, theming system, and form behavior remain identical to v0.3.x. This is purely an API naming refactor.

---

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
