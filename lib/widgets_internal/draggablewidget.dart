// This widget allows to dynamically insert drag and drop functionality.
import 'package:flutter/material.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class ConditionalDraggableDropZone extends StatefulWidget {
  const ConditionalDraggableDropZone({
    super.key,
    required this.child,
    this.draggable = true,
    this.onDrop,
    this.formats,
    this.controller,
    this.formId = "",
    this.fieldId = "",
  });

  final Widget child;
  final bool draggable;
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onDrop;
  final List<DataFormat<Object>>? formats;

  //final fleather.FleatherController? fletherController;
  final TextEditingController? controller;
  final String formId;
  final String fieldId;

  State<StatefulWidget> createState() => _ConditionalDraggableDropZoneState();
}

class _ConditionalDraggableDropZoneState
    extends State<ConditionalDraggableDropZone> {
  late bool _dropReturn;

  @override
  void initState() {
    super.initState();
    _dropReturn = false;
  }

  void updateTextField(String text) {
    if (widget.controller != null) {
      final selection = widget.controller!.selection;
      final newText = widget.controller!.text
          .replaceRange(selection.start, selection.end, text);
      widget.controller!.text = newText;
      widget.controller!.selection =
          TextSelection.collapsed(offset: selection.start + text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    // set default formats
    final defaultFormats = widget.formats ?? [...Formats.standardFormats];

    if (widget.draggable) {
      return DropRegion(
        hitTestBehavior: HitTestBehavior.opaque,
        onPerformDrop: (event) async {
          if (widget.onDrop != null) {
            widget.onDrop!(
              //fleatherController: widget.fletherController,
              formId: widget.formId,
              fieldId: widget.fieldId,
            );
          } else {
            for (final item in event.session.items) {
              final reader = item.dataReader!;
              debugPrint(
                  "Dropped Item Type: ${reader.getFormats(Formats.standardFormats)}");

              // Lets Step Through Pasting Content into a field.

              // Start with HTML then move to non-html
              if (reader.canProvide(Formats.htmlFile) ||
                  reader.canProvide(Formats.htmlText)) {
                if (reader.canProvide(Formats.htmlFile)) {
                  reader.getFile(null, (file) async {
                    final fileData = await file.readAll();
                    final value = String.fromCharCodes(fileData);

                    // Return plain text to the controller.
                    updateTextField(value.toString());
                  });
                } else {
                  // HTML Content Dragged in
                  reader.getValue(Formats.htmlText, (value) {
                    // Return plain text to the controller.
                    if (value != null) {
                      updateTextField(value.toString());
                    }
                  });
                }
              } else if (reader.canProvide(Formats.plainTextFile) ||
                  reader.canProvide(Formats.plainText)) {
                if (reader.canProvide(Formats.plainTextFile)) {
                  reader.getFile(null, (file) async {
                    debugPrint("File Dropped: ${file.fileName}");
                    final fileData = await file.readAll();
                    final value = String.fromCharCodes(fileData);
                    // Return plain text to the controller.
                    updateTextField(value);
                  });
                } else {
                  reader.getValue(Formats.plainText, (value) {
                    // Return plain text to the controller.
                    if (value != null) {
                      updateTextField(value);
                    }
                  });
                }
              }
            }
          }
        },
        formats: defaultFormats,
        onDropOver: (event) async {
          // We want to animate in a border of some kind.
          return DropOperation.copy;
        },
        onDropEnter: (event) async {
          debugPrint("Drop Enter");
          // We want to animate in a border of some kind.
          setState(() {
            _dropReturn = true;
          });
        },
        onDropLeave: (event) async {
          // We want to animate out a border of some kind.
          setState(() {
            _dropReturn = false;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _dropReturn ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondaryContainer
                          .withOpacity(0.5),
                    ),
                    child: Center(
                      child: Text("Drop",
                          style: Theme.of(context).textTheme.headlineMedium),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return widget.child;
    }
  }
}
