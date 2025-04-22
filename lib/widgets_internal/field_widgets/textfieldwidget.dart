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
  // Removed _autoCompleteFocusNode in favor of per-item focus nodes.
  late bool _gotFocus;

  // track the previous field value so we don't send meaningless field updates
  // to the champion controller
  String _lastTextValue = "";

  // Autocomplete options are tracked here.
  late List<AutoCompleteOption> _autoCompleteOptions;

  // Debounce timer for autocomplete
  Timer? _debounceTimer;

  // Overlay layer link.
  final LayerLink _layerLink = LayerLink();
  late bool _autoCompleteAvailable; // Tracks if autocomplete is available

  OverlayEntry? _overlayEntry;

  bool _updatedFromAutoComplete = false;
  AutoCompleteOption? _lastPickedOption;

  // Scroll controller for the autocomplete list.
  final ScrollController _scrollController = ScrollController();

  // List of focus nodes for each autocomplete list item.
  List<FocusNode> _autoCompleteItemFocusNodes = [];

  @override
  void initState() {
    super.initState();

    // Track if we're making a new controller or not
    final textEditingControllerExists =
        widget.controller.textEditingControllerExists(widget.field.id);

    // 1. Get or create the appropriate TextEditingController from ChampionFormController:
    _controller = widget.controller.getTextEditingController(widget.field.id);

    // If you have a default initialValue you want to set right away:
    if ((widget.initialValue ?? "").isNotEmpty &&
        !textEditingControllerExists) {
      _controller.text = widget.initialValue!;
    }

    // set the last value to the default field value
    _lastTextValue = widget.initialValue ?? "";

    _gotFocus = false;
    _autoCompleteOptions = [];
    _autoCompleteAvailable = false;

    _focusNode = FocusNode(
      onKeyEvent: (FocusNode node, KeyEvent evt) {
        // When the overlay is visible, intercept arrow keys to move focus.
        if (_overlayEntry != null && _autoCompleteOptions.isNotEmpty) {
          if (evt is KeyDownEvent) {
            if (evt.logicalKey == LogicalKeyboardKey.tab) {
              return _handleKeyboardFocusAutocompleteDropdown();
            } else if (evt.logicalKey == LogicalKeyboardKey.escape) {
              // Dismiss the autocomplete overlay.
              _removeOverlay();
              return KeyEventResult.handled;
            }
          }
        }
        // Handle Enter key submission if no autocomplete navigation is in play.
        if (!HardwareKeyboard.instance.isShiftPressed &&
            evt.logicalKey == LogicalKeyboardKey.enter) {
          if (evt is KeyDownEvent) {
            if (widget.onSubmitted != null) {
              final formResults =
                  FormResults.getResults(controller: widget.controller);
              widget.onSubmitted!(formResults);
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

    if (widget.requestFocus) _focusNode.requestFocus();
  }

  KeyEventResult _handleKeyboardFocusAutocompleteDropdown() {
    // Move focus to the first autocomplete item.
    if (_autoCompleteItemFocusNodes.isNotEmpty) {
      debugPrint("Trying to focus the autocomplete menu");
      try {
        selectTopAutoCompleteOption();
      } catch (e) {
        // Couldn't request focus for some reason, so pass through the key
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _onLoseFocus() async {
    // Transmit focus state to the controller.
    widget.controller
        .setFieldFocus(widget.field.id, _anyFocusActive, widget.field);

    setState(() {
      _gotFocus = true;
    });

    if (widget.validate != null && !_anyFocusActive) {
      //await Future.delayed(const Duration(milliseconds: 200), () {
      if (!_anyFocusActive) {
        widget.validate!(
            _gotFocus ? _controller.text : widget.initialValue ?? "");
      }
      //});
    }

    if (!_anyFocusActive) {
      await Future.delayed(const Duration(milliseconds: 200), () {
        if (!_anyFocusActive) {
          _removeOverlay(requestFocus: false);
        }
      });
    }
  }

  bool get _anyFocusActive =>
      _focusNode.hasFocus ||
      _autoCompleteItemFocusNodes.any((node) => node.hasFocus);

  void _onControllerValueUpdated() {
    final newValue =
        widget.controller.findTextFieldValue(widget.field.id)?.value ?? "";
    if (newValue != _controller.text) {
      final currentValue = _controller.value;
      _controller.value = currentValue.copyWith(
        text: newValue,
        // Preserve the current selection if it’s still valid; otherwise, collapse at the end.
        selection: currentValue.selection.isValid
            ? currentValue.selection
            : TextSelection.collapsed(offset: newValue.length),
      );
    }
  }

  void _scheduleUpdateOptions(String currentText) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
        widget.field.autoComplete?.debounceWait ??
            const Duration(milliseconds: 1000),
        () => _doUpdateOptions(currentText));
  }

  Future<void> _doUpdateOptions(String val) async {
    if (widget.field.autoComplete?.updateOptions != null) {
      final updated = await widget.field.autoComplete!.updateOptions!(val);
      setState(() {
        _autoCompleteOptions = updated;
      });
      _showOrRemoveOverlay();
    } else {
      setState(() => _autoCompleteOptions = _defaultAutoCompleteFilter(val));
      _showOrRemoveOverlay();
    }
  }

  void _onControllerChanged() {
    final newText = _controller.text;
    // Only update if the actual text (not just selection) has changed.
    if (newText != _lastTextValue) {
      // Re-enable showing the autocomplete dropdown
      // set to false to stop it blocking from recreating the overlay.
      _updatedFromAutoComplete = false;

      // Store the last value so we can see if the controller meaningfully changed
      _lastTextValue = newText;
      widget.controller.updateTextFieldValue(widget.field.id, newText);

      if (widget.onChanged != null) {
        widget.onChanged!(FormResults.getResults(
            controller: widget.controller, fields: [widget.field]));
      }

      if (widget.field.autoComplete != null &&
          widget.field.autoComplete!.type != AutoCompleteType.none &&
          newText.isNotEmpty &&
          _lastPickedOption?.value != newText) {
        _scheduleUpdateOptions(newText);
      }
    }
  }

  // Select the top autocomplete option and update the field.
  void selectTopAutoCompleteOption() {
    if (_autoCompleteOptions.isNotEmpty) {
      championCallback(_autoCompleteOptions.first);
    }
  }

  void _showOrRemoveOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_anyFocusActive &&
          widget.field.autoComplete != null &&
          widget.field.autoComplete!.type == AutoCompleteType.dropdown &&
          _controller.text.isNotEmpty &&
          _autoCompleteOptions.isNotEmpty &&
          !_updatedFromAutoComplete) {
        _removeOverlay(); // Remove any existing overlay.
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        if (_updatedFromAutoComplete) _removeOverlay(requestFocus: false);
        _autoCompleteOptions = [];
      }
    });
  }

  void _removeOverlay({bool keepAway = false, bool requestFocus = true}) {
    if (requestFocus) {
      _focusNode.requestFocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length));
        }
      });
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
    _autoCompleteAvailable = false;
    if (keepAway) _updatedFromAutoComplete = keepAway;
    _disposeAutoCompleteItemFocusNodes();
  }

  // Dispose all autocomplete item focus nodes.
  void _disposeAutoCompleteItemFocusNodes() {
    for (final node in _autoCompleteItemFocusNodes) {
      node.dispose();
    }
    _autoCompleteItemFocusNodes.clear();
  }

  // The championCallback function used for autocomplete selection.
  String championCallback(AutoCompleteOption picked) {
    setState(() {
      _controller.text = picked.value;
      _lastPickedOption = picked;
      widget.controller.updateTextFieldValue(widget.field.id, picked.value);
      if (picked.callback != null) {
        picked.callback!(picked);
      }
      _removeOverlay(keepAway: true);
    });
    return picked.value;
  }

  // Default filter for autocomplete options using simple string "startsWith".
  List<AutoCompleteOption> _defaultAutoCompleteFilter(String value) {
    return widget.field.autoComplete?.initialOptions
            .where((option) => option.value.startsWith(value))
            .toList() ??
        [];
  }

  OverlayEntry _createOverlayEntry() {
    // Mark autocomplete as available.
    _autoCompleteAvailable = true;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox());
    }

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final spaceBelow = screenSize -
        (offset.dy +
            size.height +
            (widget.field.autoComplete?.dropdownBoxMargin ?? 8));
    final minHeight = widget.field.autoComplete?.minHeight ?? 100;
    final maxHeight = widget.field.autoComplete?.maxHeight ?? 300;

    bool goUp = spaceBelow < minHeight;
    final height = goUp
        ? (offset.dy < maxHeight ? offset.dy : maxHeight).toDouble()
        : (spaceBelow < maxHeight ? spaceBelow : maxHeight).toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(0);
    });

    return OverlayEntry(
      builder: (context) {
        // Recreate autocomplete item focus nodes.
        _disposeAutoCompleteItemFocusNodes();
        _autoCompleteItemFocusNodes =
            List.generate(_autoCompleteOptions.length, (index) => FocusNode());

        return Positioned(
          width: size.width,
          height: height,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(
                0,
                goUp
                    ? (-height -
                        (widget.field.autoComplete?.dropdownBoxMargin ?? 8))
                    : size.height +
                        (widget.field.autoComplete?.dropdownBoxMargin ?? 8)),
            child: Material(
              color: widget.colorScheme?.surfaceBackground,
              textStyle: TextStyle(color: widget.colorScheme?.surfaceText),
              elevation: 4.0,
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: ListView.builder(
                  controller: _scrollController,
                  reverse: goUp,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _autoCompleteOptions.length,
                  itemBuilder: (context, index) {
                    final option = _autoCompleteOptions[index];
                    return Focus(
                      focusNode: _autoCompleteItemFocusNodes[index],
                      child: ListTile(
                        title: Text(option.title),
                        tileColor: _autoCompleteItemFocusNodes[index].hasFocus
                            ? Colors.grey[300]
                            : null,
                        onTap: () => championCallback(option),
                      ),
                    );
                  },
                ),
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
    _showOrRemoveOverlay();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerValueUpdated);
    _pasteFocusNode.dispose();
    _focusNode.dispose();
    _removeOverlay();
    _debounceTimer?.cancel(); // Ensure timer is cancelled
    _scrollController.dispose();
    super.dispose();
  }

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
          keyboardType: widget.field.keyboardType,
          inputFormatters: widget.field.inputFormatters,
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
