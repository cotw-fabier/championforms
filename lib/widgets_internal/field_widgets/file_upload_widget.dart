import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formfieldclass.dart';
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
  final FieldState currentState;
  final FieldColorScheme currentColors;
  final List<String> defaultValue;
  final ValueChanged<bool> onFocusChange;
  final ValueChanged<MultiselectOption?> onFileOptionChange;

  const FileUploadWidget({
    Key? key,
    required this.id,
    required this.controller,
    required this.field,
    required this.currentState,
    required this.currentColors,
    required this.defaultValue,
    required this.onFocusChange,
    required this.onFileOptionChange,
  }) : super(key: key);

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

    // Initialize current files from controller
    final existing =
        widget.controller.findMultiselectValue(widget.field.id)?.values ?? [];
    _files = List<MultiselectOption>.from(existing);

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    // We'll read from the controller and see if the value changed
    final existing =
        widget.controller.findMultiselectValue(widget.field.id)?.values ?? [];
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

  Future<void> _pickFiles() async {
    // If multiselect is true, allow multiple. Otherwise single
    FilePickerResult? result;
    if (widget.field.multiselect) {
      result = await FilePicker.platform.pickFiles(allowMultiple: true);
    } else {
      result = await FilePicker.platform.pickFiles();
    }

    if (result != null) {
      final List<XFile> pickedFiles = result.xFiles;
      for (final xfile in pickedFiles) {
        await _addFile(xfile);
      }
    }
  }

  Future<void> _addFile(XFile xfile) async {
    final name = xfile.name;
    final path = xfile.path;
    final bytes = await xfile.readAsBytes();

    final option = MultiselectOption(
      label: name,
      value: path,
      additionalData: bytes,
    );

    if (!widget.field.multiselect) {
      // clear existing
      _files.clear();
    }
    _files.add(option);

    widget.controller.updateMultiselectValues(
      widget.field.id,
      [option],
      multiselect: widget.field.multiselect,
    );
    // Let the builder know
    widget.onFileOptionChange(option);
    setState(() {});
  }

  String _getFileIcon(MultiselectOption opt) {
    // Attempt to parse extension to choose an icon
    final label = opt.label.toLowerCase();
    if (label.endsWith(".png") ||
        label.endsWith(".jpg") ||
        label.endsWith(".jpeg") ||
        label.endsWith(".gif")) {
      return "assets/image.png";
    } else if (label.endsWith(".pdf")) {
      return "assets/pdf.png";
    } else if (label.endsWith(".doc") || label.endsWith(".docx")) {
      return "assets/document.png";
    } else if (label.endsWith(".xls") || label.endsWith(".xlsx")) {
      return "assets/excel.png";
    } else if (label.endsWith(".csv")) {
      return "assets/csv.png";
    } else if (label.endsWith(".txt")) {
      return "assets/document.png";
    }
    return "assets/file.png";
  }

  void _removeFile(MultiselectOption opt) {
    setState(() {
      _files.remove(opt);
    });
    widget.controller.updateMultiselectValues(
      widget.field.id,
      _files,
      multiselect: widget.field.multiselect,
    );
    widget.onFileOptionChange(null);
  }

  @override
  Widget build(BuildContext context) {
    // We'll show a container with drag-n-drop overlay, plus
    // a button to pick files. Then the list of files displayed as icons.
    final theme = Theme.of(context);

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
        for (final item in event.session.items) {
          final reader = item.dataReader!;
          // We'll handle images or files
          if (reader.canProvide(Formats.png) ||
              reader.canProvide(Formats.jpeg) ||
              reader.canProvide(Formats.fileUri) ||
              reader.canProvide(Formats.plainTextFile)) {
            // We'll attempt to get a "file" from the item
            await _handleDroppedFile(reader);
          }
        }
      },
      child: Focus(
        focusNode: _focusNode,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: widget.currentColors.backgroundColor
                .withOpacity(_hovering ? 0.8 : 1.0),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _pickFiles,
                    child: Row(
                      children: [
                        Icon(Icons.upload_file,
                            color: widget.currentColors.iconColor),
                        const SizedBox(width: 8),
                        Text(
                          "Upload File",
                          style:
                              TextStyle(color: widget.currentColors.textColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Show file previews
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
                          Image.asset(
                            iconAsset,
                            width: 64,
                            height: 64,
                            errorBuilder: (ctx, err, stack) {
                              // fallback icon
                              return Icon(Icons.insert_drive_file,
                                  size: 48,
                                  color: widget.currentColors.iconColor);
                            },
                          ),
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
                                color: theme.colorScheme.error,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: theme.colorScheme.onError,
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

  Future<void> _handleDroppedFile(DataReader reader) async {
    // We'll pick the first recognized format
    Uint8List? fileBytes;
    String name = "untitled";

    if (reader.canProvide(Formats.fileUri)) {
      // This might be from Desktop or other app
      reader.getFile(null, (file) {
        final stream = file.getStream();
      });
      final file = reader;
      if (file != null) {
        fileBytes = await file.readAll();
        name = file.fileName ?? "untitled";
      }
    } else if (reader.canProvide(Formats.png)) {
      final file = await reader.getFile(Formats.png);
      if (file != null) {
        fileBytes = await file.readAll();
        name = file.fileName ?? "untitled.png";
      }
    } else if (reader.canProvide(Formats.jpeg)) {
      final file = await reader.getFile(Formats.jpeg);
      if (file != null) {
        fileBytes = await file.readAll();
        name = file.fileName ?? "untitled.jpg";
      }
    } else if (reader.canProvide(Formats.plainTextFile)) {
      final file = await reader.getFile(Formats.plainTextFile);
      if (file != null) {
        fileBytes = await file.readAll();
        name = file.fileName ?? "untitled.txt";
      }
    }

    if (fileBytes != null) {
      final path = "$name-drag"; // We can store something as path
      final option = MultiselectOption(
        label: name,
        value: path,
        additionalData: fileBytes,
      );

      if (!widget.field.multiselect) {
        _files.clear();
      }
      _files.add(option);

      widget.controller.updateMultiselectValues(
        widget.field.id,
        [option],
        multiselect: widget.field.multiselect,
      );
      widget.onFileOptionChange(option);
      setState(() {});
    }
  }
}
