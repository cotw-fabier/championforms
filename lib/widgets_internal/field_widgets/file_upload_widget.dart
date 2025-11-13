import 'package:championforms/functions/filetype_from_mime.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/fileupload.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/mime_filetypes.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/helper_widgets/fading_opacity.dart';
import 'package:championforms/widgets_external/stateful_field_widget.dart';
import 'package:championforms/widgets_internal/platform/file_drag_target.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:championforms/championforms_themes.dart';

/// FileUpload widget using [StatefulFieldWidget].
///
/// This widget provides complete file upload functionality with:
/// - Drag-and-drop from native file explorers (web and desktop)
/// - File picker dialog for manual selection
/// - File preview with type-based icons
/// - File removal functionality
/// - Visual feedback during drag operations
/// - Automatic focus and validation management via [StatefulFieldWidget]
///
/// ## Memory Considerations
///
/// **IMPORTANT:** Files are loaded entirely into memory. For large file handling:
/// - Recommended maximum file size: 50MB (configurable via `maxFileSize`)
/// - Monitor memory usage when allowing large files
/// - Files > 50MB may cause OutOfMemory errors
///
/// See [FileModel] documentation for detailed memory recommendations.
class FileUploadWidget extends StatefulFieldWidget {
  const FileUploadWidget({
    required super.context,
    super.key,
  });

  @override
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  ) {
    // Read value here where StatefulFieldWidget protects us from initialization race
    final files = ctx.getValue<List<FieldOption>>() ?? [];

    // Delegate to content widget which handles local UI state
    return _FileUploadContent(context: ctx, files: files);
  }

  @override
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Trigger onChange callback if defined
    final field = context.field as FileUpload;
    if (field.onChange != null) {
      final results = FormResults.getResults(
        controller: context.controller,
        fields: [context.field],
      );
      field.onChange!(results);
    }
  }
}

/// Internal content widget that manages drag-hover UI state.
class _FileUploadContent extends StatefulWidget {
  final FieldBuilderContext context;
  final List<FieldOption> files;

  const _FileUploadContent({
    required this.context,
    required this.files,
  });

  @override
  _FileUploadContentState createState() => _FileUploadContentState();
}

class _FileUploadContentState extends State<_FileUploadContent> {
  bool _isDragHovering = false;

  void _showInlineError(String message) {
    // Use FormController's error system (user decision)
    widget.context.addError(message);
  }

  void _showFileSizeError(String fileName, int fileSize, int maxFileSize) {
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    _showInlineError(
      'File "$fileName" is too large (${formatBytes(fileSize)}). '
      'Maximum allowed size is ${formatBytes(maxFileSize)}.',
    );
  }

  Future<void> _pickFiles() async {
    final field = widget.context.field as FileUpload;
    FilePickerResult? result;

    final fileType = field.allowedExtensions != null ? FileType.custom : FileType.any;
    final allowedExtensions = field.allowedExtensions;

    if (field.multiselect) {
      result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );
    }

    if (result != null) {
      // Clear existing files if clearOnUpload is true
      if (field.clearOnUpload) {
        widget.context.setValue(<FieldOption>[], noNotify: true);
      }

      // Add new files
      for (final xfile in result.xFiles) {
        await _addFile(xfile);
      }
    }
  }

  Future<void> _handleDroppedFile(XFile droppedFile, {bool isFirstFile = false}) async {
    try {
      final field = widget.context.field as FileUpload;
      final name = droppedFile.name;

      // Validate file size
      if (field.maxFileSize != null) {
        final fileSize = await droppedFile.length();
        if (fileSize > field.maxFileSize!) {
          _showFileSizeError(name, fileSize, field.maxFileSize!);
          return;
        }
      }

      // Clear existing files if clearOnUpload and first file
      if (field.clearOnUpload && isFirstFile) {
        widget.context.setValue(<FieldOption>[], noNotify: true);
      }

      // Read file bytes
      final Uint8List fileBytes = await droppedFile.readAsBytes();
      final path = droppedFile.path;

      // Create FileModel
      FileModel fileData = FileModel(
        fileName: name,
        fileBytes: fileBytes,
        uploadExtension: name.split('.').lastOrNull ?? '',
      );

      fileData = fileData.copyWith(mimeData: await fileData.readMimeData());

      final option = FieldOption(
        label: name,
        value: path,
        additionalData: fileData,
      );

      // Update value
      final currentFiles = widget.files;
      final newFiles = field.multiselect
          ? [...currentFiles, option]
          : [option];

      widget.context.setValue(newFiles);
    } catch (e) {
      // Fail silently
    }
  }

  Future<void> _addFile(XFile xfile) async {
    final field = widget.context.field as FileUpload;
    final name = xfile.name;
    final path = xfile.path;

    // Validate file size
    if (field.maxFileSize != null) {
      final fileSize = await xfile.length();
      if (fileSize > field.maxFileSize!) {
        _showFileSizeError(name, fileSize, field.maxFileSize!);
        return;
      }
    }

    final bytes = await xfile.readAsBytes();

    // Create FileModel
    FileModel fileData = FileModel(
      fileName: name,
      uploadExtension: name.split('.').lastOrNull ?? '',
      fileBytes: bytes,
    );

    fileData = fileData.copyWith(mimeData: await fileData.readMimeData());

    final option = FieldOption(
      label: name,
      value: path,
      additionalData: fileData,
    );

    // Update value
    final currentFiles = widget.files;
    final newFiles = field.multiselect
        ? [...currentFiles, option]
        : [option];

    widget.context.setValue(newFiles);
  }

  IconData _getFileIcon(FieldOption opt) {
    final mimeType = getFileType((opt.additionalData as FileModel).mimeData?.mime ?? "");
    switch (mimeType) {
      case MimeFileType.htmlOrCode:
        return Icons.code;
      case MimeFileType.plainText:
        return Icons.text_snippet;
      case MimeFileType.document:
        return Icons.description;
      case MimeFileType.image:
        return Icons.image;
      case MimeFileType.video:
        return Icons.videocam;
      case MimeFileType.audio:
        return Icons.audiotrack;
      case MimeFileType.executable:
        return Icons.build;
      case MimeFileType.archive:
        return Icons.archive;
      case MimeFileType.other:
        return Icons.insert_drive_file;
    }
  }

  void _removeFile(FieldOption opt) {
    final currentFiles = widget.files;
    final newFiles = currentFiles.where((f) => f.value != opt.value).toList();
    widget.context.setValue(newFiles);
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.context.field as FileUpload;
    final focusNode = widget.context.getFocusNode();
    final colors = widget.context.colors;

    return FileDragTarget(
      allowedExtensions: field.allowedExtensions,
      multiselect: field.multiselect,
      onDrop: (files) async {
        bool isFirst = true;
        for (final file in files) {
          await _handleDroppedFile(file, isFirstFile: isFirst);
          isFirst = false;
        }
        setState(() {
          _isDragHovering = false;
        });
      },
      onHover: () {
        setState(() {
          _isDragHovering = true;
        });
      },
      onLeave: () {
        setState(() {
          _isDragHovering = false;
        });
      },
      child: Focus(
        focusNode: focusNode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: (colors.textBackgroundColor ?? colors.backgroundColor)
                .withValues(alpha: _isDragHovering ? 0.8 : 1.0),
            border: Border.all(
              color: colors.borderColor,
              width: colors.borderSize.toDouble(),
            ),
            borderRadius: colors.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Upload zone
              InkWell(
                onTap: _pickFiles,
                child: field.dropDisplayWidget != null
                    ? field.dropDisplayWidget!(colors, field)
                    : DropZoneWidget(
                        field: field,
                        currentColors: colors,
                      ),
              ),
              if (field.displayUploadedFiles) const SizedBox(height: 8),
              // File previews
              if (field.displayUploadedFiles)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.files.map((opt) {
                    final iconAsset = _getFileIcon(opt);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconAsset, size: 48, color: colors.iconColor),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: Text(
                                opt.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colors.textColor,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          right: -4,
                          top: -4,
                          child: InkWell(
                            onTap: () => _removeFile(opt),
                            child: FadingWidget(
                              child: Container(
                                padding: const EdgeInsets.all(2.0),
                                decoration: BoxDecoration(
                                  color: colors.textBackgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: colors.iconColor,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drop zone display widget for file upload.
class DropZoneWidget extends StatelessWidget {
  const DropZoneWidget({
    super.key,
    required this.currentColors,
    required this.field,
  });

  final FieldColorScheme currentColors;
  final FileUpload field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: currentColors.borderColor,
            width: currentColors.borderSize.toDouble(),
            style: BorderStyle.solid,
          ),
          borderRadius: currentColors.borderRadius,
        ),
        foregroundDecoration: BoxDecoration(
          border: Border.all(
            color: currentColors.borderColor,
            width: currentColors.borderSize.toDouble(),
            style: BorderStyle.solid,
          ),
          borderRadius: currentColors.borderRadius,
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.upload_file,
              color: currentColors.iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              "Upload File",
              style: TextStyle(color: currentColors.textColor),
            ),
          ],
        ),
      ),
    );
  }
}
