// This widget allows to dynamically insert drag and drop functionality.
import 'package:flutter/material.dart';

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
  final List<String>? formats;

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
    // Note: This widget previously used super_drag_and_drop DropRegion
    // It will be replaced with native Flutter drag-drop in subsequent phases
    // For now, returning child without drag-drop functionality

    if (widget.draggable) {
      // Placeholder - drag-drop functionality to be implemented
      return Stack(
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
                        .withValues(alpha: 0.5),
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
      );
    } else {
      return widget.child;
    }
  }
}
