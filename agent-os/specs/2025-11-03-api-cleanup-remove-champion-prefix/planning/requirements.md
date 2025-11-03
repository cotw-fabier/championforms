# Spec Requirements: API Cleanup - Remove Champion Prefix

## Initial Description

The ChampionForms library currently uses "Champion" as a namespace prefix for all public-facing classes (ChampionTextField, ChampionForm, ChampionFormController, etc.). This was originally implemented to avoid namespace collisions with popular Flutter widgets.

This spec involves:
1. Removing "Champion" prefix from ALL classes throughout the library
2. Renaming base classes in lib/models/field_types/ for better clarity
3. Adopting idiomatic Dart namespace pattern using import aliases
4. Creating comprehensive migration documentation and tooling
5. Bumping version to 0.4.0 (clean break, no deprecation period)

## Requirements Discussion

### First Round Questions

**Q1: Namespace Import Strategy**
**Question:** For the new API without "Champion" prefix, should users import with a namespace like `import 'package:championforms/championforms.dart' as form;` and use `form.TextField()`, or use regular imports and let developers handle their own naming conflicts?
**Answer:** Use `import 'package:championforms/championforms.dart' as form;` approach, then developers use `form.TextField()`, `form.OptionSelect()`, etc.

**Q2: Base Class Renaming**
**Question:** The base classes need renaming for clarity. Current hierarchy is:
- ChampionFormElement (top-level abstract)
- FormFieldBase extends ChampionFormElement
- FormFieldDef implements FormFieldBase
- FormFieldNull extends FormFieldDef

Proposed new names:
- ChampionFormElement → FormElement
- FormFieldBase → FieldBase
- FormFieldDef → Field
- FormFieldNull → NullField

Is this acceptable, or do you prefer different names?
**Answer:** Approved the proposed renaming:
- `ChampionFormElement` → `FormElement`
- `FormFieldBase` → `FieldBase`
- `FormFieldDef` → `Field`
- `FormFieldNull` → `NullField`

**Q3: Version Number**
**Question:** This is a major breaking change. Should we bump to 0.4.0 (following semver pre-1.0 where MINOR is breaking)?
**Answer:** Bump to **0.4.0**

**Q4: Migration Approach**
**Question:** Should we provide a deprecation period (keeping old names with @deprecated annotations for one version) or do a clean break (acceptable since pre-1.0)?
**Answer:** **Clean break** - no deprecation period (acceptable since pre-1.0)

**Q5: Scope of Renaming**
**Question:** Should we remove "Champion" prefix from:
- All public classes (TextField, OptionSelect, Form, FormController, etc.)? YES/NO
- Internal classes (AutocompleteWrapper, FormFieldRegistry, etc.)? YES/NO
- Theme classes (FormTheme stays as-is)? FormTheme/ChampionFormTheme?
**Answer:** Remove "Champion" prefix from EVERYTHING:
- All public classes (TextField, OptionSelect, FileUpload, CheckboxSelect, ChipSelect, Row, Column, Form, FormController, FormTheme, etc.)
- Internal classes (AutocompleteWrapper, FormFieldRegistry, etc.)

**Q6: Example Application Updates**
**Question:** Should the example app demonstrate the new namespace approach exclusively, or show both old and new approaches?
**Answer:** Update all example code to new namespace approach (no mixed old/new examples)

**Q7: Migration Documentation Strategy**
**Question:** For migration docs, should we create:
- A detailed migration-0.4.0.md file with before/after examples?
- A Dart migration script that users can run to automate the changes?
- Update CHANGELOG.md with migration notes?
- Add migration section to README.md?
**Answer:** Create comprehensive migration documentation:
- Create migration-0.4.0.md with:
  - Brief explanation of why we're making this change
  - Before/after code examples
  - Find-and-replace patterns
- Create **Dart migration script** (`project-migration.dart`) that users can run with `dart run project-migration.dart` to automate migration in their projects
- Update CHANGELOG.md
- Add migration section to README.md referencing migration-0.4.0.md

**Q8: Import File Structure**
**Question:** Should we reorganize the main export file (championforms.dart) into multiple targeted export files? For example:
- championforms_core.dart (fields, controller, FormResults)
- championforms_themes.dart (themes, color schemes)
- championforms_validators.dart (validators, default validators)

Or keep one main export file?
**Answer:** Create **TWO primary export files**:
- **Export File 1** (Form lifecycle): Fields, controller, autocomplete, FormResults - used throughout app
- **Export File 2** (App initialization): Themes, field registry - used for app initialization only

**Q9: Work Organization**
**Question:** Since there are 71 Dart files to update, should we organize the work by folder structure (models/, widgets_external/, widgets_internal/, controllers/, example/) to allow parallel execution by subagents?
**Answer:** **Yes** - Organize by folder structure for parallel subagent execution:
- lib/models/
- lib/widgets_external/
- lib/widgets_internal/
- lib/controllers/
- example/

**Q10: Out of Scope Confirmation**
**Question:** To clarify scope boundaries - are these items OUT OF SCOPE?
- Package name stays "championforms" on pub.dev
- Existing migration guides (MIGRATION-0.3.0.md) remain unchanged
- No changes to validation logic, theming system, or field functionality
**Answer:** Confirmed OUT OF SCOPE:
- Package name stays "championforms" on pub.dev
- Existing migration guides (MIGRATION-0.3.0.md) remain unchanged

### Existing Code to Reference

No similar existing features identified for reference. This is a comprehensive refactoring across the entire library.

### Follow-up Questions

None - all requirements clarified.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable - this is an API refactoring project with no UI changes.

## Requirements Summary

### Functional Requirements

#### Core API Changes
- Remove "Champion" prefix from ALL classes in the library:
  - **Public Field Classes**: ChampionTextField → TextField, ChampionOptionSelect → OptionSelect, ChampionFileUpload → FileUpload, ChampionCheckboxSelect → CheckboxSelect, ChampionChipSelect → ChipSelect
  - **Layout Classes**: ChampionRow → Row, ChampionColumn → Column
  - **Form Classes**: ChampionForm → Form, ChampionFormController → FormController
  - **Theme Classes**: ChampionFormTheme → FormTheme
  - **Internal Classes**: ChampionAutocompleteWrapper → AutocompleteWrapper, ChampionFormFieldRegistry → FormFieldRegistry

#### Base Class Hierarchy Renaming
- Rename base classes for better semantic clarity:
  - `ChampionFormElement` → `FormElement` (top-level abstract class)
  - `FormFieldBase` → `FieldBase` (extends FormElement)
  - `FormFieldDef` → `Field` (implements FieldBase)
  - `FormFieldNull` → `NullField` (extends Field)

#### Import Strategy
- Primary usage pattern: `import 'package:championforms/championforms.dart' as form;`
- Users then reference classes as: `form.TextField()`, `form.Form()`, `form.FormController()`, etc.
- This allows developers to avoid namespace collisions with Flutter's built-in widgets

#### Export File Structure
Create two primary export files:

**File 1: championforms.dart** (Form Lifecycle - frequent imports)
- Field classes: TextField, OptionSelect, FileUpload, CheckboxSelect, ChipSelect
- Layout classes: Row, Column
- Base classes: FormElement, FieldBase, Field, NullField
- Form widget: Form
- Controller: FormController
- Results: FormResults, FieldResults
- Validators: FormBuilderValidator, DefaultValidators
- Autocomplete: AutoCompleteBuilder, AutoCompleteOption
- Field layouts and backgrounds

**File 2: championforms_themes.dart** (App Initialization - rare imports)
- FormTheme
- FieldColorScheme, FieldGradientColors
- Pre-built themes: softBlueColorTheme, redAccentFormTheme, iconicColorTheme
- FormFieldRegistry (for custom field type registration)

### Documentation Requirements

#### Migration Guide (migration-0.4.0.md)
Create comprehensive migration documentation including:
- **Why We Changed**: Explanation of moving to idiomatic Dart namespacing
- **Before/After Examples**:
  - Import statement changes
  - Class usage changes
  - Complete form example (old vs new)
- **Find-and-Replace Patterns**: Table of exact replacements needed
- **Step-by-Step Migration**: Numbered instructions for manual migration
- **Common Issues**: FAQ section addressing likely migration problems

#### Dart Migration Script (project-migration.dart)
Create automated migration tool that:
- Scans a Dart project directory for .dart files
- Identifies championforms import statements
- Updates import statements to use namespace alias
- Performs find-and-replace for all class name changes
- Creates backup of files before modification
- Outputs summary report of changes made
- Usage: `dart run project-migration.dart [project-path]`

#### CHANGELOG.md Updates
Add version 0.4.0 entry with:
- **Breaking Changes** section listing all renamed classes
- **Namespace Strategy** explanation
- **Migration Guide** reference to migration-0.4.0.md
- **Why This Change** brief rationale

#### README.md Updates
- Update all code examples to use new namespace approach
- Update "Installation" section version reference
- Add "Migration from v0.3.x" section with link to migration guide
- Update all class names throughout documentation
- Update "What's New" section for v0.4.0

### Reusability Opportunities

No existing similar features to reuse - this is a comprehensive rename/refactor affecting the entire library structure.

### Scope Boundaries

**In Scope:**
- Rename all "Champion"-prefixed classes throughout the library (71 files)
- Rename base classes (ChampionFormElement, FormFieldBase, FormFieldDef, FormFieldNull)
- Update all internal references to renamed classes
- Update all import/export statements
- Create two-tier export file structure
- Update example application with namespace approach
- Create migration-0.4.0.md guide
- Create automated Dart migration script (project-migration.dart)
- Update CHANGELOG.md
- Update README.md with new examples and migration info
- Bump version to 0.4.0 in pubspec.yaml
- Update all documentation and comments referencing old class names

**Out of Scope:**
- Package name remains "championforms" on pub.dev (no pub.dev republishing concerns)
- Deprecation period (clean break approach)
- Existing MIGRATION-0.3.0.md remains unchanged
- No changes to validation logic
- No changes to theming system functionality
- No changes to field rendering or behavior
- No changes to controller logic (only naming)
- No UI/UX changes (visual behavior identical)

### Technical Considerations

#### File Organization for Parallel Work
Organize refactoring by folder structure to enable parallel subagent execution:

1. **lib/models/** (30 files) - Contains field type models, themes, validators, form results
2. **lib/widgets_external/** (12 files) - Public-facing widgets like Form, field builders
3. **lib/widgets_internal/** (8 files) - Internal widgets like autocomplete overlay, form builder
4. **lib/controllers/** (1 file) - FormController
5. **lib/core/** (1 file) - Field builder registry
6. **lib/default_fields/** (5 files) - Default field builder functions
7. **lib/functions/** (8 files) - Utility functions (validators, theme helpers)
8. **lib/themes/** (4 files) - Pre-built theme definitions
9. **example/lib/** (1 file) - Example application
10. **Root files** - championforms.dart export file, README.md, CHANGELOG.md, pubspec.yaml
11. **Migration files** - Create migration-0.4.0.md, project-migration.dart

#### Class Rename Mapping (Complete)

**Public Field Classes:**
- ChampionTextField → TextField
- ChampionOptionSelect → OptionSelect
- ChampionFileUpload → FileUpload
- ChampionCheckboxSelect → CheckboxSelect
- ChampionChipSelect → ChipSelect

**Layout Classes:**
- ChampionRow → Row
- ChampionColumn → Column

**Form & Controller:**
- ChampionForm → Form
- ChampionFormController → FormController

**Theme Classes:**
- ChampionFormTheme → FormTheme

**Base Classes:**
- ChampionFormElement → FormElement
- FormFieldBase → FieldBase
- FormFieldDef → Field
- FormFieldNull → NullField

**Internal Classes:**
- ChampionAutocompleteWrapper → AutocompleteWrapper
- ChampionFormFieldRegistry → FormFieldRegistry

**Functions/Extensions:**
- buildChampionTextField → buildTextField
- buildChampionOptionSelect → buildOptionSelect
- buildChampionCheckboxSelect → buildCheckboxSelect
- buildChampionFileUpload → buildFileUpload
- buildChampionChipSelect → buildChipSelect
- ChampionTextFieldController extension → TextFieldController

#### Critical Implementation Notes

1. **Preserve File Structure**: Keep existing folder structure, only rename class names within files
2. **Update All References**: Every class reference, import, export, comment, and doc string must be updated
3. **Maintain Backward Compatibility**: None - this is a breaking change (0.4.0)
4. **Testing**: All existing tests must be updated to use new class names
5. **Example App**: Must fully demonstrate new namespace approach with working code
6. **Type Safety**: Ensure all type annotations updated (List<ChampionFormElement> → List<FormElement>)

#### Version Requirements
- Current version: 0.3.0 (in pubspec.yaml)
- New version: 0.4.0
- Dart SDK: ">=3.0.5 <4.0.0" (unchanged)
- Flutter: ">=1.17.0" (unchanged)

#### Migration Script Requirements
The Dart migration script must:
- Accept a project path as command-line argument
- Recursively find all .dart files
- Detect championforms imports
- Add namespace alias if not present
- Perform all class name replacements
- Handle edge cases (comments, strings, variable names)
- Create .backup files before modifying
- Generate summary report
- Be runnable as: `dart run project-migration.dart /path/to/project`

#### Impact Assessment
- **Files to Update**: 71 Dart files in lib/, 1 in example/
- **Documentation Files**: README.md, CHANGELOG.md, create migration-0.4.0.md
- **New Files**: project-migration.dart, championforms_themes.dart export file
- **Test Files**: All test files must be updated with new class names
- **Breaking Change Level**: Major (all public API names changed)
- **User Impact**: Every project using championforms will need migration

## Initial Task Breakdown

### Phase 1: Core Library Refactoring (Parallelizable by Folder)

**Task 1.1: lib/models/ Folder** (30 files)
- Rename base classes: ChampionFormElement → FormElement, FormFieldBase → FieldBase, FormFieldDef → Field, FormFieldNull → NullField
- Update field types: ChampionTextField, ChampionOptionSelect, ChampionFileUpload, ChampionCheckboxSelect, ChampionChipSelect
- Update ChampionFormTheme → FormTheme in theme_singleton.dart
- Update all type references and imports within models folder

**Task 1.2: lib/controllers/ Folder** (1 file)
- Rename ChampionFormController → FormController
- Update all type references (ChampionFormElement, FormFieldDef, etc.)
- Update documentation strings

**Task 1.3: lib/widgets_external/ Folder** (12 files)
- Rename ChampionForm → Form in championform.dart
- Update field builder functions
- Update all imports and type references
- Update field layout and background widgets

**Task 1.4: lib/widgets_internal/ Folder** (8 files)
- Rename ChampionAutocompleteWrapper → AutocompleteWrapper
- Update FormBuilderWidget references
- Update all internal widget references and types

**Task 1.5: lib/core/ Folder** (1 file)
- Rename ChampionFormFieldRegistry → FormFieldRegistry
- Update all type references (ChampionTextField → TextField, etc.)
- Update builder function names

**Task 1.6: lib/default_fields/ Folder** (5 files)
- Rename all builder functions: buildChampionTextField → buildTextField, etc.
- Update all type references
- Rename extension: ChampionTextFieldController → TextFieldController

**Task 1.7: lib/functions/ Folder** (8 files)
- Update any Champion references in utility functions
- Update type references in validators and theme helpers

**Task 1.8: lib/themes/ Folder** (4 files)
- Update pre-built theme functions if they reference Champion classes
- Ensure FormTheme compatibility

### Phase 2: Export Files & Public API

**Task 2.1: Create championforms_themes.dart**
- Export FormTheme, FieldColorScheme, pre-built themes
- Export FormFieldRegistry for custom field registration
- Add comprehensive documentation header

**Task 2.2: Update championforms.dart**
- Remove theme exports (moved to championforms_themes.dart)
- Update all class name exports (Champion* → *)
- Add documentation recommending namespace import approach
- Maintain backward-compatible structure

### Phase 3: Example Application

**Task 3.1: Update example/lib/main.dart**
- Add namespace import: `import 'package:championforms/championforms.dart' as form;`
- Update all class usage: ChampionForm → form.Form, ChampionTextField → form.TextField, etc.
- Update theme imports to use championforms_themes.dart
- Ensure app runs successfully with new API

### Phase 4: Documentation

**Task 4.1: Create migration-0.4.0.md**
- Write "Why We Changed" section
- Provide before/after code examples
- Create find-and-replace table
- Add step-by-step migration guide
- Include common issues FAQ

**Task 4.2: Create project-migration.dart**
- Implement file scanner
- Implement import statement updater
- Implement class name replacement logic
- Add backup file creation
- Add summary report generation
- Add CLI argument parsing
- Test on sample project

**Task 4.3: Update CHANGELOG.md**
- Add 0.4.0 version entry
- Document all breaking changes
- Reference migration guide
- Explain rationale

**Task 4.4: Update README.md**
- Update all code examples with namespace approach
- Update class names throughout
- Add "Migration from v0.3.x" section
- Update "What's New" section
- Update installation instructions

**Task 4.5: Update pubspec.yaml**
- Bump version from 0.3.0 to 0.4.0
- No dependency changes needed

### Phase 5: Testing & Validation

**Task 5.1: Update Test Files**
- Update all test files with new class names
- Ensure all tests pass
- Verify type safety

**Task 5.2: Example App Verification**
- Run example app and verify all functionality works
- Test all field types with new names
- Verify theme switching works
- Test form submission and validation

**Task 5.3: Migration Script Testing**
- Test migration script on example project
- Verify backup creation
- Verify all replacements are correct
- Test edge cases (comments, strings)

### Potential Issues & Edge Cases

1. **Flutter's Row and Column Conflict**: Our Row/Column classes will conflict with Flutter's built-in Row/Column widgets if not namespaced properly - this is why namespace approach is critical
2. **Type Inference**: Dart's type inference may need explicit types in some locations after rename
3. **String Literals**: Migration script must NOT replace "Champion" in string literals or comments that are not class references
4. **Generic Type Parameters**: All generic type parameters must be updated (List<ChampionFormElement> → List<FormElement>)
5. **Extension Names**: Extension on FormController must not conflict with other extensions
6. **Default Field Builders**: Builder function references in FormFieldRegistry must all be updated
7. **Import Cycles**: Ensure no circular import issues introduced during refactor
8. **Documentation Links**: Any cross-references in doc comments must be updated

### Success Criteria

- All 71 library files successfully renamed and updated
- Example app runs without errors using new namespace approach
- All tests pass with updated class names
- Migration guide is comprehensive and accurate
- Migration script successfully migrates a test project
- CHANGELOG.md and README.md fully updated
- Version bumped to 0.4.0
- No compilation errors or warnings
- Type safety maintained throughout

## Final Questions

No remaining questions - requirements are comprehensive and complete. Ready for specification creation and implementation.
