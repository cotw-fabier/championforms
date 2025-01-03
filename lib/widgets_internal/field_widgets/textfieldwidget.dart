import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/providers/field_focus.dart';
import 'package:championforms/providers/formfield_value_by_id.dart';
import 'package:championforms/widgets_internal/draggablewidget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class TextFieldWidget extends ConsumerStatefulWidget {
  const TextFieldWidget({
    super.key,
    required this.id,
    required this.field,
    this.fieldId = "",
    this.formId = "",
    this.colorScheme,
    required this.fieldState,
    this.fieldOverride,
    this.requestFocus = false,
    this.password = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType = TextInputType.text,
    this.validate,
    this.initialValue = "",
    this.labelText,
    this.hintText,
    this.maxLines,
    this.onDrop,
    this.formats,
    this.draggable = true,
    this.onPaste,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;
  final String id;
  final ChampionTextField field;
  final TextField? fieldOverride;
  final FieldState fieldState;
  final FieldColorScheme? colorScheme;
  final String fieldId;
  final String formId;
  final bool requestFocus;
  final bool password;
  final Function(FormResults results)? onChanged;
  final Function(FormResults results)? onSubmitted;
  final Function(String value)? validate;
  final TextInputType keyboardType;
  final String? initialValue;
  final String? labelText;
  final String? hintText;
  final int? maxLines;
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
    required WidgetRef ref,
  })? onDrop;
  final List<DataFormat<Object>>? formats;
  final bool draggable;
  final Future<void> Function({
    TextEditingController controller,
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

    _focusNode = FocusNode(
        // This code attaches shift + enter functionality for
        // new lines if there is an onsubmitted function
        // present in the form field
        onKeyEvent: (FocusNode node, KeyEvent evt) {
      if (!HardwareKeyboard.instance.isShiftPressed &&
          evt.logicalKey.keyLabel == 'Enter') {
        if (evt is KeyDownEvent) {
          if (widget.onSubmitted == null) return KeyEventResult.ignored;
          final formResults =
              FormResults.getResults(ref: ref, formId: widget.formId);
          widget.onSubmitted!(formResults);
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    });
    _pasteFocusNode = FocusNode();

    _controller.addListener(_onControllerChanged);

    _focusNode.addListener(_onLoseFocus);

    if (widget.requestFocus) _focusNode.requestFocus();
  }

  void _onLoseFocus() {
    // transmit focus state to provider
    ref
        .read(fieldFocusNotifierProvider(widget.id).notifier)
        .setFocus(_focusNode.hasFocus);

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
    ref
        .read(textFormFieldValueByIdProvider(widget.id).notifier)
        .updateValue(_controller.text);

    if (widget.onChanged != null) {
      widget.onChanged!(FormResults.getResults(
          ref: ref, formId: widget.formId, fields: [widget.field]));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _pasteFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // TODO: Handle pasting in content into the field
  // Middleware for dealing with paste events
  void _handlePaste() async {}

  @override
  Widget build(BuildContext context) {
    ref.listen(
        textFormFieldValueByIdProvider(widget.id), _onRiverpodControllerUpdate);
    final ThemeData theme = Theme.of(context);
    final textValue = ref.watch(textFormFieldValueByIdProvider(widget.id));

    return widget.fieldBuilder!(
      child: overrideTextField(
        context: context,
        leading: widget.field.leading,
        trailing: widget.field.trailing,
        icon: widget.field.icon,
        labelText: widget.labelText,
        hintText: widget.hintText,
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.password,
        colorScheme: widget.colorScheme,
        baseField: widget.fieldOverride != null
            ? widget.fieldOverride?.onSubmitted == null
                ? overrideTextField(
                    context: context,
                    onSubmitted: (value) {
                      if (widget.onSubmitted == null) return;
                      final formResults = FormResults.getResults(
                          ref: ref, formId: widget.formId);
                      widget.onSubmitted!(formResults);
                    },
                    baseField: widget.fieldOverride!,
                  )
                : widget.fieldOverride!
            : TextField(
                maxLines: widget.maxLines,
                onSubmitted: (value) {
                  if (widget.onSubmitted == null) return;
                  final formResults =
                      FormResults.getResults(ref: ref, formId: widget.formId);
                  widget.onSubmitted!(formResults);
                },
                style: theme.textTheme.bodyMedium,
              ),
      ),
    );
  }
}