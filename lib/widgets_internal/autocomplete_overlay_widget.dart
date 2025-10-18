import 'dart:async';

import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A standalone wrapper widget that provides autocomplete overlay functionality.
///
/// This widget wraps any field widget and provides an intelligent autocomplete
/// dropdown overlay. It handles positioning, keyboard navigation, accessibility,
/// and selection callbacks. The overlay automatically positions itself above or
/// below the field based on available screen space.
///
/// Example usage:
/// ```dart
/// ChampionAutocompleteWrapper(
///   child: TextField(controller: myController),
///   autoComplete: AutoCompleteBuilder(
///     type: AutoCompleteType.dropdown,
///     initialOptions: [AutoCompleteOption(value: 'Option 1')],
///   ),
///   focusNode: myFocusNode,
///   textEditingController: myController,
/// )
/// ```
class ChampionAutocompleteWrapper extends StatefulWidget {
  /// Creates an autocomplete wrapper widget.
  ///
  /// The [child] parameter is the field widget to wrap (e.g., TextField).
  /// The [autoComplete] parameter configures autocomplete behavior.
  /// The [focusNode] parameter is the field's focus node for blur detection.
  const ChampionAutocompleteWrapper({
    super.key,
    required this.child,
    required this.autoComplete,
    required this.focusNode,
    this.colorScheme,
    this.onOptionSelected,
    this.textEditingController,
    this.valueNotifier,
  });

  /// The field widget to wrap with autocomplete functionality.
  final Widget child;

  /// Configuration for autocomplete behavior, options, and display.
  final AutoCompleteBuilder autoComplete;

  /// Theme colors for the overlay surface and text.
  final FieldColorScheme? colorScheme;

  /// Callback invoked when an option is selected.
  ///
  /// If provided, this callback overrides the default behavior of updating
  /// the field value. Use this for custom selection handling.
  final Function(AutoCompleteOption)? onOptionSelected;

  /// Text editing controller for TextField integration.
  ///
  /// Either [textEditingController] or [valueNotifier] should be provided
  /// to enable value listening and updates.
  final TextEditingController? textEditingController;

  /// Value notifier for non-TextField field integration.
  ///
  /// Either [textEditingController] or [valueNotifier] should be provided
  /// to enable value listening and updates.
  final ValueNotifier<String>? valueNotifier;

  /// The field's focus node for detecting focus state and blur events.
  final FocusNode focusNode;

  @override
  State<ChampionAutocompleteWrapper> createState() =>
      _ChampionAutocompleteWrapperState();
}

/// State class for ChampionAutocompleteWrapper.
///
/// Manages overlay lifecycle, positioning calculations, keyboard navigation,
/// focus tracking, and debounced option updates.
class _ChampionAutocompleteWrapperState
    extends State<ChampionAutocompleteWrapper> {
  /// LayerLink connects the field widget to the overlay for positioning.
  final LayerLink _layerLink = LayerLink();

  /// The current overlay entry, null when overlay is not displayed.
  OverlayEntry? _overlayEntry;

  /// List of autocomplete options to display in the overlay.
  List<AutoCompleteOption> _autoCompleteOptions = [];

  /// Focus nodes for each autocomplete option (for keyboard navigation).
  List<FocusNode> _autoCompleteItemFocusNodes = [];

  /// Scroll controller for the autocomplete overlay list.
  final ScrollController _scrollController = ScrollController();

  /// FocusNode for the KeyboardListener to receive key events.
  final FocusNode _keyboardListenerFocusNode = FocusNode();

  /// Debounce timer for throttling autocomplete option updates.
  Timer? _debounceTimer;

  /// Tracks whether the field was updated from an autocomplete selection.
  ///
  /// This prevents the overlay from reopening immediately after selection.
  bool _updatedFromAutoComplete = false;

  /// Tracks the current semantics announcement for screen readers.
  String _currentSemanticAnnouncement = '';

  /// Tracks the last field value to detect changes.
  String _lastFieldValue = '';

  /// Tracks whether this is the first debounce run for faster initial response.
  bool _isFirstDebounceRun = true;

  /// Tracks the currently focused option index for visual feedback.
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();

    // Initialize options with initial options from AutoCompleteBuilder
    _autoCompleteOptions = widget.autoComplete.initialOptions;

    // Add listeners for focus and text changes
    widget.focusNode.addListener(_onFocusChanged);

    // Listen to controller/notifier changes
    if (widget.textEditingController != null) {
      widget.textEditingController!.addListener(_onControllerChanged);
    } else if (widget.valueNotifier != null) {
      widget.valueNotifier!.addListener(_onValueNotifierChanged);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChanged);

    if (widget.textEditingController != null) {
      widget.textEditingController!.removeListener(_onControllerChanged);
    } else if (widget.valueNotifier != null) {
      widget.valueNotifier!.removeListener(_onValueNotifierChanged);
    }

    _scrollController.dispose();
    _keyboardListenerFocusNode.dispose();
    _debounceTimer?.cancel();
    _disposeAutoCompleteItemFocusNodes();
    _overlayEntry?.remove();
    super.dispose();
  }

  /// Handles text controller changes to filter options and show/hide overlay.
  void _onControllerChanged() {
    if (widget.textEditingController != null) {
      final newText = widget.textEditingController!.text;
      if (newText != _lastFieldValue) {
        _lastFieldValue = newText;
        _updatedFromAutoComplete = false;
        _filterAndShowOptions(newText);
      }
    }
  }

  /// Handles value notifier changes to filter options and show/hide overlay.
  void _onValueNotifierChanged() {
    if (widget.valueNotifier != null) {
      final newText = widget.valueNotifier!.value;
      if (newText != _lastFieldValue) {
        _lastFieldValue = newText;
        _updatedFromAutoComplete = false;
        _filterAndShowOptions(newText);
      }
    }
  }

  /// Filters autocomplete options based on current text value.
  ///
  /// If [updateOptions] callback is provided in AutoCompleteBuilder, uses
  /// debounced async updates. Otherwise, filters from initialOptions locally.
  void _filterAndShowOptions(String value) {
    if (value.isEmpty || _updatedFromAutoComplete) {
      setState(() {
        _autoCompleteOptions = [];
      });
      _showOrRemoveOverlay();
      return;
    }

    // If updateOptions callback is provided, use debounced async updates
    if (widget.autoComplete.updateOptions != null) {
      _scheduleUpdateOptions(value);
      return;
    }

    // Otherwise, filter options locally from initialOptions
    setState(() {
      _autoCompleteOptions = widget.autoComplete.initialOptions
          .where((option) =>
              option.value.toLowerCase().contains(value.toLowerCase()) ||
              option.title.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });

    _showOrRemoveOverlay();
  }

  /// Schedules an async update of autocomplete options with debounce.
  ///
  /// Uses dual debounce timing: fast initial run (debounceWait, default 100ms),
  /// slower subsequent runs (debounceDuration, default 1000ms).
  ///
  /// This prevents excessive calls to the updateOptions callback while still
  /// providing responsive initial feedback.
  void _scheduleUpdateOptions(String currentText) {
    // Cancel any existing timer
    _debounceTimer?.cancel();

    // Determine debounce duration based on whether this is the first run
    final debounceDelay = _isFirstDebounceRun
        ? widget.autoComplete.debounceWait
        : widget.autoComplete.debounceDuration;

    // After first run, subsequent runs use the longer duration
    _isFirstDebounceRun = false;

    // Schedule the update
    _debounceTimer = Timer(debounceDelay, () => _doUpdateOptions(currentText));
  }

  /// Executes the async updateOptions callback and updates the overlay.
  ///
  /// This method is called by the debounce timer after the configured delay.
  Future<void> _doUpdateOptions(String value) async {
    if (widget.autoComplete.updateOptions != null) {
      final updated = await widget.autoComplete.updateOptions!(value);
      if (mounted) {
        setState(() {
          _autoCompleteOptions = updated;
        });
        _showOrRemoveOverlay();
      }
    }
  }

  /// Shows or removes overlay based on current conditions.
  ///
  /// Checks if the field has focus, autocomplete type is dropdown,
  /// text is not empty, and options are available before showing overlay.
  ///
  /// Uses WidgetsBinding.addPostFrameCallback to ensure safe overlay operations.
  void _showOrRemoveOverlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final shouldShow = widget.focusNode.hasFocus &&
          widget.autoComplete.type == AutoCompleteType.dropdown &&
          _autoCompleteOptions.isNotEmpty &&
          !_updatedFromAutoComplete;

      if (shouldShow) {
        _removeOverlay(requestFocus: false);
        _overlayEntry = _createOverlayEntry();
        Overlay.of(context).insert(_overlayEntry!);
      } else {
        if (_overlayEntry != null) {
          _removeOverlay(requestFocus: false);
        }
      }
    });
  }

  /// Handles focus changes to dismiss overlay when field loses focus.
  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus &&
        !_autoCompleteItemFocusNodes.any((node) => node.hasFocus)) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted &&
            !widget.focusNode.hasFocus &&
            !_autoCompleteItemFocusNodes.any((node) => node.hasFocus)) {
          _removeOverlay(requestFocus: false);
        }
      });
    }
  }

  /// Disposes all autocomplete item focus nodes and clears the list.
  void _disposeAutoCompleteItemFocusNodes() {
    for (final node in _autoCompleteItemFocusNodes) {
      node.removeListener(() {});
      node.dispose();
    }
    _autoCompleteItemFocusNodes.clear();
  }

  /// Handles keyboard events from KeyboardListener when overlay is visible.
  ///
  /// This is called by KeyboardListener which has a different signature than Focus.onKeyEvent.
  void _handleKeyboardEvent(KeyEvent event) {
    // Only intercept when overlay is visible and field has focus
    if (_overlayEntry != null &&
        _autoCompleteOptions.isNotEmpty &&
        widget.focusNode.hasFocus) {
      if (event is KeyDownEvent) {
        // Tab or Down Arrow: move focus to first dropdown item
        if (event.logicalKey == LogicalKeyboardKey.tab ||
            event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_autoCompleteItemFocusNodes.isNotEmpty) {
            _autoCompleteItemFocusNodes.first.requestFocus();
          }
        }
        // Escape key dismisses the overlay
        else if (event.logicalKey == LogicalKeyboardKey.escape) {
          _removeOverlay(requestFocus: true);
        }
      }
    }
  }

  /// Handles keyboard events on focused options.
  KeyEventResult _handleOptionKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent) {
      // Tab key navigation through dropdown
      if (event.logicalKey == LogicalKeyboardKey.tab) {
        if (HardwareKeyboard.instance.isShiftPressed) {
          // Shift+Tab: go to previous item or exit to field
          if (index > 0) {
            _autoCompleteItemFocusNodes[index - 1].requestFocus();
            return KeyEventResult.handled;
          } else {
            // First item: dismiss and return to field
            _removeOverlay(requestFocus: true);
            return KeyEventResult.handled;
          }
        } else {
          // Tab: go to next item or exit dropdown
          if (index < _autoCompleteItemFocusNodes.length - 1) {
            _autoCompleteItemFocusNodes[index + 1].requestFocus();
            return KeyEventResult.handled;
          } else {
            // Last item: dismiss overlay, let Tab continue to next field
            _removeOverlay(requestFocus: false);
            widget.focusNode.requestFocus();
            // Return ignored to allow Tab to proceed to next field in form
            return KeyEventResult.ignored;
          }
        }
      }

      // Enter key selects the focused option
      if (event.logicalKey == LogicalKeyboardKey.enter) {
        _championCallback(_autoCompleteOptions[index]);
        return KeyEventResult.handled;
      }

      // Escape key dismisses the overlay
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _removeOverlay(requestFocus: true);
        return KeyEventResult.handled;
      }

      // Arrow Down: move to next option (stay on last if at end)
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final nextIndex = index + 1;
        if (nextIndex < _autoCompleteItemFocusNodes.length) {
          _autoCompleteItemFocusNodes[nextIndex].requestFocus();
        }
        // Always handle arrow keys, even at boundaries
        return KeyEventResult.handled;
      }

      // Arrow Up: move to previous option (stay on first if at start)
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        final prevIndex = index - 1;
        if (prevIndex >= 0) {
          _autoCompleteItemFocusNodes[prevIndex].requestFocus();
        }
        // Always handle arrow keys, even at boundaries
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Announces the current option to screen readers when focus changes.
  void _addFocusListenerForAnnouncement(FocusNode focusNode, int index) {
    focusNode.addListener(() {
      if (focusNode.hasFocus && mounted) {
        final option = _autoCompleteOptions[index];
        setState(() {
          _focusedIndex = index;
          _currentSemanticAnnouncement =
              '${option.title}, option ${index + 1} of ${_autoCompleteOptions.length}';
        });
      } else if (!focusNode.hasFocus && mounted && _focusedIndex == index) {
        // Clear focused index when this option loses focus
        setState(() {
          _focusedIndex = null;
        });
      }
    });
  }

  /// Creates the overlay entry with intelligent positioning logic.
  ///
  /// This method calculates available space above and below the field,
  /// determines optimal overlay position (above or below), and creates
  /// an overlay entry with proper sizing and positioning.
  ///
  /// The overlay uses Material widget for proper elevation and theming,
  /// CompositedTransformFollower to maintain position during scrolling,
  /// and ListView.builder for performant option rendering.
  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return OverlayEntry(builder: (_) => const SizedBox());
    }

    // Get field size and position
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    // Calculate screen height accounting for safe areas
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    // Calculate space below the field
    final dropdownMargin = widget.autoComplete.dropdownBoxMargin.toDouble();
    final fieldBottom = offset.dy + size.height;
    final spaceBelow = screenHeight - fieldBottom - dropdownMargin;

    // Get min/max height constraints from AutoCompleteBuilder
    final minHeight = (widget.autoComplete.minHeight ?? 100).toDouble();
    final maxHeight = (widget.autoComplete.maxHeight ?? 300).toDouble();

    // Determine if overlay should position above field
    final goUp = spaceBelow < minHeight;

    // Calculate available space based on direction
    final availableSpace = goUp ? offset.dy - dropdownMargin : spaceBelow;

    // Calculate final overlay height respecting constraints
    final height = availableSpace < maxHeight ? availableSpace : maxHeight;

    // Reset scroll position when overlay appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });

    return OverlayEntry(
      builder: (context) {
        // Recreate autocomplete item focus nodes
        _disposeAutoCompleteItemFocusNodes();
        _autoCompleteItemFocusNodes = List.generate(
          _autoCompleteOptions.length,
          (index) {
            final node = FocusNode();
            // Add focus listener for screen reader announcements
            _addFocusListenerForAnnouncement(node, index);
            return node;
          },
        );

        // Get theme for color access
        final theme = Theme.of(context);

        return Positioned(
          width: size.width,
          height: height,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(
              0,
              goUp
                  ? -height - dropdownMargin
                  : size.height + dropdownMargin,
            ),
            child: Material(
              color: widget.colorScheme?.surfaceBackground,
              textStyle: TextStyle(color: widget.colorScheme?.surfaceText),
              elevation: 4.0,
              child: Semantics(
                liveRegion: true,
                label: '${_autoCompleteOptions.length} options available',
                child: FocusTraversalGroup(
                  policy: ReadingOrderTraversalPolicy(),
                  child: Column(
                    children: [
                      // Hidden semantics widget for dynamic announcements
                      if (_currentSemanticAnnouncement.isNotEmpty)
                        Semantics(
                          liveRegion: true,
                          label: _currentSemanticAnnouncement,
                          child: const SizedBox.shrink(),
                        ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          reverse: goUp,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _autoCompleteOptions.length,
                          itemBuilder: (context, index) {
                            final option = _autoCompleteOptions[index];
                            // Use StatefulBuilder to rebuild only this item when focus changes
                            return StatefulBuilder(
                              builder: (context, setItemState) {
                                return Focus(
                                  focusNode: _autoCompleteItemFocusNodes[index],
                                  onFocusChange: (hasFocus) {
                                    // Rebuild this specific ListTile when focus changes
                                    setItemState(() {});
                                  },
                                  onKeyEvent: (node, event) =>
                                      _handleOptionKeyEvent(event, index),
                                  child: Semantics(
                                    label:
                                        '${option.title}, option ${index + 1} of ${_autoCompleteOptions.length}',
                                    button: true,
                                    child: ListTile(
                                      title: Text(option.title),
                                      tileColor: _autoCompleteItemFocusNodes[index]
                                              .hasFocus
                                          ? (widget.colorScheme?.textBackgroundColor ??
                                              theme.colorScheme.surfaceContainerHighest)
                                          : null,
                                      onTap: () => _championCallback(option),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handles option selection with default or custom callback behavior.
  ///
  /// If [onOptionSelected] is provided, it delegates to that callback.
  /// Otherwise, updates the controller or notifier with the selected value,
  /// calls the option's callback if present, and removes the overlay.
  void _championCallback(AutoCompleteOption option) {
    // If custom callback provided, use it and return
    if (widget.onOptionSelected != null) {
      widget.onOptionSelected!(option);
      _removeOverlay(keepAway: true, requestFocus: false);
      return;
    }

    // Default behavior: update the controller/notifier
    _updatedFromAutoComplete = true;

    if (widget.textEditingController != null) {
      widget.textEditingController!.text = option.value;
    } else if (widget.valueNotifier != null) {
      widget.valueNotifier!.value = option.value;
    }

    // Call option's callback if provided
    option.callback?.call(option);

    // Remove overlay and return focus to field
    _removeOverlay(keepAway: true, requestFocus: true);
  }

  /// Removes the overlay entry and cleans up focus nodes.
  ///
  /// If [requestFocus] is true, returns focus to the field with cursor at end.
  /// If [keepAway] is true, prevents immediate overlay reopening.
  void _removeOverlay({bool keepAway = false, bool requestFocus = false}) {
    if (requestFocus && mounted) {
      widget.focusNode.requestFocus();
      // Set cursor to end if using TextEditingController
      if (widget.textEditingController != null) {
        widget.textEditingController!.selection = TextSelection.fromPosition(
          TextPosition(offset: widget.textEditingController!.text.length),
        );
      }
    }

    _overlayEntry?.remove();
    _overlayEntry = null;
    _currentSemanticAnnouncement = '';
    if (keepAway) _updatedFromAutoComplete = true;
    _disposeAutoCompleteItemFocusNodes();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Focus(
        onKeyEvent: (node, event) {
          // Intercept Tab key when overlay is visible to prevent default focus traversal
          if (_overlayEntry != null &&
              widget.focusNode.hasFocus &&
              event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.tab ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown)) {
            // Move focus to first dropdown item
            if (_autoCompleteItemFocusNodes.isNotEmpty) {
              _autoCompleteItemFocusNodes.first.requestFocus();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: KeyboardListener(
          focusNode: _keyboardListenerFocusNode,
          onKeyEvent: _handleKeyboardEvent,
          child: widget.child,
        ),
      ),
    );
  }
}
