# Task Breakdown: Migrate to Native Flutter Drag and Drop

## Overview
Total Task Groups: 9
Assigned Roles: ui-designer, testing-engineer

## Task List

### Phase 1: Dependency Removal and Analysis

#### Task Group 1: Remove Unmaintained Dependencies
**Assigned implementer:** ui-designer
**Dependencies:** None

- [x] 1.0 Remove unmaintained dependencies and document current state
  - [x] 1.1 Remove super_clipboard and super_drag_and_drop from pubspec.yaml
    - Remove both dependencies from dependencies section
    - Update pubspec.lock
  - [x] 1.2 Remove imports from affected files
    - Remove super_clipboard imports from lib/models/file_model.dart
    - Remove super_drag_and_drop imports from lib/widgets_internal/field_widgets/file_upload_widget.dart
    - Remove any other references in lib/default_fields/fileupload.dart and lib/models/field_types/fileupload.dart
  - [x] 1.3 Document compilation errors and affected areas
    - Run `flutter analyze` to identify all compilation errors
    - Document which methods and classes are affected
    - Create a checklist of APIs that need replacement

**Acceptance Criteria:**
- Dependencies removed from pubspec.yaml
- All imports removed from affected files
- Compilation errors documented for planning next phases
- No references to super_clipboard or super_drag_and_drop remain

### Phase 2: FileModel Refactoring

#### Task Group 2: Simplify FileModel
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 1

- [x] 2.0 Refactor FileModel to remove super_clipboard dependencies
  - [x] 2.1 Write 2-8 focused tests for FileModel functionality
    - Test FileModel creation with fileName, fileBytes, mimeData, uploadExtension
    - Test getFileBytes() returns fileBytes directly
    - Test readMimeData() with various file types (text, image, pdf, etc.)
    - Test copyWith() method creates correct copy
    - Limit to 2-8 tests covering only critical FileModel behaviors
  - [x] 2.2 Remove fileReader property from FileModel
    - Remove fileReader field (DataReader dependency)
    - Remove from constructor parameters
    - Remove from copyWith() method
  - [x] 2.3 Remove fileStream property from FileModel
    - Remove fileStream field (Stream<Uint8List> dependency)
    - Remove from constructor parameters
    - Remove from copyWith() method
  - [x] 2.4 Simplify getFileBytes() method
    - Change from async operation to return Future.value(fileBytes)
    - Remove any DataReader usage
    - Maintain Future<Uint8List?> return type for API compatibility
  - [x] 2.5 Update readMimeData() to use mime package only
    - Ensure MIME detection works with lookupMimeType
    - Test with various file extensions
    - Fallback to "application/octet-stream" for unknown types
  - [x] 2.6 Update copyWith() method
    - Remove fileReader and fileStream from parameters
    - Maintain all other parameters (fileName, fileBytes, mimeData, uploadExtension)
  - [x] 2.7 Ensure FileModel tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify all critical FileModel operations work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- FileModel has no super_clipboard dependencies
- getFileBytes() returns Future<Uint8List?> immediately
- readMimeData() works correctly with mime package
- API compatibility maintained (FormResults.grab().asFile() still works)

### Phase 3: Platform Interface Creation

#### Task Group 3: Create Platform Abstraction Layer
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 2

- [x] 3.0 Create platform-agnostic drag-drop interface
  - [x] 3.1 Create platform interface structure
    - Create lib/widgets_internal/platform/file_drag_drop_interface.dart
    - Define abstract class FileDragDropInterface with methods: onDrop, onHover, onLeave, dispose
    - Define FileDragDropEvent class for drag state events
    - Define FileDragDropFile interface for cross-platform file representation
  - [x] 3.2 Create conditional export pattern
    - Create lib/widgets_internal/platform/file_drag_target.dart (stub file)
    - Use conditional export: `export 'file_drag_target_web.dart' if (dart.library.io) 'file_drag_target_desktop.dart';`
    - Ensure proper platform detection
  - [x] 3.3 Define StreamController-based event architecture
    - Create broadcast StreamController for drag events
    - Define event types: onDropFile, onDropFiles, onDropInvalid, onHover, onLeave
    - Follow flutter_dropzone pattern for event handling
  - [x] 3.4 Create FileDragDropFile abstraction
    - Properties: name, size, mimeType, lastModified
    - Methods: getBytes() returns Future<Uint8List>
    - Allows platform-specific implementations (web.File, dart:io File)

**Acceptance Criteria:**
- Platform interface defined with clear contract
- Conditional exports set up for web/desktop selection
- Event architecture ready for platform implementations
- FileDragDropFile abstraction supports both platforms

### Phase 4: Web Platform Implementation

#### Task Group 4: Implement Web Drag-and-Drop
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 3

- [x] 4.0 Implement web drag-and-drop using HtmlElementView + JavaScript
  - [x] 4.1 Write 2-8 focused tests for web drag-drop functionality
    - Test file drop event handling (if testable with mocks)
    - Test MIME type filtering
    - Test single vs multiple file drops
    - Test hover state changes
    - Limit to 2-8 tests covering only critical web drag-drop behaviors
  - [x] 4.2 Create JavaScript file for browser event handling
    - Create web/assets/file_drag_drop.js
    - Handle dragover event: preventDefault(), set dropEffect to "copy"
    - Handle drop event: extract files from event.dataTransfer.items/files
    - Handle dragleave event: fire leave event to Dart
    - Filter files by MIME type if allowedExtensions provided
    - Fire custom events to Dart side with file data
  - [x] 4.3 Create web platform implementation widget
    - Create lib/widgets_internal/platform/file_drag_target_web.dart
    - Use HtmlElementView to create container div
    - Load JavaScript file from assets
    - Set up dart:js_interop bridge using @JS() annotations
  - [x] 4.4 Implement dart:js_interop communication
    - Define @JS() classes for JavaScript interop
    - Create event listeners for custom events from JavaScript
    - Convert web.File objects to FileDragDropFile abstraction
    - Use FileReader API to read file bytes as arrayBuffer
  - [x] 4.5 Implement FileDragDropFile for web
    - Wrap web.File objects
    - Implement getBytes() using FileReader.readAsArrayBuffer()
    - Extract name, size, type from web.File properties
  - [x] 4.6 Add MIME type filtering
    - Filter in JavaScript based on allowedExtensions
    - Convert extensions to MIME types for filtering
    - Fire onDropInvalid event for rejected files
  - [x] 4.7 Implement visual feedback callbacks
    - Fire onHover event when dragover detected
    - Fire onLeave event when dragleave detected
    - Fire onDropFile/onDropFiles on successful drop
  - [x] 4.8 Include JavaScript in web assets
    - Add file_drag_drop.js to web/assets/
    - Ensure it's loaded in index.html or dynamically loaded
    - Test loading and initialization
  - [x] 4.9 Ensure web drag-drop tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify critical web drag-drop operations work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- JavaScript file handles dragover, drop, dragleave events
- Dart ↔ JavaScript communication works via dart:js_interop
- Files extracted from dataTransfer and converted to Uint8List
- MIME type filtering works in JavaScript
- Visual feedback events fire correctly
- Web platform implementation follows flutter_dropzone patterns

### Phase 5: Desktop Platform Implementation

#### Task Group 5: Implement Desktop Drag-and-Drop
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 3

- [x] 5.0 Implement desktop drag-and-drop using native Flutter DragTarget
  - [x] 5.1 Write 2-8 focused tests for desktop drag-drop functionality
    - Test file path extraction from drag events (if testable)
    - Test file reading with dart:io
    - Test MIME type validation in Dart
    - Test single vs multiple file drops
    - Limit to 2-8 tests covering only critical desktop drag-drop behaviors
  - [x] 5.2 Create desktop platform implementation widget
    - Create lib/widgets_internal/platform/file_drag_target_desktop.dart
    - Use native Flutter DragTarget<List<String>> or platform channels
    - Research if DragTarget supports OS file drops or if platform channels needed
  - [x] 5.3 Implement file path extraction
    - Extract file paths from drag events
    - Handle single and multiple file drops
    - Validate paths exist before processing
  - [x] 5.4 Read file bytes using dart:io
    - Use dart:io File.readAsBytes() to load file contents
    - Handle errors gracefully (file not found, permission denied)
    - Wrap in try-catch blocks
  - [x] 5.5 Implement FileDragDropFile for desktop
    - Wrap dart:io File paths
    - Implement getBytes() using File.readAsBytes()
    - Extract name from file path
    - Get size from File.length()
  - [x] 5.6 Implement MIME type validation in Dart
    - Use mime package's lookupMimeType with file path
    - Filter against allowedExtensions list
    - Fire onDropInvalid for rejected files
  - [x] 5.7 Implement visual feedback callbacks
    - Fire onHover when drag enters widget bounds
    - Fire onLeave when drag exits widget bounds
    - Fire onDropFile/onDropFiles on successful drop
  - [x] 5.8 Test on macOS and Windows
    - Test drag-and-drop from Finder (macOS)
    - Test drag-and-drop from File Explorer (Windows)
    - Verify file path extraction works on both platforms
  - [x] 5.9 Ensure desktop drag-drop tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify critical desktop drag-drop operations work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 5.1 pass
- Desktop implementation uses DragTarget or platform channels
- File paths extracted and converted to bytes successfully
- MIME type validation works in Dart using mime package
- Visual feedback events fire correctly
- Works on macOS and Windows (Linux optional)

### Phase 6: Widget Integration

#### Task Group 6: Refactor FileUploadWidget
**Assigned implementer:** ui-designer
**Dependencies:** Task Groups 4, 5

- [x] 6.0 Integrate new drag-drop implementation into FileUploadWidget
  - [x] 6.1 Write 2-8 focused tests for FileUploadWidget
    - Test widget rendering with drop zone
    - Test file picker integration (existing _pickFiles method)
    - Test file addition via drag-drop
    - Test file removal via close button
    - Test multiselect behavior
    - Test clearOnUpload flag
    - Test allowedExtensions filtering
    - Test hover state visual feedback
    - Limit to 2-8 tests covering only critical widget behaviors
  - [x] 6.2 Replace DropRegion with platform-agnostic drag-drop wrapper
    - Remove DropRegion widget usage
    - Import lib/widgets_internal/platform/file_drag_target.dart
    - Wrap existing UI with new FileDragTarget widget
    - Pass callbacks for onDrop, onHover, onLeave events
  - [x] 6.3 Update _handleDroppedFile() method signature
    - Change from accepting DataReader to accepting FileDragDropFile
    - Convert FileDragDropFile to FileModel
    - Call getBytes() and create FileModel with result
    - Maintain existing validation logic
  - [x] 6.4 Implement drag hover visual feedback
    - Add state variable for hover state (bool _isDragHovering = false)
    - Set to true in onHover callback
    - Set to false in onLeave and onDrop callbacks
    - Apply opacity change (0.8) to drop zone when hovering
  - [x] 6.5 Maintain file_picker integration unchanged
    - Keep existing _pickFiles() method
    - Ensure dialog-based file selection still works
    - Verify allowedExtensions filtering in picker
  - [x] 6.6 Maintain existing validation and onChange logic
    - Keep validateLive behavior
    - Keep FormController integration
    - Keep onFileOptionChange callback
    - Trigger validation on file changes
  - [x] 6.7 Maintain file preview and icon logic
    - Keep _getFileIcon() method unchanged
    - Keep file preview rendering with icons
    - Keep close button on previews
    - Keep Wrap layout with 8px spacing
  - [x] 6.8 Test focus management
    - Verify FocusNode behavior unchanged
    - Test onFocusChange callbacks
    - Test requestFocus from field configuration
  - [x] 6.9 Ensure FileUploadWidget tests pass
    - Run ONLY the 2-8 tests written in 6.1
    - Verify critical widget behaviors work
    - Do NOT run the entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 6.1 pass
- DropRegion replaced with new platform-agnostic implementation
- Drag-drop works on both web and desktop
- file_picker integration unchanged
- Visual feedback (hover states) matches original behavior
- File previews, icons, and removal work correctly
- Validation and focus management unchanged

### Phase 7: API Compatibility Verification

#### Task Group 7: Verify Developer-Facing APIs
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 6

- [x] 7.0 Verify API compatibility and FormResults integration
  - [x] 7.1 Test FormResults.grab().asFile() API
    - Create test form with single file upload field
    - Upload file via drag-drop
    - Call FormResults.grab("fieldId").asFile()
    - Verify returns FileModel or null
    - Verify FileModel has correct properties (fileName, fileBytes, mimeData, uploadExtension)
  - [x] 7.2 Test FormResults.grab().asFileList() API
    - Create test form with multiselect file upload field
    - Upload multiple files via drag-drop
    - Call FormResults.grab("fieldId").asFileList()
    - Verify returns List<FileModel>
    - Verify all FileModel objects have correct properties
  - [x] 7.3 Test FileModel API compatibility
    - Verify FileModel.getFileBytes() returns Future<Uint8List?>
    - Verify getFileBytes() resolves immediately (no async delay)
    - Verify FileModel.fileName, .fileBytes, .mimeData, .uploadExtension accessible
    - Verify copyWith() creates correct copies
  - [x] 7.4 Test field configuration APIs unchanged
    - Verify multiselect flag behavior
    - Verify clearOnUpload flag behavior
    - Verify allowedExtensions filtering
    - Verify displayUploadedFiles flag
    - Verify dropDisplayWidget custom builder
    - Verify fileUploadBuilder custom builder
  - [x] 7.5 Create integration test for full form submission
    - Create form with file upload field
    - Upload files via drag-drop
    - Submit form
    - Verify FormResults contains correct file data
    - Verify files accessible via asFile() and asFileList()

**Acceptance Criteria:**
- FormResults.grab().asFile() returns FileModel with correct structure
- FormResults.grab().asFileList() returns List<FileModel>
- FileModel.getFileBytes() returns Future<Uint8List?> immediately
- All field configuration flags work as before
- Zero breaking changes to developer-facing APIs
- Integration test demonstrates full workflow

### Phase 8: Testing and Gap Analysis

#### Task Group 8: Comprehensive Testing Review
**Assigned implementer:** testing-engineer
**Dependencies:** Task Groups 1-7

- [x] 8.0 Remove old tests and fill critical gaps
  - [x] 8.1 Remove all existing file upload tests
    - Remove all tests that depend on super_drag_and_drop mocks
    - Remove any super_clipboard-related test setup
    - Clean up test fixtures that are no longer relevant
  - [x] 8.2 Review tests from Task Groups 2, 4, 5, 6
    - Review 2-8 tests written by ui-designer for FileModel (Task 2.1)
    - Review 2-8 tests written by ui-designer for web drag-drop (Task 4.1)
    - Review 2-8 tests written by ui-designer for desktop drag-drop (Task 5.1)
    - Review 2-8 tests written by ui-designer for FileUploadWidget (Task 6.1)
    - Total existing tests: approximately 8-32 tests
  - [x] 8.3 Analyze test coverage gaps for drag-drop migration only
    - Identify critical user workflows lacking coverage
    - Focus ONLY on gaps related to drag-drop migration
    - Do NOT assess entire application test coverage
    - Prioritize integration tests over unit test gaps
  - [x] 8.4 Write up to 10 additional strategic tests maximum
    - Integration test: Full drag-drop workflow on web
    - Integration test: Full drag-drop workflow on desktop
    - Integration test: Form with multiple file fields
    - Integration test: File validation edge cases (invalid MIME types)
    - Integration test: Multiselect with clearOnUpload combinations
    - Widget test: Hover state visual feedback
    - Widget test: allowedExtensions filtering
    - Unit test: MIME type detection with diverse file types
    - Do NOT write comprehensive coverage for all scenarios
    - Focus on critical migration-related workflows
  - [x] 8.5 Run feature-specific tests only
    - Run ONLY tests related to drag-drop migration
    - Expected total: approximately 18-42 tests maximum
    - Do NOT run the entire application test suite
    - Verify all critical workflows pass

**Acceptance Criteria:**
- All old file upload tests removed
- Feature-specific tests pass (approximately 18-42 tests total)
- Critical drag-drop workflows covered
- No more than 10 additional tests added by testing-engineer
- Testing focused exclusively on drag-drop migration

### Phase 9: Documentation and Polish

#### Task Group 9: Final Review and Documentation
**Assigned implementer:** ui-designer
**Dependencies:** Task Group 8

- [x] 9.0 Final polish and documentation
  - [x] 9.1 Update CHANGELOG.md
    - Document migration from super_clipboard and super_drag_and_drop
    - Note that developer-facing APIs unchanged (seamless upgrade)
    - Document Flutter SDK version requirement (3.35.0)
    - List removed dependencies
    - Note web and desktop platform support
  - [x] 9.2 Run flutter analyze
    - Fix all linting errors
    - Ensure no warnings related to file upload code
    - Verify clean analysis output
  - [x] 9.3 Verify all features working
    - Manual test: Drag-drop on web (Chrome, Firefox, Safari)
    - Manual test: Drag-drop on desktop (macOS, Windows)
    - Manual test: File picker dialog selection
    - Manual test: Single and multiselect modes
    - Manual test: allowedExtensions filtering
    - Manual test: clearOnUpload flag behavior
    - Manual test: File removal via close button
    - Manual test: Visual feedback (hover states)
  - [x] 9.4 Update pubspec.yaml Flutter SDK constraint
    - Set minimum Flutter SDK to 3.35.0
    - Document in pubspec.yaml comments
  - [x] 9.5 Performance test with various file sizes
    - Test with small files (< 1MB)
    - Test with medium files (1-10MB)
    - Test with large files (10-50MB)
    - Document recommended file size limits
    - Note memory usage behavior
  - [x] 9.6 Document memory limitations
    - Add comments noting files loaded fully into memory
    - Recommend file size limits (e.g., < 50MB)
    - Note potential OutOfMemory issues with large files
    - Suggest maxFileSize validation for production use
  - [x] 9.7 Clean up dead code
    - Remove any unused imports
    - Remove commented-out code
    - Remove debug print statements
    - Ensure dispose() methods clean up resources
  - [x] 9.8 Update API documentation
    - Add dartdoc comments for new platform interface
    - Document FileDragDropInterface and FileDragDropFile
    - Update FileModel documentation noting removed properties
    - Document memory considerations in FileUploadWidget

**Acceptance Criteria:**
- CHANGELOG.md updated with migration details
- flutter analyze passes with zero errors/warnings
- All features verified working on web and desktop
- Performance tested with various file sizes
- Memory limitations documented
- Dead code removed
- API documentation updated
- Code follows ChampionForms standards

## Execution Order

Recommended implementation sequence:

1. **Dependency Removal** (Task Group 1) - Clean slate
2. **FileModel Refactoring** (Task Group 2) - Foundation layer
3. **Platform Interface** (Task Group 3) - Abstraction layer
4. **Web Implementation** (Task Group 4) - Priority platform
5. **Desktop Implementation** (Task Group 5) - Secondary platform
6. **Widget Integration** (Task Group 6) - UI layer
7. **API Verification** (Task Group 7) - Compatibility check
8. **Testing Review** (Task Group 8) - Quality assurance
9. **Documentation** (Task Group 9) - Final polish

## Implementation Notes

### Key Risks and Mitigations

**Risk: Web Browser Compatibility Issues**
- Mitigation: Follow flutter_dropzone proven patterns in Task Group 4
- Test on Chrome, Firefox, Safari in Task Group 9

**Risk: Desktop Platform Limitations**
- Mitigation: Research DragTarget capabilities early in Task Group 5
- Consider platform channels if DragTarget insufficient
- Web is priority, desktop can have reduced functionality if needed

**Risk: Large File Memory Issues**
- Mitigation: Document recommended file size limits in Task Group 9
- Add maxFileSize validation recommendation
- Performance test with various sizes in Task Group 9

**Risk: Breaking API Changes**
- Mitigation: Task Group 7 dedicated to API compatibility verification
- Maintain FileModel structure exactly in Task Group 2
- Test FormResults.grab() methods thoroughly

**Risk: Testing Gaps**
- Mitigation: Write tests early in each task group (x.1 subtasks)
- testing-engineer reviews and fills critical gaps in Task Group 8
- Integration tests cover end-to-end workflows

### Platform-Specific Considerations

**Web Implementation (Task Group 4):**
- HtmlElementView creates container div
- JavaScript handles browser events (dragover, drop, dragleave)
- dart:js_interop for Dart ↔ JavaScript communication
- FileReader API for reading file bytes
- MIME filtering in JavaScript before passing to Dart

**Desktop Implementation (Task Group 5):**
- Native Flutter DragTarget or platform channels
- dart:io File for reading file bytes
- MIME filtering in Dart using mime package
- Test on macOS and Windows

### Reference Implementation

Learn from flutter_dropzone plugin at `/Users/fabier/Documents/libraries/flutter_dropzone/`:
- Platform interface pattern
- HtmlElementView + JavaScript approach
- Event-based architecture with StreamController
- FileDragDropFile abstraction (similar to DropzoneFileInterface)
- Cross-platform file representation

### Testing Strategy

**Minimal Tests During Development:**
- Each task group (2, 4, 5, 6) writes 2-8 focused tests maximum
- Tests cover only critical behaviors for that component
- Final sub-task runs ONLY those tests, not entire suite

**Comprehensive Testing Review (Task Group 8):**
- testing-engineer reviews all tests from previous groups
- Adds maximum of 10 additional strategic tests
- Focuses on integration tests for end-to-end workflows
- Expected total: approximately 18-42 tests for this feature

**Test Types:**
- Unit tests: FileModel, MIME detection, validation logic
- Widget tests: FileUploadWidget rendering, interactions, visual feedback
- Integration tests: Full drag-drop workflow, form submission, FormResults API

### Code Standards Compliance

**Flutter Widget Composition:**
- Extract UI sections into small private Widget classes
- Use const constructors where possible
- Maintain immutability with final fields
- Composition over inheritance

**Error Handling:**
- Wrap file read operations in try-catch blocks
- Use dart:developer log() for errors
- Fail gracefully, don't crash on invalid files
- Clean up resources in dispose() methods

**Testing Best Practices:**
- Follow AAA pattern (Arrange-Act-Assert)
- Test behavior, not implementation
- Keep unit tests fast
- Use descriptive test names
- Prefer fakes/stubs over mocks

### Success Metrics

**Functional Success:**
- Drag-and-drop works on web (primary platform)
- Drag-and-drop works on desktop (macOS, Windows)
- All existing features preserved
- FormResults.grab() APIs work identically
- Visual feedback matches original

**Technical Success:**
- Zero dependencies on super_drag_and_drop and super_clipboard
- Clean compilation on Flutter 3.35.0 stable
- All tests passing (18-42 tests expected)
- No linting errors
- Code follows ChampionForms standards

**Developer Experience Success:**
- Package consumers can upgrade without code changes
- Clear migration notes in CHANGELOG
- API documentation updated
- Example demonstrates functionality
