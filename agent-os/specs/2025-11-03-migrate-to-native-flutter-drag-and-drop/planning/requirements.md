# Spec Requirements: Migrate to Native Flutter Drag and Drop

## Initial Description
The championforms library currently uses super_drag_and_drop and super_clipboard plugins for file upload functionality. These plugins have fallen into disrepair and no longer compile with recent Flutter builds. We need to migrate to native Flutter drag and drop functionality while maintaining feature parity on both desktop and web platforms.

The migration must:
- Remove dependencies on super_drag_and_drop and super_clipboard
- Replace with native Flutter DragTarget and Draggable widgets
- Maintain all existing functionality (drag & drop, file picker, multiselect, clearOnUpload, file validation)
- Ensure compatibility with both web and desktop platforms
- Keep file_picker package which is still maintained

Files to refactor:
- lib/models/file_model.dart (remove DataReader dependency)
- lib/default_fields/fileupload.dart
- lib/models/field_types/fileupload.dart
- lib/widgets_internal/field_widgets/file_upload_widget.dart
- Any other files that depend on these packages

## Requirements Discussion

### First Round Questions

**Q1: Platform Priority** - Both web and desktop are important, but should we prioritize one platform for initial implementation and testing?
**Answer:** Both web and desktop are important, but web is most needed right now.

**Q2: Flutter Version Target** - What minimum Flutter version should we target? The latest stable is 3.35.0 - should we target that or maintain backward compatibility?
**Answer:** Target Flutter SDK 3.35.0 stable or near it.

**Q3: Developer-Facing APIs** - Should we maintain the exact same API for developers using ChampionForms, or is it acceptable to have minor breaking changes if we provide migration guidance?
**Answer:** Rebuild internals as needed, but maintain developer-facing APIs. FormResults should still support `results.grab("filefieldid").asFile()` or `asFileList()` returning similar objects.

**Q4: Visual Feedback/UX** - Current implementation shows hover state with opacity change. Should we maintain the same visual feedback, or can we modernize the UX?
**Answer:** Keep same visual feedback if possible.

**Q5: Feature Preservation** - Current features include multiselect, clearOnUpload flag, allowedExtensions filtering, and file preview with icons. All these should be preserved, correct?
**Answer:** Maintain all features (multiselect, clearOnUpload, allowedExtensions) with equal functionality if possible.

**Q6: MIME Type Detection** - Current implementation uses the mime package for type detection. Should we keep this approach?
**Answer:** Yes, keep the current mime package approach.

**Q7: Drag Event Mapping** - Should we map native Flutter drag events 1:1 to the current super_drag_and_drop behavior (onDropOver, onDropEnter, onDropLeave, onPerformDrop)?
**Answer:** Generally yes, map 1:1, but use discretion for ergonomic choices to avoid code problems.

**Q8: Migration Path** - Single PR acceptable, or should this be broken into phases?
**Answer:** Single PR is fine.

**Q9: file_picker Package** - Current implementation uses file_picker for the dialog-based selection. This should remain unchanged?
**Answer:** Keep it as-is, working fine on all platforms.

**Q10: Browser Limitations** - Are there known browser-specific drag-and-drop limitations we should document or handle differently?
**Answer:** Learn from flutter_dropzone plugin at `/Users/fabier/Documents/libraries/flutter_dropzone/`

**Q11: Testing Strategy** - Should we add specific tests for drag-and-drop functionality, or focus on integration tests?
**Answer:** Remove all file tests and add new ones.

**Q12: Scope Clarification** - Should we only focus on file drag-and-drop into the app, or also consider clipboard paste functionality?
**Answer:** Focus only on file drag and drop into the app. No clipboard paste functionality needed.

### Existing Code to Reference

**Similar Features Identified:**
- Reference implementation: flutter_dropzone plugin at `/Users/fabier/Documents/libraries/flutter_dropzone/`

**flutter_dropzone Analysis - Key Patterns:**

**Architecture Pattern:**
- Uses platform interface pattern with separate web/native implementations
- Platform interface defines abstract methods that each platform implements
- Uses a broadcast StreamController for events
- Event-based architecture for drag states (onDropFile, onDropFiles, onDropInvalid)

**Web Implementation Strategy:**
- Creates an HTMLDivElement container using HtmlElementView
- Includes a JavaScript file (flutter_dropzone.js) that handles native browser events
- Uses `@JS()` annotations and dart:js_interop for Dart ↔ JavaScript communication
- JavaScript handles: dragover, dragleave, drop events
- MIME type filtering performed in JavaScript
- Returns web.File objects wrapped in DropzoneFileInterface

**File Abstraction Pattern:**
- Cross-platform file interface (DropzoneFileInterface) with:
  - Properties: name, size, type (MIME), lastModified
  - Methods: getNative() returns platform-specific file object
- Platform-specific implementations:
  - Web: Wraps web.File
  - Native: Would use platform channels (not implemented in flutter_dropzone)

**Web Drag-and-Drop Flow:**
1. Container listens for dragover → prevents default, sets dropEffect
2. On drop → reads event.dataTransfer.items
3. Filters by MIME type if specified
4. Calls getAsFile() for file items
5. Fires events (onDropFile, onDropFiles, onDropInvalid)
6. Can read file as bytes (arrayBuffer) or chunked stream (blob.slice)

**Key Patterns to Adopt:**
1. Platform-specific implementations with shared interface
2. For web: HtmlElementView + JavaScript + dart:js_interop
3. Abstract file interface that wraps platform-specific types
4. Event-based architecture for drag states
5. MIME filtering at JavaScript level (web) or Dart level (native)

### Follow-up Questions

None - all requirements clarified.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A

## Requirements Summary

### Functional Requirements

**Core Drag-and-Drop Functionality:**
- Accept file drops from native file explorers (Finder, File Explorer, etc.) on both web and desktop
- Support single-file and multi-file drops based on field configuration
- Provide visual feedback during drag operations (hover states with opacity changes)
- Validate file types during drop operations against allowedExtensions
- Reject invalid file types without adding them to the field

**File Picker Integration:**
- Maintain existing file_picker integration for dialog-based selection
- Support both single and multiple file selection via dialog
- Apply allowedExtensions filtering to file picker dialog
- No changes to existing file_picker behavior

**File Management:**
- Store file data as FileModel objects with:
  - fileName
  - fileBytes (full file in memory)
  - mimeData (MIME type and extension)
  - uploadExtension (original file extension)
- Remove fileReader and fileStream properties (super_clipboard dependencies)
- Display uploaded files as icons with labels
- Allow file removal via close button on file previews
- Support clearOnUpload flag to replace vs append files

**API Compatibility:**
- Maintain FormResults.grab("fieldId").asFile() API
- Maintain FormResults.grab("fieldId").asFileList() API
- Return FileModel objects with same structure (minus removed properties)
- No breaking changes to developer-facing APIs

**Validation:**
- Support live validation (validateLive flag)
- Validate against allowedExtensions list
- Use mime package for MIME type detection
- Support custom validators via FormBuilderValidator pattern

**Visual Feedback:**
- Hover state during drag operations (opacity change)
- File icon previews based on MIME type (code, text, document, image, video, audio, executable, archive, generic)
- File name labels (truncated with ellipsis)
- Remove button on each file preview
- Drop zone widget with upload icon and text

**Field Configuration:**
- multiselect: Boolean to allow multiple files
- clearOnUpload: Boolean to clear existing files on new upload
- allowedExtensions: List of allowed file extensions (optional)
- displayUploadedFiles: Boolean to show/hide file previews
- dropDisplayWidget: Custom drop zone widget builder (optional)
- fileUploadBuilder: Custom file list builder (optional)

### Platform Implementation Strategy

**Web Platform:**
- Use HtmlElementView to create a container div
- Create JavaScript file for native browser event handling
- Use dart:js_interop for Dart ↔ JavaScript communication
- Handle dragover, dragleave, drop events in JavaScript
- Extract files from event.dataTransfer.items/files
- Wrap web.File objects in cross-platform abstraction
- Read file bytes using FileReader API (arrayBuffer)
- Filter by MIME type in JavaScript before passing to Dart

**Desktop Platform:**
- Use native Flutter DragTarget widget
- Accept Draggable data with file paths
- Use dart:io File to read file bytes
- Perform MIME type validation in Dart
- May require platform channels for full drag-and-drop support

**Shared Abstraction:**
- FileModel as cross-platform file representation
- Unified event callbacks (onFileOptionChange)
- Consistent validation logic in Dart
- Shared MIME type detection using mime package

### Technical Architecture

**File Model (lib/models/file_model.dart):**
- Remove: fileReader (DataReader from super_clipboard)
- Remove: fileStream (Stream<Uint8List>)
- Keep: fileName, fileBytes, mimeData, uploadExtension
- Keep: getFileBytes() method (simplified to just return fileBytes)
- Keep: readMimeData() method using mime package

**File Upload Widget (lib/widgets_internal/field_widgets/file_upload_widget.dart):**
- Replace: DropRegion (super_drag_and_drop) with native Flutter DragTarget or platform-specific implementation
- Remove: super_clipboard imports
- Remove: DataReader usage
- Keep: file_picker integration unchanged
- Keep: _pickFiles() method
- Refactor: _handleDroppedFile() to work with native drag events
- Keep: Visual feedback, file preview, and icon logic
- Keep: Focus management and validation

**Field Type (lib/models/field_types/fileupload.dart):**
- No changes required (already defines configuration)
- Maintains all properties: multiselect, clearOnUpload, allowedExtensions, etc.

**Builder (lib/default_fields/fileupload.dart):**
- No significant changes required
- Continues to delegate to FileUploadWidget

**Dependencies (pubspec.yaml):**
- Remove: super_clipboard (^0.9.1)
- Remove: super_drag_and_drop (^0.9.1)
- Keep: file_picker (^10.3.2)
- Keep: cross_file (^0.3.4+2)
- Keep: mime (^2.0.0)
- Potentially Add: dart:js_interop (built-in, no pubspec entry needed)
- Potentially Add: dart:html for web (built-in, conditional import)

**Platform-Specific Implementation:**
- Create: Platform interface for drag-and-drop abstraction
- Create: Web implementation using HtmlElementView + JavaScript
- Create: Desktop implementation using native Flutter or platform channels
- Use: Conditional imports (dart:html for web, dart:io for desktop)

### Reusability Opportunities

**From flutter_dropzone:**
- Platform interface pattern for cross-platform abstraction
- HtmlElementView approach for web drag-and-drop
- JavaScript event handling pattern
- File abstraction with getNative() method for platform-specific access
- StreamController-based event architecture

**From existing ChampionForms:**
- FieldColorScheme and theming system (already in place)
- FormController integration (already in place)
- Validation system (already in place)
- File icon mapping logic (already in place)
- Focus management pattern (already in place)

### Scope Boundaries

**In Scope:**
- Remove super_drag_and_drop and super_clipboard dependencies
- Implement native Flutter drag-and-drop for web platform (priority)
- Implement native Flutter drag-and-drop for desktop platform
- Maintain all existing file upload features
- Maintain API compatibility for developers
- Update file_model.dart to remove super_clipboard dependencies
- Refactor file_upload_widget.dart to use native drag-and-drop
- Create platform-specific implementations following flutter_dropzone patterns
- Remove existing file upload tests
- Add comprehensive new tests for drag-and-drop functionality
- Support allowedExtensions validation
- Support multiselect and clearOnUpload flags
- Maintain visual feedback and file previews

**Out of Scope:**
- Clipboard paste functionality (explicitly removed from scope)
- Changes to file_picker integration (working fine)
- Changes to developer-facing APIs (must maintain compatibility)
- Adding new features beyond current functionality
- Image cropping or file editing
- Upload progress indicators
- Cloud storage integration
- Streaming file uploads (removed in favor of full in-memory loading)
- Changes to theming or visual design (maintain current)
- Supporting older Flutter versions (targeting 3.35.0)

**Future Enhancements (Not in This Migration):**
- Clipboard paste support
- File streaming for large files
- Upload progress indicators
- Image preview thumbnails
- Drag-and-drop reordering of files

### Testing Strategy

**Remove:**
- All existing file upload tests that depend on super_drag_and_drop

**Add - Unit Tests:**
- FileModel creation and manipulation
- getFileBytes() method
- readMimeData() with various file types
- MIME type detection accuracy
- File extension validation

**Add - Widget Tests:**
- FileUploadWidget rendering
- File picker dialog integration
- File addition and removal
- Multiselect behavior
- clearOnUpload flag behavior
- allowedExtensions filtering
- Visual feedback (hover states)
- Focus management
- Validation triggers

**Add - Platform-Specific Tests:**
- Web drag-and-drop event handling (if testable)
- Desktop drag-and-drop (if testable)
- Cross-platform file abstraction

**Add - Integration Tests:**
- End-to-end file upload workflow
- Form submission with file fields
- Multiple file fields in one form
- File validation in form context

**Test Coverage Focus:**
- File type validation
- Multi-file scenarios
- Single vs multiselect behavior
- clearOnUpload flag combinations
- Edge cases (empty files, invalid types, large files)

### Technical Considerations

**Flutter Version:**
- Target: Flutter SDK 3.35.0 stable or near it
- No backward compatibility requirements with older versions

**Platform Channels:**
- May be needed for full desktop drag-and-drop support
- Web implementation should be pure Dart + JavaScript (no platform channels)

**Memory Management:**
- Files loaded fully into memory (no streaming in initial implementation)
- May cause performance issues with very large files
- Document recommended file size limits

**Browser Compatibility:**
- Follow flutter_dropzone patterns for web compatibility
- Use event.dataTransfer API properly
- Handle browser security restrictions
- Test across major browsers (Chrome, Firefox, Safari)

**MIME Type Detection:**
- Use mime package for cross-platform detection
- Fallback to "application/octet-stream" for unknown types
- Support header-based detection (magic numbers)

**Error Handling:**
- Gracefully handle failed file reads
- Validate file types before processing
- Provide clear error messages for invalid files
- Don't crash on unsupported file types

**Focus Management:**
- Maintain FocusNode behavior
- Trigger onFocusChange callbacks
- Support requestFocus from field configuration

**State Management:**
- Use existing ChampionFormController
- Update multiselect values via controller
- Trigger validation via FormResults
- Call onChange callbacks when files change
- Maintain reactive updates via controller listeners

**JavaScript Integration (Web):**
- Create flutter_dropzone-style JavaScript file
- Use @JS() annotations for interop
- Handle dragover, dragleave, drop events
- Extract files from dataTransfer
- Return file data to Dart side
- Include JavaScript file in web assets

### Migration Steps

**Phase 1: Dependency Removal**
1. Remove super_clipboard and super_drag_and_drop from pubspec.yaml
2. Remove imports from affected files
3. Identify all compilation errors

**Phase 2: FileModel Refactoring**
1. Remove fileReader property
2. Remove fileStream property
3. Simplify getFileBytes() to just return fileBytes
4. Update copyWith() method
5. Ensure readMimeData() still works with mime package

**Phase 3: Platform Interface Creation**
1. Create abstract platform interface for drag-and-drop
2. Define methods: initialize, onDrop, onHover, dispose
3. Create factory constructor for platform selection

**Phase 4: Web Implementation**
1. Create HtmlElementView-based widget
2. Write JavaScript file for browser drag-and-drop events
3. Implement dart:js_interop communication
4. Wrap web.File objects in FileModel
5. Test with various file types and browsers

**Phase 5: Desktop Implementation**
1. Implement using native Flutter DragTarget
2. Or create platform channel for native drag-and-drop
3. Handle file path extraction
4. Read file bytes using dart:io
5. Test on macOS, Windows, Linux if applicable

**Phase 6: Widget Refactoring**
1. Replace DropRegion in file_upload_widget.dart
2. Update _handleDroppedFile() to work with new implementation
3. Maintain existing _pickFiles() logic
4. Ensure visual feedback works
5. Test focus management

**Phase 7: Testing**
1. Remove old tests
2. Write new unit tests for FileModel
3. Write widget tests for FileUploadWidget
4. Write integration tests for full workflow
5. Test on web and desktop platforms
6. Verify API compatibility

**Phase 8: Documentation & Cleanup**
1. Update CHANGELOG.md
2. Verify all features work
3. Clean up dead code
4. Run linter
5. Performance testing with various file sizes

### Known Risks & Mitigation

**Risk: Browser Compatibility Issues**
- Mitigation: Follow flutter_dropzone proven patterns, test on major browsers

**Risk: Desktop Drag-and-Drop Complexity**
- Mitigation: Start with web (priority), iterate on desktop, consider platform channels if needed

**Risk: Large File Memory Usage**
- Mitigation: Document recommended limits, consider adding file size validation

**Risk: Breaking API Changes**
- Mitigation: Maintain FileModel structure, thorough testing of FormResults APIs

**Risk: Test Coverage Gaps**
- Mitigation: Write tests early, test on actual platforms not just mocks

**Risk: Flutter Version Compatibility**
- Mitigation: Target specific version (3.35.0), document clearly in pubspec.yaml

### Success Criteria

**Functional Success:**
- All existing file upload features work on web and desktop
- Developer-facing APIs unchanged (FormResults.grab().asFile())
- No regression in user experience
- File validation works correctly
- Visual feedback matches current implementation

**Technical Success:**
- zero dependencies on super_drag_and_drop and super_clipboard
- Clean compilation on Flutter 3.35.0
- All new tests passing
- No linting errors
- Code follows ChampionForms standards

**User Success:**
- Developers can upgrade without code changes
- End users see same or better drag-and-drop experience
- File uploads work reliably across platforms
- Clear error messages for invalid files
