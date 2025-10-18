# Task Breakdown: File Upload Clear on Upload

## Overview
Total Tasks: 3 task groups
Assigned roles: ui-designer, testing-engineer
Complexity: Low (small feature, single boolean flag with focused behavior change)

## Task List

### Model Layer

#### Task Group 1: ChampionFileUpload Model Enhancement
**Assigned implementer:** ui-designer
**Dependencies:** None
**Complexity:** Low

- [x] 1.0 Add clearOnUpload flag to ChampionFileUpload model
  - [x] 1.1 Write 2-4 focused tests for clearOnUpload property
    - Limit to 2-4 highly focused tests maximum
    - Test only critical model behaviors (e.g., default value is false, property accepts true/false)
    - Location: Create or update test file for ChampionFileUpload model
    - Skip exhaustive coverage of all model properties
  - [x] 1.2 Add clearOnUpload property to ChampionFileUpload class
    - File: `/Users/fabier/Documents/code/championforms/lib/models/field_types/championfileupload.dart`
    - Add property: `final bool clearOnUpload;`
    - Default value: `false` (maintains backward compatibility)
    - Follow pattern from existing boolean flags like `displayUploadedFiles`, `validateLive`, `disabled`
  - [x] 1.3 Update ChampionFileUpload constructor
    - Add parameter: `this.clearOnUpload = false,`
    - Place parameter logically with other boolean configuration flags
    - Use named parameter pattern consistent with existing constructor
  - [x] 1.4 Ensure model layer tests pass
    - Run ONLY the 2-4 tests written in 1.1
    - Verify property is accessible and defaults to false
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-4 tests written in 1.1 pass
- clearOnUpload property added with default value false
- Constructor accepts clearOnUpload parameter
- No breaking changes to existing ChampionFileUpload API
- Code follows Dart/Flutter style conventions from standards

### Widget Implementation Layer

#### Task Group 2: FileUploadWidget Clear Logic
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 1 (COMPLETED)
**Complexity:** Medium

- [x] 2.0 Implement file clearing logic in FileUploadWidget
  - [x] 2.1 Write 4-8 focused tests for clearing behavior
    - Limit to 4-8 highly focused tests maximum
    - Test critical clearing scenarios:
      - clearOnUpload = false maintains running tally (existing behavior)
      - clearOnUpload = true clears files on file picker selection
      - clearOnUpload = true clears files on drag-and-drop
      - Multi-file upload with clearOnUpload = true processes all new files
    - Location: Create or update widget test file for FileUploadWidget
    - Skip edge cases like empty selections, rapid uploads unless business-critical
  - [x] 2.2 Implement clearing logic in _pickFiles method
    - File: `/Users/fabier/Documents/code/championforms/lib/widgets_internal/field_widgets/file_upload_widget.dart`
    - Check `(widget.field as ChampionFileUpload).clearOnUpload` flag
    - If true AND result != null: Clear _files list before processing new files
    - Call `widget.controller.updateMultiselectValues(widget.field.id, [], overwrite: true)` to clear controller state
    - Then proceed with existing file addition logic (lines 133-135)
    - Maintain two-step process: clear existing, then add new
  - [x] 2.3 Implement clearing logic in _handleDroppedFile method
    - File: Same as 2.2
    - Check `(widget.field as ChampionFileUpload).clearOnUpload` flag
    - Identify first file in drop operation (to clear once, not per-file)
    - If clearOnUpload = true AND this is first dropped file: Clear _files and controller state
    - Proceed with existing drag-and-drop file processing logic
    - Ensure clearing happens before all dropped files are processed
  - [x] 2.4 Verify state synchronization during clearing
    - Ensure _files local state and controller state stay synchronized
    - Verify _onControllerUpdate handles cleared state correctly
    - Test that validation triggers after clearing and adding new files
    - Follow existing state management patterns in widget
  - [x] 2.5 Handle edge cases
    - Empty file selection (user cancels picker): No clearing should occur
    - Single-file mode (multiselect = false): Verify clearing works (may be implicit)
    - Multi-file drag-and-drop: Clear once before processing all files, not per-file
    - Validation errors: Should clear with files automatically via controller update
  - [x] 2.6 Ensure widget layer tests pass
    - Run ONLY the 4-8 tests written in 2.1
    - Verify clearing behavior works in file picker and drag-and-drop scenarios
    - Verify running tally still works when clearOnUpload = false
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 4-8 tests written in 2.1 pass
- clearOnUpload = false maintains existing running tally behavior (backward compatible)
- clearOnUpload = true clears files before adding new selections (file picker)
- clearOnUpload = true clears files before adding dropped files (drag-and-drop)
- Multi-file operations clear once, then add all new files
- Controller state synchronized with widget state throughout clearing
- Validation runs after clearing and file addition
- Code follows Flutter widget composition and state management standards

### Testing

#### Task Group 3: Test Review & Gap Analysis
**Assigned implementer:** testing-engineer
**Dependencies:** Task Groups 1-2
**Complexity:** Low

- [x] 3.0 Review existing tests and fill critical gaps only
  - [x] 3.1 Review tests from Task Groups 1-2
    - Review the 2-4 tests written by ui-designer for model (Task 1.1)
    - Review the 4-8 tests written by ui-designer for widget (Task 2.1)
    - Total existing tests: approximately 6-12 tests
  - [x] 3.2 Analyze test coverage gaps for clearOnUpload feature only
    - Identify critical workflows that lack test coverage
    - Focus ONLY on gaps related to clearOnUpload feature requirements
    - Do NOT assess entire ChampionForms package test coverage
    - Prioritize integration scenarios over additional unit tests
    - Key areas to check:
      - Integration between model property and widget behavior
      - State synchronization during clearing operations
      - Validation behavior after clearing
      - Platform-specific file selection scenarios (if testable)
  - [x] 3.3 Write up to 6 additional strategic tests maximum
    - Add maximum of 6 new tests to fill identified critical gaps
    - Focus on end-to-end clearing workflows and edge cases
    - Suggested test scenarios to consider:
      - Clearing with validateLive = true triggers validation on new files
      - Clearing with custom validators works correctly
      - Sequential uploads with clearOnUpload = true replace files each time
      - Mixed scenario: Switch clearOnUpload from false to true at runtime (if supported)
    - Do NOT write comprehensive coverage for all scenarios
    - Skip non-critical edge cases, performance tests unless business-critical
  - [x] 3.4 Run feature-specific tests only
    - Run ONLY tests related to clearOnUpload feature (tests from 1.1, 2.1, and 3.3)
    - Expected total: approximately 12-18 tests maximum
    - Do NOT run the entire ChampionForms package test suite
    - Verify all critical workflows pass
    - Document any platform-specific manual testing requirements

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 12-18 tests total)
- Critical clearOnUpload workflows are covered by tests
- No more than 6 additional tests added by testing-engineer
- Testing focused exclusively on clearOnUpload feature requirements
- Integration between model and widget is validated
- State synchronization and validation behavior verified

## Execution Order

Recommended implementation sequence:
1. Model Layer (Task Group 1) - Add clearOnUpload property to ChampionFileUpload
2. Widget Implementation (Task Group 2) - Implement clearing logic in FileUploadWidget
3. Test Review (Task Group 3) - Review coverage and add strategic integration tests

## Notes

### Backward Compatibility
- Default value of `false` ensures no behavior change for existing implementations
- Existing ChampionForms users can upgrade without modifying their code
- Feature is opt-in, activated only when clearOnUpload explicitly set to true

### Implementation Pattern
- Follow existing boolean flag patterns in ChampionFileUpload (e.g., `displayUploadedFiles`, `validateLive`)
- Use existing controller method `updateMultiselectValues` with `overwrite: true` for clearing
- Maintain separation between clearing logic and file addition logic
- Two-step process: clear existing files, then add new files

### Platform Considerations
- Implementation is platform-agnostic using existing abstractions
- file_picker handles native file dialogs across platforms
- super_drag_and_drop handles drag-and-drop across platforms
- No platform-specific code required for clearing behavior

### Testing Strategy
- Widget tests cover critical user workflows
- Focus on file picker and drag-and-drop scenarios
- Test both clearOnUpload = true and false behaviors
- Verify state synchronization and validation integration
- Manual testing may be needed for platform-specific file selection UI

### Files to Modify
1. `/Users/fabier/Documents/code/championforms/lib/models/field_types/championfileupload.dart` - Add clearOnUpload property
2. `/Users/fabier/Documents/code/championforms/lib/widgets_internal/field_widgets/file_upload_widget.dart` - Implement clearing logic
3. Test files (create/update as needed) - Add focused tests for feature validation

### Standards Compliance
This tasks list aligns with:
- Flutter/Dart coding style standards (concise, declarative, null-safe)
- Flutter widget composition standards (stateful widget patterns, state synchronization)
- Testing standards (focused tests, AAA pattern, test behavior not implementation)
- Tech stack standards (Flutter framework, ChampionForms patterns, file_picker, super_drag_and_drop)
