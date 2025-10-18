import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/functions/filetype_from_mime.dart';
import 'package:championforms/models/field_types/championfileupload.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/mime_filetypes.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_external/helper_widgets/fading_opacity.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'dart:typed_data';

class FileUploadWidget extends StatefulWidget {
  final String id;
  final ChampionFormController controller;
  final ChampionOptionSelect field;
  final FieldColorScheme currentColors;
  final ValueChanged<bool> onFocusChange;
  final Function(MultiselectOption? file) onFileOptionChange;

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
  bool _hovering = false;

  List<MultiselectOption> _files = [];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode!.addListener(() {
      widget.onFocusChange(_focusNode!.hasFocus);
    });

    // Initialize current files from controller (check if field exists first)
    final existing = widget.controller.hasField(widget.field.id)
        ? widget.controller.getFieldValue<List<MultiselectOption>>(widget.field.id) ?? []
        : [];
    _files = List<MultiselectOption>.from(existing);

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // We'll read from the controller and see if the value changed (check if field exists first)
    final existing = widget.controller.hasField(widget.field.id)
        ? widget.controller.getFieldValue<List<MultiselectOption>>(widget.field.id) ?? []
        : [];
    if (existing.length != _files.length) {
      setState(() {
        _files = List<MultiselectOption>.from(existing);
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
          _files = List<MultiselectOption>.from(existing);
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

  Future<void> _pickFiles() async {
    // If multiselect is true, allow multiple. Otherwise single
    FilePickerResult? result;

    final fileType;
    final allowedExtensions;

    if ((widget.field as ChampionFileUpload).allowedExtensions != null) {
      fileType = FileType.custom;
      allowedExtensions =
          (widget.field as ChampionFileUpload).allowedExtensions;
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
      if ((widget.field as ChampionFileUpload).clearOnUpload) {
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

  Future<void> _handleDroppedFile(DataReader reader, {bool isFirstFile = false}) async {
    // Pick a default name. We'll replace this in a moment
    String name = "untitled";

    // We are going to skip streams for now
    // This seems like a good idea for speed and reliability
    // but for the time being we will only load the entire file into memory.
    // This might cause lag, so we should try to get a stream working in the future.
    // Stream<Uint8List>? stream;
    // // This might be from Desktop or other app
    // reader.getFile(null, (file) {
    //   stream = file.getStream();
    // });
    final fileReader = reader;

    name = await fileReader.getSuggestedName() ?? "untitled";

    if ((widget.field as ChampionFileUpload).allowedExtensions != null) {
      bool foundExtension = false;
      for (final ext
          in (widget.field as ChampionFileUpload).allowedExtensions!) {
        if (name.toLowerCase().endsWith('.' + ext.toLowerCase())) {
          foundExtension = true;
          break;
        }
      }
      if (!foundExtension) {
        return;
      }
    }

    // Clear existing files if clearOnUpload is true and this is the first dropped file
    if ((widget.field as ChampionFileUpload).clearOnUpload && isFirstFile) {
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

    fileReader.getFile(null, (file) async {
      try {
        final Uint8List fileBytes = await file.readAll();

        final path = "$name-drag"; // We can store something as path

        // Create filemodel for storage
        FileModel fileData = FileModel(
          fileName: name,
          //fileStream: stream,
          fileBytes: fileBytes,
          fileReader: reader,
          uploadExtension: name.split('.').lastOrNull ?? '',
        );

        fileData = fileData.copyWith(mimeData: await fileData.readMimeData());

        final option = MultiselectOption(
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
        // Couldn't read the file for some reason
        debugPrint("Error Reading File Data: $e");
      }
    });
  }

  Future<void> _addFile(XFile xfile) async {
    final name = xfile.name;
    final path = xfile.path;
    final bytes = await xfile.readAsBytes();

    // Create filemodel for storage
    FileModel fileData = FileModel(
      fileName: name,
      uploadExtension: name.split('.').lastOrNull ?? '',
      fileBytes: bytes,
    );

    fileData = fileData.copyWith(mimeData: await fileData.readMimeData());

    final option = MultiselectOption(
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

  IconData _getFileIcon(MultiselectOption opt) {
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

  void _removeFile(MultiselectOption opt) {
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

    return DropRegion(
      formats: Formats.standardFormats,
      onDropOver: (event) {
        // we just say copy for everything
        return DropOperation.copy;
      },
      onDropEnter: (event) {
        setState(() {
          _hovering = true;
        });
      },
      onDropLeave: (event) {
        setState(() {
          _hovering = false;
        });
      },
      onPerformDrop: (event) async {
        if (!widget.field.multiselect) {
          final reader = event.session.items.firstOrNull?.dataReader;
          if (reader != null) {
            await _handleDroppedFile(reader, isFirstFile: true);
            return;
          }
        } else {
          // If Multiselect is true then lets do all the files
          bool isFirst = true;
          for (final item in event.session.items) {
            final reader = item.dataReader!;
            // We'll handle images or files

            // We'll attempt to get a "file" from the item
            await _handleDroppedFile(reader, isFirstFile: isFirst);
            isFirst = false;
          }
        }
      },
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: (widget.currentColors.textBackgroundColor ??
                    widget.currentColors.backgroundColor)
                .withValues(alpha: _hovering ? 0.8 : 1.0),
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
                child: (widget.field as ChampionFileUpload).dropDisplayWidget !=
                        null
                    ? (widget.field as ChampionFileUpload).dropDisplayWidget!(
                        widget.currentColors,
                        widget.field as ChampionFileUpload)
                    : DropZoneWidget(
                        field: widget.field as ChampionFileUpload,
                        currentColors: widget.currentColors),
              ),
              if ((widget.field as ChampionFileUpload).displayUploadedFiles)
                const SizedBox(height: 8),
              // Show file previews
              if ((widget.field as ChampionFileUpload).displayUploadedFiles)
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
  final ChampionFileUpload field;

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
        padding: EdgeInsets.all(20),
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
