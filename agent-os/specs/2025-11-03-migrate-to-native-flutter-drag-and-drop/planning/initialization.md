# Initial Spec Idea

## User's Initial Description
**Title**: Migrate from super_drag_and_drop to native Flutter drag and drop

**Description**:
The championforms library currently uses super_drag_and_drop and super_clipboard plugins for file upload functionality. These plugins have fallen into disrepair and no longer compile with recent Flutter builds. We need to migrate to native Flutter drag and drop functionality while maintaining feature parity on both desktop and web platforms.

**Scope**:
- Remove dependencies on super_drag_and_drop and super_clipboard
- Replace with native Flutter DragTarget and Draggable widgets
- Maintain all existing functionality (drag & drop, file picker, multiselect, clearOnUpload, file validation)
- Ensure compatibility with both web and desktop platforms
- Keep file_picker package which is still maintained
- Refactor affected files:
  - lib/models/file_model.dart (remove DataReader dependency)
  - lib/default_fields/fileupload.dart
  - lib/models/field_types/fileupload.dart
  - lib/widgets_internal/field_widgets/file_upload_widget.dart
  - Any other files that depend on these packages

## Metadata
- Date Created: 2025-11-03
- Spec Name: migrate-to-native-flutter-drag-and-drop
- Spec Path: agent-os/specs/2025-11-03-migrate-to-native-flutter-drag-and-drop
