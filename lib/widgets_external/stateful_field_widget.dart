import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/widgets.dart';

/// Abstract base class for custom form field widgets with automatic lifecycle management.
///
/// [StatefulFieldWidget] eliminates ~50 lines of boilerplate per custom field by:
/// - Automatically integrating with [FormController] via [FieldBuilderContext]
/// - Providing lifecycle hooks for value and focus changes
/// - Automatically triggering validation on focus loss (when `validateLive` is true)
/// - Managing controller listener registration/disposal
/// - Optimizing rebuilds to only occur on relevant state changes
///
/// ## Usage
///
/// Extend this class to create custom field widgets:
///
/// ```dart
/// class CustomTextField extends StatefulFieldWidget {
///   const CustomTextField({required super.context, super.key});
///
///   @override
///   Widget buildWithTheme(
///     BuildContext context,
///     FormTheme theme,
///     FieldBuilderContext ctx,
///   ) {
///     final textController = ctx.getTextController();
///     final focusNode = ctx.getFocusNode();
///
///     return TextField(
///       controller: textController,
///       focusNode: focusNode,
///       decoration: InputDecoration(
///         labelText: ctx.field.textFieldTitle,
///       ),
///     );
///   }
///
///   @override
///   void onValueChanged(dynamic oldValue, dynamic newValue) {
///     // Handle value changes
///     print('Value changed from $oldValue to $newValue');
///   }
///
///   @override
///   void onFocusChanged(bool isFocused) {
///     // Handle focus changes
///     print('Focus changed: $isFocused');
///   }
/// }
/// ```
///
/// ## Lifecycle Hooks
///
/// Override these methods to respond to field state changes:
///
/// - [onValueChanged]: Called when the field's value changes
/// - [onFocusChanged]: Called when the field's focus state changes
/// - [onValidate]: Called on focus loss (default: triggers `validateField` if `validateLive` is true)
///
/// ## Automatic Validation
///
/// By default, when a field loses focus and `field.validateLive` is true,
/// the widget automatically calls `controller.validateField(field.id)`.
/// Override [onValidate] to customize this behavior.
///
/// ## Field Initialization
///
/// When a [StatefulFieldWidget] is constructed and its field doesn't yet exist
/// in the [FormController], the widget automatically initializes the field with
/// its default value during `initState()`. This initialization happens silently
/// without triggering controller listener notifications, preventing unnecessary
/// rebuilds during widget construction.
///
/// This behavior resolves the field initialization race condition where widgets
/// are built before the Form widget has a chance to register fields, allowing
/// [StatefulFieldWidget] to work correctly regardless of registration timing.
///
/// ## Performance Optimizations
///
/// - Rebuilds only when field value or focus state changes (not on unrelated field updates)
/// - Lazy initialization of TextEditingController and FocusNode (only created when accessed)
/// - Value comparison prevents redundant state updates
/// - Field initialization in controller happens without listener notifications
///
/// ## Known Limitations
///
/// - **FormController Notification Behavior**: The underlying [FormController.updateFieldValue]
///   always notifies listeners even when the value doesn't actually change. This means
///   setting a field to its current value will trigger a controller notification, though
///   [StatefulFieldWidget] optimizes this by not rebuilding the widget tree if the value
///   comparison shows no change. This is a limitation of the controller layer, not this
///   widget.
///
/// ## Resource Disposal
///
/// The widget automatically:
/// - Removes controller listener on disposal
/// - Cleans up TextEditingController and FocusNode (managed by FormController)
///
/// See also:
/// - [FieldBuilderContext] for accessing controller methods and resources
/// - [FormController] for state management operations
/// - [Field] for field definition properties
abstract class StatefulFieldWidget extends StatefulWidget {
  /// The context containing all field dependencies (controller, field, theme, etc.).
  final FieldBuilderContext context;

  /// Creates a [StatefulFieldWidget] with the provided [context].
  ///
  /// The [context] bundles all dependencies needed by the field widget,
  /// including the controller, field definition, theme, and state.
  const StatefulFieldWidget({
    required this.context,
    super.key,
  });

  /// Builds the widget UI with access to theme and context.
  ///
  /// This is the primary method subclasses must implement. It receives:
  /// - [context]: The Flutter [BuildContext]
  /// - [theme]: The resolved [FormTheme] for this field
  /// - [ctx]: The [FieldBuilderContext] for accessing controller methods
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// Widget buildWithTheme(
  ///   BuildContext context,
  ///   FormTheme theme,
  ///   FieldBuilderContext ctx,
  /// ) {
  ///   return TextField(
  ///     controller: ctx.getTextController(),
  ///     focusNode: ctx.getFocusNode(),
  ///     decoration: InputDecoration(
  ///       labelText: ctx.field.textFieldTitle,
  ///     ),
  ///   );
  /// }
  /// ```
  Widget buildWithTheme(
    BuildContext context,
    FormTheme theme,
    FieldBuilderContext ctx,
  );

  /// Called when the field's value changes.
  ///
  /// Override this method to respond to value changes:
  ///
  /// ```dart
  /// @override
  /// void onValueChanged(dynamic oldValue, dynamic newValue) {
  ///   // Trigger custom callbacks
  ///   if (context.field.onChange != null) {
  ///     final results = FormResults.getResults(controller: context.controller);
  ///     context.field.onChange!(results);
  ///   }
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [oldValue]: The previous field value
  /// - [newValue]: The new field value
  void onValueChanged(dynamic oldValue, dynamic newValue) {
    // Default: no-op. Subclasses override to implement custom behavior.
  }

  /// Called when the field's focus state changes.
  ///
  /// Override this method to respond to focus changes:
  ///
  /// ```dart
  /// @override
  /// void onFocusChanged(bool isFocused) {
  ///   if (isFocused) {
  ///     // Show autocomplete overlay
  ///   } else {
  ///     // Hide autocomplete overlay
  ///   }
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [isFocused]: `true` if the field gained focus, `false` if it lost focus
  void onFocusChanged(bool isFocused) {
    // Default: no-op. Subclasses override to implement custom behavior.
  }

  /// Called when the field should be validated (on focus loss by default).
  ///
  /// The default implementation triggers deferred validation if `field.validateLive`
  /// is true. Deferred validation runs after the current notification cycle completes,
  /// preventing infinite loops when validation is triggered from within notification
  /// handlers.
  ///
  /// ```dart
  /// if (context.field.validateLive) {
  ///   context.controller.requestDeferredValidation(context.field.id);
  /// }
  /// ```
  ///
  /// Override this method to customize validation behavior:
  ///
  /// ```dart
  /// @override
  /// void onValidate() {
  ///   // Custom validation logic
  ///   context.clearErrors();
  ///   if (myCustomValidation()) {
  ///     context.addError('Custom validation failed');
  ///   }
  /// }
  /// ```
  void onValidate() {
    // Default: trigger deferred validation if validateLive is true
    // Using requestDeferredValidation prevents infinite loops when validation
    // is triggered from within notification handlers
    if (context.field.validateLive) {
      context.controller.requestDeferredValidation(context.field.id);
    }
  }

  @override
  State<StatefulFieldWidget> createState() => _StatefulFieldWidgetState();
}

/// Internal state class for [StatefulFieldWidget].
///
/// This class handles:
/// - Controller listener registration/removal
/// - Value and focus change detection
/// - Lifecycle hook invocation
/// - Rebuild optimization (only rebuild on relevant changes)
class _StatefulFieldWidgetState extends State<StatefulFieldWidget> {
  /// The last known value of this field.
  ///
  /// Used for change detection to determine if [onValueChanged] should be called.
  dynamic _lastValue;

  /// The last known focus state of this field.
  ///
  /// Used for change detection to determine if [onFocusChanged] should be called.
  late bool _lastFocusState;

  /// The FocusNode we created and are managing (for cleanup).
  ///
  /// If we create a FocusNode during initialization, we track it here so we can
  /// properly remove our listener during disposal.
  FocusNode? _managedFocusNode;

  /// The focus listener callback we registered (for cleanup).
  ///
  /// Tracked so we can remove it during disposal to prevent memory leaks.
  VoidCallback? _focusListener;

  @override
  void initState() {
    super.initState();
    // Initialize tracked state - get current value from controller
    // Note: getValue() without type parameter returns null when no explicit value is set,
    // so we need to check the default value as a fallback
    _lastValue = _getCurrentValue();
    _lastFocusState = widget.context.hasFocus;

    // Setup focus tracking (must happen before controller listener)
    _setupFocusTracking();

    // Listen to controller updates
    widget.context.controller.addListener(_onControllerUpdate);
  }

  /// Sets up automatic focus state tracking.
  ///
  /// This method checks if a FocusNode already exists for this field. If not,
  /// it creates one via [FieldBuilderContext.getFocusNode] and registers a
  /// listener that syncs focus changes to the [FormController].
  ///
  /// **Why This Is Needed:**
  /// The [FormController] needs to know about focus changes to:
  /// - Track field focus state via `isFieldFocused()`
  /// - Trigger validation on focus loss (when `validateLive` is true)
  /// - Notify listeners so [_onControllerUpdate] can detect focus changes
  ///
  /// Without this listener, focus changes in the UI would never propagate
  /// to the controller, breaking focus-dependent features like validation.
  ///
  /// **Lifecycle:**
  /// - Called once during `initState()`
  /// - If we create the FocusNode, we track it in [_managedFocusNode]
  /// - The listener is tracked in [_focusListener] for cleanup
  /// - Both are cleaned up in `dispose()`
  void _setupFocusTracking() {
    // Get or create the FocusNode for this field directly from the controller
    // This is the single source of truth that persists across widget rebuilds
    final fieldId = widget.context.field.id;
    final controller = widget.context.controller;

    final existing = controller.getFieldController<FocusNode>(fieldId);

    FocusNode focusNode;
    if (existing != null) {
      focusNode = existing;
    } else {
      focusNode = FocusNode();
      controller.addFieldController(fieldId, focusNode);
    }

    _managedFocusNode = focusNode;

    // Create listener that syncs focus state to controller
    _focusListener = () {
      // Update controller's focus tracking
      // This triggers controller.notifyListeners(), which calls _onControllerUpdate()
      controller.setFieldFocus(
        fieldId,
        focusNode.hasFocus,
      );
    };

    // Register the listener
    // Note: If this FocusNode was already created elsewhere, we're adding
    // a second listener, but that's OK - removeListener will clean it up
    focusNode.addListener(_focusListener!);
  }

  /// Gets the current value, initializing the field if it doesn't exist yet.
  ///
  /// This method:
  /// 1. Checks if the field exists in the controller
  /// 2. If field doesn't exist, initializes it with default value
  /// 3. If field exists, retrieves its current value
  /// 4. Initialization happens without notifying listeners (we're in initState)
  ///
  /// This resolves the field initialization race condition where widgets are
  /// constructed before the Form widget registers fields in the controller.
  dynamic _getCurrentValue() {
    final fieldId = widget.context.field.id;
    final controller = widget.context.controller;

    // Check if field exists BEFORE trying to get value (to avoid exception)
    if (!controller.hasFieldValue(fieldId)) {
      // Field doesn't exist in controller yet - initialize it with default value
      final defaultValue = controller.getFieldDefaultValue(fieldId);

      // Initialize field in controller without notifying listeners
      // (we're in initState, no need to trigger rebuilds)
      // Using createFieldValue() which doesn't require field definition to exist
      controller.createFieldValue(fieldId, defaultValue, noNotify: true);

      return defaultValue;
    }

    // Field exists, get its value
    return widget.context.getValue();
  }

  /// Called whenever the controller notifies of a state change.
  ///
  /// This method:
  /// 1. Checks if this field's value changed
  /// 2. Checks if this field's focus state changed
  /// 3. Invokes appropriate lifecycle hooks
  /// 4. Triggers validation on focus loss (if applicable)
  /// 5. Only calls `setState()` if relevant changes occurred
  void _onControllerUpdate() {
    final newValue = _getCurrentValue();
    final newFocus = widget.context.hasFocus;

    bool shouldRebuild = false;

    // Check for value changes
    if (newValue != _lastValue) {
      widget.onValueChanged(_lastValue, newValue);
      _lastValue = newValue;
      shouldRebuild = true;
    }

    // Check for focus changes
    if (newFocus != _lastFocusState) {
      widget.onFocusChanged(newFocus);
      _lastFocusState = newFocus;
      shouldRebuild = true;

      // Trigger validation on focus loss
      if (!newFocus) {
        widget.onValidate();
      }
    }

    // Only rebuild if relevant changes occurred
    // This optimization prevents unnecessary rebuilds when unrelated fields change
    if (shouldRebuild) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.buildWithTheme(
      context,
      widget.context.theme,
      widget.context,
    );
  }

  @override
  void dispose() {
    // Remove focus listener if we added one
    // This prevents "listener callback still registered" errors and memory leaks
    if (_managedFocusNode != null && _focusListener != null) {
      _managedFocusNode!.removeListener(_focusListener!);
    }

    // Remove controller listener to prevent memory leaks
    widget.context.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }
}
