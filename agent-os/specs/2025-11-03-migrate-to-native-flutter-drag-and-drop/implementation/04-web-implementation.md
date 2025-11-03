# Task 4: Implement Web Drag-and-Drop

## Overview
**Task Reference:** Task #4 from `agent-os/specs/2025-11-03-migrate-to-native-flutter-drag-and-drop/tasks.md`
**Implemented By:** ui-designer
**Date:** 2025-11-03
**Status:** ✅ Complete

### Task Description
Implement web drag-and-drop functionality using HtmlElementView + JavaScript + dart:js_interop following the flutter_dropzone pattern. This implementation allows users to drag files from their desktop/file explorer directly into the web application, with MIME type filtering and visual feedback.

## Implementation Summary

The web drag-and-drop implementation was successfully completed using a proven pattern from flutter_dropzone. The solution consists of three main components:

1. **JavaScript Bridge** (`file_drag_drop.js`) - Handles native browser drag-and-drop events (dragover, drop, dragleave) and manages MIME type filtering before passing files to Dart.

2. **Dart Web Implementation** (`file_drag_target_web.dart`) - Uses HtmlElementView to create a container div, loads the JavaScript bridge dynamically, and establishes bidirectional communication via dart:js_interop.

3. **File Abstraction** (`FileDragDropFileWeb`) - Wraps web.File objects and implements the FileDragDropFile interface, providing cross-platform file access with async byte reading via FileReader API.

The implementation prioritizes the web platform (as specified in requirements) and provides a solid foundation for desktop implementation in Task Group 5. All 8 tests pass, demonstrating correct widget rendering, configuration handling, and interface compliance.

## Files Changed/Created

### New Files
- `lib/assets/file_drag_drop.js` - JavaScript bridge handling browser drag-drop events with MIME filtering
- `lib/widgets_internal/platform/file_drag_target_web.dart` - Web platform implementation using HtmlElementView and dart:js_interop
- `example/test/file_drag_target_web_test.dart` - 8 focused tests verifying web drag-drop functionality

### Modified Files
- `pubspec.yaml` - Added `web: ^1.1.0` dependency and configured flutter assets section to include `file_drag_drop.js`

### Deleted Files
None

## Key Implementation Details

### JavaScript Bridge (`file_drag_drop.js`)
**Location:** `lib/assets/file_drag_drop.js`

Created a JavaScript class `ChampionFormsDragDrop` that:
- Handles `dragover` events by calling `preventDefault()` and setting `dropEffect` to "copy" to enable dropping
- Handles `dragleave` events to notify Dart when drag exits the drop zone (with target check to avoid child element false positives)
- Handles `drop` events by extracting files from `event.dataTransfer.items` (preferred) or `event.dataTransfer.files` (fallback)
- Filters files based on allowed MIME types before passing to Dart
- Supports wildcard MIME patterns (e.g., "image/*")
- Exposes global `window.championforms_dragdrop` API for Dart interop

**Rationale:** Following the flutter_dropzone pattern ensures a proven, reliable approach. Performing MIME filtering in JavaScript reduces unnecessary data transfer to Dart and improves performance.

### Dart-JS Interop (`file_drag_target_web.dart`)
**Location:** `lib/widgets_internal/platform/file_drag_target_web.dart`

Implemented the `FileDragTarget` widget with `_FileDragTargetWebState`:
- Uses `ui_web.platformViewRegistry.registerViewFactory()` to create HtmlElementView
- Dynamically loads JavaScript file using `ui_web.assetManager.getAssetUrl()` with deferred loading
- Listens for `championforms_dragdrop_ready` event to initialize bridge when JavaScript loads
- Converts file extensions to MIME types using comprehensive mapping (images, documents, text, archives, audio, video)
- Uses `@JS()` annotations to define external JavaScript functions: `_createDragDropZone`, `_setAllowedMimeTypes`, `_setOperation`, `_disposeDragDropZone`
- Handles multiselect configuration by limiting to first file when disabled
- Uses `Stack` with `Positioned.fill` to overlay child widget above platform view with `IgnorePointer` to allow click-through

**Rationale:** The HtmlElementView approach is necessary for web to access native browser drag-drop APIs. Dynamic script loading prevents duplicate script tags. The Stack/IgnorePointer pattern allows visual child widget while platform view handles events.

### FileDragDropFile Web Implementation
**Location:** `lib/widgets_internal/platform/file_drag_target_web.dart` (class `FileDragDropFileWeb`)

Implemented `FileDragDropFileWeb` class wrapping `web.File`:
- Exposes `name`, `size`, `mimeType` (from `web.File.type`), and `lastModified` properties
- Implements `getBytes()` using `web.File.arrayBuffer().toDart` and converts to `Uint8List`
- Handles errors gracefully with try-catch and descriptive error messages

**Rationale:** The FileReader arrayBuffer API is the modern, efficient way to read file contents on web. Error handling ensures robustness when files cannot be read.

### MIME Type Filtering
**Location:** Both JavaScript and Dart implementations

JavaScript side:
- `isAllowedMimeType()` method checks exact matches and wildcard patterns
- Filters files before firing callbacks to Dart
- Fires `onDropInvalid` for rejected files with their MIME type

Dart side:
- `_extensionsToMimeTypes()` converts common extensions (.jpg, .pdf, etc.) to MIME types
- Comprehensive mapping covers 30+ file types across images, documents, text, archives, audio, and video
- Passes MIME array to JavaScript during initialization

**Rationale:** Filtering in JavaScript is more efficient as it prevents unnecessary data transfer. The comprehensive MIME map covers common use cases while allowing easy extension.

### Visual Feedback Implementation
**Location:** `lib/widgets_internal/platform/file_drag_target_web.dart`

Implemented callback methods:
- `_onHover()` - Fires when dragover detected, calls `widget.onHover?.call()`
- `_onLeave()` - Fires when dragleave detected, calls `widget.onLeave?.call()`
- `_onDropFile()` and `_onDropFiles()` - Fire when files successfully dropped

**Rationale:** Simple callback pattern allows parent widget to manage visual state (opacity changes, border highlights, etc.) while keeping drag-drop logic separate.

### Asset Configuration
**Location:** `pubspec.yaml`

Added flutter section with assets configuration:
```yaml
flutter:
  assets:
    - lib/assets/file_drag_drop.js
```

Also added `web: ^1.1.0` dependency for web.File and browser APIs.

**Rationale:** Flutter packages must explicitly declare assets for them to be bundled. The web dependency provides type-safe browser API access.

## Database Changes
N/A - ChampionForms is a frontend-only package with no database.

## Dependencies

### New Dependencies Added
- `web: ^1.1.0` - Provides type-safe web platform APIs (web.File, web.HTMLDivElement, web.window, etc.) for dart:js_interop

### Configuration Changes
- Added `flutter.assets` section to pubspec.yaml to include JavaScript file
- JavaScript file will be bundled with package and loaded at runtime

## Testing

### Test Files Created/Updated
- `example/test/file_drag_target_web_test.dart` - 8 widget and unit tests for web drag-drop

### Test Coverage

**Unit tests:** ✅ Complete (2 tests)
- FileDragDropFile interface existence
- FileDragDropEvent types creation and inheritance

**Widget tests:** ✅ Complete (6 tests)
- Renders child widget correctly
- Fires onHover callback (structure test - actual drag events require browser)
- Fires onLeave callback (structure test - actual drag events require browser)
- Accepts multiselect configuration
- Accepts allowedExtensions configuration
- Disposes without errors

**Integration tests:** ⚠️ Deferred to Task Group 8
- Actual drag-drop with real browser events cannot be tested in Flutter widget tests
- Manual testing and browser-based integration tests required

**Edge cases covered:**
- Widget disposal cleanup
- Configuration acceptance (multiselect, allowedExtensions)
- Event interface compliance

### Manual Testing Performed

Tests run successfully:
```
cd /Users/fabier/Documents/code/championforms/example && flutter test test/file_drag_target_web_test.dart
00:04 +8: All tests passed!
```

All 8 tests passed, verifying:
- Widget renders child correctly
- Configuration properties accepted
- Callbacks can be assigned
- Disposal works without errors
- Event types are properly defined
- Interface exists and is accessible

**Note:** Actual browser drag-drop events require manual testing in a web browser or browser automation tests (Selenium, Puppeteer). This will be performed in Task Group 9 (manual testing) and potentially Task Group 8 (integration tests).

## User Standards & Preferences Compliance

### frontend/components.md
**File Reference:** `agent-os/standards/frontend/components.md`

**How Your Implementation Complies:**
- Used `StatefulWidget` for `FileDragTarget` as it needs to manage internal state (_isJsReady, _container)
- All widget fields marked as `final` for immutability
- Used composition (Stack with Positioned.fill) rather than inheritance
- Included `Key? key` parameter with proper `super.key` forwarding
- Extracted `FileDragDropFileWeb` as separate class following single responsibility
- Used named parameters for all constructor arguments
- Clear widget interface with explicit types and optional/required distinction

**Deviations:** None

### frontend/style.md
**File Reference:** `agent-os/standards/frontend/style.md`

**How Your Implementation Complies:**
- JavaScript asset will be dynamically loaded, no hardcoded styles in widgets
- Visual feedback handled through callbacks, allowing parent widget to control opacity/appearance
- Child widget passed through and rendered, maintaining existing styling
- Platform view uses Stack/IgnorePointer pattern to preserve visual hierarchy

**Deviations:** None

### frontend/accessibility.md
**File Reference:** `agent-os/standards/frontend/accessibility.md`

**How Your Implementation Complies:**
- Drag-drop zone accepts keyboard-triggered file picker as alternative (maintained in existing FileUploadWidget)
- Visual feedback callbacks (onHover, onLeave) allow parent to provide visual cues
- Error handling with descriptive messages for file reading failures
- Child widget overlay with IgnorePointer allows parent to include accessible labels/instructions

**Deviations:** None - Full accessibility implementation handled at FileUploadWidget level (Task Group 6)

### global/coding-style.md
**File Reference:** `agent-os/standards/global/coding-style.md`

**How Your Implementation Complies:**
- Used descriptive method names (`_initializePlatformView`, `_extensionsToMimeTypes`, `_getMimeTypeForExtension`)
- Clear separation of concerns: JavaScript handles events, Dart handles widget lifecycle and data conversion
- Immutable widget properties with final fields
- Clear documentation with dartdoc comments
- Logical grouping of related methods (initialization, callbacks, interop)

**Deviations:** None

### global/error-handling.md
**File Reference:** `agent-os/standards/global/error-handling.md`

**How Your Implementation Complies:**
- Wrapped file byte reading in try-catch with descriptive error message: `throw Exception('Failed to read file bytes: $e')`
- JavaScript error callback `_onError()` logs errors in debug mode using `print()`
- Null checks before disposing JavaScript bridge (`if (_container != null && _isJsReady)`)
- JavaScript checks for null callbacks before invoking them (`if (this.onHover != null)`)

**Deviations:** None

### global/conventions.md
**File Reference:** `agent-os/standards/global/conventions.md`

**How Your Implementation Complies:**
- Used lowercase with underscores for file names (`file_drag_target_web.dart`, `file_drag_drop.js`)
- Private methods prefixed with underscore (`_onLoaded`, `_initializePlatformView`)
- External JS functions marked with `@JS()` annotation and prefixed with underscore
- Clear naming: `FileDragDropFileWeb` indicates web implementation of interface
- Consistent naming patterns across JavaScript and Dart (onHover, onLeave, onDrop)

**Deviations:** None

### testing/test-writing.md
**File Reference:** `agent-os/standards/testing/test-writing.md`

**How Your Implementation Complies:**
- Followed AAA pattern (Arrange-Act-Assert) in all tests
- Descriptive test names explaining what is being tested
- Tests focused on behavior (widget renders, callbacks fire) not implementation
- Used `testWidgets` for widget tests and `test` for unit tests
- Fast unit tests (milliseconds) for event type verification
- Independent tests with no shared state

**Deviations:** Actual drag-drop event simulation not possible in Flutter widget tests (browser-specific behavior). Tests verify structure and configuration; manual/integration testing required for event flow.

## Integration Points

### APIs/Endpoints
N/A - This is a client-side drag-drop implementation with no server communication.

### External Services
N/A - Uses only browser native APIs (dataTransfer, FileReader).

### Internal Dependencies
- Depends on `FileDragDropInterface` and `FileDragDropFile` abstraction from Task Group 3
- Will be used by `FileUploadWidget` in Task Group 6
- Conditional export in `file_drag_target.dart` routes to this implementation on web platform

## Known Issues & Limitations

### Issues
None currently identified.

### Limitations

1. **Browser Drag-Drop Testing**
   - Description: Flutter widget tests cannot simulate native browser drag-drop events
   - Reason: Browser events require actual HTML/JavaScript DOM interaction
   - Future Consideration: Add browser automation tests (Selenium/Puppeteer) in Task Group 8

2. **MIME Type Detection Reliability**
   - Description: Browser-reported MIME types may be incorrect or empty for some files
   - Reason: Browsers rely on file extension or content sniffing, which isn't always accurate
   - Future Consideration: Consider server-side MIME validation if critical for security

3. **Memory Loading**
   - Description: Files loaded entirely into memory (no streaming)
   - Reason: Initial implementation prioritizes simplicity; streaming adds complexity
   - Future Consideration: Document file size limits in Task Group 9; implement streaming in future version if needed

4. **Single Widget Instance per ViewId**
   - Description: Each FileDragTarget instance creates a unique platform view
   - Reason: Platform view registry requires unique viewType strings
   - Future Consideration: This is standard practice and not a real limitation

## Performance Considerations

- JavaScript file loaded only once per app session (checked via `_isJsLibraryLoaded()`)
- Script tag insertion prevented if already exists (checked with `querySelector`)
- MIME filtering happens in JavaScript before data sent to Dart (reduces overhead)
- Files read as ArrayBuffer (efficient binary format) and converted directly to Uint8List
- Each widget instance has unique view ID to avoid conflicts
- Dynamic script loading with defer attribute prevents blocking

## Security Considerations

- Files cannot be accessed without user explicitly dragging them (browser security model)
- No file system paths exposed on web (only file name and contents)
- MIME type filtering provides basic file type validation (not security guarantee)
- JavaScript sandbox prevents arbitrary code execution
- No eval() or innerHTML usage in JavaScript
- File bytes remain in memory only (not persisted)

## Dependencies for Other Tasks

This implementation is a dependency for:
- **Task Group 5:** Desktop implementation will follow same pattern with dart:io instead of web.File
- **Task Group 6:** FileUploadWidget will import and use FileDragTarget widget
- **Task Group 7:** API compatibility tests will verify drag-drop integration with FileModel and FormResults

## Notes

### Design Decisions

1. **Dynamic Script Loading:** Chose to load JavaScript dynamically rather than requiring manual index.html modification. This makes the package easier to use and prevents duplicate script tags.

2. **Extension-to-MIME Mapping:** Implemented comprehensive mapping in Dart rather than relying solely on browser MIME detection. This provides consistent filtering even when browsers report incorrect MIME types.

3. **Callback Pattern:** Used simple callbacks rather than Stream-based events. This matches the existing FileUploadWidget pattern and is easier to understand for package consumers.

4. **Stack/IgnorePointer:** Used Stack to overlay child widget above platform view with IgnorePointer. This allows visual child content while platform view handles events. Alternative approaches (like transparent overlay) would block drag-drop events.

### Future Enhancements

1. Add support for drag-over visual styling directly in FileDragTarget (currently handled by parent)
2. Implement file streaming for large files to reduce memory usage
3. Add progress callbacks for file reading operations
4. Support drag-and-drop reordering of file lists
5. Add support for dragging files out of the application

### Lessons Learned

- Flutter's platform view system requires careful coordination between Dart and JavaScript
- Browser drag-drop API is well-supported but testing requires actual browser environment
- MIME type filtering is more reliable when done on multiple levels (JavaScript + Dart)
- Dynamic asset loading requires understanding of Flutter's asset management system
- The flutter_dropzone pattern is solid and well-suited for this use case
