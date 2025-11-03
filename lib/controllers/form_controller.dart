// We are going to build one giant controller to handle all aspects of our form.

import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

/// Central state management controller for ChampionForms.
///
/// The [FormController] manages all aspects of form state including
/// field values, validation errors, focus states, and TextEditingController
/// lifecycles. It serves as the single source of truth for form data and
/// enables programmatic control over form fields.
///
/// ## Features
///
/// - **Centralized Value Storage**: Generic field value storage supporting
///   text, multiselect, file uploads, and custom types
/// - **Validation Management**: Run validators, track errors, clear errors
/// - **Focus Control**: Programmatically manage field focus states
/// - **Page Grouping**: Organize fields into pages for multi-step workflows
/// - **Lifecycle Management**: Automatic disposal of controllers and focus nodes
///
/// ## Basic Usage
///
/// ```dart
/// // 1. Create a controller
/// final controller = FormController();
///
/// // 2. Use in Form widget
/// Form(
///   controller: controller,
///   fields: myFields,
/// )
///
/// // 3. Access form data
/// final name = controller.getFieldValue<String>('name');
///
/// // 4. Validate and get results
/// final results = FormResults.getResults(controller: controller);
/// if (!results.errorState) {
///   // Process results...
/// }
///
/// // 5. Dispose when done
/// controller.dispose();
/// ```
///
/// ## Important Notes
///
/// - **Always call dispose()**: The controller manages many resources that
///   must be properly disposed to prevent memory leaks
/// - **ChangeNotifier**: Extends [ChangeNotifier], so listeners are notified
///   of state changes. Most methods accept a `noNotify` parameter to suppress
///   notifications during batch operations
/// - **Integration**: Designed to work seamlessly with [Form],
///   [Field], and [FormResults]
///
/// See also:
/// - [Form] for the form widget
/// - [FormResults] for retrieving validated form data
/// - [Field] for field definitions
class FormController extends ChangeNotifier {
  // ===========================================================================
  // CONSTRUCTOR
  // ===========================================================================

  FormController({
    String? id,
    this.fields = const [],
    this.formErrors = const [],
    this.activeFields = const [],
    Map<String, List<Field>>? pageFields,
  })  : id = id ?? Uuid().v4(),
        pageFields = pageFields ?? {};

  // ===========================================================================
  // PUBLIC PROPERTIES
  // ===========================================================================

  /// Unique identifier for this controller instance.
  ///
  /// Automatically generated using UUID if not provided during construction.
  /// Used to differentiate this controller from other controller instances
  /// in the application.
  final String id;

  /// List of all field definitions linked to this controller.
  ///
  /// Contains all [Field] instances that have been associated with
  /// this controller. Primarily used for initialization and bulk operations.
  List<Field> fields;

  /// List of current validation errors in the form.
  ///
  /// Contains [FormBuilderError] objects for all fields that have failed
  /// validation. Updated automatically when validation runs or when errors
  /// are manually added/cleared.
  ///
  /// Example: `[FormBuilderError(fieldId: 'email', reason: 'Invalid email')]`
  List<FormBuilderError> formErrors;

  /// List of currently rendered field definitions.
  ///
  /// Contains an updated list of [Field] objects currently rendered
  /// in [Form] widgets. Automatically maintained by the form widget
  /// lifecycle methods.
  ///
  /// This differs from [fields] in that it only contains fields actively
  /// being displayed, not all fields that have been registered.
  List<Field> activeFields;

  /// Map of field definitions organized by page name.
  ///
  /// Groups fields into named pages for multi-step form workflows. Fields
  /// are added to pages using the `pageName` parameter on [Form].
  /// Retrieve a page's fields using [getPageFields].
  ///
  /// Example: `{'step-1': [field1, field2], 'step-2': [field3, field4]}`
  ///
  /// See also:
  /// - [getPageFields] to retrieve fields for a specific page
  /// - [updatePageFields] to add fields to a page
  Map<String, List<Field>> pageFields;

  // ===========================================================================
  // PRIVATE PROPERTIES
  // ===========================================================================

  /// Internal storage for field values indexed by field ID.
  ///
  /// Stores the current value for each field using the field's unique ID as
  /// the key. Values can be of any type (`String`, `List&lt;MultiselectOption&gt;`,
  /// etc.) depending on the field type.
  ///
  /// Example: `{'name': 'John Doe', 'email': 'john@example.com'}`
  final Map<String, dynamic> _fieldValues = {};

  /// Internal storage for field state indexed by field ID.
  ///
  /// Tracks the current visual/interaction state (normal, active, error,
  /// disabled) for each field. Updated automatically based on focus, errors,
  /// and field properties.
  ///
  /// Example: `{'name': FieldState.normal, 'email': FieldState.error}`
  final Map<String, FieldState> _fieldStates = {};

  /// Internal storage for field definitions indexed by field ID.
  ///
  /// Maintains a lookup map of all registered field definitions for quick
  /// access to field metadata, validators, and properties. Populated by
  /// [addFields].
  ///
  /// Example: `{'name': TextField(...), 'email': TextField(...)}`
  final Map<String, Field> _fieldDefinitions = {};

  /// Internal storage for field focus states indexed by field ID.
  ///
  /// Tracks whether each field is currently focused (true) or not (false).
  /// Used internally to calculate field states and manage focus transitions.
  ///
  /// Example: `{'name': true, 'email': false}`
  final Map<String, bool> _fieldFocusStates = {};

  /// Internal storage for field controllers indexed by field ID.
  ///
  /// Stores TextEditingController and other controller instances for fields
  /// that require them. Controllers are automatically disposed when the form
  /// controller is disposed.
  ///
  /// Example: `{'name': TextEditingController(), 'description': TextEditingController()}`
  final Map<String, dynamic> _fieldControllers = {};

  // ===========================================================================
  // PUBLIC LIFECYCLE METHODS
  // ===========================================================================

  /// Disposes all resources managed by this controller.
  ///
  /// Properly disposes all TextEditingControllers, FocusNodes, and other
  /// ChangeNotifier instances stored in this controller. Must be called
  /// when the controller is no longer needed to prevent memory leaks.
  ///
  /// **Important**: Keep the controller alive as long as you are interacting
  /// with any fields this controller manages, or the fields will break.
  ///
  /// **Example:**
  /// ```dart
  /// @override
  /// void dispose() {
  ///   formController.dispose();
  ///   super.dispose();
  /// }
  /// ```
  @override
  void dispose() {
    _fieldControllers.forEach((key, controller) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      } else if (controller is FocusNode) {
        controller.dispose();
      }
    });

    super.dispose();
  }

  /// Registers field definitions with this controller.
  ///
  /// Populates the controller with new field definitions, initializing their
  /// internal state tracking. This is automatically called when fields are
  /// added to a [Form] widget, but can be manually called to
  /// prepopulate the controller before a form widget is created.
  ///
  /// Only adds fields that don't already exist or updates them if the
  /// definition has changed. Recalculates field states after adding.
  ///
  /// **Parameters:**
  /// - [newFields]: List of field definitions to register
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Multi-page form: prepopulate controller with all pages
  /// controller.addFields([...page1Fields, ...page2Fields, ...page3Fields]);
  ///
  /// // Then use the controller with different Form widgets
  /// Form(controller: controller, fields: page1Fields)
  /// ```
  ///
  /// See also:
  /// - [updateActiveFields] to track currently rendered fields
  void addFields(
    List<Field> newFields, {
    bool noNotify = false,
  }) {
    bool changed = false;
    for (final Field field in newFields) {
      if (!_fieldDefinitions.containsKey(field.id)) {
        _fieldDefinitions[field.id] = field;
        _fieldFocusStates.putIfAbsent(field.id, () => false);
        _updateFieldState(field.id);
        changed = true;
      } else if (_fieldDefinitions[field.id] != field) {
        _fieldDefinitions[field.id] = field;
        _updateFieldState(field.id);
        changed = true;
      }
    }
    if (changed && !noNotify) {
      notifyListeners();
    }
  }

  /// Updates the list of currently rendered fields.
  ///
  /// Merges the provided fields into [activeFields], which tracks all field
  /// definitions currently being displayed in [Form] widgets.
  /// Automatically called by the form widget during its build lifecycle.
  ///
  /// Removes any existing fields with matching IDs before adding to prevent
  /// duplicates.
  ///
  /// **Parameters:**
  /// - [fields]: List of field definitions currently being rendered
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  void updateActiveFields(
    List<Field> fields, {
    bool noNotify = false,
  }) {
    removeActiveFields(fields, noNotify: true);

    activeFields = [...activeFields, ...fields];

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Removes fields from the active fields list.
  ///
  /// Removes the provided field definitions from [activeFields]. Automatically
  /// called by [Form] when the widget is torn down. Can also be called
  /// manually to track which fields are no longer rendered.
  ///
  /// **Parameters:**
  /// - [fields]: List of field definitions to remove from active fields
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  void removeActiveFields(
    List<Field> fields, {
    bool noNotify = false,
  }) {
    activeFields = activeFields
        .where((field) => !fields.any((f) => f.id == field.id))
        .toList();

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Adds field definitions to a named page group.
  ///
  /// Organizes fields into named pages for multi-step form workflows. If the
  /// page already exists, adds the fields to the existing list. Otherwise,
  /// creates a new page with the provided fields.
  ///
  /// Does not notify listeners since this should happen silently as the
  /// controller is updated by form widgets.
  ///
  /// **Parameters:**
  /// - [pageName]: Unique identifier for the page
  /// - [fields]: List of field definitions to add to the page
  ///
  /// **Example:**
  /// ```dart
  /// // Manually organize fields into pages
  /// controller.updatePageFields('personal-info', [nameField, emailField]);
  /// controller.updatePageFields('address', [streetField, cityField]);
  ///
  /// // Or let Form do it automatically:
  /// Form(
  ///   controller: controller,
  ///   pageName: 'personal-info',
  ///   fields: [nameField, emailField],
  /// )
  /// ```
  ///
  /// See also:
  /// - [getPageFields] to retrieve fields for a page
  void updatePageFields(
    String pageName,
    List<Field> fields,
  ) {
    if (pageFields.containsKey(pageName)) {
      pageFields[pageName] = [...pageFields[pageName]!, ...fields];
    } else {
      pageFields[pageName] = fields;
    }
  }

  /// Retrieves all field definitions for a specific page.
  ///
  /// Returns the list of [Field] objects associated with the
  /// specified page name. Returns an empty list if the page doesn't exist.
  ///
  /// **Parameters:**
  /// - [pageName]: The unique identifier of the page
  ///
  /// **Returns:**
  /// List of field definitions for the page, or empty list if page not found.
  ///
  /// **Example:**
  /// ```dart
  /// // Get fields for a specific page
  /// final step1Fields = controller.getPageFields('step-1');
  ///
  /// // Validate only fields on current page
  /// final pageResults = FormResults.getResults(
  ///   controller: controller,
  ///   fields: controller.getPageFields('step-1'),
  /// );
  /// ```
  ///
  /// See also:
  /// - [updatePageFields] to add fields to a page
  List<Field> getPageFields(String pageName) {
    if (pageFields.containsKey(pageName)) {
      return pageFields[pageName] ?? [];
    } else {
      return [];
    }
  }

  // ===========================================================================
  // PUBLIC FIELD VALUE METHODS
  // ===========================================================================

  /// Retrieves the current value for a field.
  ///
  /// Returns the stored value for the specified field ID, or the field's
  /// default value if no value has been explicitly set. Returns null if the
  /// field doesn't exist or has no value or default.
  ///
  /// Use the generic type parameter [T] for type-safe value retrieval. If
  /// the stored value doesn't match type [T], returns null.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// The field's current value cast to type [T], the default value, or null.
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  /// - [TypeError]: If stored value type doesn't match requested type [T]
  ///
  /// **Example:**
  /// ```dart
  /// // Get text field value
  /// final name = controller.getFieldValue<String>('name');
  ///
  /// // Get multiselect value
  /// final options = controller.getFieldValue<List<MultiselectOption>>('skills');
  ///
  /// // Check if value exists
  /// final email = controller.getFieldValue<String>('email');
  /// if (email != null) {
  ///   print('Email: $email');
  /// }
  /// ```
  ///
  /// See also:
  /// - [updateFieldValue] to set a field's value
  /// - [getMultiselectValue] for convenient multiselect field access
  T? getFieldValue<T>(String fieldId) {
    try {
      // Validate field exists
      if (!_fieldDefinitions.containsKey(fieldId)) {
        throw ArgumentError(
          'Field "$fieldId" does not exist in controller. '
          'Available fields: ${_fieldDefinitions.keys.join(", ")}',
        );
      }

      final value = _fieldValues[fieldId];

      // Type validation
      if (value != null && value is! T && T != dynamic) {
        throw TypeError();
      }

      if (value is T || T == dynamic) {
        return value;
      }

      // Return default value if no value set
      if (value == null) {
        final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;
        if (defaultValue is T) {
          return defaultValue;
        }
      }

      return null;
    } on ArgumentError {
      rethrow;
    } on TypeError {
      rethrow;
    } catch (e) {
      return null;
    }
  }

  /// Updates the value for a field.
  ///
  /// Sets a new value for the specified field, automatically triggering the
  /// field's `onChange` callback if the value actually changed. If
  /// `validateLive` is enabled on the field, also runs validation.
  ///
  /// Pass null as [newValue] to remove the explicit value, causing the field
  /// to revert to its default value.
  ///
  /// **Parameters:**
  /// - [id]: The unique identifier of the field
  /// - [newValue]: The new value to set, or null to clear
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [id] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Update text field
  /// controller.updateFieldValue<String>('email', 'user@example.com');
  ///
  /// // Clear a field (revert to default)
  /// controller.updateFieldValue<String>('email', null);
  ///
  /// // Batch updates without notifications
  /// controller.updateFieldValue<String>('name', 'John', noNotify: true);
  /// controller.updateFieldValue<String>('email', 'john@example.com', noNotify: true);
  /// controller.notifyListeners();
  /// ```
  ///
  /// See also:
  /// - [getFieldValue] to retrieve a field's value
  /// - [updateMultiselectValues] for multiselect-specific updates
  void updateFieldValue<T>(String id, T? newValue, {bool noNotify = false}) {
    // Validate field exists
    if (!_fieldDefinitions.containsKey(id)) {
      throw ArgumentError(
        'Field "$id" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    final T? oldValue =
        _fieldValues.containsKey(id) ? _fieldValues[id] as T? : null;

    if (newValue != null) {
      _fieldValues[id] = newValue;
    } else {
      _fieldValues.remove(id);
    }

    if (oldValue != newValue) {
      final fieldDef = _fieldDefinitions[id];
      if (fieldDef?.onChange != null) {
        try {
          final results = FormResults.getResults(
              controller: this, fields: [if (fieldDef != null) fieldDef]);
          fieldDef!.onChange!(results);
        } catch (e) {
          // Silent error handling - onChange is external code
        }
      }

      if (fieldDef?.validateLive ?? false) {
        _validateField(id);
      }

      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Returns all field values as a Map.
  ///
  /// Useful for debugging, serialization, or batch operations. Includes only
  /// fields that have values set (not default values unless explicitly set).
  ///
  /// **Returns:**
  /// Map of field ID to field value. May be empty if no values set.
  ///
  /// **Example:**
  /// ```dart
  /// final allValues = controller.getAllFieldValues();
  /// print('Form data: $allValues');
  ///
  /// // Save to local storage
  /// await storage.write('form-draft', jsonEncode(allValues));
  /// ```
  ///
  /// See also:
  /// - [setFieldValues] to batch set values
  /// - [getFieldValue] to get a single value
  Map<String, dynamic> getAllFieldValues() {
    return Map.from(_fieldValues);
  }

  /// Batch sets multiple field values at once.
  ///
  /// Useful for loading saved form data or pre-populating forms. Suppresses
  /// individual notifications and notifies once after all values are set.
  ///
  /// **Parameters:**
  /// - [values]: Map of field ID to value
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Load saved draft
  /// final savedData = await storage.read('form-draft');
  /// controller.setFieldValues(jsonDecode(savedData));
  ///
  /// // Pre-populate from user profile
  /// controller.setFieldValues({
  ///   'name': user.name,
  ///   'email': user.email,
  /// });
  /// ```
  ///
  /// **Note:** Only sets values for fields that exist. Ignores unknown field IDs.
  ///
  /// See also:
  /// - [getAllFieldValues] to retrieve all values
  /// - [updateFieldValue] to set a single value
  void setFieldValues(Map<String, dynamic> values, {bool noNotify = false}) {
    for (final entry in values.entries) {
      if (_fieldDefinitions.containsKey(entry.key)) {
        updateFieldValue(entry.key, entry.value, noNotify: true);
      }
    }
    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Retrieves the default value for a field.
  ///
  /// Returns the [Field.defaultValue] specified in the field definition.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// The default value, or null if field doesn't exist or has no default.
  ///
  /// **Example:**
  /// ```dart
  /// final defaultEmail = controller.getFieldDefaultValue('email');
  /// print('Default: $defaultEmail');
  /// ```
  ///
  /// See also:
  /// - [resetField] to reset field to default value
  dynamic getFieldDefaultValue(String fieldId) {
    return _fieldDefinitions[fieldId]?.defaultValue;
  }

  /// Checks if a field has a value explicitly set.
  ///
  /// Returns `true` if the field has a value in [_fieldValues], even if that
  /// value is empty or null. Returns `false` if the field has never been set
  /// and is relying on its default value.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// True if field has an explicit value set, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// // Check if user has interacted with field
  /// if (controller.hasFieldValue('email')) {
  ///   // User has entered something
  /// }
  /// ```
  ///
  /// See also:
  /// - [getFieldValue] to retrieve the value
  bool hasFieldValue(String fieldId) {
    return _fieldValues.containsKey(fieldId);
  }

  /// Checks if any field has been modified from its default value.
  ///
  /// Returns `true` if any field in [_fieldValues] differs from its default,
  /// or if any field has a value set when it has no default.
  ///
  /// **Returns:**
  /// True if form has been modified, false if pristine.
  ///
  /// **Example:**
  /// ```dart
  /// // Warn before navigating away
  /// if (controller.isDirty) {
  ///   showDialog(/* "You have unsaved changes" */);
  /// }
  /// ```
  ///
  /// See also:
  /// - [resetAllFields] to restore defaults
  bool get isDirty {
    for (final entry in _fieldValues.entries) {
      final fieldId = entry.key;
      final currentValue = entry.value;
      final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;

      if (currentValue != defaultValue) {
        return true;
      }
    }
    return false;
  }

  // ===========================================================================
  // PUBLIC FIELD MANAGEMENT METHODS
  // ===========================================================================

  /// Dynamically updates or adds a field definition.
  ///
  /// If a field with the same ID exists, replaces its definition. If not,
  /// adds it as a new field. Updates field state after modification.
  ///
  /// **Parameters:**
  /// - [field]: The field definition to update or add
  ///
  /// **Example:**
  /// ```dart
  /// // Dynamically disable a field
  /// final updatedField = myField.copyWith(disabled: true);
  /// controller.updateField(updatedField);
  ///
  /// // Add a new field dynamically
  /// controller.updateField(TextField(id: 'dynamic-field', ...));
  /// ```
  ///
  /// See also:
  /// - [addFields] to add multiple fields at once
  /// - [removeField] to remove a field
  void updateField(Field field) {
    _fieldDefinitions[field.id] = field;
    _fieldFocusStates.putIfAbsent(field.id, () => false);
    _updateFieldState(field.id);
    notifyListeners();
  }

  /// Removes a field from the controller.
  ///
  /// Clears the field's value, errors, state, and definition. Disposes any
  /// associated controller or focus node.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to remove
  ///
  /// **Example:**
  /// ```dart
  /// // Conditionally remove a field based on user selection
  /// if (userType == 'guest') {
  ///   controller.removeField('account-password');
  /// }
  /// ```
  ///
  /// **Note:** This does not update [activeFields] or [pageFields]. Use
  /// [removeActiveFields] for managing rendered fields.
  ///
  /// See also:
  /// - [updateField] to modify a field
  /// - [clearForm] to clear all field values
  void removeField(String fieldId) {
    // Dispose controller if it exists
    final controller = _fieldControllers[fieldId];
    if (controller != null) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      } else if (controller is FocusNode) {
        controller.dispose();
      }
      _fieldControllers.remove(fieldId);
    }

    // Remove from all internal maps
    _fieldDefinitions.remove(fieldId);
    _fieldValues.remove(fieldId);
    _fieldStates.remove(fieldId);
    _fieldFocusStates.remove(fieldId);

    // Clear errors for this field
    clearErrors(fieldId, noNotify: true);

    notifyListeners();
  }

  /// Checks if a field definition exists in the controller.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to check
  ///
  /// **Returns:**
  /// True if field exists, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (controller.hasField('optional-notes')) {
  ///   final notes = controller.getFieldValue<String>('optional-notes');
  /// }
  /// ```
  bool hasField(String fieldId) {
    return _fieldDefinitions.containsKey(fieldId);
  }

  /// Resets a field to its default value.
  ///
  /// Sets the field's value back to its [Field.defaultValue] and clears
  /// any validation errors for that field.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to reset
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Reset field after error
  /// controller.resetField('email');
  /// ```
  ///
  /// See also:
  /// - [resetAllFields] to reset entire form
  /// - [getFieldDefaultValue] to retrieve default without resetting
  void resetField(String fieldId) {
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;
    updateFieldValue(fieldId, defaultValue, noNotify: true);
    clearErrors(fieldId, noNotify: true);
    notifyListeners();
  }

  /// Resets all fields to their default values.
  ///
  /// Iterates through all field definitions and resets each to its
  /// [Field.defaultValue]. Clears all validation errors.
  ///
  /// **Parameters:**
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Reset form after submission
  /// controller.resetAllFields();
  ///
  /// // Or show confirmation dialog first
  /// if (await confirmReset()) {
  ///   controller.resetAllFields();
  /// }
  /// ```
  ///
  /// See also:
  /// - [resetField] to reset a single field
  /// - [clearForm] to clear all values without restoring defaults
  void resetAllFields({bool noNotify = false}) {
    for (final fieldId in _fieldDefinitions.keys) {
      final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;
      updateFieldValue(fieldId, defaultValue, noNotify: true);
    }
    clearAllErrors(noNotify: true);

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Clears all field values without restoring defaults.
  ///
  /// Removes all entries from [_fieldValues], effectively setting all fields
  /// to empty/null. Does not clear validation errors.
  ///
  /// **Parameters:**
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Start fresh form
  /// controller.clearForm();
  /// controller.clearAllErrors();
  /// ```
  ///
  /// See also:
  /// - [resetAllFields] to reset to default values instead
  /// - [clearAllErrors] to clear validation errors
  void clearForm({bool noNotify = false}) {
    // Get all field IDs that had values
    final fieldIdsWithValues = _fieldValues.keys.toList();

    // Clear the values map
    _fieldValues.clear();

    // Update state for all fields that had values
    for (final fieldId in fieldIdsWithValues) {
      _updateFieldState(fieldId);
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // ===========================================================================
  // PUBLIC MULTISELECT METHODS
  // ===========================================================================

  /// Retrieves the currently selected options for a multiselect field.
  ///
  /// Returns the list of [MultiselectOption] objects currently selected for
  /// the specified field. Returns null if the field hasn't been interacted
  /// with or has no value set. Returns an empty list if the field is set but
  /// has no options selected.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the multiselect field
  ///
  /// **Returns:**
  /// List of selected options, empty list if none selected, or null if field
  /// has no value set.
  ///
  /// **Example:**
  /// ```dart
  /// // Get selected options
  /// final selected = controller.getMultiselectValue('skills');
  /// if (selected != null && selected.isNotEmpty) {
  ///   print('Selected skills: ${selected.map((o) => o.label).join(", ")}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [updateMultiselectValues] to modify selections
  /// - [toggleMultiSelectValue] for convenient toggle operations
  List<MultiselectOption>? getMultiselectValue(String fieldId) {
    return getFieldValue<List<MultiselectOption>>(fieldId);
  }

  /// Updates the selected value(s) for a multiselect or option field.
  ///
  /// Provides flexible control over field selections with support for both
  /// single-select and multi-select fields. Can either overwrite existing
  /// selections or toggle options on/off.
  ///
  /// **Parameters:**
  /// - [id]: The unique identifier of the field
  /// - [newValue]: List of options to set or toggle
  /// - [multiselect]: If true, allows multiple selections. If null, infers from field definition
  /// - [overwrite]: If true, replaces all selections. If false, toggles options
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  /// - [noOnChange]: If true, suppresses onChange callback. Defaults to false
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [id] does not exist
  /// - [TypeError]: If field is not a OptionSelect
  ///
  /// **Example:**
  /// ```dart
  /// // Overwrite selections
  /// controller.updateMultiselectValues(
  ///   'skills',
  ///   [option1, option2],
  ///   overwrite: true,
  /// );
  ///
  /// // Toggle selections (add if not present, remove if present)
  /// controller.updateMultiselectValues(
  ///   'skills',
  ///   [option3],
  ///   overwrite: false,
  /// );
  ///
  /// // Force single-select behavior
  /// controller.updateMultiselectValues(
  ///   'priority',
  ///   [highPriority],
  ///   multiselect: false,
  ///   overwrite: true,
  /// );
  /// ```
  ///
  /// See also:
  /// - [toggleMultiSelectValue] for simpler toggle operations
  /// - [removeMultiSelectOptions] to clear all selections
  void updateMultiselectValues(
    String id,
    List<MultiselectOption> newValue, {
    bool? multiselect,
    bool overwrite = false,
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    // Validate field exists
    if (!_fieldDefinitions.containsKey(id)) {
      throw ArgumentError(
        'Field "$id" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    final field = _fieldDefinitions[id];

    // Validate field type
    if (field is! OptionSelect) {
      throw TypeError();
    }

    final isMultiselect = multiselect ?? field.multiselect;

    List<MultiselectOption> currentValues = List<MultiselectOption>.from(
        getFieldValue<List<MultiselectOption>>(id) ?? []);
    List<MultiselectOption> finalValue;

    if (overwrite) {
      if (isMultiselect) {
        finalValue = List<MultiselectOption>.from(newValue);
      } else {
        finalValue = newValue.isNotEmpty ? [newValue.first] : [];
      }
    } else {
      final Set<String> newValueValues = newValue.map((o) => o.value).toSet();
      final Set<String> currentValuesSet =
          currentValues.map((o) => o.value).toSet();
      List<MultiselectOption> mergedValues = [];

      if (isMultiselect) {
        mergedValues.addAll(currentValues
            .where((option) => !newValueValues.contains(option.value)));
        mergedValues.addAll(newValue
            .where((option) => !currentValuesSet.contains(option.value)));
      } else {
        if (newValue.isNotEmpty) {
          final firstNewOption = newValue.first;
          if (!currentValuesSet.contains(firstNewOption.value)) {
            mergedValues = [firstNewOption];
          } else {
            mergedValues = [];
          }
        } else {
          mergedValues = [];
        }
      }
      finalValue = mergedValues;
    }

    updateFieldValue<List<MultiselectOption>>(id, finalValue,
        noNotify: noNotify);
  }

  /// Toggles specific options on or off for a multiselect field.
  ///
  /// Provides a convenient way to ensure specific options are selected
  /// (toggleOn) or deselected (toggleOff) without needing to manage the full
  /// list of selections. Works with option values (not labels).
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [toggleOn]: List of option values to ensure are selected
  /// - [toggleOff]: List of option values to ensure are deselected
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  /// - [TypeError]: If field is not a OptionSelect
  ///
  /// **Example:**
  /// ```dart
  /// // Select some options
  /// controller.toggleMultiSelectValue(
  ///   'skills',
  ///   toggleOn: ['dart', 'flutter'],
  /// );
  ///
  /// // Deselect some options
  /// controller.toggleMultiSelectValue(
  ///   'skills',
  ///   toggleOff: ['java', 'kotlin'],
  /// );
  ///
  /// // Combine both
  /// controller.toggleMultiSelectValue(
  ///   'skills',
  ///   toggleOn: ['dart', 'flutter'],
  ///   toggleOff: ['java'],
  /// );
  /// ```
  ///
  /// **Note:** Uses the `value` property of [MultiselectOption], not the label.
  ///
  /// See also:
  /// - [updateMultiselectValues] for more control over selections
  /// - [removeMultiSelectOptions] to clear all selections
  void toggleMultiSelectValue(
    String fieldId, {
    List<String> toggleOn = const [],
    List<String> toggleOff = const [],
    bool noNotify = false,
  }) {
    // Validate field exists
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    final fieldDef = _fieldDefinitions[fieldId];

    // Validate field type
    if (fieldDef is! OptionSelect) {
      throw TypeError();
    }

    final List<MultiselectOption> currentSelectedOptions =
        getFieldValue<List<MultiselectOption>>(fieldId) ?? [];

    final Set<String> newSelectedValues =
        currentSelectedOptions.map((o) => o.value).toSet();

    for (final valueToSelect in toggleOn) {
      newSelectedValues.add(valueToSelect);
    }
    for (final valueToDeselect in toggleOff) {
      newSelectedValues.remove(valueToDeselect);
    }

    final List<MultiselectOption> finalSelectedOptions =
        (fieldDef.options ?? [])
            .where((option) => newSelectedValues.contains(option.value))
            .toList();

    updateFieldValue<List<MultiselectOption>>(
      fieldId,
      finalSelectedOptions,
      noNotify: noNotify,
    );
  }

  /// Clears all selected options for a multiselect field.
  ///
  /// Removes all selections by setting the field's value to an empty list.
  /// Optionally triggers onChange callback and notifies listeners.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  /// - [noOnChange]: If true, suppresses onChange callback. Defaults to false
  ///
  /// **Example:**
  /// ```dart
  /// // Clear all file uploads
  /// controller.removeMultiSelectOptions('attachments');
  ///
  /// // Clear selections without notification
  /// controller.removeMultiSelectOptions('skills', noNotify: true);
  /// ```
  ///
  /// See also:
  /// - [resetMultiselectChoices] (equivalent method)
  /// - [updateMultiselectValues] for more control
  void removeMultiSelectOptions(
    String fieldId, {
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    updateMultiselectValues(
      fieldId,
      [],
      overwrite: true,
      noNotify: noNotify,
      noOnChange: noOnChange,
    );
  }

  /// Resets a multiselect field by clearing its selected values.
  ///
  /// This is equivalent to calling [removeMultiSelectOptions] and clears all
  /// selected options from the field.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  /// - [noOnChange]: If true, suppresses onChange callback. Defaults to false
  ///
  /// **Example:**
  /// ```dart
  /// // Reset checkbox selections
  /// controller.resetMultiselectChoices('preferences');
  /// ```
  ///
  /// See also:
  /// - [removeMultiSelectOptions] (equivalent method)
  void resetMultiselectChoices(
    String fieldId, {
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    removeMultiSelectOptions(
      fieldId,
      noNotify: noNotify,
      noOnChange: noOnChange,
    );
  }

  // ===========================================================================
  // PUBLIC VALIDATION METHODS
  // ===========================================================================

  /// Validates all active fields in the form.
  ///
  /// Runs all validators for every field in [activeFields] and updates the
  /// [formErrors] list. This method is typically called before retrieving
  /// form results to ensure all data is valid.
  ///
  /// **Returns:**
  /// True if the form has no validation errors, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (controller.validateForm()) {
  ///   // Form is valid, proceed with submission
  ///   final results = FormResults.getResults(controller: controller);
  ///   submitData(results);
  /// } else {
  ///   // Show errors to user
  ///   print('Form has ${controller.formErrors.length} errors');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isFormValid] for a quick validity check without re-running validators
  /// - [validateField] to validate a single field
  /// - [validatePage] to validate fields on a specific page
  bool validateForm() {
    for (final field in activeFields) {
      _validateField(field.id, notify: false);
    }
    notifyListeners();
    return formErrors.isEmpty;
  }

  /// Quick check for whether the form currently has any validation errors.
  ///
  /// Unlike [validateForm], this getter does not re-run validators. It simply
  /// checks if [formErrors] is currently empty. Use this for quick status
  /// checks or to enable/disable submit buttons reactively.
  ///
  /// **Returns:**
  /// True if [formErrors] is empty, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// // In build method
  /// ElevatedButton(
  ///   onPressed: controller.isFormValid ? _handleSubmit : null,
  ///   child: Text('Submit'),
  /// )
  /// ```
  ///
  /// See also:
  /// - [validateForm] to run validators and update error state
  /// - [hasErrors] to check for errors on specific fields
  bool get isFormValid => formErrors.isEmpty;

  /// Public wrapper to validate a specific field.
  ///
  /// Runs all validators for the specified field and updates [formErrors].
  /// Previously, field validation was only accessible internally via the
  /// private [_validateField] method.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to validate
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Validate email field after user input
  /// controller.validateField('email');
  ///
  /// // Check for errors
  /// final emailErrors = controller.findErrors('email');
  /// if (emailErrors.isNotEmpty) {
  ///   print('Email is invalid: ${emailErrors.first.reason}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [validateForm] to validate all fields at once
  /// - [findErrors] to retrieve validation errors for a field
  void validateField(String fieldId) {
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }
    _validateField(fieldId, notify: true);
  }

  /// Validates all fields on a specific page.
  ///
  /// Runs validators for all fields that were registered to the specified page
  /// using the `pageName` parameter in [Form]. Useful for multi-step
  /// forms where you want to validate one page at a time.
  ///
  /// **Parameters:**
  /// - [pageName]: The name of the page to validate
  ///
  /// **Returns:**
  /// True if all fields on the page are valid, false otherwise.
  ///
  /// **Throws:**
  /// - [ArgumentError]: If page with [pageName] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Multi-step form validation
  /// if (controller.validatePage('personal-info')) {
  ///   // Move to next page
  ///   navigateToNextPage();
  /// } else {
  ///   // Show errors on current page
  ///   showErrorMessage('Please fix errors before continuing');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isPageValid] for a quick check without re-running validators
  /// - [getPageFields] to retrieve fields on a page
  /// - [validateForm] to validate entire form
  bool validatePage(String pageName) {
    final fieldsOnPage = getPageFields(pageName);

    if (fieldsOnPage.isEmpty && !pageFields.containsKey(pageName)) {
      throw ArgumentError(
        'Page "$pageName" does not exist in controller. '
        'Available pages: ${pageFields.keys.join(", ")}',
      );
    }

    for (final field in fieldsOnPage) {
      _validateField(field.id, notify: false);
    }
    notifyListeners();

    // Check if any field on this page has errors
    final fieldIdsOnPage = fieldsOnPage.map((f) => f.id).toSet();
    return !formErrors.any((error) => fieldIdsOnPage.contains(error.fieldId));
  }

  /// Quick check for whether a specific page has validation errors.
  ///
  /// Unlike [validatePage], this method does not re-run validators. It checks
  /// if any fields on the specified page currently have errors in [formErrors].
  ///
  /// **Parameters:**
  /// - [pageName]: The name of the page to check
  ///
  /// **Returns:**
  /// True if no fields on the page have errors, false otherwise.
  ///
  /// **Throws:**
  /// - [ArgumentError]: If page with [pageName] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Check if user can proceed to next page
  /// final canProceed = controller.isPageValid('step-1');
  /// ```
  ///
  /// See also:
  /// - [validatePage] to run validators on page fields
  /// - [isFormValid] to check entire form validity
  bool isPageValid(String pageName) {
    final fieldsOnPage = getPageFields(pageName);

    if (fieldsOnPage.isEmpty && !pageFields.containsKey(pageName)) {
      throw ArgumentError(
        'Page "$pageName" does not exist in controller. '
        'Available pages: ${pageFields.keys.join(", ")}',
      );
    }

    final fieldIdsOnPage = fieldsOnPage.map((f) => f.id).toSet();
    return !formErrors.any((error) => fieldIdsOnPage.contains(error.fieldId));
  }

  /// Checks if the form or a specific field has validation errors.
  ///
  /// When [fieldId] is provided, checks for errors on that specific field.
  /// When [fieldId] is null, checks if the entire form has any errors.
  ///
  /// **Parameters:**
  /// - [fieldId]: Optional field ID to check. If null, checks entire form.
  ///
  /// **Returns:**
  /// True if errors exist, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// // Check specific field
  /// if (controller.hasErrors('email')) {
  ///   showErrorIndicator();
  /// }
  ///
  /// // Check entire form
  /// if (controller.hasErrors(null)) {
  ///   disableSubmitButton();
  /// }
  /// ```
  ///
  /// See also:
  /// - [findErrors] to retrieve the actual error objects
  /// - [isFormValid] for checking form validity
  bool hasErrors(String? fieldId) {
    if (fieldId == null) {
      return formErrors.isNotEmpty;
    }
    return formErrors.any((error) => error.fieldId == fieldId);
  }

  /// Clears all validation errors from the form.
  ///
  /// Removes all errors from [formErrors] and updates field states accordingly.
  /// Notifies listeners unless [noNotify] is true.
  ///
  /// **Parameters:**
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false.
  ///
  /// **Example:**
  /// ```dart
  /// // Clear all errors when user starts fresh
  /// controller.clearAllErrors();
  ///
  /// // Or during batch operations
  /// controller.clearAllErrors(noNotify: true);
  /// // ... more operations
  /// controller.notifyListeners();
  /// ```
  ///
  /// See also:
  /// - [clearErrors] to clear errors for a specific field
  /// - [validateForm] to re-run validation
  void clearAllErrors({bool noNotify = false}) {
    if (formErrors.isEmpty) {
      return;
    }

    // Get list of unique field IDs with errors
    final fieldIdsWithErrors = formErrors.map((error) => error.fieldId).toSet();

    // Clear the errors list
    formErrors = [];

    // Update state for all affected fields
    for (final fieldId in fieldIdsWithErrors) {
      _updateFieldState(fieldId);
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  // ===========================================================================
  // PUBLIC ERROR METHODS
  // ===========================================================================

  /// Finds all validation errors for a specific field.
  ///
  /// Returns a list of [FormBuilderError] objects associated with the
  /// specified field ID. Returns an empty list if the field has no errors.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// List of errors for the field, or empty list if no errors exist.
  ///
  /// **Example:**
  /// ```dart
  /// // Check for field errors
  /// final emailErrors = controller.findErrors('email');
  /// if (emailErrors.isNotEmpty) {
  ///   print('Email errors: ${emailErrors.map((e) => e.reason).join(", ")}');
  /// }
  /// ```
  ///
  /// See also:
  /// - [clearErrors] to remove errors for a field
  /// - [addError] to manually add an error
  List<FormBuilderError> findErrors(String fieldId) {
    return formErrors.where((error) => error.fieldId == fieldId).toList();
  }

  /// Clears all validation errors for a specific field.
  ///
  /// Removes all [FormBuilderError] objects associated with the specified
  /// field ID and updates the field's state accordingly.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  ///
  /// **Example:**
  /// ```dart
  /// // Clear errors when user starts correcting input
  /// controller.clearErrors('email');
  ///
  /// // Clear errors during batch operations
  /// controller.clearErrors('name', noNotify: true);
  /// controller.clearErrors('email', noNotify: true);
  /// controller.notifyListeners();
  /// ```
  ///
  /// See also:
  /// - [findErrors] to retrieve errors for a field
  /// - [clearError] to remove a specific error
  void clearErrors(
    String fieldId, {
    bool noNotify = false,
  }) {
    final hadErrors = formErrors.any((error) => error.fieldId == fieldId);
    if (hadErrors) {
      formErrors =
          formErrors.where((error) => error.fieldId != fieldId).toList();
      _updateFieldState(fieldId);
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Clears a specific validation error by its validator position.
  ///
  /// Removes a single error based on its position in the field's validators
  /// list. Less commonly used than [clearErrors], which clears all errors
  /// for a field.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [errorPosition]: The index of the validator that generated the error
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  ///
  /// **Example:**
  /// ```dart
  /// // Clear only the first validator's error
  /// controller.clearError('email', 0);
  /// ```
  ///
  /// See also:
  /// - [clearErrors] to clear all errors for a field
  void clearError(
    String fieldId,
    int errorPosition, {
    bool noNotify = false,
  }) {
    final initialCount = formErrors.length;
    formErrors = formErrors
        .where((error) => !(error.fieldId == fieldId &&
            error.validatorPosition == errorPosition))
        .toList();

    if (formErrors.length < initialCount) {
      _updateFieldState(fieldId);
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Adds a validation error to the form.
  ///
  /// Manually adds a [FormBuilderError] to the form's error list. Avoids
  /// adding duplicate errors (same field and validator position) and updates
  /// the field's state to reflect the error.
  ///
  /// **Parameters:**
  /// - [error]: The error object to add
  /// - [noNotify]: If true, suppresses listener notification. Defaults to false
  ///
  /// **Example:**
  /// ```dart
  /// // Add a custom error
  /// controller.addError(
  ///   FormBuilderError(
  ///     fieldId: 'username',
  ///     reason: 'Username already taken',
  ///     validatorPosition: 0,
  ///   ),
  /// );
  /// ```
  ///
  /// See also:
  /// - [clearErrors] to remove errors
  /// - [findErrors] to retrieve errors
  void addError(
    FormBuilderError error, {
    bool noNotify = false,
  }) {
    final exists = formErrors.any((e) =>
        e.fieldId == error.fieldId &&
        e.validatorPosition == error.validatorPosition);
    if (!exists) {
      formErrors = [error, ...formErrors];
      _updateFieldState(error.fieldId);
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  // ===========================================================================
  // PUBLIC FOCUS METHODS
  // ===========================================================================

  /// Sets focus to the specified field programmatically.
  ///
  /// Removes focus from any other field and updates field states. Field
  /// widgets will be notified through the [ChangeNotifier] mechanism. Does
  /// nothing if the specified field is already focused.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to focus
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Focus email field to draw user attention
  /// controller.focusField('email');
  ///
  /// // Focus first error field
  /// if (controller.formErrors.isNotEmpty) {
  ///   controller.focusField(controller.formErrors.first.fieldId);
  /// }
  /// ```
  ///
  /// See also:
  /// - [unfocusField] to remove focus from a field
  /// - [currentlyFocusedFieldId] to get the focused field
  void focusField(String fieldId) {
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    final previouslyFocusedId = currentlyFocusedFieldId;

    if (previouslyFocusedId == fieldId) {
      return;
    }

    if (previouslyFocusedId != null) {
      _fieldFocusStates[previouslyFocusedId] = false;
      _updateFieldState(previouslyFocusedId);
    }

    _fieldFocusStates[fieldId] = true;
    _updateFieldState(fieldId);

    notifyListeners();
  }

  /// Removes focus from the specified field programmatically.
  ///
  /// Updates field state to reflect unfocused status. Field widgets will be
  /// notified through the [ChangeNotifier] mechanism. Does nothing if the
  /// field is not currently focused.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to unfocus
  ///
  /// **Throws:**
  /// - [ArgumentError]: If field with [fieldId] does not exist
  ///
  /// **Example:**
  /// ```dart
  /// // Remove focus from current field
  /// final focused = controller.currentlyFocusedFieldId;
  /// if (focused != null) {
  ///   controller.unfocusField(focused);
  /// }
  /// ```
  ///
  /// See also:
  /// - [focusField] to set focus to a field
  /// - [isFieldFocused] to check focus state
  void unfocusField(String fieldId) {
    if (!_fieldDefinitions.containsKey(fieldId)) {
      throw ArgumentError(
        'Field "$fieldId" does not exist in controller. '
        'Available fields: ${_fieldDefinitions.keys.join(", ")}',
      );
    }

    if (_fieldFocusStates[fieldId] == true) {
      _fieldFocusStates[fieldId] = false;
      _updateFieldState(fieldId);

      notifyListeners();
    }
  }

  /// Internal callback for field widgets to report focus changes.
  ///
  /// Called by field widgets when their focus state changes. Manages the
  /// internal focus map ([_fieldFocusStates]) and updates field states.
  /// Not intended for direct use by application code.
  ///
  /// **Parameters:**
  /// - [fieldId]: The field reporting focus change
  /// - [isFocused]: Whether the field gained or lost focus
  ///
  /// **Note:** For programmatic focus control, use [focusField] or [unfocusField]
  /// instead. This method is an internal callback for field widgets and should
  /// not be called directly from application code.
  ///
  /// See also:
  /// - [focusField] for programmatic focus control
  /// - [unfocusField] for programmatic unfocus control
  void setFieldFocus(String fieldId, bool isFocused) {
    if (!_fieldDefinitions.containsKey(fieldId)) {
      return;
    }

    final currentlyFocused = currentlyFocusedFieldId;
    final bool alreadyHadFocus = _fieldFocusStates[fieldId] ?? false;

    if (isFocused) {
      if (currentlyFocused != fieldId) {
        if (currentlyFocused != null) {
          _fieldFocusStates[currentlyFocused] = false;
          _updateFieldState(currentlyFocused);
        }
        _fieldFocusStates[fieldId] = true;
        _updateFieldState(fieldId);
        notifyListeners();
      }
    } else {
      if (currentlyFocused == fieldId) {
        _fieldFocusStates[fieldId] = false;
        _updateFieldState(fieldId);
        notifyListeners();
      } else {
        if (alreadyHadFocus) {
          _fieldFocusStates[fieldId] = false;
          _updateFieldState(fieldId);
          notifyListeners();
        }
      }
    }
  }

  /// Checks if a specific field is currently focused.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to check
  ///
  /// **Returns:**
  /// True if the field is focused, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (controller.isFieldFocused('email')) {
  ///   showAutocompleteSuggestions();
  /// }
  /// ```
  ///
  /// See also:
  /// - [currentlyFocusedFieldId] to get the ID of the focused field
  bool isFieldFocused(String fieldId) {
    return _fieldFocusStates[fieldId] ?? false;
  }

  /// Returns the ID of the currently focused field, if any.
  ///
  /// Searches the internal focus state map for a field marked as focused.
  /// Returns null if no field is currently focused.
  ///
  /// **Returns:**
  /// The field ID of the focused field, or null if no field is focused.
  ///
  /// **Example:**
  /// ```dart
  /// final focused = controller.currentlyFocusedFieldId;
  /// if (focused != null) {
  ///   print('Current field: $focused');
  /// }
  /// ```
  ///
  /// See also:
  /// - [isFieldFocused] to check if a specific field is focused
  String? get currentlyFocusedFieldId {
    try {
      return _fieldFocusStates.entries
          .firstWhere((entry) => entry.value == true)
          .key;
    } catch (e) {
      return null;
    }
  }

  // ===========================================================================
  // PUBLIC CONTROLLER METHODS
  // ===========================================================================

  /// Checks if a TextEditingController exists for a field.
  ///
  /// Queries the internal controller storage to determine if a controller
  /// has been created and stored for the specified field ID.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// True if a controller exists, false otherwise.
  ///
  /// **Example:**
  /// ```dart
  /// if (controller.controllerExists('description')) {
  ///   // Controller is available
  /// }
  /// ```
  ///
  /// See also:
  /// - [getFieldController] to retrieve a controller
  /// - [addFieldController] to add a new controller
  bool controllerExists(String fieldId) {
    return _fieldControllers[fieldId] != null;
  }

  /// Retrieves a controller for a specific field.
  ///
  /// Provides direct access to the controller (typically TextEditingController)
  /// for a field. This can be useful for advanced operations like moving the
  /// cursor position or highlighting text.
  ///
  /// **Warning:** Direct controller manipulation may desync values between
  /// the controller and FormController. Generally prefer using
  /// [updateFieldValue] instead.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// The controller cast to type [T], or null if not found or wrong type.
  ///
  /// **Example:**
  /// ```dart
  /// // Get TextEditingController for advanced operations
  /// final textController = controller.getFieldController<TextEditingController>('bio');
  /// if (textController != null) {
  ///   // Move cursor to end
  ///   textController.selection = TextSelection.collapsed(
  ///     offset: textController.text.length,
  ///   );
  /// }
  /// ```
  ///
  /// See also:
  /// - [addFieldController] to store a controller
  /// - [updateFieldValue] for value updates without direct controller access
  T? getFieldController<T>(String fieldId) {
    final existing = _fieldControllers[fieldId];
    if (existing is T) {
      return existing;
    }

    return null;
  }

  /// Stores a controller for a specific field.
  ///
  /// Adds a controller (typically TextEditingController or FocusNode) to the
  /// internal storage, associating it with the specified field ID. The
  /// controller will be automatically disposed when the form controller is
  /// disposed.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  /// - [controller]: The controller instance to store
  ///
  /// **Example:**
  /// ```dart
  /// // Store a custom TextEditingController
  /// final customController = TextEditingController(text: 'Initial value');
  /// controller.addFieldController('description', customController);
  /// ```
  ///
  /// See also:
  /// - [getFieldController] to retrieve a stored controller
  void addFieldController<T>(String fieldId, T controller) {
    _fieldControllers[fieldId] = controller;
  }

  // ===========================================================================
  // PUBLIC STATE METHODS
  // ===========================================================================

  /// Retrieves the current state of a field.
  ///
  /// Returns the calculated [FieldState] for the specified field, which
  /// determines its visual appearance (normal, active, error, disabled).
  /// Returns [FieldState.normal] if the field is not found.
  ///
  /// The state is automatically calculated based on the field's focus state,
  /// error status, and disabled property.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  ///
  /// **Returns:**
  /// The current [FieldState] for the field.
  ///
  /// **Example:**
  /// ```dart
  /// final state = controller.getFieldState('email');
  /// if (state == FieldState.error) {
  ///   // Show error indicator
  /// }
  /// ```
  FieldState getFieldState(String fieldId) {
    if (_fieldDefinitions[fieldId]?.disabled ?? false) {
      return FieldState.disabled;
    }
    return _fieldStates[fieldId] ?? FieldState.normal;
  }

  // ===========================================================================
  // PRIVATE INTERNAL METHODS
  // ===========================================================================

  /// Runs validators for a specific field and updates errors.
  ///
  /// Internal method that executes all validators defined for a field,
  /// collects any errors, updates the [formErrors] list, and recalculates
  /// the field's state. Called automatically during validation operations
  /// or when [validateLive] is enabled.
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field to validate
  /// - [notify]: If true, notifies listeners of changes. Defaults to true.
  void _validateField(String fieldId, {bool notify = true}) {
    final fieldDef = _fieldDefinitions[fieldId];
    final validators = fieldDef?.validators;
    if (fieldDef == null || validators == null || validators.isEmpty) {
      final hadErrors = findErrors(fieldId).isNotEmpty;
      if (hadErrors) {
        clearErrors(fieldId, noNotify: !notify);
      }
      return;
    }

    final value = getFieldValue<dynamic>(fieldId);
    List<FormBuilderError> currentFieldErrors = [];
    bool errorsChanged = false;

    final previousErrors = findErrors(fieldId);
    if (previousErrors.isNotEmpty) {
      formErrors.removeWhere((err) => err.fieldId == fieldId);
      errorsChanged = true;
    }

    for (int i = 0; i < validators.length; i++) {
      final validator = validators[i];
      try {
        final bool isValid = (validator.validator as dynamic)(value);

        if (!isValid) {
          final newError = FormBuilderError(
            reason: validator.reason,
            fieldId: fieldId,
            validatorPosition: i,
          );
          currentFieldErrors.add(newError);
        }
      } catch (e) {
        // Silent error handling - validator execution is external code
      }
    }

    if (currentFieldErrors.isNotEmpty) {
      formErrors = [...currentFieldErrors, ...formErrors];
      errorsChanged = true;
    }

    if (errorsChanged) {
      _updateFieldState(fieldId);
      if (notify) {
        notifyListeners();
      }
    }
  }

  /// Recalculates and updates the state for a field.
  ///
  /// Internal method that determines the appropriate [FieldState] based on
  /// the field's current focus status, error state, and disabled property.
  /// Updates the internal state map if the state has changed.
  ///
  /// State precedence (highest to lowest):
  /// 1. Disabled (if field.disabled is true)
  /// 2. Error (if field has validation errors)
  /// 3. Active (if field is focused)
  /// 4. Normal (default state)
  ///
  /// **Parameters:**
  /// - [fieldId]: The unique identifier of the field
  void _updateFieldState(String fieldId) {
    final fieldDef = _fieldDefinitions[fieldId];
    if (fieldDef == null) return;

    final oldState = _fieldStates[fieldId] ?? FieldState.normal;
    FieldState newState;

    final hasErrors = findErrors(fieldId).isNotEmpty;
    final isFocused = isFieldFocused(fieldId);

    if (fieldDef.disabled) {
      newState = FieldState.disabled;
    } else if (hasErrors) {
      newState = FieldState.error;
    } else if (isFocused) {
      newState = FieldState.active;
    } else {
      newState = FieldState.normal;
    }

    if (oldState != newState) {
      _fieldStates[fieldId] = newState;
    }
  }
}
