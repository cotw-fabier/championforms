# Specification: Migrate to Native Flutter Drag and Drop

## Goal

Remove unmaintained dependencies (super_drag_and_drop v0.9.1 and super_clipboard v0.9.1) that no longer compile with recent Flutter builds, and replace with native Flutter drag-and-drop functionality while maintaining complete API compatibility and feature parity across web and desktop platforms.

## User Stories

- As a ChampionForms package consumer, I want existing code to work without changes after upgrading, so that migration is seamless
- As an end user on web, I want to drag files from my desktop into the application, so that I can upload files quickly
- As an end user on desktop, I want to drag files into the application with visual feedback, so that I know when a drop zone is active
- As a developer, I want FormResults.grab("fieldId").asFile() to continue working identically, so that I don't need to refactor existing code
- As a package maintainer, I want to compile on Flutter 3.35.0 stable, so that the package stays current with the ecosystem

## Core Requirements

### Functional Requirements

- Support drag-and-drop file uploads from native file explorers (Finder, File Explorer, Nautilus)
- Accept single or multiple files based on field configuration (multiselect flag)
- Validate dropped files against allowedExtensions list before acceptance
- Display visual feedback during drag operations (hover state with opacity change)
- Show file previews with type-based icons (code, text, document, image, video, audio, executable, archive, generic)
- Allow file removal via close button on previews
- Support clearOnUpload flag (replace vs append behavior)
- Maintain file_picker integration for dialog-based selection (unchanged)
- Detect MIME types using existing mime package
- Store files as FileModel with fileName, fileBytes, mimeData, uploadExtension
- Support custom drop zone and file list builders via callbacks
- Trigger validation on file changes when validateLive is enabled

### Non-Functional Requirements

- Zero breaking changes to developer-facing APIs
- Target Flutter SDK 3.35.0 stable
- Compile successfully on web and desktop (macOS/Windows)
- Maintain current visual design and UX patterns
- Files loaded fully into memory (no streaming in initial implementation)
- Clean code following ChampionForms standards
- Pass all linting checks

## Visual Design

No mockups provided. Maintain existing visual design:
- Drop zone with upload icon and "Upload File" text
- Border with hover state (opacity 0.8 when dragging)
- File previews as icons with truncated labels (max 2 lines, ellipsis)
- Close button (X) overlaid on top-right of each file preview
- Wrap layout for multiple files with 8px spacing

## Reusable Components

### Existing Code to Leverage

**From flutter_dropzone reference implementation:**
- Platform interface pattern with abstract base class
- Web implementation using HtmlElementView + JavaScript
- Event-based architecture with StreamController
- File abstraction interface (DropzoneFileInterface pattern)
- JavaScript interop using @JS() annotations
- MIME type filtering in JavaScript for web

**From existing ChampionForms:**
- FieldColorScheme for theming (no changes)
- FormController integration (no changes)
- Validation system and FormResults (no changes)
- File icon mapping logic in _getFileIcon() (reuse)
- Focus management with FocusNode (reuse)
- file_picker integration in _pickFiles() (reuse)
- _addFile() method for XFile processing (reuse with minor updates)

### New Components Required

**Web Platform Implementation:**
- Platform-agnostic drag-drop wrapper widget to replace DropRegion
- Web-specific implementation with HtmlElementView
- JavaScript file for browser event handling (dragover, drop, dragleave)
- Dart ↔ JavaScript bridge using dart:js_interop
- Web file wrapper conforming to FileModel requirements

**Desktop Platform Implementation:**
- Native Flutter DragTarget wrapper
- File path extraction from drag events
- Desktop file wrapper using dart:io
- Platform channel integration (if native DragTarget insufficient)

**FileModel Changes:**
- Remove fileReader property (DataReader dependency)
- Remove fileStream property (Stream<Uint8List> dependency)
- Simplify getFileBytes() to synchronous access
- Update copyWith() to remove deprecated parameters

## Technical Approach

### Architecture

Follow flutter_dropzone's proven platform interface pattern:

1. **Platform Interface Layer**: Abstract class defining drag-drop operations
2. **Web Implementation**: HtmlElementView + JavaScript + dart:js_interop
3. **Desktop Implementation**: Native Flutter DragTarget or platform channels
4. **Shared FileModel**: Cross-platform file representation

### Database

No database changes required. ChampionForms is a frontend-only package.

### API

**External API (Must Remain Unchanged):**
- `FormResults.grab("fieldId").asFile()` → returns FileModel or null
- `FormResults.grab("fieldId").asFileList()` → returns List<FileModel>
- FileModel properties: fileName, fileBytes, mimeData, uploadExtension
- FileUpload field configuration: multiselect, clearOnUpload, allowedExtensions, displayUploadedFiles

**Internal Changes:**
- Replace DropRegion with new drag-drop wrapper widget
- Update _handleDroppedFile() signature to accept platform-agnostic file data
- FileModel.getFileBytes() returns Future<Uint8List?> but always resolves immediately
- Remove DataReader parameters from FileModel constructor

### Frontend

**Widget Structure:**
```
FileUploadWidget (existing container)
  └─ DragDropWrapper (new - replaces DropRegion)
      └─ Focus
          └─ Container (existing visual wrapper)
              ├─ InkWell → DropZoneWidget
              └─ Wrap → File previews
```

**Web-Specific Components:**
- Create lib/widgets_internal/platform/web/file_drag_target_web.dart
- Create web/assets/file_drag_drop.js for browser events
- JavaScript handles dragover, drop, dragleave
- Extract files from event.dataTransfer
- Filter by MIME type in JavaScript
- Return file data (name, bytes, type) to Dart

**Desktop-Specific Components:**
- Create lib/widgets_internal/platform/desktop/file_drag_target_desktop.dart
- Wrap native DragTarget<List<String>> accepting file paths
- Read files using dart:io File
- Perform MIME validation in Dart

### Testing

**Remove:**
- All existing file upload tests using super_drag_and_drop mocks

**Add - Unit Tests:**
- FileModel creation without fileReader/fileStream
- getFileBytes() synchronous behavior
- readMimeData() with various file types
- MIME type detection accuracy
- Extension validation logic

**Add - Widget Tests:**
- FileUploadWidget rendering
- File picker integration
- File addition/removal
- Multiselect behavior
- clearOnUpload behavior
- allowedExtensions filtering
- Hover state visual feedback
- Focus management

**Add - Integration Tests:**
- End-to-end file upload workflow
- Form submission with files
- Multiple file fields in one form
- FormResults.grab().asFile() and .asFileList()

## Implementation Plan

### Phase 1: Dependency Removal
- Remove super_clipboard and super_drag_and_drop from pubspec.yaml
- Remove imports from affected files
- Document compilation errors

### Phase 2: FileModel Refactoring
- Remove fileReader and fileStream properties
- Update constructor and copyWith()
- Simplify getFileBytes() to return fileBytes directly
- Ensure backward compatibility for null fileBytes case

### Phase 3: Web Platform Implementation
- Create web drag-drop JavaScript file
- Implement HtmlElementView-based widget
- Create dart:js_interop bridge
- Handle dragover, drop, dragleave events
- Extract and validate files
- Return Uint8List file data to Dart

### Phase 4: Desktop Platform Implementation
- Create DragTarget-based implementation
- Handle file path extraction
- Read file bytes with dart:io
- Implement MIME validation
- Test on macOS and Windows

### Phase 5: Widget Integration
- Create platform-agnostic DragDropWrapper
- Replace DropRegion in FileUploadWidget
- Update _handleDroppedFile() signature
- Ensure visual feedback works
- Test hover states

### Phase 6: Testing
- Remove old tests
- Write FileModel unit tests
- Write FileUploadWidget widget tests
- Write integration tests
- Verify API compatibility

### Phase 7: Documentation & Polish
- Update CHANGELOG.md with migration details
- Verify all features working
- Run flutter analyze
- Performance test with various file sizes
- Document memory limitations

## Out of Scope

- Clipboard paste functionality (explicitly removed)
- Changes to file_picker integration (working correctly)
- File streaming for large files (removed in favor of in-memory)
- Upload progress indicators
- Image preview thumbnails
- File drag-and-drop reordering
- Cloud storage integration
- Changes to theming or visual design
- Backward compatibility with Flutter versions < 3.35.0

## Success Criteria

### Functional Success
- Drag-and-drop works on web (primary platform)
- Drag-and-drop works on desktop (macOS, Windows)
- All existing features preserved (multiselect, clearOnUpload, allowedExtensions, validation)
- FormResults.grab().asFile() and .asFileList() work identically
- File previews with icons display correctly
- Visual feedback (hover states) matches current implementation
- File removal works correctly
- file_picker integration unchanged

### Technical Success
- Zero dependencies on super_drag_and_drop and super_clipboard
- Clean compilation on Flutter 3.35.0 stable
- All new tests passing
- No linting errors
- No breaking API changes
- Code follows ChampionForms standards (SOLID, composition, immutability)
- Proper error handling with try-catch blocks
- Resources cleaned up in dispose()

### Developer Experience Success
- Package consumers can upgrade without code changes
- Clear migration notes in CHANGELOG (even though no changes needed)
- API documentation updated
- Example app demonstrates file upload functionality

## Risks and Mitigations

### Risk: Web Browser Compatibility Issues
**Impact:** High - Web is primary platform
**Likelihood:** Medium
**Mitigation:** Follow flutter_dropzone proven patterns, test on Chrome, Firefox, Safari. Use standard dataTransfer API which has broad support.

### Risk: Desktop Platform Limitations
**Impact:** Medium - Desktop is secondary platform
**Likelihood:** Medium
**Mitigation:** Start with web implementation. Research Flutter's native DragTarget capabilities early. Plan for platform channels if needed. Desktop can have reduced functionality if necessary.

### Risk: Large File Memory Issues
**Impact:** Medium - Could cause crashes
**Likelihood:** High for large files
**Mitigation:** Document recommended file size limits (e.g., < 50MB). Consider adding maxFileSize validation. Plan streaming support for future enhancement.

### Risk: Breaking API Changes
**Impact:** Critical - Would break consumer code
**Likelihood:** Low with careful planning
**Mitigation:** Maintain FileModel structure exactly. Write comprehensive API compatibility tests. Test FormResults.grab() methods thoroughly. Review all public APIs before merge.

### Risk: MIME Type Detection Inaccuracy
**Impact:** Low - Incorrect file type icons
**Likelihood:** Medium
**Mitigation:** Use existing mime package which has broad type support. Fallback to "application/octet-stream" for unknowns. Test with diverse file types.

### Risk: Visual Regression
**Impact:** Medium - User experience degradation
**Likelihood:** Low
**Mitigation:** Maintain exact same widget structure. Reuse existing color scheme and layout. Visual testing before/after. Compare hover state behavior carefully.

### Risk: Testing Gaps
**Impact:** Medium - Bugs in production
**Likelihood:** Medium
**Mitigation:** Write tests early and run continuously. Test on actual platforms not just mocks. Cover edge cases (empty files, invalid types, maxed lists). Integration test full workflows.

### Risk: Flutter Version Compatibility
**Impact:** Medium - May not work on older Flutter
**Likelihood:** Low with 3.35.0 target
**Mitigation:** Target specific version (3.35.0), document clearly in pubspec.yaml. Test on exact target version. Don't use experimental APIs.

## Technical Notes

### Platform Detection
Use conditional imports:
```dart
// lib/widgets_internal/platform/file_drag_target.dart (stub)
export 'file_drag_target_web.dart' if (dart.library.io) 'file_drag_target_desktop.dart';
```

### Web Implementation Pattern
- HtmlElementView creates container div
- JavaScript file loaded as asset
- JavaScript handles native browser events
- Fires custom events to Dart side
- Dart listens via EventStreamProvider

### Desktop Implementation Considerations
- Flutter's DragTarget may require Draggable source (won't work for OS files)
- May need platform channels (MethodChannel) for true OS drag-drop
- Consider dropping desktop support in v1 if too complex

### Memory Management
- Files stored as Uint8List in memory
- Each file fully loaded before processing
- No streaming in initial implementation
- Potential for OutOfMemory with large files
- Consider weak references for large file lists

### JavaScript Security
- Browser prevents arbitrary file system access (by design)
- dataTransfer API is secure
- No file path information available on web (only name and contents)
- MIME type validation prevents some exploits but not all

### Error Handling Strategy
- Wrap file read operations in try-catch
- Log errors with dart:developer log()
- Show user-friendly messages, not stack traces
- Fail gracefully - don't crash on invalid file
- Clean up resources even on error paths
