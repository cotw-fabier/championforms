import 'package:championforms/providers/textformfieldbyid.dart';
import 'package:championforms/widgets_internal/draggablewidget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:fleather/fleather.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:html2md/html2md.dart' as html2md;

class TextFieldWidget extends ConsumerStatefulWidget {
  const TextFieldWidget({
    super.key,
    required this.id,
    this.fieldId = "",
    this.formId = "",
    this.requestFocus = false,
    this.password = false,
    this.onChanged,
    this.onSubmitted,
    this.validate,
    this.icon,
    this.initialValue = "",
    this.hintText = '',
    this.maxLines,
    this.width,
    this.height,
    this.maxHeight,
    this.expanded = false,
    this.onDrop,
    this.formats,
    this.draggable = true,
    this.onPaste,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;
  final String id;
  final String fieldId;
  final String formId;
  final bool requestFocus;
  final bool password;
  final Function(String value)? onChanged;
  final Function(String value)? onSubmitted;
  final Function(String value)? validate;
  final String? initialValue;
  final Icon? icon;
  final String hintText;
  final int? maxLines;
  final double? width;
  final double? height;
  final double? maxHeight;
  final bool expanded;
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onDrop;
  final List<DataFormat<Object>>? formats;
  final bool draggable;
  final Future<void> Function({
    FleatherController? fleatherController,
    TextEditingController? controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onPaste;
  final Widget Function({required Widget child})? fieldBuilder;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _TextFieldWidgetState();
}

class _TextFieldWidgetState extends ConsumerState<TextFieldWidget> {
  late TextEditingController _controller;
  late FocusNode _pasteFocusNode;
  late FocusNode _focusNode;
  late bool _gotFocus;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    _gotFocus = false;

    _focusNode = FocusNode();
    _pasteFocusNode = FocusNode();

    _controller.addListener(_onControllerChanged);

    _focusNode.addListener(_onLoseFocus);

    if (widget.requestFocus) _focusNode.requestFocus();
  }

  void _onLoseFocus() {
    setState(() {
      _gotFocus = true;
    });

    if (widget.validate != null && !_focusNode.hasFocus) {
      // if this field ever recieved focus then we can rely on the text controller
      // If not, then we'll run the validator on the initial value supplied
      widget
          .validate!(_gotFocus ? _controller.text : widget.initialValue ?? "");
    }
  }

  void _onRiverpodControllerUpdate(String? previous, String next) {
    if (next != _controller.text) {
      _controller.text = next;
    }
    //debugPrint("Riverpod controller update: $next");
  }

  void _onControllerChanged() {
    if (widget.onChanged != null) widget.onChanged!(_controller.text);

    ref.read(textFormFieldValueById(widget.id).notifier).state =
        _controller.text;
  }

  @override
  void dispose() {
    _controller.dispose();
    _pasteFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handlePaste() async {
    final clipboard = SystemClipboard.instance;
    final reader = await clipboard?.read();
    final plainTextData = reader?.canProvide(Formats.plainText) ?? false
        ? await reader!.readValue(Formats.plainText)
        : null;
    final htmlData = reader?.canProvide(Formats.htmlText) ?? false
        ? await reader!.readValue(Formats.htmlText)
        : null;

    debugPrint("Can Provide HTML: ${reader?.canProvide(Formats.htmlText)}");
    debugPrint("Can Provide Text: ${reader?.canProvide(Formats.plainText)}");
    //debugPrint(htmlData ?? "No HTML Data");

    if (htmlData != null) {
      //final document = Document.fromHtml(htmlData);
      //final delta = document.toDelta();
      final text = html2md.convert(htmlData);

      final selection = _controller.selection;
      final newText =
          _controller.text.replaceRange(selection.start, selection.end, text);
      _controller.text = newText;
      _controller.selection =
          TextSelection.collapsed(offset: selection.start + text.length);

      /* controller.compose(
        delta,
        controller.selection,
        ChangeSource.local,
      ); */
    } else if (plainTextData != null) {
      //print('Pasting plain text');
      final selection = _controller.selection;
      final newText = _controller.text
          .replaceRange(selection.start, selection.end, plainTextData);
      _controller.text = newText;
      _controller.selection = TextSelection.collapsed(
          offset: selection.start + plainTextData.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(textFormFieldValueById(widget.id), _onRiverpodControllerUpdate);
    final ThemeData theme = Theme.of(context);
    final textValue = ref.watch(textFormFieldValueById(widget.id));
    return LayoutBuilder(builder: (context, constraints) {
      return Container(
        width: widget.width ??
            (constraints.maxWidth < double.infinity && widget.expanded
                ? constraints.maxWidth
                : null),
        height: widget.height ??
            (constraints.maxHeight < double.infinity && widget.expanded
                ? constraints.maxHeight
                : 50),
        constraints: widget.maxHeight != null
            ? BoxConstraints(maxHeight: widget.maxHeight!)
            : null,
        child: widget.fieldBuilder!(
          child: ConditionalDraggableDropZone(
            onDrop: widget.onDrop,
            formats: widget.formats,
            draggable: widget.draggable,
            controller: _controller,
            fieldId: widget.fieldId,
            formId: widget.formId,
            child: Focus(
              focusNode: _pasteFocusNode,
              onKeyEvent: (FocusNode node, KeyEvent event) {
                final isPasteEvent = event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.keyV &&
                    (HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.controlLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.controlRight) ||
                        HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.metaLeft) ||
                        HardwareKeyboard.instance.logicalKeysPressed
                            .contains(LogicalKeyboardKey.metaRight));

                if (isPasteEvent) {
                  debugPrint("Paste Function: ${widget.onPaste.toString()}");
                  widget.onPaste == null
                      ? _handlePaste()
                      : widget.onPaste!(
                          controller: _controller,
                          ref: ref,
                          formId: widget.formId,
                          fieldId: widget.fieldId,
                        );
                  return KeyEventResult.handled;
                } else {
                  return KeyEventResult.ignored;
                }
              },
              child: TextFormField(
                obscureText: widget.password,
                maxLines: widget.maxLines,
                focusNode: _focusNode,
                controller: _controller,
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  prefixIcon: widget.icon,
                  filled: true,
                  fillColor:
                      Colors.transparent, // To ensure the gradient is visible
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none, // No additional border needed
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10.0, horizontal: 20.0),
                  hintText: widget.hintText,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5)),
                ),
                onFieldSubmitted: widget.onSubmitted != null
                    ? (value) {
                        if (widget.maxLines != null) {
                          ref
                              .read(textFormFieldValueById(widget.id).notifier)
                              .state = value;
                        }
                        if (widget.onSubmitted != null) {
                          widget.onSubmitted!(value);
                        }
                      }
                    : null,
              ),
            ),
          ),
        ),
      );
    });
  }
}
