# Spec Requirements: File Upload Clear on Upload

## Initial Description

File uploads keep a running tally of uploaded files in memory which are displayed below the file upload field. The user has found that often they don't wish to retain uploads between uploads.

**Core Requirements:**
- If multi-file uploads are enabled: clear all previously uploaded files, then handle all files which have been dragged in or selected
- If multi-file uploads are disabled: clear all previous files, then handle only the new file
- Create a new flag called "clearOnUpload" which can be set to true to enable this behavior
- If left unset or set to false, retain the current functionality (keep running tally)

## Requirements Discussion

### Implementation Approach Confirmed

**Decision: Option A - Two-Step Process (Confirmed by User)**

The user has confirmed implementation using a two-step process:

**Step 1: Clear existing files**
- When new files are selected/dropped AND clearOnUpload is true
- Clear all existing files from the field's state
- Reset the file list in memory

**Step 2: Add new files**
- Process the newly selected/dropped files normally
- Apply existing validation logic
- Update the UI with only the new files

This approach maintains clean separation of concerns and leverages existing file handling logic.

### Existing Code to Reference

**ChampionFileUpload Component:**
- Location: Core field component for file upload functionality
- Current behavior: Maintains running tally of uploaded files across multiple selections
- Integration points: ChampionFormController for state management, file_picker and super_drag_and_drop for file selection

**Related Validation:**
- DefaultValidators library handles file type and size validation
- MIME type filtering via mime package
- File validation occurs after files are selected/dropped

### Functional Requirements

#### Core Functionality
1. **New clearOnUpload Flag**
   - Type: Boolean flag on ChampionFileUpload field
   - Default value: false (preserves current behavior)
   - When true: Clears existing files before processing new selections
   - When false/unset: Maintains running tally behavior (current functionality)

2. **File Clearing Behavior**
   - Trigger: User selects new files (via picker) OR drops new files (via drag & drop)
   - Condition: Only executes if clearOnUpload is true
   - Action: Remove all previously stored files from field state before processing new files

3. **Multi-File Upload Interaction**
   - If multipleFiles is enabled: Clear all previous, then add all newly selected files
   - If multipleFiles is disabled: Clear all previous, then add only the single new file
   - Validation applies to the new file set after clearing

4. **State Management**
   - File list managed through ChampionFormController
   - Clearing operation updates controller state
   - UI automatically reflects cleared state before showing new files

#### User Experience Flow

**Current Behavior (clearOnUpload = false or unset):**
1. User uploads File A → Shows [File A]
2. User uploads File B → Shows [File A, File B]
3. User uploads File C → Shows [File A, File B, File C]
4. Running tally maintained across uploads

**New Behavior (clearOnUpload = true):**
1. User uploads File A → Shows [File A]
2. User uploads File B → Shows [File B] (File A cleared)
3. User uploads File C → Shows [File C] (File B cleared)
4. Each upload replaces previous files

#### Technical Considerations

**Integration Points:**
- ChampionFormController: Manages file state and clearing operations
- file_picker: Native file dialog selections trigger clearing logic
- super_drag_and_drop: Drag & drop operations trigger clearing logic
- FormResults API: Results reflect current file state after clearing

**Validation Implications:**
- File validation (type, size) applies to new files after clearing
- Validation errors from previous files are cleared with the files
- FormBuilderValidator patterns continue to work as expected

**Cross-Platform Compatibility:**
- Clearing logic platform-agnostic (works on iOS, Android, Web, macOS, Desktop)
- No platform-specific file handling changes required
- Existing file_picker and super_drag_and_drop abstractions sufficient

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A - Feature is behavioral enhancement to existing ChampionFileUpload component with no UI changes beyond file list updates.

## Requirements Summary

### Functional Requirements
- Add clearOnUpload boolean flag to ChampionFileUpload field definition
- Default clearOnUpload to false to maintain backward compatibility
- When clearOnUpload is true: clear existing files before processing new selections
- Clearing occurs on both file picker selections and drag & drop operations
- Works with both single-file and multi-file upload modes
- State updates propagate through ChampionFormController
- Validation applies to new file set after clearing

### Reusability Opportunities
- ChampionFileUpload existing component (enhancement only, no new components)
- ChampionFormController state management patterns
- DefaultValidators for file validation (no changes needed)
- Existing file_picker and super_drag_and_drop integration

### Scope Boundaries

**In Scope:**
- Adding clearOnUpload flag to ChampionFileUpload
- Implementing clear-then-add logic for file selections
- Supporting both file picker and drag & drop workflows
- Maintaining backward compatibility (default false)
- Working with single and multi-file upload modes
- Controller state management for clearing operation

**Out of Scope:**
- UI changes to file upload component appearance
- Changes to file validation logic
- Modifications to drag & drop behavior beyond clearing
- Additional file management features (reordering, individual removal, etc.)
- Undo/redo functionality for file clearing
- Confirmation dialogs before clearing files
- Different clearing strategies (e.g., clear on form submit, clear on timeout)

### Technical Considerations
- Implementation follows Option A: two-step process (clear existing, then add new)
- Platform-agnostic solution using existing abstractions
- No new dependencies required
- No breaking changes to existing API
- Maintains Flutter package architecture and distribution model
- Aligns with ChampionForms' centralized controller pattern
- Compatible with existing FormResults retrieval API
- No impact on FormTheme system or field styling

### Backward Compatibility
- Default value of false ensures no behavior change for existing implementations
- Existing forms continue to work without modification
- Opt-in feature activated only when clearOnUpload explicitly set to true
- No migration required for current users of ChampionFileUpload
