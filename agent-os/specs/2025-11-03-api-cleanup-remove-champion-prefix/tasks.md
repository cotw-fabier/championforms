# Task Breakdown: API Cleanup - Remove Champion Prefix

## Overview

**Spec Version:** 0.4.0 (Breaking Change)
**Total Task Groups:** 5 phases
**Total Files to Update:** ~74 Dart files + 4 documentation files
**Assigned Roles:** dart-library-engineer (custom), testing-engineer, documentation-engineer (custom)

## Project Context

This is a comprehensive API refactoring of the ChampionForms Flutter library that removes the "Champion" prefix from all classes and adopts idiomatic Dart namespace patterns. The work is organized by folder structure to enable efficient parallel execution.

**Key Changes:**
- Remove "Champion" prefix from all public and internal classes
- Rename base classes for better semantic clarity
- Adopt namespace import pattern: `import 'package:championforms/championforms.dart' as form;`
- Create two-tier export system (lifecycle vs. initialization)
- Provide comprehensive migration tooling and documentation

## Task List

---

### Phase 1: Core Library Refactoring (Parallelizable by Folder)

This phase handles the bulk of class renaming across the library. Each task group can be executed in parallel as they work on separate folders with minimal interdependencies.

---

#### Task Group 1.1: Models Folder - Base Classes and Field Types
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** None
**Complexity:** High
**Files:** ~30 files in `/lib/models/`

- [x] 1.1.0 Refactor models folder
  - [x] 1.1.1 Rename base class hierarchy
    - Rename `ChampionFormElement` → `FormElement` in `field_types/form_element.dart`
    - Rename `FormFieldBase` → `FieldBase` in `field_types/form_field_base.dart`
    - Rename `FormFieldDef` → `Field` in `field_types/form_field_def.dart`
    - Rename `FormFieldNull` → `NullField` in `field_types/form_field_null.dart`
    - Update all constructor, method, and property references
    - Update all documentation comments referencing old names
  - [x] 1.1.2 Rename field type classes
    - Rename `ChampionTextField` → `TextField` in `field_types/championtextfield.dart`
    - Rename `ChampionOptionSelect` → `OptionSelect` in `field_types/championoptionselect.dart`
    - Rename `ChampionFileUpload` → `FileUpload` in `field_types/championfileupload.dart`
    - Rename `ChampionCheckboxSelect` → `CheckboxSelect` in `field_types/championcheckboxselect.dart`
    - Rename `ChampionChipSelect` → `ChipSelect` in `field_types/championchipselect.dart`
    - Update all type references to use new base class names (FormElement, FieldBase, Field)
    - Update all imports within field type files
  - [x] 1.1.3 Rename layout classes
    - Rename `ChampionRow` → `Row` in `field_types/championrow.dart`
    - Rename `ChampionColumn` → `Column` in `field_types/championcolumn.dart`
    - Update type references and imports
  - [x] 1.1.4 Update theme classes
    - Rename `ChampionFormTheme` → `FormTheme` in `theme_singleton.dart`
    - Update all references to theme classes in models folder
    - Update FieldColorScheme and FieldGradientColors if they reference Champion classes
  - [x] 1.1.5 Update remaining model files
    - Update all type references in validators, form results, and utility model files
    - Update generic type parameters: `List<ChampionFormElement>` → `List<FormElement>`
    - Update all imports to reference new class names
    - Search for any remaining "Champion" references in comments or strings

**Acceptance Criteria:**
- All base classes renamed with consistent naming
- All field type classes renamed and updated
- All type references updated throughout models folder
- No "Champion" prefix remains in class names or type references
- All imports are valid and point to correct files
- Code compiles without errors in models folder

**Estimated Time:** 4-6 hours

---

#### Task Group 1.2: Controllers Folder - FormController
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1 (needs updated model class names)
**Complexity:** Medium
**Files:** 1 file in `/lib/controllers/`

- [x] 1.2.0 Refactor controllers folder
  - [x] 1.2.1 Rename controller class
    - Rename `ChampionFormController` → `FormController` in `championform_controller.dart`
    - Update class declaration, constructors, and all methods
    - Update documentation comments
  - [x] 1.2.2 Update type references
    - Update all references to `ChampionFormElement` → `FormElement`
    - Update all references to `FormFieldDef` → `Field`
    - Update all references to `FormFieldBase` → `FieldBase`
    - Update generic type parameters: `List<ChampionFormElement>` → `List<FormElement>`
  - [x] 1.2.3 Update imports
    - Update all import statements to reference new class names from models folder
    - Verify no broken imports remain

**Acceptance Criteria:**
- FormController class renamed successfully
- All type references updated to new base class names
- All imports valid and pointing to correct renamed classes
- Controller functionality preserved (no logic changes)
- Code compiles without errors

**Estimated Time:** 1-2 hours

---

#### Task Group 1.3: Widgets External Folder - Public Widgets
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Groups 1.1, 1.2 (needs updated models and controller)
**Complexity:** High
**Files:** ~12 files in `/lib/widgets_external/`

- [ ] 1.3.0 Refactor widgets_external folder
  - [ ] 1.3.1 Rename Form widget
    - Rename `ChampionForm` → `Form` in `championform.dart`
    - Update class declaration, constructors, build method
    - Update all references to `ChampionFormController` → `FormController`
    - Update all references to field types (ChampionTextField → TextField, etc.)
    - Update documentation comments
  - [ ] 1.3.2 Update field layout widgets
    - Update all field layout widget files (fieldSimpleLayout, etc.)
    - Update type references: `FormFieldDef` → `Field`, `FieldBase`, `FormElement`
    - Update imports to reference new class names
  - [ ] 1.3.3 Update field background widgets
    - Update all field background widget files (fieldSimpleBackground, etc.)
    - Update type references to new base class names
    - Update imports
  - [ ] 1.3.4 Update remaining external widgets
    - Update any other external widget files in the folder
    - Search for all "Champion" references and update
    - Update generic type parameters
    - Update all imports

**Acceptance Criteria:**
- Form widget renamed successfully
- All field layout and background widgets updated
- All type references updated throughout widgets_external folder
- All imports valid and pointing to renamed classes
- No "Champion" prefix remains in this folder
- Code compiles without errors

**Estimated Time:** 3-4 hours

---

#### Task Group 1.4: Widgets Internal Folder - Internal Widgets
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1 (needs updated model class names)
**Complexity:** Medium
**Files:** ~8 files in `/lib/widgets_internal/`

- [x] 1.4.0 Refactor widgets_internal folder
  - [x] 1.4.1 Rename AutocompleteWrapper
    - Rename `ChampionAutocompleteWrapper` → `AutocompleteWrapper` in internal widgets
    - Update class declaration and all references
    - Update documentation comments
  - [x] 1.4.2 Update FormBuilderWidget
    - Update any references to Champion-prefixed classes
    - Update type references to new base class names (FormElement, Field, FieldBase)
    - Update imports
  - [x] 1.4.3 Update remaining internal widgets
    - Update all internal widget files (form overlays, helpers, etc.)
    - Search for "Champion" references throughout folder
    - Update all type references and imports
    - Update generic type parameters

**Acceptance Criteria:**
- AutocompleteWrapper renamed successfully
- All internal widgets updated with new type references
- All imports valid
- No "Champion" prefix remains in internal widgets
- Code compiles without errors

**Estimated Time:** 2-3 hours

---

#### Task Group 1.5: Core Folder - Field Registry
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1, 1.6 (needs updated models and builder functions)
**Complexity:** Medium
**Files:** 1 file in `/lib/core/`

- [x] 1.5.0 Refactor core folder
  - [x] 1.5.1 Rename FormFieldRegistry
    - Rename `ChampionFormFieldRegistry` → `FormFieldRegistry` in registry file
    - Update class declaration and singleton instance
    - Update documentation comments
  - [x] 1.5.2 Update field type registrations
    - Update registrations: `'TextField'` → `TextField` (new class reference)
    - Update all builder function references: `buildChampionTextField` → `buildTextField`
    - Update all field type references throughout registry
  - [x] 1.5.3 Update type references
    - Update generic type parameters and return types
    - Update all imports to reference new class names
    - Update any field type map keys if using class names

**Acceptance Criteria:**
- FormFieldRegistry renamed successfully
- All field type registrations updated to new names
- All builder function references updated
- All imports valid
- Registry functionality preserved
- Code compiles without errors

**Estimated Time:** 1-2 hours

---

#### Task Group 1.6: Default Fields Folder - Builder Functions
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1 (needs updated field type classes)
**Complexity:** Medium
**Files:** ~5 files in `/lib/default_fields/`

- [x] 1.6.0 Refactor default_fields folder
  - [x] 1.6.1 Rename builder functions
    - Rename `buildChampionTextField` → `buildTextField` in default builder files
    - Rename `buildChampionOptionSelect` → `buildOptionSelect`
    - Rename `buildChampionCheckboxSelect` → `buildCheckboxSelect`
    - Rename `buildChampionFileUpload` → `buildFileUpload`
    - Rename `buildChampionChipSelect` → `buildChipSelect`
    - Update function signatures and documentation
  - [x] 1.6.2 Rename extensions
    - Rename `ChampionTextFieldController` extension → `TextFieldController`
    - Update extension methods and documentation
  - [x] 1.6.3 Update type references
    - Update all return types: `ChampionTextField` → `TextField`, etc.
    - Update all parameter types to new class names
    - Update all imports
  - [x] 1.6.4 Update function implementations
    - Update any internal references to Champion-prefixed classes
    - Update constructor calls to use new class names

**Acceptance Criteria:**
- All builder functions renamed successfully
- Extension renamed successfully
- All type references updated
- All imports valid
- Builder functions return correct new class types
- Code compiles without errors

**Estimated Time:** 2-3 hours

---

#### Task Group 1.7: Functions Folder - Utility Functions
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1 (needs updated model class names)
**Complexity:** Low
**Files:** ~8 files in `/lib/functions/`

- [x] 1.7.0 Refactor functions folder
    - [x] 1.7.1 Update validator functions
    - Update any type references in validator utility functions
    - Update imports to reference new class names
    - Update documentation comments
    - [x] 1.7.2 Update theme helper functions
    - Update any references to `ChampionFormTheme` → `FormTheme`
    - Update type references and imports
    - [x] 1.7.3 Update remaining utility functions
    - Search for "Champion" references in all function files
    - Update type references, parameters, and return types
    - Update all imports

**Acceptance Criteria:**
- All utility functions updated with new type references
- All imports valid
- No "Champion" prefix remains in functions folder
- Utility function logic preserved (no behavior changes)
- Code compiles without errors

**Estimated Time:** 1-2 hours

---

#### Task Group 1.8: Themes Folder - Pre-built Themes
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Task Group 1.1 (needs updated FormTheme class)
**Complexity:** Low
**Files:** ~4 files in `/lib/themes/`

- [ ] 1.8.0 Refactor themes folder
  - [ ] 1.8.1 Update theme function references
    - Update all references to `ChampionFormTheme` → `FormTheme`
    - Update return types in theme factory functions
    - Update theme instantiation calls
  - [ ] 1.8.2 Update theme exports
    - Verify theme functions return new `FormTheme` class
    - Update imports to reference new class names
    - Update documentation comments
  - [ ] 1.8.3 Verify pre-built themes
    - Test that softBlueColorTheme uses FormTheme correctly
    - Test that redAccentFormTheme uses FormTheme correctly
    - Test that iconicColorTheme uses FormTheme correctly

**Acceptance Criteria:**
- All theme functions updated to use FormTheme
- All pre-built themes work with new class names
- All imports valid
- Theme functionality preserved
- Code compiles without errors

**Estimated Time:** 1 hour

---

### Phase 2: Export Files and Public API

This phase creates the new two-tier export system and updates the main export file.

---

#### Task Group 2.1: Create Themes Export File
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Phase 1 complete (all classes renamed)
**Complexity:** Low
**Files:** Create new file `/lib/championforms_themes.dart`

- [ ] 2.1.0 Create championforms_themes.dart export file
  - [ ] 2.1.1 Add documentation header
    - Add comprehensive doc comment explaining this file's purpose
    - Explain usage: "Typically imported once during app initialization"
    - Include usage example: `import 'package:championforms/championforms_themes.dart';`
  - [ ] 2.1.2 Export theme classes
    - Export `FormTheme` from models
    - Export `FieldColorScheme` from models
    - Export `FieldGradientColors` from models
  - [ ] 2.1.3 Export pre-built themes
    - Export `softBlueColorTheme` from themes folder
    - Export `redAccentFormTheme` from themes folder
    - Export `iconicColorTheme` from themes folder
  - [ ] 2.1.4 Export field registry
    - Export `FormFieldRegistry` from core folder
    - Add doc comment explaining custom field type registration use case

**Acceptance Criteria:**
- New championforms_themes.dart file created
- Documentation header is clear and helpful
- All theme-related classes exported correctly
- FormFieldRegistry exported for custom field registration
- File compiles without errors
- Exports are organized and well-documented

**Estimated Time:** 30 minutes

---

#### Task Group 2.2: Update Main Export File
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Phase 1 complete, Task Group 2.1 complete
**Complexity:** Medium
**Files:** Update `/lib/championforms.dart`

- [ ] 2.2.0 Update championforms.dart export file
  - [ ] 2.2.1 Add/Update documentation header
    - Add comprehensive doc comment recommending namespace import
    - Include recommended usage: `import 'package:championforms/championforms.dart' as form;`
    - Explain namespace approach prevents collisions with Flutter's Form, Row, Column
    - Provide quick usage examples: `form.TextField()`, `form.Form()`, etc.
  - [ ] 2.2.2 Remove theme exports
    - Remove exports for FormTheme (moved to championforms_themes.dart)
    - Remove exports for FieldColorScheme, FieldGradientColors (moved to themes)
    - Remove exports for pre-built themes (moved to themes)
    - Remove export for FormFieldRegistry (moved to themes)
  - [ ] 2.2.3 Update field class exports
    - Update export: `ChampionTextField` → `TextField`
    - Update export: `ChampionOptionSelect` → `OptionSelect`
    - Update export: `ChampionFileUpload` → `FileUpload`
    - Update export: `ChampionCheckboxSelect` → `CheckboxSelect`
    - Update export: `ChampionChipSelect` → `ChipSelect`
  - [ ] 2.2.4 Update layout class exports
    - Update export: `ChampionRow` → `Row`
    - Update export: `ChampionColumn` → `Column`
  - [ ] 2.2.5 Update form and controller exports
    - Update export: `ChampionForm` → `Form`
    - Update export: `ChampionFormController` → `FormController`
  - [ ] 2.2.6 Update base class exports
    - Update export: `ChampionFormElement` → `FormElement`
    - Update export: `FormFieldBase` → `FieldBase`
    - Update export: `FormFieldDef` → `Field`
    - Update export: `FormFieldNull` → `NullField`
  - [ ] 2.2.7 Verify remaining exports
    - Keep exports: FormResults, FieldResults
    - Keep exports: FormBuilderValidator, DefaultValidators
    - Keep exports: AutoCompleteBuilder, AutoCompleteOption
    - Keep exports: field layout functions (fieldSimpleLayout, etc.)
    - Keep exports: field background functions (fieldSimpleBackground, etc.)
    - Keep exports: utility functions (getErrors, result getters)

**Acceptance Criteria:**
- Documentation header clearly recommends namespace import approach
- All class name exports updated to remove "Champion" prefix
- Theme-related exports removed (now in championforms_themes.dart)
- All non-theme exports preserved with updated names
- File compiles without errors
- Export structure is clean and well-organized

**Estimated Time:** 1-2 hours

---

### Phase 3: Example Application Update

This phase updates the example application to demonstrate the new namespace approach.

---

#### Task Group 3.1: Update Example Application
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Phase 1 and 2 complete (all library classes renamed and exported)
**Complexity:** Medium
**Files:** ~1-3 files in `/example/lib/`

- [ ] 3.1.0 Update example application
  - [ ] 3.1.1 Update import statements
    - Change import to use namespace: `import 'package:championforms/championforms.dart' as form;`
    - Add theme import: `import 'package:championforms/championforms_themes.dart';`
    - Remove any old non-namespaced championforms imports
  - [ ] 3.1.2 Update controller initialization
    - Change `ChampionFormController` → `form.FormController`
    - Update all controller variable declarations and type annotations
  - [ ] 3.1.3 Update Form widget usage
    - Change `ChampionForm` → `form.Form`
    - Update all Form widget instantiations
  - [ ] 3.1.4 Update field usage
    - Change all `ChampionTextField` → `form.TextField`
    - Change all `ChampionOptionSelect` → `form.OptionSelect`
    - Change all `ChampionFileUpload` → `form.FileUpload`
    - Change all `ChampionCheckboxSelect` → `form.CheckboxSelect`
    - Change all `ChampionChipSelect` → `form.ChipSelect`
  - [ ] 3.1.5 Update layout usage
    - Change all `ChampionRow` → `form.Row`
    - Change all `ChampionColumn` → `form.Column`
  - [ ] 3.1.6 Update theme usage
    - Update theme references (if any) to use `FormTheme` (without namespace, from themes import)
    - Update any theme initialization code
  - [ ] 3.1.7 Test example app
    - Run `flutter pub get` in example directory
    - Run `flutter run` and verify app compiles
    - Test all form functionality (field input, validation, submission)
    - Test all field types render correctly
    - Test layout components (Row, Column) work correctly
    - Test theme switching (if applicable)

**Acceptance Criteria:**
- All imports updated to namespace approach
- All class usage updated to `form.ClassName` pattern
- Example app compiles without errors
- Example app runs successfully
- All form functionality works as before
- All field types render and function correctly
- No visual or functional regressions

**Estimated Time:** 2-3 hours

---

### Phase 4: Documentation and Migration Tools

This phase creates comprehensive migration documentation and automated migration tooling.

---

#### Task Group 4.1: Create Migration Guide
**Assigned implementer:** documentation-engineer (custom role)
**Dependencies:** Phase 1-3 complete (implementation finished)
**Complexity:** Medium
**Files:** Create `/MIGRATION-0.4.0.md` in project root

- [ ] 4.1.0 Create comprehensive migration guide
  - [ ] 4.1.1 Write "Why We Changed" section
    - Explain move to idiomatic Dart namespace patterns
    - Discuss benefits: cleaner API, shorter names, better namespace handling
    - Address namespace collision handling with import aliases
    - Emphasize alignment with Dart best practices
  - [ ] 4.1.2 Write "Before/After Examples" section
    - Show old import: `import 'package:championforms/championforms.dart';`
    - Show new import: `import 'package:championforms/championforms.dart' as form;`
    - Show controller initialization (before/after)
    - Show field usage in forms (before/after)
    - Show Row/Column layout usage (before/after)
    - Show theme initialization (before/after with new import)
    - Provide complete working form example showing full migration
  - [ ] 4.1.3 Write "Find-and-Replace Table" section
    - Create comprehensive table with columns: "Old Name (v0.3.x)", "New Name (v0.4.0)", "Category"
    - Include all class renames (TextField, OptionSelect, FileUpload, etc.)
    - Include base class renames (FormElement, FieldBase, Field, NullField)
    - Include layout classes (Row, Column)
    - Include form classes (Form, FormController)
    - Include theme classes (FormTheme)
    - Include internal classes (AutocompleteWrapper, FormFieldRegistry)
    - Include builder functions (buildTextField, etc.)
    - Include extensions (TextFieldController)
    - Note special cases about namespace requirement
  - [ ] 4.1.4 Write "Step-by-Step Manual Migration" section
    - Step 1: Update import statements to use namespace alias
    - Step 2: Replace all `Champion*` class references with `form.*` prefix
    - Step 3: Update type annotations in variables and function signatures
    - Step 4: Update generic type parameters (List<ChampionFormElement> → List<form.FormElement>)
    - Step 5: Add theme import if using FormTheme or FormFieldRegistry
    - Step 6: Run `flutter pub get` and verify no compilation errors
    - Step 7: Run tests and fix any remaining issues
    - Step 8: Do a final search for "Champion" to catch any missed references
  - [ ] 4.1.5 Write "Automated Migration" section
    - Explain the automated migration script purpose
    - Command: `dart run project-migration.dart /path/to/your/project`
    - List what the script does automatically
    - Note about backup files created (*.backup)
    - Recommend reviewing changes after script runs
    - Note any limitations (string literals, comments)
  - [ ] 4.1.6 Write "Common Issues FAQ" section
    - Q: Why "The name 'TextField' is defined in the libraries" error?
      - A: Need namespace alias to disambiguate from Flutter's TextField
    - Q: Can I use both ChampionForms Form and Flutter's Form widget?
      - A: Yes, use `form.Form` for ChampionForms, `Form` for Flutter
    - Q: Why namespace instead of different class names?
      - A: Aligns with Dart idioms, cleaner API, explicit namespace control
    - Q: Will this affect my existing data or form state?
      - A: No, only class names changed - functionality identical
    - Q: Do I need to migrate all at once?
      - A: Yes, partial migration not supported (breaking change)
    - Q: What if I have custom field types registered?
      - A: Update your custom builder functions and registrations to new names
  - [ ] 4.1.7 Add metadata and conclusion
    - Add version info at top (v0.3.x → v0.4.0)
    - Add date and author info
    - Add conclusion encouraging users about benefits
    - Link to CHANGELOG.md for detailed changes

**Acceptance Criteria:**
- Migration guide is comprehensive and easy to follow
- All major migration scenarios covered with examples
- Before/after examples are accurate and complete
- Find-and-replace table is exhaustive
- Step-by-step instructions are clear and actionable
- FAQ addresses likely user concerns
- Document is well-formatted and professional
- Total length is appropriate (not too brief, not overwhelming)

**Estimated Time:** 3-4 hours

---

#### Task Group 4.2: Create Automated Migration Script
**Assigned implementer:** api-engineer
**Dependencies:** Phase 1-3 complete, Task Group 4.1 started
**Complexity:** High
**Files:** Create `/tools/project-migration.dart` in project root

- [x] 4.2.0 Create automated Dart migration script with CLI, file scanning, import updates, class name replacements, backup creation, and dry-run support
  - [x] 4.2.1 Set up script structure
    - Create `tools/project-migration.dart` file
    - Add script header with usage instructions
    - Add shebang for direct execution: `#!/usr/bin/env dart`
    - Add version and description comments
  - [x] 4.2.2 Implement CLI argument parsing
    - Accept project path as first argument
    - Validate argument is provided
    - Validate path exists and is a directory
    - Add `--help` flag with usage instructions
    - Add `--dry-run` flag to preview changes without modifying files
    - Add `--no-backup` flag to skip backup creation (with warning)
  - [x] 4.2.3 Implement file scanner
    - Recursively scan provided directory for `.dart` files
    - Skip common exclude patterns: `build/`, `.dart_tool/`, `.git/`, `*.g.dart`, `*.freezed.dart`
    - Collect all matching file paths
    - Report number of files found
  - [x] 4.2.4 Implement championforms import detection
    - Detect: `import 'package:championforms/championforms.dart'`
    - Detect if namespace alias already present
    - Identify files that need migration
    - Skip files without championforms imports
  - [x] 4.2.5 Implement import statement updater
    - Replace: `import 'package:championforms/championforms.dart';`
    - With: `import 'package:championforms/championforms.dart' as form;`
    - Handle existing namespace aliases (skip if already present)
  - [x] 4.2.6 Implement class name replacement logic
    - Create map of all class name replacements
    - Field classes: ChampionTextField → form.TextField (with namespace)
    - Layout classes: ChampionRow → form.Row, ChampionColumn → form.Column
    - Form classes: ChampionForm → form.Form, ChampionFormController → form.FormController
    - Theme classes: ChampionFormTheme → FormTheme (no namespace)
    - Base classes: ChampionFormElement → form.FormElement, FormFieldBase → form.FieldBase, etc.
    - Internal classes: ChampionAutocompleteWrapper → form.AutocompleteWrapper, etc.
    - Use word boundary regex: `\bChampionTextField\b` → `form.TextField`
    - Handle generic type parameters: `List<ChampionTextField>` → `List<form.TextField>`
  - [x] 4.2.7 Implement smart detection for strings and comments
    - Skip replacements inside string literals (single and double quotes)
    - Skip replacements inside multi-line strings (triple quotes)
    - Preserve "Champion" in comments
    - Use proper Dart parsing to avoid false positives
  - [x] 4.2.8 Implement backup file creation
    - Create `.backup` file for each file before modification
    - Backup naming: `original_file.dart` → `original_file.dart.backup`
    - Only create backup if `--no-backup` flag not set
    - Report backup file paths
  - [x] 4.2.9 Implement file modification
    - Read original file content
    - Apply import updates
    - Apply class name replacements
    - Write modified content back to original file
    - Preserve file permissions and metadata
  - [x] 4.2.10 Implement summary report generation
    - Track files scanned count
    - Track files modified count
    - Track files skipped count (no championforms imports)
    - Track backups created count
    - List specific changes made to each file
    - Display summary at end with clear formatting
    - In dry-run mode, show what would change without modifying
  - [x] 4.2.11 Add error handling
    - Handle file read/write errors gracefully
    - Handle invalid paths
    - Handle permission issues
    - Display helpful error messages
    - Exit with appropriate status codes
  - [x] 4.2.12 Test migration script
    - Create test project directory with sample files
    - Test on files with championforms imports
    - Test on files without championforms imports
    - Test backup creation
    - Test dry-run mode
    - Test error scenarios (invalid paths, permission issues)
    - Verify all class names replaced correctly
    - Verify no false positives in strings/comments
    - Test on example application as real-world test

**Acceptance Criteria:**
- Migration script accepts project path as argument
- Script correctly scans for .dart files
- Script detects championforms imports accurately
- Import statements updated to namespace approach
- All class name replacements performed correctly
- Backup files created before modifications
- String literals and comments not incorrectly modified
- Summary report is clear and informative
- Dry-run mode works correctly
- Script handles errors gracefully
- Script successfully migrates test project
- Script is well-documented with usage instructions

**Estimated Time:** 6-8 hours

---

#### Task Group 4.3: Update CHANGELOG
**Assigned implementer:** documentation-engineer (custom role)
**Dependencies:** Phase 1-3 complete, Task Group 4.1 complete
**Complexity:** Low
**Files:** Update `/CHANGELOG.md`

- [x] 4.3.0 Update CHANGELOG.md
  - [x] 4.3.1 Add version 0.4.0 entry
    - Add header: `## [0.4.0] - [Date]` at top of changelog
    - Add brief summary of this release
  - [x] 4.3.2 Write "Breaking Changes" section
    - List all renamed public classes (TextField, OptionSelect, FileUpload, etc.)
    - List renamed layout classes (Row, Column)
    - List renamed form classes (Form, FormController)
    - List renamed base classes (FormElement, FieldBase, Field, NullField)
    - List renamed theme classes (FormTheme)
    - Note that ALL "Champion" prefixes removed
  - [x] 4.3.3 Write "Namespace Strategy" section
    - Explain new import approach: `as form`
    - Explain two-tier export system (championforms.dart vs championforms_themes.dart)
    - Note benefits: avoids collisions with Flutter widgets, cleaner API
  - [x] 4.3.4 Write "Migration" section
    - Reference MIGRATION-0.4.0.md guide
    - Mention automated migration script availability
    - Note that this is a clean break (no deprecation period)
    - Emphasize comprehensive migration tooling available
  - [x] 4.3.5 Write "Why This Change" section
    - Brief explanation of move to idiomatic Dart patterns
    - Note alignment with Dart best practices
    - Emphasize cleaner, more maintainable API
  - [x] 4.3.6 Add comparison links
    - Add link at bottom: `[0.4.0]: https://github.com/[org]/championforms/compare/v0.3.0...v0.4.0`
    - Update any existing version comparison links

**Acceptance Criteria:**
- Version 0.4.0 entry added at top of CHANGELOG
- All breaking changes clearly documented
- Migration resources referenced
- Rationale explained briefly
- Changelog entry is well-formatted and professional
- Version comparison link added

**Estimated Time:** 1 hour

---

#### Task Group 4.4: Update README
**Assigned implementer:** documentation-engineer (custom role)
**Dependencies:** Phase 1-3 complete, Task Group 4.1 complete
**Complexity:** Medium
**Files:** Update `/README.md`

- [x] 4.4.0 Update README.md
  - [x] 4.4.1 Update installation section
    - Update version reference to 0.4.0
    - Keep installation instructions (pubspec.yaml entry)
    - Add note about namespace import recommendation
  - [x] 4.4.2 Update quick start / usage examples
    - Change all code examples to use namespace import
    - Update import: `import 'package:championforms/championforms.dart' as form;`
    - Update controller: `form.FormController()`
    - Update form widget: `form.Form()`
    - Update field examples: `form.TextField()`, `form.OptionSelect()`, etc.
    - Update layout examples: `form.Row()`, `form.Column()`
  - [x] 4.4.3 Update "What's New" or features section
    - Add v0.4.0 section highlighting API modernization
    - Mention namespace approach
    - Mention cleaner class names
    - Link to migration guide for existing users
  - [x] 4.4.4 Add "Migration from v0.3.x" section
    - Brief explanation that v0.4.0 is a breaking change
    - Link to MIGRATION-0.4.0.md for full guide
    - Mention automated migration script: `dart run tools/project-migration.dart`
    - Encourage upgrade for cleaner API
  - [x] 4.4.5 Update all field type examples
    - Search entire README for any remaining "Champion" prefixed class references
    - Update all to namespace approach (form.TextField, form.OptionSelect, etc.)
    - Update any type annotations to new class names
    - Update generic type examples
  - [x] 4.4.6 Update theme examples (if present)
    - Update FormTheme references
    - Show theme import: `import 'package:championforms/championforms_themes.dart';`
    - Update theme initialization examples
  - [x] 4.4.7 Update advanced usage examples
    - Update any custom field registration examples to use FormFieldRegistry
    - Update any extension examples to use TextFieldController
    - Ensure all advanced examples use namespace approach
  - [x] 4.4.8 Update API documentation section (if present)
    - Update links to class documentation
    - Update class name references throughout
  - [x] 4.4.9 Final review
    - Search entire README for any remaining "Champion" references
    - Ensure consistency in namespace usage throughout
    - Verify all code examples are syntactically correct
    - Check all links work correctly

**Acceptance Criteria:**
- All code examples updated to namespace approach
- All class names updated throughout README
- Migration section added with clear guidance
- Installation section updated with correct version
- "What's New" section highlights v0.4.0 changes
- No "Champion" prefixes remain in class references
- All code examples are accurate and working
- README is professional and up-to-date

**Estimated Time:** 2-3 hours

---

#### Task Group 4.5: Update Package Metadata
**Assigned implementer:** dart-library-engineer (custom role)
**Dependencies:** Phase 1-4 complete (all code and docs updated)
**Complexity:** Low
**Files:** Update `/pubspec.yaml`

- [x] 4.5.0 Update pubspec.yaml
  - [x] 4.5.1 Bump version number
    - Change `version: 0.3.0` to `version: 0.4.0`
    - Verify version follows semver pre-1.0 conventions (MINOR = breaking)
  - [x] 4.5.2 Update description (if needed)
    - Review package description
    - Update if it mentions "Champion" prefix or outdated API style
    - Keep description concise and accurate
  - [x] 4.5.3 Verify dependencies
    - Review dependencies - no changes needed for this refactor
    - Verify SDK constraints still appropriate: `sdk: ">=3.0.5 <4.0.0"`
    - Verify Flutter constraint still appropriate: `flutter: ">=1.17.0"`
  - [x] 4.5.4 Review repository and issue tracker links
    - Ensure repository URL is correct
    - Ensure issue tracker URL is correct
    - Ensure homepage URL is correct
  - [x] 4.5.5 Final validation
    - Run `flutter pub get` to verify pubspec is valid
    - Run `dart pub publish --dry-run` to check package is publishable
    - Verify no warnings or errors

**Acceptance Criteria:**
- Version bumped to 0.4.0
- Package description updated if needed
- Dependencies verified as correct
- Pubspec passes validation
- Dry-run publish succeeds

**Estimated Time:** 30 minutes

---

### Phase 5: Testing and Validation

This phase ensures all changes work correctly and nothing is broken.

---

#### Task Group 5.1: Update Test Files
**Assigned implementer:** testing-engineer
**Dependencies:** Phase 1-2 complete (library code updated)
**Complexity:** High
**Files:** All test files in `/test/`

- [ ] 5.1.0 Update all test files with new class names
  - [ ] 5.1.1 Update test imports
    - Change all test imports to namespace approach
    - Update: `import 'package:championforms/championforms.dart' as form;`
    - Add theme imports where needed: `import 'package:championforms/championforms_themes.dart';`
  - [ ] 5.1.2 Update unit tests for models
    - Update all type references in model tests
    - Update: ChampionFormElement → form.FormElement
    - Update: FormFieldBase → form.FieldBase
    - Update: FormFieldDef → form.Field
    - Update: FormFieldNull → form.NullField
    - Update all field type references with namespace prefix
    - Update generic type parameters in tests
  - [ ] 5.1.3 Update unit tests for controller
    - Update: ChampionFormController → form.FormController
    - Update all controller instantiation in tests
    - Update type annotations and variable declarations
  - [ ] 5.1.4 Update widget tests
    - Update all Form widget references: ChampionForm → form.Form
    - Update all field widget references with namespace prefix
    - Update layout widget references: ChampionRow → form.Row, etc.
    - Update testWidgets declarations
  - [ ] 5.1.5 Update test helper utilities
    - Update any test factories or builders using Champion classes
    - Update test fixture classes with new names
    - Update mock objects if using Champion-prefixed classes
  - [ ] 5.1.6 Run all tests
    - Run `flutter test` to execute all test suites
    - Verify all tests pass
    - Fix any test failures
    - Ensure no test compilation errors
  - [ ] 5.1.7 Verify test coverage
    - Check test coverage with: `flutter test --coverage`
    - Ensure coverage hasn't decreased
    - Verify critical paths still tested

**Acceptance Criteria:**
- All test files updated to use namespace approach
- All type references updated throughout tests
- All tests compile without errors
- All tests pass successfully
- Test coverage maintained or improved
- No regressions in test functionality

**Estimated Time:** 4-6 hours

---

#### Task Group 5.2: Example App Verification
**Assigned implementer:** testing-engineer
**Dependencies:** Task Group 3.1 complete (example app updated)
**Complexity:** Medium
**Files:** `/example/` directory

- [ ] 5.2.0 Comprehensive example app testing
  - [ ] 5.2.1 Build verification
    - Navigate to example directory
    - Run `flutter pub get`
    - Run `flutter analyze` - verify no warnings or errors
    - Run `flutter build apk --debug` (or appropriate platform)
    - Verify build succeeds without errors
  - [ ] 5.2.2 Runtime functionality testing
    - Run example app: `flutter run`
    - Verify app launches successfully
    - Verify no runtime errors in console
    - Verify hot reload works correctly
  - [ ] 5.2.3 Test all field types
    - Test TextField input and display
    - Test OptionSelect dropdown functionality
    - Test FileUpload file picker integration
    - Test CheckboxSelect selection behavior
    - Test ChipSelect chip interactions
    - Verify all fields render correctly
    - Verify all field interactions work as expected
  - [ ] 5.2.4 Test layout components
    - Test form.Row layout behavior
    - Test form.Column layout behavior
    - Test responsive behavior if applicable
    - Verify layouts render as expected
  - [ ] 5.2.5 Test form functionality
    - Test form controller initialization
    - Test field value changes update controller
    - Test form validation triggers correctly
    - Test form submission works
    - Test form reset functionality
    - Test error display for validation failures
  - [ ] 5.2.6 Test theme functionality (if applicable)
    - Test theme switching if example includes it
    - Test FormTheme application
    - Verify theme colors and styles apply correctly
    - Test pre-built theme examples if shown
  - [ ] 5.2.7 Visual regression check
    - Compare visual appearance to v0.3.x screenshots (if available)
    - Verify no unintended visual changes
    - Verify all styling preserved
  - [ ] 5.2.8 Performance check
    - Monitor app performance during testing
    - Verify no noticeable performance degradation
    - Check for memory leaks or unusual resource usage

**Acceptance Criteria:**
- Example app builds successfully
- Example app runs without errors
- All field types work correctly
- All layout components render correctly
- Form submission and validation work as expected
- Theme functionality works if applicable
- No visual regressions detected
- No performance issues detected
- App behavior identical to v0.3.x

**Estimated Time:** 2-3 hours

---

#### Task Group 5.3: Migration Script Testing
**Assigned implementer:** testing-engineer
**Dependencies:** Task Group 4.2 complete (migration script created)
**Complexity:** Medium
**Files:** `/tools/project-migration.dart` and test projects

- [x] 5.3.0 Comprehensive migration script testing
  - [x] 5.3.1 Set up test projects
    - Create test project #1: Simple project with basic championforms usage
    - Create test project #2: Complex project with advanced features, custom fields
    - Create test project #3: Project with edge cases (comments with "Champion", string literals)
    - Ensure test projects use v0.3.x API style
  - [x] 5.3.2 Test basic functionality
    - Run migration script on test project #1
    - Command: `dart run tools/project-migration.dart /path/to/test-project-1`
    - Verify script completes successfully
    - Verify backup files created (*.backup)
    - Verify import statements updated to namespace approach
    - Verify class names replaced correctly
  - [x] 5.3.3 Test complex scenarios
    - Run migration script on test project #2
    - Verify advanced features migrated correctly
    - Verify custom field registrations updated
    - Verify generic type parameters updated
    - Verify controller type annotations updated
  - [x] 5.3.4 Test edge cases
    - Run migration script on test project #3
    - Verify "Champion" in comments handled appropriately
    - Verify "Champion" in string literals not replaced
    - Verify variable names containing "Champion" not affected
    - Verify already-migrated files skipped appropriately
  - [x] 5.3.5 Test dry-run mode
    - Run script with `--dry-run` flag on test project
    - Verify files not modified
    - Verify preview output shows what would change
    - Verify dry-run mode helpful for review
  - [x] 5.3.6 Test error handling
    - Test with invalid path - verify helpful error message
    - Test with non-existent directory - verify graceful failure
    - Test with permission issues - verify appropriate error
    - Test with no Dart files - verify appropriate message
  - [x] 5.3.7 Verify migrated projects work
    - Run `flutter pub get` in migrated test projects
    - Run `flutter analyze` - verify no errors
    - Run tests if test projects have them
    - Build and run migrated projects
    - Verify functionality preserved
  - [x] 5.3.8 Test backup restoration
    - Restore one test project from .backup files
    - Verify restoration successful
    - Re-run migration script
    - Verify migration works on restored project
  - [x] 5.3.9 Review summary reports
    - Verify summary report accuracy
    - Verify file counts correct
    - Verify change descriptions helpful
    - Verify report formatting clear

**Acceptance Criteria:**
- Migration script successfully migrates simple projects
- Migration script successfully migrates complex projects
- Edge cases handled correctly (comments, strings, variable names)
- Dry-run mode works as expected
- Error handling is graceful and helpful
- Backup files created correctly
- Migrated projects compile without errors
- Migrated projects run successfully
- Summary reports are accurate and helpful
- Script is reliable and production-ready

**Estimated Time:** 4-5 hours

---

#### Task Group 5.4: Final Validation and Pre-Release Checklist
**Assigned implementer:** testing-engineer
**Dependencies:** All previous task groups complete
**Complexity:** Medium
**Files:** Entire project

- [ ] 5.4.0 Final validation before release
  - [ ] 5.4.1 Code quality checks
    - Run `flutter analyze` on entire project - zero warnings or errors
    - Run `dart format` to ensure consistent formatting
    - Review any TODO or FIXME comments added during refactor
    - Search entire codebase for remaining "Champion" references
    - Verify "Champion" only appears in: CHANGELOG, MIGRATION guide, README migration section
  - [ ] 5.4.2 Documentation completeness
    - Verify MIGRATION-0.4.0.md is complete and accurate
    - Verify CHANGELOG.md is complete
    - Verify README.md is updated throughout
    - Verify all code examples in docs are accurate
    - Verify all links in documentation work
  - [ ] 5.4.3 Test suite validation
    - Run full test suite: `flutter test`
    - Verify 100% of tests pass
    - Check test coverage: `flutter test --coverage`
    - Verify critical paths have test coverage
    - Fix any flaky or intermittent test failures
  - [ ] 5.4.4 Build validation
    - Build example app for all supported platforms
    - `flutter build apk` (Android)
    - `flutter build ios` (iOS, if applicable)
    - `flutter build web` (Web, if applicable)
    - Verify all builds succeed
  - [ ] 5.4.5 Package publication readiness
    - Run `dart pub publish --dry-run`
    - Verify package passes all publication checks
    - Verify no warnings about missing documentation
    - Verify package size reasonable
    - Verify all exports accessible
  - [ ] 5.4.6 Migration tooling verification
    - Verify migration script executable
    - Verify migration script documentation clear
    - Test migration script one final time on fresh project
    - Verify backup mechanism works
  - [ ] 5.4.7 Version verification
    - Verify pubspec.yaml shows 0.4.0
    - Verify CHANGELOG.md has 0.4.0 entry
    - Verify README.md references 0.4.0
    - Verify all documentation consistent on version
  - [ ] 5.4.8 Namespace consistency check
    - Verify example app uses namespace consistently
    - Verify README examples use namespace consistently
    - Verify MIGRATION guide uses namespace consistently
    - Verify test files use namespace consistently
  - [ ] 5.4.9 Breaking change validation
    - Confirm all Champion-prefixed classes removed
    - Confirm two-tier export system in place
    - Confirm namespace approach documented
    - Confirm migration tools complete
  - [ ] 5.4.10 Create release checklist
    - Document manual verification steps performed
    - List any known issues or limitations
    - List post-release monitoring tasks
    - Prepare release notes summary

**Acceptance Criteria:**
- Zero analyzer warnings or errors
- All tests pass successfully
- All documentation complete and accurate
- All builds succeed for supported platforms
- Package passes publication dry-run
- Migration script tested and verified
- Version numbers consistent across project
- Namespace approach used consistently
- Breaking changes properly implemented
- Release checklist complete

**Estimated Time:** 3-4 hours

---

## Execution Order

### Recommended Sequence:

**Phase 1 (Parallel Execution Possible):**
- Task Groups 1.1, 1.2, 1.3, 1.4, 1.6, 1.7, 1.8 can run in parallel (with caution on imports)
- Task Group 1.5 should run after 1.1 and 1.6 complete (depends on models and builder functions)

**Phase 2 (Sequential):**
- Task Group 2.1 and 2.2 can run after Phase 1 complete

**Phase 3 (Sequential):**
- Task Group 3.1 after Phase 1 and 2 complete

**Phase 4 (Partially Parallel):**
- Task Groups 4.1, 4.3, 4.4 can run in parallel (documentation tasks)
- Task Group 4.2 (migration script) can start early but benefits from having 4.1 started
- Task Group 4.5 should be last in Phase 4

**Phase 5 (Mostly Sequential):**
- Task Group 5.1 after Phase 1-2 complete
- Task Group 5.2 after Task Group 3.1 complete
- Task Group 5.3 after Task Group 4.2 complete
- Task Group 5.4 after all other task groups complete

### Critical Path:
Phase 1 (Core Library) → Phase 2 (Exports) → Phase 3 (Example) → Phase 5 (Testing)
Phase 4 (Documentation) can run largely in parallel with Phases 2-3

---

## Risk Mitigation

**Risk: Import Cycle Issues**
- Mitigation: Preserve existing file structure and import patterns
- Verification: Task 5.4.1 includes analyzer check

**Risk: Type Inference Failures**
- Mitigation: Comprehensive testing in Phase 5
- Verification: Task 5.1 ensures test suite passes

**Risk: Namespace Collision Confusion**
- Mitigation: Clear documentation in all examples and migration guide
- Verification: Task 4.1, 4.4 emphasize namespace approach

**Risk: Incomplete Migration**
- Mitigation: Automated migration script with dry-run mode
- Verification: Task 5.3 thoroughly tests script

**Risk: String Literal False Positives**
- Mitigation: Smart detection in migration script
- Verification: Task 5.3.4 tests edge cases

**Risk: Documentation Inconsistency**
- Mitigation: Final validation task searches for "Champion" references
- Verification: Task 5.4.1 includes comprehensive search

---

## Success Metrics

- [ ] All 74+ Dart files updated with new class names
- [ ] Zero compilation errors or warnings
- [ ] All tests pass (100% pass rate)
- [ ] Example app runs successfully with new API
- [x] Migration script successfully migrates test projects
- [ ] All documentation updated and consistent
- [ ] Package passes `dart pub publish --dry-run`
- [ ] Version bumped to 0.4.0 across all files
- [ ] Namespace approach used consistently throughout

---

## Notes

**Custom Roles Used:**
- **dart-library-engineer**: Handles Dart library refactoring, class renaming, and code structure changes
- **documentation-engineer**: Handles comprehensive documentation writing for migration guides and user-facing docs

These custom roles are used because the existing implementers (database-engineer, api-engineer, ui-designer) don't fit this Dart/Flutter library refactoring project. The work is highly specialized to Dart language patterns and Flutter library structure.

**Testing Philosophy:**
Per the testing standards, this project focuses on:
- Minimal new test writing (only updating existing tests)
- Core flow validation (form lifecycle, field rendering)
- Skipping exhaustive edge case testing (not critical for renaming)
- Fast test execution to enable frequent verification

**Parallel Execution:**
Phase 1 task groups are designed for parallel execution by organizing work by folder structure, as specified in the requirements. Each folder has minimal dependencies on other folders during the renaming phase.
