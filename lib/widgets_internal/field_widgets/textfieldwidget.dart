import 'dart:async';

import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/fieldbuilders/textfieldbuilder.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championtextfield.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/widgets_internal/fieldwrapperdefault.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class TextFieldWidget extends StatefulWidget {
  const TextFieldWidget({
    super.key,
    required this.controller,
    required this.field,
    this.fieldId = "",
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
  final ChampionFormController controller;
  final ChampionTextField field;
  final TextField? fieldOverride;
  final FieldState fieldState;
  final FieldColorScheme? colorScheme;
  final String fieldId;
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
  })? onDrop;
  final List<DataFormat<Object>>? formats;
  final bool draggable;
  final Future<void> Function({
    TextEditingController controller,
    required String formId,
    required String fieldId,
  })? onPaste;
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

  // Autocomplete options are tracked here.
  late List<AutoCompleteOption> _autoCompleteOptions;

  // Debounce timer for autocomplete
  Timer? _debounceTimer;

  //Other AutoComplete Dropdown variables to track
  final LayerLink _layerLink = LayerLink();
  late bool _autoCompleteAvailable; // Tracks if we can perform autocomplete

  OverlayEntry? _overlayEntry;

  bool _updatedFromAutoComplete = false;
  AutoCompleteOption? _lastPickedOption;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);

    _gotFocus = false;

    // Add autocomplete options from the incoming field
    _autoCompleteOptions = [];
    _autoCompleteAvailable = false;

    _focusNode = FocusNode(
        // This code attaches shift  enter functionality for
        // new lines if there is an onsubmitted function
        // present in the form field
        onKeyEvent: (FocusNode node, KeyEvent evt) {
      if (!HardwareKeyboard.instance.isShiftPressed &&
          evt.logicalKey.keyLabel == 'Enter') {
        if (evt is KeyDownEvent) {
          if (widget.onSubmitted == null) return KeyEventResult.ignored;
          final formResults =
              FormResults.getResults(controller: widget.controller);
          widget.onSubmitted!(formResults);
        }
        return KeyEventResult.handled;
      } else if (evt.logicalKey.keyLabel == 'Tab' && _autoCompleteAvailable) {
        // Insert logic here for handling inserting autocomplete data.
        // TODO: fix this to insert the active autocomplete
        _controller.text = "";
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    });
    _pasteFocusNode = FocusNode();

    _controller.addListener(_onControllerChanged);

    _focusNode.addListener(_onLoseFocus);

    widget.controller.addListener(_onControllerValueUpdated);

    if (widget.requestFocus) _focusNode.requestFocus();
  }

  Future<void> _onLoseFocus() async {
    // transmit focus state to controller
    widget.controller
        .setFieldFocus(widget.field.id, _focusNode.hasFocus, widget.field);

    setState(() {
      _gotFocus = true;
    });

    if (widget.validate != null && !_focusNode.hasFocus) {
      // if this field ever recieved focus then we can rely on the text controller
      // If not, then we'll run the validator on the initial value supplied
      widget
          .validate!(_gotFocus ? _controller.text : widget.initialValue ?? "");
    }

    // When the controller's active field updates
    // check if the field has focus and if the field is registered as active
    if (!_focusNode.hasFocus) {
      // We wait to see if this is just a momentary loss of focus as it should snap
      // from the suggested autosuggestion back to the field if we're inserting content
      // If we did actually lose focus then remove it after waiting a hot second
      await Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus) {
          _removeOverlay(requestFocus: false);
        }
      });
    }
  }

  // Allow us to programatically update this text field through the controller
  void _onControllerValueUpdated() {
    if (widget.controller.findTextFieldValue(widget.field.id)?.value !=
        _controller.text) {
      _controller.text =
          widget.controller.findTextFieldValue(widget.field.id)?.value ?? "";
    }

    //debugPrint("Riverpod controller update: $next");
  }

  // Quick helper to handle the min. typical pattern
  // updates autocomplete options using the callback function
  // provided in field.autoComplete.updateOptions();
  void _scheduleUpdateOptions(String currentText) {
    // Cancel previous timer if still active
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
        widget.field.autoComplete?.debounceWait ??
            const Duration(milliseconds: 1000),
        () => _doUpdateOptions(currentText));
  }

  Future<void> _doUpdateOptions(String val) async {
    if (widget.field.autoComplete?.updateOptions != null) {
      // We may want to keep a separate Timer so we can also use autoComplete.debounceDuration.
      // For simplicity, let's do a single short wait above. You can expand as needed.
      final updated = await widget.field.autoComplete!.updateOptions!(val);
      setState(() {
        _autoCompleteOptions = updated;
      });
      _showOrRemoveOverlay();
    } else {
      debugPrint("Filtering options with ${_autoCompleteOptions.length}");
      // If no callback, filter initial options.
      setState(() => _autoCompleteOptions = _defaultAutoCompleteFilter(val));
      _showOrRemoveOverlay();
    }
  }

  void _onControllerChanged() {
    final textVal = _controller.text;

    widget.controller.updateTextFieldValue(widget.field.id, _controller.text);

    if (widget.onChanged != null) {
      widget.onChanged!(FormResults.getResults(
          controller: widget.controller, fields: [widget.field]));
    }

    // If we have autocomplete turned on and user typed something,
    // let's do an update.
    if (widget.field.autoComplete != null &&
        widget.field.autoComplete!.type != AutoCompleteType.none &&
        textVal != "" &&
        _lastPickedOption?.value != textVal) {
      _scheduleUpdateOptions(textVal);
    } else {
      // Just remove overlay if any
      //_removeOverlay();
      //_showOrRemoveOverlay();

      // Do we need to reset to the default options?
    }
    if (_lastPickedOption != null &&
        _lastPickedOption?.value != _controller.text) {
      _updatedFromAutoComplete = false;
    }
  }

  // Decide whether to show or remove the autocomplete overlay
  void _showOrRemoveOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_focusNode.hasFocus &&
          widget.field.autoComplete != null &&
          widget.field.autoComplete!.type == AutoCompleteType.dropdown &&
          _controller.text.isNotEmpty &&
          _autoCompleteOptions.isNotEmpty &&
          !_updatedFromAutoComplete) {
        _removeOverlay(); // remove any existing overlay
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        // Reset available options

        if (_updatedFromAutoComplete) _removeOverlay(requestFocus: false);
        _autoCompleteOptions = [];
      }
    });
  }

  void _removeOverlay({bool keepAway = false, bool requestFocus = true}) {
    // Request focus back to the field after clicking an option in the overlay.
    if (requestFocus) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
    _updatedFromAutoComplete = keepAway;
  }

  // The championCallback function used to set the text and close
  // in an AutoComplete dropdown
  String championCallback(AutoCompleteOption picked) {
    setState(() {
      // Update the controller
      _controller.text = picked.value;
      // Save the last picked option for comparison later.
      _lastPickedOption = picked;
      widget.controller.updateTextFieldValue(widget.field.id, picked.value);
      // If they gave a callback in the option, run it
      if (picked.callback != null) {
        picked.callback!(picked);
      }

      _removeOverlay(keepAway: true);
    });

    return picked.value;
  }

  // Default filter of autocomplete options, does simple string "startsWith()"
  List<AutoCompleteOption> _defaultAutoCompleteFilter(String value) {
    return widget.field.autoComplete?.initialOptions
            .where((option) => option.value.startsWith(value))
            .toList() ??
        [];
  }

  OverlayEntry _createOverlayEntry() {
    // First, figure out the position of the text field in global coordinates
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      // fallback
      return OverlayEntry(builder: (_) => const SizedBox());
    }

    final size = renderBox.size;
    debugPrint("Renderbox Size is ${renderBox.size.height}");
    final offset = renderBox.localToGlobal(Offset.zero);

    // Figure out how much space is below vs above
    final screenSize = MediaQuery.sizeOf(context);
    final spaceBelow = screenSize.height - (offset.dy + size.height);
    // We'll use a minHeight from the builder or default to 100
    final minHeight = widget.field.autoComplete?.minHeight ?? 100;
    // Use maxHeight from the builder or some default
    final maxHeight = widget.field.autoComplete?.maxHeight ?? 300;
    // Optional: if percentageHeight is set, you can interpret it here
    // e.g. final pHeight = widget.field.autoComplete?.percentageHeight;

    // Decide whether to put the dropdown below or above
    bool goUp = spaceBelow < minHeight;

    // If going up, optionally reverse the list
    final actualOptions =
        goUp ? _autoCompleteOptions.reversed.toList() : _autoCompleteOptions;

    return OverlayEntry(
      builder: (context) {
        // The container for the dropdown
        return Positioned(
          // if going up, align bottom with the textfield's top
          top: goUp ? (offset.dy - minHeight) : (offset.dy + size.height),
          left: offset.dx,
          width: size.width,
          // We'll pick whichever is smaller: spaceBelow or maxHeight,
          // but also ensure at least minHeight if we can
          height: goUp
              ? (offset.dy < maxHeight ? offset.dy : maxHeight).toDouble()
              : (spaceBelow < maxHeight ? spaceBelow : maxHeight).toDouble(),
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: goUp
                ? Offset(0, -size.height)
                : Offset(0, 0), // or no offset; you'll adjust if needed
            child: Material(
              elevation: 4.0,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: actualOptions.length,
                itemBuilder: (context, index) {
                  final option = actualOptions[index];

                  // If there's a custom builder at the Option level, use it
                  final overrideBuilder = option.optionBuilder;
                  // Or if there's a custom builder in the autoComplete object, use that
                  final fieldBuilder = widget.field.autoComplete?.optionBuilder;

                  if (overrideBuilder != null) {
                    return overrideBuilder(option, championCallback);
                  } else if (fieldBuilder != null) {
                    return fieldBuilder(option, championCallback);
                  } else {
                    // default
                    return ListTile(
                      title: Text(option.title),
                      onTap: () => championCallback(option),
                    );
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(covariant TextFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If anything changes that might require redrawing the overlay:
    _showOrRemoveOverlay();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerValueUpdated);
    _controller.dispose();
    _pasteFocusNode.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  // TODO: Handle pasting in content into the field
  // Middleware for dealing with paste events
  // void _handlePaste() async {}

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return widget.fieldBuilder!(
      child: CompositedTransformTarget(
        link: _layerLink,
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
                          controller: widget.controller,
                        );
                        widget.onSubmitted!(formResults);
                      },
                      baseField: widget.fieldOverride!,
                    )
                  : widget.fieldOverride!
              : TextField(
                  maxLines: widget.maxLines,
                  onSubmitted: (value) {
                    if (widget.onSubmitted == null) return;
                    final formResults = FormResults.getResults(
                      controller: widget.controller,
                    );
                    widget.onSubmitted!(formResults);
                  },
                  style: theme.textTheme.bodyMedium,
                ),
        ),
      ),
    );
  }
}
