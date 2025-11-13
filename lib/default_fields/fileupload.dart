import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/widgets.dart';

/// Builder function for FileUpload fields using the new StatefulFieldWidget API.
///
/// This simplified builder creates a [FileUploadWidget] which handles all
/// lifecycle management, validation, and change detection automatically.
///
/// The widget provides complete file upload functionality including:
/// - Drag-and-drop file selection
/// - File picker integration
/// - File size and extension validation
/// - Visual file preview
/// - Automatic focus and validation management
Widget buildFileUpload(FieldBuilderContext context) {
  return FileUploadWidget(context: context);
}
