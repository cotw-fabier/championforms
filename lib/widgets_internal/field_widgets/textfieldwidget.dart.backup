import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/textfield.dart' as form_types;
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/material.dart' as material_tf show TextField;
import 'package:flutter/services.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.field,
    this.colorScheme,
    required this.fieldState,
    this.fieldOverride,
    this.validate,
    Widget Function({required Widget child})? fieldBuilder,
  }) : fieldBuilder = fieldBuilder ?? defaultFieldBuilder;
  final FormController controller;
  final form_types.TextField field;
  final material_tf.TextField? fieldOverride;
  final FieldState fieldState;
  final FieldColorScheme? colorScheme;

  final Function(String value)? validate;

  final Widget Function({required Widget child})? fieldBuilder;

  // Default implementation for the fieldBuilder.
  static Widget defaultFieldBuilder({required Widget child}) {
    // Replace this with the implementation of `FormFieldWrapperDesignWidget`.
    return FormFieldWrapperDesignWidget(child: child);
  }

  @override
  State<StatefulWidget> createState() => _TextFieldWidgetState();
}

class _TextFieldWidgetState extends State<TextFieldWidget> {
  late TextEditingController _controller;
  late FocusNode _pasteFocusNode;
  late FocusNode _focusNode;
  late bool _gotFocus;

  // track the previous field value so we don't send meaningless field updates
  // to the champion controller
  String _lastTextValue = "";

  @override
  void initState() {
    super.initState();

    // Track if we're making a new controller or not
    final textEditingControllerExists =
        widget.controller.controllerExists(widget.field.id);

    // 1. Get or create the appropriate TextEditingController from ChampionFormController:
    if (!textEditingControllerExists) {
      widget.controller.addFieldController<TextEditingController>(
          widget.field.id, TextEditingController());
    }
    _controller = widget.controller
        .getFieldController<TextEditingController>(widget.field.id)!;

    // If you have a default initialValue you want to set right away:
    if ((widget.field.defaultValue ?? "").isNotEmpty &&
        !textEditingControllerExists) {
      _controller.text = widget.field.defaultValue!;
    }

    // set the last value to the default field value
    _lastTextValue = widget.field.defaultValue ?? "";

    _gotFocus = false;

    _focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent evt) {
        // Handle Enter key submission
        if (!HardwareKeyboard.instance.isShiftPressed &&
            evt.logicalKey == LogicalKeyboardKey.enter) {
          if (evt is KeyDownEvent) {
            if (widget.field.onSubmit != null) {
              final formResults =
                  FormResults.getResults(controller: widget.controller);
              widget.field.onSubmit!(formResults);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
    );

    _pasteFocusNode = FocusNode();

    _controller.addListener(_onControllerChanged);
    _focusNode.addListener(_onLoseFocus);
    widget.controller.addListener(_onControllerValueUpdated);

    if (widget.field.requestFocus) _focusNode.requestFocus();
  }

  Future<void> _onLoseFocus() async {
    // Transmit focus state to the controller.
    widget.controller.setFieldFocus(widget.field.id, _focusNode.hasFocus);

    setState(() {
      _gotFocus = true;
    });

    if (widget.validate != null && !_focusNode.hasFocus) {
      if (!_focusNode.hasFocus) {
        widget.validate!(
            _gotFocus ? _controller.text : widget.field.defaultValue ?? "");
      }
    }
  }

  void _onControllerValueUpdated() {
    // Check if field exists before getting value
    final newValue = widget.controller.hasField(widget.field.id)
        ? widget.controller.getFieldValue<String>(widget.field.id) ?? ""
        : "";
    if (newValue != _controller.text) {
      final currentValue = _controller.value;
      _controller.value = currentValue.copyWith(
        text: newValue,
        // Preserve the current selection if it's still valid; otherwise, collapse at the end.
        selection: currentValue.selection.isValid
            ? currentValue.selection
            : TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  void _onControllerChanged() {
    final newText = _controller.text;
    // Only update if the actual text (not just selection) has changed.
    if (newText != _lastTextValue) {
      // Store the last value so we can see if the controller meaningfully changed
      _lastTextValue = newText;
      widget.controller.updateFieldValue<String>(widget.field.id, newText);

      if (widget.field.onChange != null) {
        widget.field.onChange!(FormResults.getResults(
            controller: widget.controller, fields: [widget.field]));
      }
    }
  }

  @override
  void didUpdateWidget(covariant TextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerValueUpdated);
    _pasteFocusNode.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Build the TextField widget
    final textField = overrideTextField(
      context: context,
      leading: widget.field.leading,
      trailing: widget.field.trailing,
      icon: widget.field.icon,
      labelText: widget.field.textFieldTitle,
      hintText: widget.field.hintText,
      keyboardType: widget.field.keyboardType,
      inputFormatters: widget.field.inputFormatters,
      controller: _controller,
      focusNode: _focusNode,
      obscureText: widget.field.password,
      colorScheme: widget.colorScheme,
      baseField: widget.fieldOverride != null
          ? widget.fieldOverride?.onSubmitted == null
              ? overrideTextField(
                  context: context,
                  onSubmitted: (value) {
                    if (widget.field.onSubmit == null) return;
                    final formResults = FormResults.getResults(
                      controller: widget.controller,
                    );
                    widget.field.onSubmit!(formResults);
                  },
                  baseField: widget.fieldOverride!,
                )
              : widget.fieldOverride!
          : material_tf.TextField(
              maxLines: widget.field.maxLines,
              onSubmitted: (value) {
                if (widget.field.onSubmit == null) return;
                final formResults = FormResults.getResults(
                  controller: widget.controller,
                );
                widget.field.onSubmit!(formResults);
              },
              style: theme.textTheme.bodyMedium,
            ),
    );

    // Wrap with autocomplete if configured
    final wrappedField = widget.field.autoComplete != null &&
            widget.field.autoComplete!.type != AutoCompleteType.none
        ? AutocompleteWrapper(
            child: textField,
            autoComplete: widget.field.autoComplete!,
            focusNode: _focusNode,
            textEditingController: _controller,
            colorScheme: widget.colorScheme,
          )
        : textField;

    return widget.fieldBuilder!(child: wrappedField);
  }
}
