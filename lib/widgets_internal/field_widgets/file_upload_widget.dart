import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/functions/filetype_from_mime.dart';
import 'package:championforms/models/field_types/fileupload.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/mime_filetypes.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/helper_widgets/fading_opacity.dart';
import 'package:championforms/widgets_internal/platform/file_drag_target.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

/// Widget for file upload functionality with drag-and-drop and file picker support.
///
/// Provides a complete file upload interface with:
/// - Drag-and-drop from native file explorers (web and desktop)
/// - File picker dialog for manual selection
/// - File preview with type-based icons
/// - File removal functionality
/// - Visual feedback during drag operations
///
/// ## Memory Considerations
///
/// **IMPORTANT:** Files are loaded entirely into memory. For large file handling:
/// - Recommended maximum file size: 50MB
/// - Consider implementing `maxFileSize` validation in production
/// - Monitor memory usage when allowing large files
/// - Files > 50MB may cause OutOfMemory errors
///
/// See [FileModel] documentation for detailed memory recommendations.
class FileUploadWidget extends StatefulWidget {
  final String id;
  final FormController controller;
  final OptionSelect field;
  final FieldColorScheme currentColors;
  final ValueChanged<bool> onFocusChange;
  final Function(FieldOption? file) onFileOptionChange;

  const FileUploadWidget({
    super.key,
    required this.id,
    required this.controller,
    required this.field,
    required this.currentColors,
    required this.onFocusChange,
    required this.onFileOptionChange,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  FocusNode? _focusNode;
  bool _isDragHovering = false;

  List<FieldOption> _files = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
      widget.onFocusChange(_focusNode!.hasFocus);
    });

    // Initialize current files from controller (check if field exists first)
    final existing = widget.controller.hasField(widget.field.id)
        ? widget.controller.getFieldValue<List<FieldOption>>(widget.field.id) ?? []
        : [];
    _files = List<FieldOption>.from(existing);

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // We'll read from the controller and see if the value changed (check if field exists first)
    final existing = widget.controller.hasField(widget.field.id)
        ? widget.controller.getFieldValue<List<FieldOption>>(widget.field.id) ?? []
        : [];
    if (existing.length != _files.length) {
      setState(() {
        _files = List<FieldOption>.from(existing);
      });
    } else {
      // Check if any mismatch
      bool different = false;
      for (int i = 0; i < existing.length; i++) {
        if (existing[i].value != _files[i].value) {
          different = true;
          break;
        }
      }
      if (different) {
        setState(() {
          _files = List<FieldOption>.from(existing);
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode?.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _validateLive() {
    if (widget.field.validateLive) {
      FormResults.getResults(
          controller: widget.controller, fields: [widget.field]);
    }
  }

  void _showFileSizeError(String fileName, int fileSize, int maxFileSize) {
    // Format file sizes in a human-readable way
    String formatBytes(int bytes) {
      if (bytes < 1024) return '$bytes B';
      if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'File "$fileName" is too large (${formatBytes(fileSize)}). '
          'Maximum allowed size is ${formatBytes(maxFileSize)}.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _pickFiles() async {
    // If multiselect is true, allow multiple. Otherwise single
    FilePickerResult? result;

    final fileType;
    final allowedExtensions;

    if ((widget.field as FileUpload).allowedExtensions != null) {
      fileType = FileType.custom;
      allowedExtensions =
          (widget.field as FileUpload).allowedExtensions;
    } else {
      fileType = FileType.any;
      allowedExtensions = null;
    }

    if (widget.field.multiselect) {
      result = await FilePicker.platform.pickFiles(
          type: fileType,
          allowedExtensions: allowedExtensions,
          allowMultiple: true);
    } else {
      result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
      );
    }

    if (result != null) {
      // Clear existing files if clearOnUpload is true
      if ((widget.field as FileUpload).clearOnUpload) {
        _files.clear();
        widget.controller.updateMultiselectValues(
          widget.field.id,
          [],
          overwrite: true,
          noOnChange: true,
        );
      }

      // Add new files
      final List<XFile> pickedFiles = result.xFiles;
      for (final xfile in pickedFiles) {
        await _addFile(xfile);
      }
    }
  }

  Future<void> _handleDroppedFile(XFile droppedFile, {bool isFirstFile = false}) async {
    try {
      final name = droppedFile.name;

      // Validate file size if maxFileSize is specified
      final maxFileSize = (widget.field as FileUpload).maxFileSize;
      if (maxFileSize != null) {
        final fileSize = await droppedFile.length();
        if (fileSize > maxFileSize) {
          _showFileSizeError(name, fileSize, maxFileSize);
          return;
        }
      }

      // Clear existing files if clearOnUpload is true and this is the first dropped file
      if ((widget.field as FileUpload).clearOnUpload && isFirstFile) {
        setState(() {
          _files.clear();
        });
        widget.controller.updateMultiselectValues(
          widget.field.id,
          [],
          overwrite: true,
          noOnChange: true,
        );
      }

      // Read file bytes
      final Uint8List fileBytes = await droppedFile.readAsBytes();

      final path = droppedFile.path;

      // Create filemodel for storage
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

      setState(() {
        // Only the last option is kept if multiselect is turned off.
        if (!widget.field.multiselect) {
          _files.clear();
        }
        _files.add(option);

        widget.controller.updateMultiselectValues(
          widget.field.id,
          _files,
          multiselect: widget.field.multiselect,
          overwrite: true,
          noOnChange: true,
        );
        // Report back that a file has been uploaded
        widget.onFileOptionChange(option);

        // if validate live then run validation
        _validateLive();
      });
    } catch (e) {
      // Couldn't read the file for some reason - fail silently
      // In production, consider logging to error reporting service
    }
  }

  Future<void> _addFile(XFile xfile) async {
    final name = xfile.name;
    final path = xfile.path;

    // Validate file size if maxFileSize is specified
    final maxFileSize = (widget.field as FileUpload).maxFileSize;
    if (maxFileSize != null) {
      final fileSize = await xfile.length();
      if (fileSize > maxFileSize) {
        _showFileSizeError(name, fileSize, maxFileSize);
        return;
      }
    }

    final bytes = await xfile.readAsBytes();

    // Create filemodel for storage
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

    setState(() {
      if (!widget.field.multiselect) {
        // clear existing
        _files.clear();
      }
      _files.add(option);
      widget.controller.updateMultiselectValues(
        widget.field.id,
        _files,
        multiselect: widget.field.multiselect,
        overwrite: true,
        noOnChange: true,
      );
      // Let the builder know
      widget.onFileOptionChange(option);

      // if validate live then run validation
      _validateLive();
    });
  }

  IconData _getFileIcon(FieldOption opt) {
    final mimeType =
        getFileType((opt.additionalData as FileModel).mimeData?.mime ?? "");
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
    setState(() {
      _files.remove(opt);
    });
    widget.controller.updateMultiselectValues(
      widget.field.id,
      _files,
      multiselect: widget.field.multiselect,
      overwrite: true,
    );
    widget.onFileOptionChange(null);

    // if validate live then run validation
    _validateLive();
  }

  @override
  Widget build(BuildContext context) {
    // We'll show a container with drag-n-drop overlay, plus
    // a button to pick files. Then the list of files displayed as icons.

    return FileDragTarget(
      allowedExtensions: (widget.field as FileUpload).allowedExtensions,
      multiselect: widget.field.multiselect,
      onDrop: (files) async {
        // Handle dropped files
        bool isFirst = true;
        for (final file in files) {
          await _handleDroppedFile(file, isFirstFile: isFirst);
          isFirst = false;
        }
        // Reset hover state after drop
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
        focusNode: _focusNode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: (widget.currentColors.textBackgroundColor ??
                    widget.currentColors.backgroundColor)
                .withValues(alpha: _isDragHovering ? 0.8 : 1.0),
            border: Border.all(
              color: widget.currentColors.borderColor,
              width: widget.currentColors.borderSize.toDouble(),
            ),
            borderRadius: widget.currentColors.borderRadius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              InkWell(
                onTap: _pickFiles,
                child: (widget.field as FileUpload).dropDisplayWidget !=
                        null
                    ? (widget.field as FileUpload).dropDisplayWidget!(
                        widget.currentColors,
                        widget.field as FileUpload)
                    : DropZoneWidget(
                        field: widget.field as FileUpload,
                        currentColors: widget.currentColors),
              ),
              if ((widget.field as FileUpload).displayUploadedFiles)
                const SizedBox(height: 8),
              // Show file previews
              if ((widget.field as FileUpload).displayUploadedFiles)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _files.map((opt) {
                    final iconAsset = _getFileIcon(opt);
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconAsset,
                                size: 48,
                                color: widget.currentColors.iconColor),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 80,
                              child: Text(
                                opt.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: widget.currentColors.textColor,
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
                                  color:
                                      widget.currentColors.textBackgroundColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  color: widget.currentColors.iconColor,
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

class DropZoneWidget extends StatelessWidget {
  const DropZoneWidget({
    super.key,
    required this.currentColors,
    required this.field,
  });

  /// Current Field Colors (changes as field state changes)
  final FieldColorScheme currentColors;

  /// Field settings
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
