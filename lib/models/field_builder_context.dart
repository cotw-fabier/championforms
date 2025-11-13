import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter/widgets.dart';

/// Context object that bundles all parameters needed by custom field builders.
///
/// The [FieldBuilderContext] simplifies the custom field builder API by packaging
/// all necessary dependencies into a single object. It provides convenience methods
/// for common operations like value management, error handling, and lazy resource
/// initialization.
///
/// ## Core Properties
///
/// - [controller]: The [FormController] managing this field's state
/// - [field]: The field definition ([TextField], [OptionSelect], etc.)
/// - [theme]: The resolved [FormTheme] for this field (after cascading)
/// - [state]: The current [FieldState] (normal, active, error, disabled)
/// - [colors]: The current [FieldColorScheme] based on state
///
/// ## Convenience Methods
///
/// **Value Management:**
/// - [getValue] - Get field value with type safety
/// - [setValue] - Update field value
///
/// **Error Management:**
/// - [addError] - Add a validation error
/// - [clearErrors] - Clear all errors for this field
///
/// **Focus Management:**
/// - [hasFocus] - Check if field is currently focused
///
/// **Resource Management (Lazy Initialization):**
/// - [getTextController] - Get or create [TextEditingController]
/// - [getFocusNode] - Get or create [FocusNode]
///
/// ## Usage in Custom Fields
///
/// ```dart
/// class CustomFieldWidget extends StatelessWidget {
///   final FieldBuilderContext context;
///
///   const CustomFieldWidget({required this.context});
///
///   @override
///   Widget build(BuildContext context) {
///     // Access field definition
///     final field = context.field;
///
///     // Get current value
///     final value = context.getValue<String>() ?? '';
///
///     // Get TextEditingController (created lazily)
///     final controller = context.getTextController();
///
///     // Get FocusNode (created lazily)
///     final focusNode = context.getFocusNode();
///
///     return TextField(
///       controller: controller,
///       focusNode: focusNode,
///       decoration: InputDecoration(
///         labelText: field.title,
///       ),
///       onChanged: (value) {
///         context.setValue(value);
///       },
///     );
///   }
/// }
/// ```
///
/// ## Advanced Usage: Direct Controller Access
///
/// For advanced use cases, the [controller] property provides full access
/// to [FormController] methods:
///
/// ```dart
/// // Programmatic focus control
/// context.controller.setFieldFocus(context.field.id, true);
///
/// // Access other fields' values
/// final otherValue = context.controller.getFieldValue('other_field_id');
///
/// // Trigger validation
/// context.controller.validateField(context.field.id);
/// ```
///
/// ## Lazy Resource Initialization
///
/// [TextEditingController] and [FocusNode] instances are only created when
/// first accessed via [getTextController] or [getFocusNode]. This improves
/// performance by avoiding unnecessary resource allocation for fields that
/// don't need these controllers.
///
/// The same controller/node instance is returned on subsequent calls, ensuring
/// consistency throughout the field's lifecycle.
///
/// ## Theme Cascading
///
/// The [theme] property contains the fully resolved theme after applying the
/// cascade: Default Theme → Global Theme → Form Theme → Field Theme.
/// The [colors] property provides the appropriate [FieldColorScheme] for the
/// current field state.
///
/// See also:
/// - [FormController] for state management operations
/// - [Field] for field definition properties
/// - [FormTheme] for theming configuration
/// - [StatefulFieldWidget] for base class using this context
class FieldBuilderContext {
  // ===========================================================================
  // PUBLIC PROPERTIES
  // ===========================================================================

  /// The [FormController] managing this field's state.
  ///
  /// Exposed publicly for advanced use cases that need direct controller access.
  /// For most operations, prefer using the convenience methods on this context
  /// object ([getValue], [setValue], etc.).
  final FormController controller;

  /// The field definition for this field.
  ///
  /// Contains all field metadata including ID, title, description, validators,
  /// callbacks, and field-specific properties.
  final Field field;

  /// The resolved theme for this field.
  ///
  /// This theme has already been resolved through the theme cascade:
  /// Default Theme → Global Theme → Form Theme → Field Theme.
  final FormTheme theme;

  /// The current state of this field.
  ///
  /// One of: [FieldState.normal], [FieldState.active], [FieldState.error],
  /// or [FieldState.disabled].
  final FieldState state;

  /// The color scheme for the current field state.
  ///
  /// Automatically selected based on [state] from the theme's color schemes
  /// (normal, active, error, disabled).
  final FieldColorScheme colors;

  // ===========================================================================
  // PRIVATE PROPERTIES (Lazy-Initialized Resources)
  // ===========================================================================

  /// Cached [TextEditingController] instance (lazy-initialized).
  TextEditingController? _textController;

  /// Cached [FocusNode] instance (lazy-initialized).
  FocusNode? _focusNode;

  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  /// Creates a new [FieldBuilderContext] with the provided dependencies.
  ///
  /// This constructor is typically called by the [Form] widget when building
  /// fields. Custom field implementations receive an already-constructed context.
  FieldBuilderContext({
    required this.controller,
    required this.field,
    required this.theme,
    required this.state,
    required this.colors,
  });

  // ===========================================================================
  // CONVENIENCE METHODS: Value Management
  // ===========================================================================

  /// Gets the current value for this field.
  ///
  /// Returns the field's stored value cast to type [T], or the field's default
  /// value if no value has been set, or null if neither exists.
  ///
  /// **Type Safety:**
  /// Use the generic type parameter for type-safe access:
  ///
  /// ```dart
  /// final name = context.getValue<String>();
  /// final options = context.getValue<List<FieldOption>>();
  /// final files = context.getValue<List<FileModel>>();
  /// ```
  ///
  /// **Returns:**
  /// The field's current value of type [T], the default value, or null.
  ///
  /// See also:
  /// - [setValue] to update the field value
  /// - [FormController.getFieldValue] for the underlying implementation
  T? getValue<T>() {
    final fieldId = field.id;

    // Check if field definition exists before trying to get value
    if (!controller.hasFieldDefinition(fieldId)) {
      // Field definition doesn't exist yet - initialize with default value
      final defaultValue = controller.getFieldDefaultValue(fieldId);

      // Initialize silently (no notifications during initialization)
      controller.createFieldValue(fieldId, defaultValue, noNotify: true);

      // Return default value with proper type casting
      if (defaultValue is T) {
        return defaultValue;
      }
      return null;
    }

    // Field exists, get its value normally
    return controller.getFieldValue<T>(fieldId);
  }

  /// Sets the value for this field.
  ///
  /// Updates the field's value in the controller and optionally notifies
  /// listeners.
  ///
  /// **Parameters:**
  /// - [value]: The new value to set
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Simple value update
  /// context.setValue('new value');
  ///
  /// // Silent update (no notification)
  /// context.setValue('new value', noNotify: true);
  /// ```
  ///
  /// See also:
  /// - [getValue] to retrieve the field value
  /// - [FormController.updateFieldValue] for the underlying implementation
  void setValue<T>(
    T value, {
    bool noNotify = false,
  }) {
    controller.updateFieldValue<T>(
      field.id,
      value,
      noNotify: noNotify,
    );
  }

  // ===========================================================================
  // CONVENIENCE METHODS: Error Management
  // ===========================================================================

  /// Adds a validation error for this field.
  ///
  /// Creates a new [FormBuilderError] with the provided reason and adds it
  /// to the controller's error list. Does not remove existing errors for this
  /// field; call [clearErrors] first if you want to replace errors.
  ///
  /// **Parameters:**
  /// - [reason]: The error message to display
  ///
  /// **Example:**
  /// ```dart
  /// // Add an error
  /// context.addError('Invalid email format');
  ///
  /// // Add multiple errors
  /// context.addError('Field is required');
  /// context.addError('Must be at least 8 characters');
  /// ```
  ///
  /// See also:
  /// - [clearErrors] to remove errors
  /// - [FormController.addError] for the underlying implementation
  void addError(String reason) {
    controller.addError(
      FormBuilderError(
        fieldId: field.id,
        reason: reason,
        validatorPosition: 0, // Default to first validator position
      ),
    );
  }

  /// Clears all validation errors for this field.
  ///
  /// Removes all [FormBuilderError] instances associated with this field's ID
  /// from the controller's error list.
  ///
  /// **Example:**
  /// ```dart
  /// // Clear all errors before re-validating
  /// context.clearErrors();
  ///
  /// // Then add new errors if needed
  /// if (isInvalid) {
  ///   context.addError('Validation failed');
  /// }
  /// ```
  ///
  /// See also:
  /// - [addError] to add new errors
  /// - [FormController.clearErrors] for the underlying implementation
  void clearErrors() {
    controller.clearErrors(field.id);
  }

  // ===========================================================================
  // CONVENIENCE METHODS: Focus Management
  // ===========================================================================

  /// Returns whether this field is currently focused.
  ///
  /// **Returns:**
  /// `true` if the field has focus, `false` otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (context.hasFocus) {
  ///   // Show autocomplete overlay
  /// }
  /// ```
  ///
  /// See also:
  /// - [getFocusNode] to access the focus node directly
  /// - [FormController.isFieldFocused] for the underlying implementation
  bool get hasFocus {
    return controller.isFieldFocused(field.id);
  }

  // ===========================================================================
  // LAZY RESOURCE INITIALIZATION
  // ===========================================================================

  /// Gets or creates a [TextEditingController] for this field.
  ///
  /// Creates a new [TextEditingController] on first call and caches it for
  /// subsequent calls. The controller is automatically registered with the
  /// [FormController] for lifecycle management.
  ///
  /// **Lazy Initialization Benefits:**
  /// - Only allocates controller when needed
  /// - Improves performance for fields that don't need text editing
  /// - Returns the same instance on repeated calls
  ///
  /// **Important:**
  /// The controller is managed by [FormController] and will be disposed
  /// automatically when the controller is disposed. Do NOT manually dispose
  /// the returned controller.
  ///
  /// **Example:**
  /// ```dart
  /// final textController = context.getTextController();
  /// return TextField(
  ///   controller: textController,
  ///   decoration: InputDecoration(
  ///     labelText: context.field.title,
  ///   ),
  /// );
  /// ```
  ///
  /// **Returns:**
  /// The [TextEditingController] for this field.
  ///
  /// See also:
  /// - [getFocusNode] for focus management
  /// - [FormController.getFieldController] for the underlying implementation
  TextEditingController getTextController() {
    if (_textController == null) {
      // Check if controller already exists in FormController
      _textController = controller.getFieldController<TextEditingController>(field.id);

      // If not, create and register it
      if (_textController == null) {
        // Get initial value safely - check if field exists first
        String initialValue = '';
        if (controller.hasFieldValue(field.id)) {
          initialValue = controller.getFieldValue<String>(field.id) ?? '';
        } else {
          // Field doesn't exist yet, use default value
          initialValue = controller.getFieldDefaultValue(field.id) as String? ?? '';
          // Initialize field with default value (silent, no notifications)
          controller.createFieldValue(field.id, initialValue, noNotify: true);
        }

        _textController = TextEditingController(text: initialValue);
        controller.addFieldController(field.id, _textController!);
      }
    }
    return _textController!;
  }

  /// Gets or creates a [FocusNode] for this field.
  ///
  /// Creates a new [FocusNode] on first call, registers it with the controller,
  /// and caches it for subsequent calls.
  ///
  /// **Lazy Initialization Benefits:**
  /// - Only allocates focus node when needed
  /// - Improves performance for fields that don't manage focus
  /// - Returns the same instance on repeated calls
  ///
  /// **Controller Integration:**
  /// The focus node is automatically registered with [FormController] via
  /// [FormController.addFieldController], enabling focus state tracking and
  /// automatic cleanup on disposal.
  ///
  /// **Important:**
  /// The focus node is managed by [FormController] and will be disposed
  /// automatically when the controller is disposed. Do NOT manually dispose
  /// the returned focus node.
  ///
  /// **Example:**
  /// ```dart
  /// final focusNode = context.getFocusNode();
  /// return TextField(
  ///   focusNode: focusNode,
  ///   onFocusChange: (hasFocus) {
  ///     if (!hasFocus) {
  ///       // Validate on focus loss
  ///       context.controller.validateField(context.field.id);
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// **Returns:**
  /// The [FocusNode] for this field.
  ///
  /// See also:
  /// - [getTextController] for text editing
  /// - [hasFocus] to check current focus state
  /// - [FormController.addFieldController] for controller registration
  FocusNode getFocusNode() {
    // Always check the controller first - it's the single source of truth
    final existingNode = controller.getFieldController<FocusNode>(field.id);

    if (existingNode != null) {
      // Use the existing node from controller
      _focusNode = existingNode;
      return existingNode;
    }

    // Only create a new node if one doesn't exist in controller
    if (_focusNode == null) {
      _focusNode = FocusNode();
      controller.addFieldController(field.id, _focusNode!);
    }

    return _focusNode!;
  }
}
