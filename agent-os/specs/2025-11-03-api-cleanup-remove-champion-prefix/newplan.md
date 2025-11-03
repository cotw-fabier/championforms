# Model Class Renaming Plan - v0.4.0 Extension

**Status**: Ready for Implementation
**Version**: v0.4.0 (extending existing migration)
**Created**: 2025-11-03
**Estimated Effort**: ~7 hours with parallel execution

---

## Executive Summary

This plan extends the v0.4.0 API cleanup to rename four additional model classes, completing the modernization of the ChampionForms API. These changes will be incorporated into the existing v0.4.0 migration documentation and tooling.

### Final Naming Decisions

| Current Name | New Name | Namespace |
|--------------|----------|-----------|
| `FormBuilderValidator` | `Validator` | `form.Validator` |
| `MultiselectOption` | `FieldOption` | `form.FieldOption` |
| `AutoCompleteOption` | `CompleteOption` | `form.CompleteOption` |
| `DefaultValidators` | `Validators` | `form.Validators` |

### Impact Summary

- **Files to modify**: 65+ files
- **Total references**: ~389 occurrences
- **Breaking change**: Yes (part of v0.4.0)
- **Test files**: 15+ files need updates
- **Documentation**: 4 files need updates

---

## Phase 1: Core Model Class Definitions

**Agent**: api-engineer
**Priority**: CRITICAL - Must complete before all other phases
**Estimated Time**: 30 minutes

### Task 1.1: Update Class Definition Files (4 files)

#### File 1: `/lib/models/validatorclass.dart`
**Changes**: Rename `FormBuilderValidator` → `Validator`
- Line 1: Update class name in definition
- Line 6: Update constructor name
- Update all class documentation references

#### File 2: `/lib/models/multiselect_option.dart`
**Changes**: Rename `MultiselectOption` → `FieldOption`
- Line 1: Update class name in definition
- Update constructor name
- Update all class documentation references

#### File 3: `/lib/models/autocomplete/autocomplete_option_class.dart`
**Changes**: Rename `AutoCompleteOption` → `CompleteOption`
- Line 18: Update class name in definition
- Update constructor name
- Update callback signature types (6 occurrences)
- Update optionBuilder parameters
- Update all documentation

#### File 4: `/lib/functions/defaultvalidators/defaultvalidators.dart`
**Changes**:
1. Rename `DefaultValidators` → `Validators`
   - Line 11: Update class name
   - Line ~15: Update constructor
2. Update internal FieldOption references (10 occurrences)
   - File validator helper methods
   - Type conversions

### Task 1.2: Update Export File

#### File: `/lib/championforms.dart`
**Changes**: Update export comments
- Line 67: Update comment for Validator export
- Line 60: Verify FieldOption export comment
- Line 78: Update comment for CompleteOption export
- Line 68: Update comment for Validators export

### Validation
```bash
flutter analyze lib/
```
**Expected Result**: ~300+ errors initially (references to old names not yet updated)

---

## Phase 2: Core Library Updates

**3 Agents Running in Parallel**
**Priority**: HIGH
**Estimated Time**: 2 hours total (parallel execution)

---

### Agent A: Controller & Form Results (api-engineer)

**Files**: 3 high-impact files
**Estimated Time**: 45 minutes

#### Task 2A.1: Update FormController
**File**: `/lib/controllers/form_controller.dart`
**Impact**: HIGH - 17 FieldOption references

**Changes Required**:
- Method return types: `List<FieldOption>` (multiple methods)
- Generic type parameters in toggle methods
- Helper method signatures
- Documentation strings

**Key Methods to Update**:
- `getMultiSelectValue()` - return type
- `toggleMultiSelectValue()` - parameter types
- `addMultiSelectOptions()` - parameter types
- `removeMultiSelectOptions()` - parameter types
- Internal helper methods

#### Task 2A.2: Update FormResults
**File**: `/lib/models/formresults.dart`
**Impact**: HIGH - 14 FieldOption references

**Changes Required**:
- Type conversion methods
- `asMultiselectList()` method - return type
- Helper method parameters
- Generic type handling
- Documentation

#### Task 2A.3: Update GetErrors Function
**File**: `/lib/functions/geterrors.dart`
**Impact**: LOW - 2 Validator references

**Changes Required**:
- Line ~15: Iterator type annotation
- Documentation comment

**Validation**:
```bash
flutter analyze lib/controllers/ lib/models/formresults.dart lib/functions/geterrors.dart
```

---

### Agent B: Field Types & Models (api-engineer)

**Files**: 9 files
**Estimated Time**: 1 hour

#### Task 2B.1: Update Field Base Classes (3 files)

**File 1**: `/lib/models/field_types/formfieldclass.dart`
- Type parameter: `List<Validator>? validators`
- Update property definition

**File 2**: `/lib/models/field_types/optionselect.dart`
- **Impact**: HIGH - 14 FieldOption references
- Property types: `List<FieldOption> options`
- Default value types: `List<FieldOption> defaultValue`
- Method parameters
- Converter function types

**File 3**: `/lib/models/field_types/fileupload.dart`
- 5 FieldOption references
- Type parameters in file handling
- Documentation

#### Task 2B.2: Update Convenience Classes (2 files)

**File 1**: `/lib/models/field_types/convienence_classes/checkboxselect.dart`
- 1 FieldOption reference

**File 2**: `/lib/models/field_types/convienence_classes/chipselect.dart`
- 1 FieldOption reference

#### Task 2B.3: Update Autocomplete Models (1 file)

**File**: `/lib/models/autocomplete/autocomplete_class.dart`
- **Impact**: MEDIUM - 6 CompleteOption references
- Future return types: `Future<List<CompleteOption>>`
- Callback signature: `Future<List<CompleteOption>> Function(String)`
- `optionBuilder` parameter: `Widget Function(CompleteOption)`
- `initialOptions` list type
- Documentation

#### Task 2B.4: Update Form Values (1 file)

**File**: `/lib/models/formvalues/multiselect_form_field_value_by_id.dart`
- 1 FieldOption reference

**Validation**:
```bash
flutter analyze lib/models/
```

---

### Agent C: Widgets, Builders & Default Fields (api-engineer)

**Files**: 12 files
**Estimated Time**: 1 hour

#### Task 2C.1: Update Default Fields (4 files)

**Files**:
1. `/lib/default_fields/optionselect.dart` - FieldOption references
2. `/lib/default_fields/checkboxselect.dart` - FieldOption references
3. `/lib/default_fields/chipselect.dart` - FieldOption references
4. `/lib/default_fields/fileupload.dart` - FieldOption references (2 occurrences)

**Changes**: Function parameters, return types

#### Task 2C.2: Update Field Builders (4 files)

**Files**:
1. `/lib/widgets_external/field_builders/dropdownfield_builder.dart` - 2 FieldOption
2. `/lib/widgets_external/field_builders/checkboxfield_builder.dart` - 3 FieldOption
3. `/lib/widgets_external/field_builders/chipfield_builder.dart` - 2 FieldOption
4. `/lib/widgets_external/field_builders/fileupload_field_builder.dart` - 2 FieldOption

**Changes**: Widget builder function parameters, list types

#### Task 2C.3: Update Widgets (2 files)

**File 1**: `/lib/widgets_internal/field_widgets/file_upload_widget.dart`
- **Impact**: MEDIUM - 11 FieldOption references
- State management with FieldOption lists
- File handling logic
- Widget builder callbacks

**File 2**: `/lib/widgets_internal/autocomplete_overlay_widget.dart`
- 4 CompleteOption references
- Widget parameters
- List types
- Callback signatures

**Validation**:
```bash
flutter analyze lib/default_fields/ lib/widgets_external/ lib/widgets_internal/
```

---

## Phase 3: Example App & Tests

**Agent**: ui-designer
**Priority**: MEDIUM
**Estimated Time**: 1.5 hours
**Dependencies**: Must wait for Phase 2 to complete

### Task 3.1: Update Example App

**File**: `/example/lib/main.dart`
**Impact**: HIGH - 42 total references

**Breakdown**:
- 7 Validator references (form validators)
- 10 FieldOption references (dropdown/checkbox options)
- 18 CompleteOption references (autocomplete options)
- 7 Validators references (validator instantiation)

**Changes**:
1. Update import statements (already done - using namespace)
2. Replace all validator declarations: `form.Validator`
3. Replace all option declarations: `form.FieldOption`
4. Replace all autocomplete options: `form.CompleteOption`
5. Replace validator helper calls: `form.Validators()`

### Task 3.2: Update Test Files (15+ files)

#### File Upload Tests (3 files - ~84 references)
1. `/example/test/fileupload_clearonupload_integration_test.dart` (30 refs)
   - FieldOption references in file handling
   - Validator references in validation tests

2. `/example/test/fileupload_widget_clearonupload_test.dart` (28 refs)
   - FieldOption in widget tests
   - Validator in validation tests

3. `/example/test/championfileupload_test.dart`
   - Update test expectations

#### Autocomplete Tests (5 files - ~68 references)
1. `/example/test/autocomplete_overlay_integration_test.dart` (18 refs)
2. `/example/test/autocomplete_overlay_keyboard_accessibility_test.dart` (16 refs)
3. `/example/test/autocomplete_overlay_positioning_test.dart` (15 refs)
4. `/example/test/autocomplete_overlay_selection_debounce_test.dart` (10 refs)
5. `/example/test/autocomplete_overlay_widget_structure_test.dart` (9 refs)

**Changes**: Update CompleteOption in test setup, assertions, widget finders

#### Integration Tests
- Update remaining integration tests with mixed references

### Validation
```bash
flutter test example/
```
**Expected Result**: All tests pass

---

## Phase 4: Migration Script & Tools

**Agent**: api-engineer
**Priority**: MEDIUM
**Estimated Time**: 1 hour
**Dependencies**: Can run in parallel with Phase 3

### Task 4.1: Update Migration Script

**File**: `/tools/project-migration.dart`

**Changes Required**:

1. **Add to `classReplacements` map** (around lines 241-266):
```dart
// Add after existing field types section
// Validators
'FormBuilderValidator': 'form.Validator',
'DefaultValidators': 'form.Validators',

// Add to options section (update existing if present)
'MultiselectOption': 'form.FieldOption',

// Add to autocomplete section
'AutoCompleteOption': 'form.CompleteOption',
```

2. **Update usage instructions** (lines 508-520):
   - Add examples showing the 4 new class replacements
   - Update "What this script does" section

3. **Verify word boundary handling**:
   - Ensure regex `\\b{ClassName}\\b` works for all 4 classes
   - Test that partial matches are avoided

### Task 4.2: Update Help Text

**Update `_printUsage()` function** (lines 486-524):
- Add note about the 4 new class names in migration summary
- Update example output to show new classes

### Task 4.3: Test Migration Script

**Create test scenario**:
1. Copy example app to temporary directory
2. Manually revert to old class names (FormBuilderValidator, etc.)
3. Run migration script with `--dry-run`:
```bash
dart run tools/project-migration.dart /tmp/test-project --dry-run
```
4. Verify all 4 classes appear in replacement report
5. Run without dry-run and verify changes

**Validation**:
```bash
# Test the script
dart run tools/project-migration.dart /path/to/test/project --dry-run

# Verify output shows all 4 class replacements
```

---

## Phase 5: Documentation Updates

**Agent**: database-engineer
**Priority**: MEDIUM
**Estimated Time**: 1 hour
**Dependencies**: Can run in parallel with Phases 3 & 4

---

### Task 5.1: Update CHANGELOG.md

**File**: `/CHANGELOG.md`

**Section 1: Expand Breaking Changes List** (after line 25)

Add to the class rename list:
```markdown
- `FormBuilderValidator` → `form.Validator`
- `MultiselectOption` → `form.FieldOption`
- `AutoCompleteOption` → `form.CompleteOption`
- `DefaultValidators` → `form.Validators`
```

**Section 2: Update Builder Functions** (after line 27, if applicable)
- Check if builder functions mention these classes
- Update any references

**Section 3: Verify Namespace Strategy Section** (lines 37-59)
- Add example showing new class names:
```dart
form.TextField(
  id: 'email',
  validators: [
    form.Validator(
      validator: (r) => form.Validators().isEmail(r),
      reason: 'Invalid email'
    )
  ],
),
form.OptionSelect(
  options: [
    form.FieldOption(label: 'Option 1', value: 'val1'),
  ],
)
```

---

### Task 5.2: Update MIGRATION-0.4.0.md

**File**: `/MIGRATION-0.4.0.md`

**Section 1: Overview** (lines 9-16)
Update key highlights to include:
```markdown
- ✨ Cleaner validator names: `FormBuilderValidator` → `Validator`
- ✨ Clearer option names: `MultiselectOption` → `FieldOption`
- ✨ Simplified autocomplete: `AutoCompleteOption` → `CompleteOption`
- ✨ Concise helper class: `DefaultValidators` → `Validators`
```

**Section 2: Find-and-Replace Table** (lines 433-461)

Add 4 new rows to the reference table:
```markdown
| `FormBuilderValidator` | `form.Validator` | Validation | Namespace required |
| `MultiselectOption` | `form.FieldOption` | Model | Namespace required |
| `AutoCompleteOption` | `form.CompleteOption` | Feature | Namespace required |
| `DefaultValidators` | `form.Validators` | Validation | Namespace required |
```

**Section 3: Step-by-Step Manual Migration** (lines 474-611)

**Subsection: Step 2 - Add Namespace Prefix** (around line 508)

Add to the find-and-replace table:
```markdown
| Find | Replace |
|------|---------|
| `\\bFormBuilderValidator\\b` | `form.Validator` |
| `\\bMultiselectOption\\b` | `form.FieldOption` |
| `\\bAutoCompleteOption\\b` | `form.CompleteOption` |
| `\\bDefaultValidators\\b` | `form.Validators` |
```

**Section 4: Before/After Examples**

**Update "Basic Form with Text Fields" example** (lines 88-143):
```dart
// BEFORE (v0.3.x)
validators: [
  FormBuilderValidator(
    validator: (r) => DefaultValidators().isEmpty(r),
    reason: 'Name is required'
  )
]

// AFTER (v0.4.0)
validators: [
  form.Validator(
    validator: (r) => form.Validators().isEmpty(r),
    reason: 'Name is required'
  )
]
```

**Update "Field Types" example** (lines 189-240):
```dart
// BEFORE (v0.3.x)
ChampionOptionSelect(
  options: [
    MultiselectOption(label: 'USA', value: 'us'),
  ],
)

// AFTER (v0.4.0)
form.OptionSelect(
  options: [
    form.FieldOption(label: 'USA', value: 'us'),
  ],
)
```

**Add new "Autocomplete" example** (create new section):
```markdown
### Autocomplete Fields

#### Before (v0.3.x)
```dart
ChampionTextField(
  autoComplete: AutoCompleteBuilder(
    initialOptions: [
      AutoCompleteOption(value: "test@example.com"),
    ],
  ),
)
```

#### After (v0.4.0)
```dart
form.TextField(
  autoComplete: form.AutoCompleteBuilder(
    initialOptions: [
      form.CompleteOption(value: "test@example.com"),
    ],
  ),
)
```
```

**Section 5: Common Issues & FAQ** (lines 706-857)

Add new FAQ entry:
```markdown
### Q: Why use `FieldOption` instead of just `Option`?

**A:** `Option` is too generic and commonly conflicts with other packages. `FieldOption` maintains context (form field options) while being concise and descriptive.

### Q: Why abbreviate `AutoCompleteOption` to `CompleteOption`?

**A:** We shortened it while maintaining clarity. "Complete" still conveys the autocomplete context, and the namespace `form.CompleteOption` makes the purpose clear.
```

---

### Task 5.3: Update README.md

**File**: `/README.md`

**Search and replace operations** (22 total occurrences):

1. **Validator references** (7 occurrences)
   - Find: `FormBuilderValidator`
   - Replace: `form.Validator`
   - Update code examples showing validator usage

2. **FieldOption references** (6 occurrences)
   - Find: `MultiselectOption`
   - Replace: `form.FieldOption`
   - Update dropdown and checkbox examples

3. **CompleteOption references** (1 occurrence)
   - Find: `AutoCompleteOption`
   - Replace: `form.CompleteOption`
   - Update autocomplete example

4. **Validators references** (8 occurrences)
   - Find: `DefaultValidators()`
   - Replace: `form.Validators()`
   - Update validation helper examples

**Key sections to update**:
- Quick Start example
- Field Types documentation
- Validation section
- Autocomplete documentation
- API Reference (if present)

### Validation
```bash
# Check for any remaining old references
grep -r "FormBuilderValidator\|MultiselectOption\|AutoCompleteOption\|DefaultValidators" *.md
```

**Expected Result**: No matches (only new names should remain)

---

## Phase 6: Final Verification & Testing

**Agent**: implementation-verifier
**Priority**: CRITICAL
**Estimated Time**: 1 hour
**Dependencies**: All previous phases must complete

### Task 6.1: Static Analysis

**Commands**:
```bash
# Analyze entire project
flutter analyze

# Check for specific old class names
grep -r "FormBuilderValidator" lib/ --include="*.dart"
grep -r "MultiselectOption" lib/ --include="*.dart"
grep -r "AutoCompleteOption" lib/ --include="*.dart"
grep -r "DefaultValidators" lib/ --include="*.dart"
```

**Expected Results**:
- `flutter analyze`: 0 errors (only pre-existing warnings acceptable)
- `grep` commands: No matches in code (only in comments/strings acceptable)

**Acceptance Criteria**:
- Zero compilation errors
- All imports resolve correctly
- No undefined class references
- No type mismatch errors

---

### Task 6.2: Test Suite Execution

**Commands**:
```bash
# Run main package tests
flutter test

# Run example app tests
flutter test example/

# Run specific test suites
flutter test example/test/autocomplete_overlay_*.dart
flutter test example/test/fileupload_*.dart
```

**Expected Results**:
- All tests pass ✅
- No test failures
- No runtime type errors
- No null reference exceptions

**Acceptance Criteria**:
- 100% test pass rate
- No new test failures introduced
- All assertions pass
- Test coverage maintained

---

### Task 6.3: Build & Manual Testing

**Build Commands**:
```bash
# Build for web
cd example
flutter build web

# Run on device/simulator
flutter run -d chrome
# OR
flutter run -d macos
```

**Manual Test Checklist**:

1. **Form Rendering**
   - [ ] All field types render correctly
   - [ ] Layout (Row/Column) works properly
   - [ ] No visual regressions

2. **Validator Class (form.Validator)**
   - [ ] Text field validation triggers
   - [ ] Error messages display correctly
   - [ ] Live validation works
   - [ ] Submit validation works

3. **FieldOption Class (form.FieldOption)**
   - [ ] Dropdowns show options correctly
   - [ ] Checkboxes render option lists
   - [ ] Chip selects display options
   - [ ] Option selection works
   - [ ] Multi-select behavior correct

4. **CompleteOption Class (form.CompleteOption)**
   - [ ] Autocomplete dropdown appears
   - [ ] Options filter on typing
   - [ ] Option selection works
   - [ ] Keyboard navigation works
   - [ ] Async option loading works

5. **Validators Class (form.Validators)**
   - [ ] `isEmail()` validation works
   - [ ] `isEmpty()` validation works
   - [ ] `fileIsImage()` validation works
   - [ ] All default validators function

6. **Form Submission**
   - [ ] Form submits successfully
   - [ ] FormResults returns correct values
   - [ ] Field values accessible via `.grab()`
   - [ ] Error state detected correctly

---

### Task 6.4: Migration Script Validation

**Test Procedure**:

1. **Create test project**:
```bash
# Copy example app to test location
cp -r example /tmp/test-migration-project
cd /tmp/test-migration-project
```

2. **Manually revert to old names**:
```bash
# Use sed to revert names for testing
find lib -name "*.dart" -exec sed -i '' 's/form\.Validator/form.FormBuilderValidator/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/form\.FieldOption/form.MultiselectOption/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/form\.CompleteOption/form.AutoCompleteOption/g' {} \;
find lib -name "*.dart" -exec sed -i '' 's/form\.Validators/form.DefaultValidators/g' {} \;
```

3. **Run migration script**:
```bash
cd /Users/fabier/Documents/code/championforms
dart run tools/project-migration.dart /tmp/test-migration-project --dry-run
```

4. **Verify dry-run output**:
   - [ ] Shows all 4 class replacements
   - [ ] Counts occurrences correctly
   - [ ] Lists modified files

5. **Run actual migration**:
```bash
dart run tools/project-migration.dart /tmp/test-migration-project
```

6. **Verify results**:
```bash
cd /tmp/test-migration-project
flutter analyze
flutter test
```

**Acceptance Criteria**:
- Migration script detects all old names
- Script replaces all occurrences correctly
- Backup files created successfully
- Migrated project passes all tests

---

### Task 6.5: Documentation Review

**Verification Checklist**:

1. **CHANGELOG.md**
   - [ ] All 4 classes listed in v0.4.0 section
   - [ ] Breaking changes clearly marked
   - [ ] Examples use new names

2. **MIGRATION-0.4.0.md**
   - [ ] Reference table includes all 4 classes
   - [ ] Before/After examples updated
   - [ ] Step-by-step guide includes new classes
   - [ ] FAQ addresses new names

3. **README.md**
   - [ ] All code examples compile
   - [ ] Quick start uses new names
   - [ ] API reference updated
   - [ ] No old class names remain (except in migration notes)

4. **Code Examples Compile**:
```bash
# Extract and test code examples from markdown
# (Manual verification or use markdown code extractor)
```

5. **Migration Script Help**:
```bash
dart run tools/project-migration.dart --help
```
   - [ ] Lists all 4 classes in help text
   - [ ] Examples show new names

**Final Grep Check**:
```bash
# Should return NO results in code files
grep -r "FormBuilderValidator" lib/ example/lib --include="*.dart"
grep -r "MultiselectOption" lib/ example/lib --include="*.dart"
grep -r "AutoCompleteOption" lib/ example/lib --include="*.dart"
grep -r "DefaultValidators" lib/ example/lib --include="*.dart"

# Should return results only in MIGRATION docs (acceptable)
grep -r "FormBuilderValidator" *.md
grep -r "MultiselectOption" *.md
```

---

## Success Criteria Summary

### Code Quality
✅ Zero analyzer errors (`flutter analyze`)
✅ All tests passing (100% pass rate)
✅ No runtime errors in example app
✅ All 4 classes renamed throughout codebase
✅ ~389 references updated across 65+ files

### Functionality
✅ All form field types work correctly
✅ Validation system functions properly
✅ Autocomplete operates as expected
✅ Form submission and results work
✅ File upload functionality intact

### Documentation
✅ CHANGELOG.md updated with all 4 classes
✅ MIGRATION-0.4.0.md includes comprehensive guide
✅ README.md examples use new names
✅ All code examples compile successfully

### Migration Support
✅ Migration script handles all 4 renames
✅ Script tested on example project
✅ Backup files created correctly
✅ Dry-run mode shows accurate preview

### Testing
✅ All unit tests pass
✅ All integration tests pass
✅ Example app builds and runs
✅ Manual testing completed successfully

---

## Task Delegation Summary

### Phase 1 (Sequential)
- **api-engineer**: Core model definitions (4 files)

### Phase 2 (Parallel - 3 agents)
- **api-engineer A**: Controller & FormResults (3 files)
- **api-engineer B**: Field types & models (9 files)
- **api-engineer C**: Widgets & builders (12 files)

### Phase 3-5 (Parallel - 3 agents)
- **ui-designer**: Example app & tests (16 files)
- **api-engineer**: Migration script (1 file)
- **database-engineer**: Documentation (4 files)

### Phase 6 (Sequential)
- **implementation-verifier**: Final validation & testing

---

## Execution Timeline

**With Parallel Execution**:
- Phase 1: 30 minutes (sequential)
- Phase 2: 2 hours (3 agents in parallel)
- Phase 3-5: 1.5 hours (3 agents in parallel)
- Phase 6: 1 hour (sequential)

**Total Estimated Time**: ~5-7 hours

---

## Risk Mitigation

1. **Incremental Validation**: Run `flutter analyze` after each phase
2. **Test Early**: Don't wait until Phase 6 to run tests
3. **Git Commits**: Commit after each phase for easy rollback
4. **Backup**: Migration script creates .backup files automatically
5. **Documentation First**: Update docs in parallel to avoid forgetting details

---

## Notes for Subagents

### Important Reminders

1. **Use Word Boundaries**: When searching/replacing, use `\b` word boundaries to avoid partial matches
2. **Preserve Formatting**: Maintain existing code formatting and style
3. **Update Comments**: Don't forget to update documentation comments
4. **Test Incrementally**: Verify your changes with `flutter analyze` before completing
5. **Report Issues**: If you encounter unexpected references, report them immediately

### Common Pitfalls to Avoid

- ❌ Don't replace class names inside string literals
- ❌ Don't replace in URLs or file paths
- ❌ Don't modify commented-out code (but do update documentation comments)
- ❌ Don't forget generic type parameters `List<FieldOption>`
- ❌ Don't miss callback function signatures

### Reference This Plan

All subagents should:
1. Read this plan completely before starting
2. Understand your specific phase/task
3. Know which other phases depend on your completion
4. Report progress and any blockers
5. Validate your work before marking complete

---

## Quick Reference: Old → New Names

```dart
// Copy-paste reference for all subagents

// Validators
FormBuilderValidator  →  form.Validator
DefaultValidators     →  form.Validators

// Options
MultiselectOption     →  form.FieldOption
AutoCompleteOption    →  form.CompleteOption

// Example usage
validators: [
  form.Validator(
    validator: (r) => form.Validators().isEmail(r),
    reason: 'Invalid email'
  )
]

options: [
  form.FieldOption(label: 'Option 1', value: 'val1'),
]

autoComplete: form.AutoCompleteBuilder(
  initialOptions: [
    form.CompleteOption(value: "example"),
  ],
)
```

---

## Version History

- **2025-11-03**: Initial plan created
- **Status**: Ready for implementation approval

---

**END OF PLAN**
