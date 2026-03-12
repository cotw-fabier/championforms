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
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    // Ensure field value is initialized (StatefulFieldWidget protects from race)
    ctx.getValue<List<FieldOption>>();

    // Delegate to content widget which reads files directly from controller
    return _FileUploadContent(context: ctx);
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
///
/// Reads files directly from the controller to avoid stale state issues.
/// Listens to the controller directly to ensure rebuilds happen immediately
/// when files are added/removed, regardless of parent widget rebuild timing.
class _FileUploadContent extends StatefulWidget {
  final FieldBuilderContext context;

  const _FileUploadContent({
    required this.context,
  });

  @override
  _FileUploadContentState createState() => _FileUploadContentState();
}

class _FileUploadContentState extends State<_FileUploadContent> {
  bool _isDragHovering = false;

  /// Read the current files directly from the controller (never stale).
  List<FieldOption> get _files =>
      widget.context.getValue<List<FieldOption>>() ?? [];

  @override
  void initState() {
    super.initState();
    widget.context.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(_FileUploadContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context.controller != widget.context.controller) {
      oldWidget.context.controller.removeListener(_onControllerChanged);
      widget.context.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.context.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

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

  /// Resolves whether to use the native image picker (photo gallery) or file picker (file browser).
  bool _shouldUseImagePicker(FileUpload field) {
    if (field.useImagePicker != null) return field.useImagePicker!;
    // Auto-detect: use image_picker for image/video file types on mobile
    return field.fileType == FileType.image || field.fileType == FileType.video;
  }

  Future<void> _pickFiles() async {
    final field = widget.context.field as FileUpload;

    // Use native image picker on mobile platforms for image/video types
    if (!kIsWeb && _shouldUseImagePicker(field)) {
      await _pickWithImagePicker(field);
    } else {
      await _pickWithFilePicker(field);
    }
  }

  /// Reads an [XFile], validates size, and returns a [FieldOption] or null if invalid.
  Future<FieldOption?> _buildFileOption(XFile xfile, FileUpload field) async {
    final name = xfile.name;

    // Validate file size
    if (field.maxFileSize != null) {
      final fileSize = await xfile.length();
      if (fileSize > field.maxFileSize!) {
        _showFileSizeError(name, fileSize, field.maxFileSize!);
        return null;
      }
    }

    final bytes = await xfile.readAsBytes();

    FileModel fileData = FileModel(
      fileName: name,
      uploadExtension: name.split('.').lastOrNull ?? '',
      fileBytes: bytes,
    );

    fileData = fileData.copyWith(mimeData: await fileData.readMimeData());

    return FieldOption(
      label: name,
      value: const Uuid().v4(),
      additionalData: fileData,
    );
  }

  Future<void> _pickWithImagePicker(FileUpload field) async {
    final picker = ImagePicker();
    List<XFile> picked;

    if (field.multiselect) {
      if (field.fileType == FileType.video) {
        // image_picker doesn't support multi-video; pick single video
        final video = await picker.pickVideo(source: ImageSource.gallery);
        picked = video != null ? [video] : [];
      } else {
        picked = await picker.pickMultiImage();
      }
    } else {
      XFile? single;
      if (field.fileType == FileType.video) {
        single = await picker.pickVideo(source: ImageSource.gallery);
      } else {
        single = await picker.pickImage(source: ImageSource.gallery);
      }
      picked = single != null ? [single] : [];
    }

    if (picked.isNotEmpty) {
      // Build all options first, then set once
      final baseFiles = field.clearOnUpload
          ? <FieldOption>[]
          : (widget.context.getValue<List<FieldOption>>() ?? []);

      final newOptions = <FieldOption>[];
      for (final xfile in picked) {
        final option = await _buildFileOption(xfile, field);
        if (option != null) newOptions.add(option);
      }

      if (newOptions.isNotEmpty) {
        final finalFiles = field.multiselect
            ? [...baseFiles, ...newOptions]
            : [newOptions.last];
        widget.context.setValue(finalFiles);
      }
    }
  }

  Future<void> _pickWithFilePicker(FileUpload field) async {
    FilePickerResult? result;

    FileType fileType;
    List<String>? allowedExtensions;

    if (field.fileType != null) {
      fileType = field.fileType!;
      allowedExtensions = null;
      if (field.allowedExtensions != null) {
        debugPrint('Warning: FileUpload "${field.id}" has both fileType and allowedExtensions set. '
            'fileType takes priority; allowedExtensions will be ignored.');
      }
    } else if (field.allowedExtensions != null) {
      fileType = FileType.custom;
      allowedExtensions = field.allowedExtensions;
    } else {
      fileType = FileType.any;
      allowedExtensions = null;
    }

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
      // Build all options first, then set once
      final baseFiles = field.clearOnUpload
          ? <FieldOption>[]
          : (widget.context.getValue<List<FieldOption>>() ?? []);

      final newOptions = <FieldOption>[];
      for (final xfile in result.xFiles) {
        final option = await _buildFileOption(xfile, field);
        if (option != null) newOptions.add(option);
      }

      if (newOptions.isNotEmpty) {
        final finalFiles = field.multiselect
            ? [...baseFiles, ...newOptions]
            : [newOptions.last];
        widget.context.setValue(finalFiles);
      }
    }
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
    // Read fresh from controller
    final currentFiles = widget.context.getValue<List<FieldOption>>() ?? [];
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
        final field = widget.context.field as FileUpload;

        // Build all options first, then set once
        final baseFiles = field.clearOnUpload
            ? <FieldOption>[]
            : (widget.context.getValue<List<FieldOption>>() ?? []);

        final newOptions = <FieldOption>[];
        for (final droppedFile in files) {
          final option = await _buildFileOption(droppedFile, field);
          if (option != null) newOptions.add(option);
        }

        if (newOptions.isNotEmpty) {
          final finalFiles = field.multiselect
              ? [...baseFiles, ...newOptions]
              : [newOptions.last];
          widget.context.setValue(finalFiles);
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
                  children: _files.map((opt) {
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
