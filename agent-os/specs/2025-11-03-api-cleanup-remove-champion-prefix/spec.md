# Specification: API Cleanup - Remove Champion Prefix

## Goal

Modernize the ChampionForms library API by removing the "Champion" prefix from all classes and adopting idiomatic Dart namespace patterns. This breaking change (v0.4.0) simplifies the API, reduces verbosity, and aligns with Dart best practices by using import aliases to handle namespace collisions with Flutter's built-in widgets.

## User Stories

- As a ChampionForms user, I want to use shorter, cleaner class names like `form.TextField()` instead of `ChampionTextField()` so that my code is more readable and maintainable
- As a library maintainer, I want to follow Dart's idiomatic namespace patterns so that the library feels more natural to Dart/Flutter developers
- As a new user, I want to import the library with a namespace alias (e.g., `as form`) so that I can avoid collisions with Flutter's built-in Row, Column, and Form widgets
- As an existing user, I want migration tooling and clear documentation so that I can upgrade to v0.4.0 with minimal friction

## Core Requirements

### Functional Requirements

**API Renaming - Remove "Champion" Prefix:**
- Public field classes: `ChampionTextField` → `TextField`, `ChampionOptionSelect` → `OptionSelect`, `ChampionFileUpload` → `FileUpload`, `ChampionCheckboxSelect` → `CheckboxSelect`, `ChampionChipSelect` → `ChipSelect`
- Layout classes: `ChampionRow` → `Row`, `ChampionColumn` → `Column`
- Form classes: `ChampionForm` → `Form`, `ChampionFormController` → `FormController`
- Theme classes: `ChampionFormTheme` → `FormTheme`
- Internal classes: `ChampionAutocompleteWrapper` → `AutocompleteWrapper`, `ChampionFormFieldRegistry` → `FormFieldRegistry`

**Base Class Hierarchy Renaming:**
- `ChampionFormElement` → `FormElement` (top-level abstract class)
- `FormFieldBase` → `FieldBase` (extends FormElement)
- `FormFieldDef` → `Field` (implements FieldBase)
- `FormFieldNull` → `NullField` (extends Field)

**Builder Function Renaming:**
- `buildChampionTextField` → `buildTextField`
- `buildChampionOptionSelect` → `buildOptionSelect`
- `buildChampionCheckboxSelect` → `buildCheckboxSelect`
- `buildChampionFileUpload` → `buildFileUpload`
- `buildChampionChipSelect` → `buildChipSelect`

**Extension Renaming:**
- `ChampionTextFieldController` extension → `TextFieldController`

**Namespace Import Strategy:**
- Primary usage pattern: `import 'package:championforms/championforms.dart' as form;`
- Users reference classes as: `form.TextField()`, `form.Form()`, `form.FormController()`, etc.
- This approach avoids namespace collisions with Flutter's Row, Column, and Form widgets

**Two-Tier Export System:**
- Create two separate export files for different use cases
- File 1: `championforms.dart` - Form lifecycle (frequent imports throughout app)
- File 2: `championforms_themes.dart` - App initialization (rare imports, typically once)

### Non-Functional Requirements

**Version Management:**
- Bump version from 0.3.0 to 0.4.0 (breaking change per semver pre-1.0)
- Clean break approach - no deprecation period (acceptable for pre-1.0 versions)
- Package name remains "championforms" on pub.dev

**Documentation Quality:**
- Comprehensive migration guide with before/after examples
- Automated migration script to reduce user effort
- Updated README with all new class names and namespace approach
- Detailed CHANGELOG entry explaining breaking changes

**Backward Compatibility:**
- None - this is a breaking change
- All users on v0.3.x must migrate to use v0.4.0
- Migration tooling provided to ease transition

## Visual Design

Not applicable - this is an API refactoring with no visual changes. All UI components maintain identical visual behavior.

## Reusable Components

### Existing Code to Leverage

**Current File Structure (Preserve):**
- `/lib/models/` - Field types, themes, validators, form results (30 files)
- `/lib/widgets_external/` - Public-facing widgets (12 files)
- `/lib/widgets_internal/` - Internal widgets (8 files)
- `/lib/controllers/` - FormController (1 file)
- `/lib/core/` - Field builder registry (1 file)
- `/lib/default_fields/` - Default field builder functions (5 files)
- `/lib/functions/` - Utility functions (8 files)
- `/lib/themes/` - Pre-built theme definitions (4 files)
- `/example/lib/` - Example application (1 file)

**Existing Export Pattern:**
- Current: Single `championforms.dart` file exports all classes
- New: Split into two files based on usage frequency

### New Components Required

**New Export File:**
- `championforms_themes.dart` - New export file for theme-related classes and field registry

**Migration Tooling:**
- `project-migration.dart` - Automated Dart script to migrate user projects
- `MIGRATION-0.4.0.md` - Comprehensive migration guide document

**Updated Documentation:**
- Rewritten README.md with namespace approach examples
- Updated CHANGELOG.md with v0.4.0 breaking changes
- All example code updated to demonstrate new API

## Technical Approach

### Database

Not applicable - this is a client-side Flutter library with no database component.

### API Changes

**Complete Class Name Mapping:**

| Old Name (v0.3.x) | New Name (v0.4.0) | Category |
|-------------------|-------------------|----------|
| `ChampionTextField` | `TextField` | Field Type |
| `ChampionOptionSelect` | `OptionSelect` | Field Type |
| `ChampionFileUpload` | `FileUpload` | Field Type |
| `ChampionCheckboxSelect` | `CheckboxSelect` | Field Type |
| `ChampionChipSelect` | `ChipSelect` | Field Type |
| `ChampionRow` | `Row` | Layout |
| `ChampionColumn` | `Column` | Layout |
| `ChampionForm` | `Form` | Widget |
| `ChampionFormController` | `FormController` | Controller |
| `ChampionFormTheme` | `FormTheme` | Theme |
| `ChampionFormElement` | `FormElement` | Base Class |
| `FormFieldBase` | `FieldBase` | Base Class |
| `FormFieldDef` | `Field` | Base Class |
| `FormFieldNull` | `NullField` | Base Class |
| `ChampionAutocompleteWrapper` | `AutocompleteWrapper` | Internal |
| `ChampionFormFieldRegistry` | `FormFieldRegistry` | Internal |

**Usage Before (v0.3.x):**
```dart
import 'package:championforms/championforms.dart';

ChampionFormController controller = ChampionFormController();

ChampionForm(
  controller: controller,
  fields: [
    ChampionTextField(id: 'email', title: 'Email'),
    ChampionRow(
      children: [
        ChampionTextField(id: 'first', title: 'First Name'),
        ChampionTextField(id: 'last', title: 'Last Name'),
      ],
    ),
  ],
)
```

**Usage After (v0.4.0):**
```dart
import 'package:championforms/championforms.dart' as form;

form.FormController controller = form.FormController();

form.Form(
  controller: controller,
  fields: [
    form.TextField(id: 'email', title: 'Email'),
    form.Row(
      children: [
        form.TextField(id: 'first', title: 'First Name'),
        form.TextField(id: 'last', title: 'Last Name'),
      ],
    ),
  ],
)
```

### Export File Structure

**File 1: `lib/championforms.dart` (Form Lifecycle)**

Used throughout the application wherever forms are used. Import as: `import 'package:championforms/championforms.dart' as form;`

**Exports:**
- Field classes: `TextField`, `OptionSelect`, `FileUpload`, `CheckboxSelect`, `ChipSelect`
- Layout classes: `Row`, `Column`
- Base classes: `FormElement`, `FieldBase`, `Field`, `NullField`
- Form widget: `Form`
- Controller: `FormController`
- Results: `FormResults`, `FieldResults`
- Validators: `FormBuilderValidator`, `DefaultValidators`
- Autocomplete: `AutoCompleteBuilder`, `AutoCompleteOption`
- Field layouts: `fieldSimpleLayout` and other layout functions
- Field backgrounds: `fieldSimpleBackground` and other background functions
- Utility functions: `getErrors`, result getters

**File 2: `lib/championforms_themes.dart` (App Initialization)**

Used once during app initialization for theme configuration and custom field registration. Import as: `import 'package:championforms/championforms_themes.dart';`

**Exports:**
- `FormTheme`
- `FieldColorScheme`, `FieldGradientColors`
- Pre-built themes: `softBlueColorTheme`, `redAccentFormTheme`, `iconicColorTheme`
- `FormFieldRegistry` (for registering custom field types)

**Documentation Header for championforms.dart:**
```dart
/// ChampionForms - Form Lifecycle Classes
///
/// This file exports all classes needed for building and managing forms
/// throughout your application.
///
/// ## Recommended Usage:
/// ```dart
/// import 'package:championforms/championforms.dart' as form;
/// ```
///
/// This namespace approach prevents collisions with Flutter's built-in
/// Form, Row, and Column widgets.
```

**Documentation Header for championforms_themes.dart:**
```dart
/// ChampionForms - Theming & Configuration
///
/// This file exports theme-related classes and the field registry.
/// Typically imported once during app initialization.
///
/// ## Usage:
/// ```dart
/// import 'package:championforms/championforms_themes.dart';
/// ```
```

### Testing

**Test File Updates:**
- Update all test files to use new class names with namespace import
- Verify all existing tests pass without modification to test logic
- Ensure type safety is maintained in all generic type parameters
- Test namespace collisions are properly avoided

**Example App Verification:**
- Update example app to demonstrate namespace approach
- Verify all field types render correctly with new names
- Test form submission, validation, and all interactive features
- Confirm theme switching works with new `FormTheme` name

**Migration Script Testing:**
- Test migration script on example project
- Verify backup files are created before modification
- Confirm all class name replacements are accurate
- Test edge cases: comments, string literals, variable naming

## Migration Strategy

### Migration Documentation (MIGRATION-0.4.0.md)

**Section 1: Why We Changed**
- Explain move to idiomatic Dart namespace patterns
- Discuss benefits of shorter, cleaner API
- Address namespace collision handling with import aliases

**Section 2: Before/After Examples**
- Import statement changes
- Controller initialization
- Field usage in forms
- Row/Column layout usage
- Theme initialization
- Complete working form example (old vs new)

**Section 3: Find-and-Replace Table**
- Comprehensive table of all class name changes
- Include import statement patterns
- Note special cases (Row/Column collision with Flutter)

**Section 4: Step-by-Step Manual Migration**
1. Update import statements to use namespace alias
2. Replace all `Champion*` class references with namespace prefix
3. Update type annotations in variables and function signatures
4. Update generic type parameters
5. Run `flutter pub get` and verify no compilation errors
6. Run tests and fix any remaining issues

**Section 5: Automated Migration**
- Instructions for using `project-migration.dart` script
- Command: `dart run project-migration.dart /path/to/your/project`
- Explanation of what the script does
- Note about backup files created

**Section 6: Common Issues FAQ**
- Q: Why am I getting "The name 'TextField' is defined in the libraries" error?
  - A: You need to use the namespace alias (`form.TextField`) to disambiguate
- Q: Can I use both `ChampionForms` and Flutter's `Form` widget?
  - A: Yes, use `form.Form` for ChampionForms and `Form` for Flutter's widget
- Q: Will this affect my existing data or form state?
  - A: No, only class names changed - functionality is identical

### Automated Migration Script (project-migration.dart)

**Features:**
- Command-line argument: accepts project path
- Recursively scans for all `.dart` files
- Detects championforms import statements
- Updates imports to add namespace alias (`as form`)
- Performs all class name find-and-replace operations
- Creates `.backup` files in new backups folder in project root "backups/path/to/original/file/location" folder before modifying originals
- Skips modifications inside string literals and comments
- Generates summary report of changes made
- Handles edge cases (already namespaced imports, partial migrations)

**Usage:**
```bash
dart run project-migration.dart /path/to/your/flutter/project
```

**Output Example:**
```
ChampionForms Migration Tool v0.4.0
===================================
Scanning: /path/to/your/flutter/project
Found 23 Dart files to analyze

Analyzing files...
✓ lib/main.dart - Modified (backup: lib/main.dart.backup)
✓ lib/screens/login_form.dart - Modified (backup: lib/screens/login_form.dart.backup)
✓ lib/screens/profile_form.dart - No changes needed

Summary:
- Files scanned: 23
- Files modified: 15
- Files skipped: 8
- Backups created: 15

Migration complete! Please review changes and test your application.
```

### Implementation Phases

**Phase 1: Core Library Refactoring (Parallelizable)**

Work is organized by folder to enable parallel execution by subagents:

- **Task 1.1: lib/models/** (30 files)
  - Rename base classes: `ChampionFormElement` → `FormElement`, `FormFieldBase` → `FieldBase`, `FormFieldDef` → `Field`, `FormFieldNull` → `NullField`
  - Update field type classes: `ChampionTextField`, `ChampionOptionSelect`, `ChampionFileUpload`, `ChampionCheckboxSelect`, `ChampionChipSelect`
  - Update `ChampionFormTheme` → `FormTheme`
  - Update all type references and imports

- **Task 1.2: lib/controllers/** (1 file)
  - Rename `ChampionFormController` → `FormController`
  - Update all type references

- **Task 1.3: lib/widgets_external/** (12 files)
  - Rename `ChampionForm` → `Form`
  - Update field builder functions
  - Update all imports and type references

- **Task 1.4: lib/widgets_internal/** (8 files)
  - Rename `ChampionAutocompleteWrapper` → `AutocompleteWrapper`
  - Update internal widget references

- **Task 1.5: lib/core/** (1 file)
  - Rename `ChampionFormFieldRegistry` → `FormFieldRegistry`
  - Update builder function references

- **Task 1.6: lib/default_fields/** (5 files)
  - Rename builder functions: `buildChampionTextField` → `buildTextField`, etc.
  - Rename extension: `ChampionTextFieldController` → `TextFieldController`

- **Task 1.7: lib/functions/** (8 files)
  - Update type references in validators and utility functions

- **Task 1.8: lib/themes/** (4 files)
  - Update theme function references to new class names

**Phase 2: Export Files & Public API**

- **Task 2.1: Create championforms_themes.dart**
  - Export `FormTheme`, `FieldColorScheme`, pre-built themes
  - Export `FormFieldRegistry`
  - Add documentation header

- **Task 2.2: Update championforms.dart**
  - Remove theme exports (moved to championforms_themes.dart)
  - Update all class name exports
  - Add documentation header recommending namespace import

**Phase 3: Example Application**

- **Task 3.1: Update example/lib/main.dart**
  - Add namespace import: `import 'package:championforms/championforms.dart' as form;`
  - Update all class usage to namespace pattern
  - Update theme imports to use championforms_themes.dart
  - Verify app runs successfully

**Phase 4: Documentation**

- **Task 4.1: Create MIGRATION-0.4.0.md**
  - Write comprehensive migration guide with all sections

- **Task 4.2: Create project-migration.dart**
  - Implement automated migration script
  - Add CLI argument parsing and file scanning
  - Implement backup and replace logic
  - Test on sample project

- **Task 4.3: Update CHANGELOG.md**
  - Add v0.4.0 entry with breaking changes
  - Reference migration guide

- **Task 4.4: Update README.md**
  - Update all code examples with namespace approach
  - Add migration section
  - Update "What's New" section

- **Task 4.5: Update pubspec.yaml**
  - Bump version from 0.3.0 to 0.4.0

**Phase 5: Testing & Validation**

- **Task 5.1: Update Test Files**
  - Update all test files with new class names
  - Ensure all tests pass

- **Task 5.2: Example App Verification**
  - Run example app and verify all functionality
  - Test all field types with new names

- **Task 5.3: Migration Script Testing**
  - Test migration script on example project
  - Verify all replacements are correct

## Out of Scope

**Not Included in This Release:**
- Package name remains "championforms" on pub.dev (no package rename)
- Existing MIGRATION-0.3.0.md remains unchanged
- No changes to validation logic or algorithms
- No changes to theming system functionality
- No changes to field rendering or visual behavior
- No changes to controller logic beyond naming
- No UI/UX changes - all visual behavior identical
- No changes to field builder architecture
- No changes to Dart/Flutter SDK version requirements

**Future Enhancements (Post-0.4.0):**
- Potential 1.0.0 stable release
- Additional field types
- Enhanced theming capabilities

## Success Criteria

**Code Quality:**
- All 71 library files successfully renamed with consistent naming
- All type references updated (including generics like `List<FormElement>`)
- No compilation errors or warnings
- Type safety maintained throughout the library
- All imports/exports correctly reference new class names

**Functionality:**
- Example app runs without errors using namespace approach
- All tests pass with updated class names
- All field types render and function identically to v0.3.x
- Form submission, validation, and interactive features work as before
- Theme switching works with new `FormTheme` name

**Documentation:**
- MIGRATION-0.4.0.md is comprehensive with clear examples
- Migration script successfully migrates test projects
- CHANGELOG.md and README.md fully updated
- All code examples use namespace approach
- Version bumped to 0.4.0 in pubspec.yaml

**Migration Tools:**
- `project-migration.dart` script runs successfully
- Script creates backups before modifying files
- Script correctly handles edge cases (strings, comments)
- Script generates accurate summary report

**User Experience:**
- Migration guide is easy to follow
- Before/after examples are clear and accurate
- Common issues FAQ addresses likely problems
- Automated script reduces migration effort significantly

## Risks & Mitigations

### Risk 1: Flutter Widget Namespace Collisions
**Description:** ChampionForms' `Row`, `Column`, and `Form` classes conflict with Flutter's built-in widgets.

**Mitigation:**
- Mandate namespace import approach (`as form`)
- Document this clearly in all examples and migration guide
- Add prominent note in README about namespace requirements
- Migration script automatically adds namespace alias

### Risk 2: Type Inference Issues
**Description:** Dart's type inference may fail in some contexts after renaming.

**Mitigation:**
- Test thoroughly across different usage patterns
- Document any cases requiring explicit type annotations
- Ensure all generic type parameters are correctly updated
- Include examples of explicit typing when needed

### Risk 3: String Literal False Positives
**Description:** Migration script might incorrectly replace "Champion" in string literals or comments.

**Mitigation:**
- Implement smart detection to skip string literals
- Create backup files before any modifications
- Provide dry-run mode to preview changes
- Document edge cases in migration guide

### Risk 4: Generic Type Parameter Updates
**Description:** All generic type parameters must be updated (e.g., `List<ChampionFormElement>` → `List<FormElement>`).

**Mitigation:**
- Systematic review of all generic type usage
- Comprehensive test coverage for type safety
- Migration script includes generic type parameter patterns
- Phase 5 testing specifically validates type safety

### Risk 5: Import Cycle Issues
**Description:** Refactoring might introduce circular import dependencies.

**Mitigation:**
- Preserve existing file structure and import patterns
- Only rename classes, don't reorganize file locations
- Verify no new import cycles during Phase 5 testing
- Maintain current dependency graph

### Risk 6: User Adoption Friction
**Description:** Users may resist upgrading due to breaking changes.

**Mitigation:**
- Provide automated migration script to reduce effort
- Create comprehensive, easy-to-follow migration guide
- Include before/after examples for all common patterns
- Emphasize benefits: cleaner API, better namespace handling
- Pre-1.0 version signals that breaking changes are expected

### Risk 7: Documentation Consistency
**Description:** Some documentation or comments might reference old class names.

**Mitigation:**
- Systematic search for all "Champion" references in comments
- Update all inline documentation and doc comments
- Review README, CHANGELOG, and all markdown files
- Include documentation review in Phase 5 validation

### Risk 8: Extension Name Conflicts
**Description:** Extension on `FormController` might conflict with other extensions.

**Mitigation:**
- Use clear, specific extension names
- Document extension usage patterns
- Test extension method resolution in various contexts
- Provide examples of extension usage in migration guide

### Risk 9: Third-Party Integration Breaking
**Description:** Third-party packages extending ChampionForms may break.

**Mitigation:**
- Clear communication about breaking changes
- Detailed migration guide helps third-party maintainers
- Version bump to 0.4.0 clearly signals breaking change
- Consider reaching out to known third-party integrations

### Risk 10: Incomplete Migration
**Description:** Users might partially migrate, leading to inconsistent codebases.

**Mitigation:**
- Migration script does complete migration in one pass
- Document that partial migration is not supported
- Encourage users to commit migration as single change
- Provide git-friendly workflow in migration guide
