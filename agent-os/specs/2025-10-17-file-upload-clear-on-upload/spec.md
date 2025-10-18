# Specification: File Upload Clear on Upload

## Goal
Add a clearOnUpload boolean flag to ChampionFileUpload that allows users to automatically clear previously uploaded files before processing new file selections, replacing the default running tally behavior with a replace-on-upload workflow.

## User Stories
- As a form builder using ChampionForms, I want to configure file upload fields to clear previous files on new uploads so that users can easily replace files instead of accumulating them
- As an end user uploading files, I want my new file selection to replace the previous files so that I don't have to manually remove old files before adding new ones
- As a developer, I want backward compatibility so that existing forms continue to work without modification when upgrading to this new version

## Core Requirements

### Functional Requirements
- Add clearOnUpload boolean flag to ChampionFileUpload field definition
- Default clearOnUpload to false to maintain backward compatibility with existing forms
- When clearOnUpload is true, clear all existing files from field state before processing newly selected files
- Clearing behavior triggers on both file picker selections and drag-and-drop operations
- Works correctly with single-file mode (multiselect = false) and multi-file mode (multiselect = true)
- State updates propagate through ChampionFormController to maintain centralized state management
- File validation applies to the new file set after clearing operation completes
- Validation errors from previous files are cleared along with the files

### Non-Functional Requirements
- Platform-agnostic implementation that works on iOS, Android, Web, macOS, and Desktop
- No breaking changes to existing ChampionFileUpload API
- No new package dependencies required
- Maintains clean separation of concerns between clearing logic and file processing logic
- Performance: Clearing operation must complete before new files are processed to avoid race conditions

## Visual Design
No visual changes to the ChampionFileUpload component. The feature is a behavioral enhancement that affects how files are managed internally. The UI continues to display uploaded files in the same way, but the file list contents change based on the clearOnUpload flag.

## Reusable Components

### Existing Code to Leverage
- **ChampionFileUpload Model** (`lib/models/field_types/championfileupload.dart`): Add new clearOnUpload property to existing field definition
- **FileUploadWidget** (`lib/widgets_internal/field_widgets/file_upload_widget.dart`): Extend _pickFiles and _handleDroppedFile methods to implement clearing logic
- **ChampionFormController** (`lib/controllers/form_controller.dart`): Use existing updateMultiselectValues method with overwrite: true to clear files
- **State Management Pattern**: Follow existing pattern where _files local state syncs with controller via updateMultiselectValues
- **Validation Pattern**: Leverage existing _validateLive method that runs after file operations

### New Components Required
None. This feature is implemented entirely as an enhancement to existing components without requiring new widgets, models, or utilities.

## Technical Approach

### Database
Not applicable. ChampionForms is a Flutter package for client-side form building. File upload state is managed in-memory through ChampionFormController.

### API

**ChampionFileUpload Field Definition Changes:**
```
Add property:
- clearOnUpload: bool (default: false)
```

**Constructor Signature Update:**
```
ChampionFileUpload({
  // ... existing parameters ...
  this.clearOnUpload = false,  // New parameter
})
```

**No changes to:**
- ChampionFormController API (uses existing updateMultiselectValues method)
- FormResults API (results reflect current file state regardless of clearing)
- Validation API (existing validators continue to work)

### Frontend

**Implementation in FileUploadWidget (_FileUploadWidgetState):**

**File Picker Flow (_pickFiles method):**
1. User clicks upload button to open file picker
2. User selects one or more files
3. If clearOnUpload is true: Clear _files list and update controller before processing
4. If clearOnUpload is false: Maintain existing behavior (running tally)
5. Process selected files using existing _addFile logic
6. Update controller state and trigger validation

**Drag-and-Drop Flow (_handleDroppedFile method):**
1. User drags and drops one or more files
2. Extension validation occurs (if allowedExtensions configured)
3. If clearOnUpload is true AND this is the first file in the drop operation: Clear _files list and update controller
4. If clearOnUpload is false: Maintain existing behavior (running tally)
5. Process dropped files using existing logic
6. Update controller state and trigger validation

**Clearing Implementation Details:**
- Check (widget.field as ChampionFileUpload).clearOnUpload flag
- When true, clear _files list and call controller.updateMultiselectValues with empty list before adding new files
- Leverage existing controller state propagation to update UI
- Maintain consistency between _files local state and controller state

**Edge Cases Handled:**
- Single-file mode: Clearing happens naturally as existing logic already clears for single files
- Multi-file mode: Explicit clearing before processing new files
- Multi-file drag-and-drop: Clear once before processing all dropped files (not per-file)
- Validation errors: Cleared automatically via controller state update
- Empty file selection: No clearing occurs if user cancels file picker dialog

### Testing

**Widget Tests (integration_test):**
- Test clearOnUpload = false maintains existing running tally behavior
- Test clearOnUpload = true clears files on file picker selection
- Test clearOnUpload = true clears files on drag-and-drop operation
- Test multi-file upload with clearOnUpload = true processes all new files after clearing
- Test single-file upload with clearOnUpload = true works correctly
- Test that validation runs after clearing and adding new files
- Test that controller state stays synchronized with widget state during clearing

**Manual Testing Requirements:**
- Verify file picker on mobile (iOS, Android)
- Verify file picker on web browsers
- Verify drag-and-drop on desktop (macOS, Windows, Linux)
- Test with allowedExtensions to ensure validation still works after clearing
- Test with custom validators to ensure errors clear properly
- Test displayUploadedFiles = true shows correct files after clearing
- Test rapid sequential uploads to verify no race conditions

## Out of Scope
- UI changes to file upload component appearance or layout
- Confirmation dialogs before clearing files (users can implement via onChange if desired)
- Undo/redo functionality for cleared files
- Individual file removal behavior (existing close button functionality unchanged)
- File reordering capabilities
- Different clearing strategies (e.g., clear on form submit, clear on timeout, selective clearing)
- Changes to file validation logic or validator implementations
- Modifications to drag-and-drop visual feedback beyond clearing behavior
- Server-side file upload handling (ChampionForms is client-side only)

## Success Criteria
- ChampionFileUpload accepts clearOnUpload parameter with default value false
- When clearOnUpload = false, behavior matches current running tally functionality (backward compatible)
- When clearOnUpload = true, new file selections via picker clear previous files before adding new files
- When clearOnUpload = true, drag-and-drop operations clear previous files before adding dropped files
- Multi-file uploads with clearOnUpload = true clear previous files, then add all newly selected files
- Single-file uploads with clearOnUpload = true work correctly (clearing is implicit in single-file mode)
- File validation executes on new files after clearing operation
- Controller state remains synchronized with widget state throughout clearing process
- Feature works identically across all supported platforms (iOS, Android, Web, macOS, Desktop)
- All widget tests pass, confirming correct behavior in both single and multi-file modes
- No breaking changes to existing ChampionFileUpload implementations
