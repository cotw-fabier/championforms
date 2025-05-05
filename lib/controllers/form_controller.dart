// We are going to build one giant controller to handle all aspects of our form.

import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class ChampionFormController extends ChangeNotifier {
  /// field ID. This differentiates this field from other fields.
  final String id;

  /// Link Fields to this controller
  List<FormFieldDef> fields;

  /// Generic field value storage
  /// Stores all the values from all registered fields
  /// This replaces textFieldValues and multiselectvalues
  final Map<String, dynamic> _fieldValues = {};

  // --- State Storage ---
  final Map<String, FieldState> _fieldStates = {};
  // Keep track of field definitions for checking 'disabled' status
  final Map<String, FormFieldDef<dynamic>> _fieldDefinitions = {};

  /// Stores the focus state for each field. true if focused, false or absent otherwise.
  final Map<String, bool> _fieldFocusStates = {};

  /// Handle text field default values
  /// depreciated
  // List<TextFormFieldValueById> textFieldValues;

  /// Handle multiselect field default values
  /// depreciated
  // List<MultiselectFormFieldValueById> multiselectValues;

  /// Handle form focus controllers
  /// Depreciated
  // List<FieldFocus> fieldFocus;

  /// Form Error Data
  List<FormBuilderError> formErrors;

  /// Currently active field. This follows field focus
  /// DEPRECIATED? (Using currentlyFocusedFieldId getter now)
  // FormFieldDef? activeField;

  /// Generic storage for field controllers
  /// this allows us to hold and manage controllers
  /// for any type of field.
  /// Map<fieldId, controller>
  final Map<String, dynamic> _fieldControllers = {};

  /// List of texteditingcontrollers for direct access to text fields
  /// depreciated
  // final List<FieldController> _textControllers = [];

  /// Active Fields
  /// This contains an updated list of fields currently
  /// rendered in a championform widget.
  List<FormFieldDef> activeFields;

  /// Page Fields
  /// Subsets of fields added as pages are identified.
  /// use pageName param on ChampionForm to add fields
  /// to a page. Then you can return
  /// a list of pages as needed by calling
  /// controller.getPageFields("pageID");
  Map<String, List<FormFieldDef>> pageFields;

  ChampionFormController({
    String? id,
    this.fields = const [],
    // this.textFieldValues = const [],
    // this.multiselectValues = const [],
    this.formErrors = const [],
    this.activeFields = const [],
    Map<String, List<FormFieldDef>>? pageFields,
  })  : id = id ?? Uuid().v4(),
        pageFields = pageFields ?? {};

  // ---------------------------------------------------------------------------
  // Controller lifecycle functions
  // These functions manage the lifecycle of the ChampionFormController.
  // Creation, adding fields, and then disposing of the controller
  // ---------------------------------------------------------------------------

  /// When you no longer need the ChampionFormController, you must call dispose()
  /// to properly dispose of all stored values, internal controllers, and more
  /// this is a sizable controller which manages the state of many other fields
  /// so calling this is very important when you are done using the controller.
  ///
  /// Keep the controller alive as long as you are interacting with any fields
  /// this controller manages, or the fields will break.
  @override
  void dispose() {
    _fieldControllers.forEach((key, controller) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      }
      // Also dispose FocusNodes if they are stored here directly
      // For example, if _fieldControllers stored {'someId_focusNode': FocusNode}
      else if (controller is FocusNode) {
        controller.dispose();
      }
    });
    _fieldControllers.clear();
    _fieldStates.clear();
    _fieldDefinitions.clear();
    _fieldFocusStates.clear();
    _fieldValues.clear();
    formErrors.clear();
    activeFields.clear();
    pageFields.clear();

    super.dispose();
  }

  /// Update Active Fields
  /// Merges in a list of fields being actively displayed
  /// This is called by formbuilder on widget build
  /// to create a running list of active fields.
  void updateActiveFields(
    List<FormFieldDef> fields, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    // start by cleaning any fields with the same IDs
    removeActiveFields(fields, noNotify: true);

    activeFields = [...activeFields, ...fields];

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Remove active fields.
  /// Removes a list of fields from active fields
  /// this is called in FormBuilder when it is being
  /// torn down.
  void removeActiveFields(
    List<FormFieldDef> fields, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    activeFields = activeFields
        .where((field) => !fields.any((f) => f.id == field.id))
        .toList();

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Add fields to a specific "page"
  /// This allows you to build form groups by page
  /// using one controller.
  /// This is useful for pulling subsets of results
  /// from your forms.
  ///
  /// Doesn't notify listeners since it should happen silently
  /// as the controller is updated.'

  void updatePageFields(
    String pageName,
    List<FormFieldDef> fields,
  ) {
    if (pageFields.containsKey(pageName)) {
      pageFields[pageName] = [...pageFields[pageName]!, ...fields];
    } else {
      pageFields[pageName] = fields;
    }
  }

  /// Grab page fields
  /// as a subset List<FormFieldDef>
  List<FormFieldDef> getPageFields(String pageName) {
    if (pageFields.containsKey(pageName)) {
      return pageFields[pageName] ?? [];
    } else {
      return [];
    }
  }

  /// Gets the current state of a field. Defaults to normal if not found.
  FieldState getFieldState(String fieldId) {
    // Ensure disabled state takes precedence if the field definition says so
    if (_fieldDefinitions[fieldId]?.disabled ?? false) {
      return FieldState.disabled;
    }
    return _fieldStates[fieldId] ?? FieldState.normal;
  }

  /// Recalculates and updates the state for a given field.
  /// Notifies listeners if the state actually changes.
  void _updateFieldState(String fieldId) {
    final fieldDef = _fieldDefinitions[fieldId];
    if (fieldDef == null) return;

    final oldState = _fieldStates[fieldId] ?? FieldState.normal;
    FieldState newState;

    final hasErrors = findErrors(fieldId).isNotEmpty;
    // MODIFIED: Read from the focus map
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
      // Notification is usually handled by the calling method (addFocus, removeFocus, updateErrors)
      // to avoid redundant notifications if multiple states change at once.
      debugPrint(
          "Internal: Field '$fieldId' state calculated as $newState (was $oldState)");
    }
  }

  /// Lets start by managing all the fields this controller is responsible for.
  /// This function allows us to connect disparate championform instances together into one controller.
  ///
  /// This function populates the controller with new fields. You can call this as often
  /// as you want. This is automatically called when adding new fields to the
  /// ChampionForm() widget. You may wish to manually call it if you want to prepopulate
  /// the controller before an associated ChampionForm() widget is called.
  ///
  /// For example: a multi-page form handling more than one group of fields.
  void addFields(
    List<FormFieldDef> newFields, {
    bool noNotify = false,
  }) {
    bool changed = false;
    for (final field in newFields) {
      // Only add if it's not already present or if the definition differs
      // (Note: Deep equality check for FormFieldDef might be complex/costly)
      if (!_fieldDefinitions.containsKey(field.id)) {
        _fieldDefinitions[field.id] = field;
        // Ensure initial focus state is false (or absent)
        _fieldFocusStates.putIfAbsent(field.id, () => false);
        // Calculate initial state
        _updateFieldState(field.id); // Calculate and store initial state
        changed = true;
      } else if (_fieldDefinitions[field.id] != field) {
        // Handle update if definition changes (e.g., 'disabled' toggled)
        _fieldDefinitions[field.id] = field;
        _updateFieldState(field.id); // Recalculate state if def changed
        changed = true;
      }
    }
    if (changed && !noNotify) {
      notifyListeners();
    }
  }

  // ----------------------------------------
  // Functions related to managing generic field data
  // ----------------------------------------
  //

  /// Get the value for any field ID. Returns null if not found.
  /// Use type T for type safety if you know the expected type.
  T? getFieldValue<T>(String fieldId) {
    final value = _fieldValues[fieldId];
    if (value is T) {
      return value;
    }

    // Return default value from definition if value is null/absent
    if (value == null) {
      final defaultValue = _fieldDefinitions[fieldId]?.defaultValue;
      if (defaultValue is T) {
        return defaultValue;
      }
    }

    // Optional: Handle type mismatch (e.g., log warning, return null)
    return null;
  }

  /// Update the value for any field ID.
  /// Notifies listeners unless noNotify is true.
  /// Update the value for any field ID.
  void updateFieldValue<T>(String id, T? newValue, {bool noNotify = false}) {
    final T? oldValue =
        _fieldValues.containsKey(id) ? _fieldValues[id] as T? : null;

    // Store or remove the value
    if (newValue != null) {
      _fieldValues[id] = newValue;
    } else {
      _fieldValues
          .remove(id); // Remove if null to potentially revert to default
    }

    // Trigger onChange if defined and value actually changed
    if (oldValue != newValue) {
      final fieldDef = _fieldDefinitions[id];
      if (fieldDef?.onChange != null) {
        // Use try-catch for safety, as onChange is external code
        try {
          // Get results *after* updating the value
          final results = FormResults.getResults(
              controller: this, fields: [if (fieldDef != null) fieldDef]);
          fieldDef!.onChange!(results);
        } catch (e) {
          debugPrint("Error executing onChange for field '$id': $e");
        }
      }

      // If validation is live, check for errors after change
      if (fieldDef?.validateLive ?? false) {
        _validateField(id); // Separate validation logic
      }

      // Notify listeners only if value changed and notification not suppressed
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Runs validators for a specific field and updates errors/state.
  void _validateField(String fieldId, {bool notify = true}) {
    final fieldDef = _fieldDefinitions[fieldId];
    final validators = fieldDef?.validators;
    if (fieldDef == null || validators == null || validators.isEmpty) {
      // If no validators, ensure any existing errors are cleared
      final hadErrors = findErrors(fieldId).isNotEmpty;
      if (hadErrors) {
        clearErrors(fieldId,
            noNotify: !notify); // Clear errors, notify if requested
      }
      return; // No validation needed or possible
    }

    final value = getFieldValue<dynamic>(fieldId); // Get current value
    List<FormBuilderError> currentFieldErrors = [];
    bool errorsChanged = false;

    // Clear previous errors for this field *before* running validators
    final previousErrors = findErrors(fieldId);
    if (previousErrors.isNotEmpty) {
      formErrors.removeWhere((err) => err.fieldId == fieldId);
      errorsChanged = true; // Mark that errors *might* change overall
    }

    // Run validators
    for (int i = 0; i < validators.length; i++) {
      final validator = validators[i];
      try {
        // We need to cast the validator's function to the expected type.
        // This relies on the validator being correctly typed for the field.
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
        debugPrint(
            "Error running validator $i for field '$fieldId': $e. Ensure validator function type matches field value type (${value?.runtimeType}).");
        // Optionally add a generic error?
        // currentFieldErrors.add(FormBuilderError(reason: "Validation Error", fieldId: fieldId, validatorPosition: i));
      }
    }

    // Add new errors if any
    if (currentFieldErrors.isNotEmpty) {
      formErrors = [...currentFieldErrors, ...formErrors];
      errorsChanged = true; // Mark change if new errors were added
    }

    // Update state and notify if errors changed
    if (errorsChanged) {
      _updateFieldState(fieldId); // Update state based on new error status
      if (notify) {
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Text Field public Functions.
  // These functions manage text fields.
  // ---------------------------------------------------------------------------

  /// Query if a text editing controller exists for a field
  bool controllerExists(String fieldId) {
    return _fieldControllers[fieldId] != null;
  }

  /// Get Field Controller
  /// This gives you direct access to the controller for a
  /// given field ID. This can be useful if you want to manipulate any functions
  /// associated with that controller. For example, moving the cursor position or highlighting text.
  ///
  /// Generally, it may be better to modify the field value using the associated updateValue function().
  /// It is possible that by calling this directly you may unsync the values in ChampionFormController
  /// and the Controller.
  T? getFieldController<T>(String fieldId) {
    // Check if we already have a FieldController for this field:
    final existing = _fieldControllers[fieldId];
    if (existing is T) {
      return existing;
    }

    return null;
  }

  /// Add a new controller
  void addFieldController<T>(String fieldId, T controller) {
    _fieldControllers[fieldId] = controller;
  }

  // ---------------------------------------------------------------------------
  // Multiselect public Functions (Checkboxes, Dropdowns, File Uploads)
  // ---------------------------------------------------------------------------

  /// Updates the selected value(s) for a multiselect/option field.
  /// Handles single/multi select logic, overwrite/toggle behavior.
  void updateMultiselectValues(
    String id,
    List<MultiselectOption> newValue, {
    bool? multiselect, // Optional: If null, infer from field definition
    bool overwrite = false,
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    final field = _fieldDefinitions[id];
    // Infer multiselect capability if not provided
    final isMultiselect =
        multiselect ?? (field is ChampionOptionSelect && field.multiselect);

    List<MultiselectOption> currentValues = List<MultiselectOption>.from(
        getFieldValue<List<MultiselectOption>>(id) ?? []);
    List<MultiselectOption> finalValue;

    if (overwrite) {
      // Directly replace, respecting multiselect flag
      if (isMultiselect) {
        finalValue =
            List<MultiselectOption>.from(newValue); // Ensure new list instance
      } else {
        finalValue = newValue.isNotEmpty ? [newValue.first] : [];
      }
    } else {
      // Toggle logic
      final Set<String> newValueValues = newValue.map((o) => o.value).toSet();
      final Set<String> currentValuesSet =
          currentValues.map((o) => o.value).toSet();
      List<MultiselectOption> mergedValues = [];

      if (isMultiselect) {
        // Keep existing options not part of the toggle action
        mergedValues.addAll(currentValues
            .where((option) => !newValueValues.contains(option.value)));
        // Add new options that weren't already selected
        mergedValues.addAll(newValue
            .where((option) => !currentValuesSet.contains(option.value)));
      } else {
        // Single select toggle logic
        if (newValue.isNotEmpty) {
          final firstNewOption = newValue.first;
          // If the new option wasn't selected, select it. If it was, deselect (empty list).
          if (!currentValuesSet.contains(firstNewOption.value)) {
            mergedValues = [firstNewOption];
          } else {
            mergedValues = []; // Deselect if it was already selected
          }
        } else {
          mergedValues = []; // Deselect if newValue is empty
        }
      }
      finalValue = mergedValues;
    }

    // Use the generic updateFieldValue, triggering its onChange and validation logic
    updateFieldValue<List<MultiselectOption>>(id, finalValue,
        noNotify: noNotify // Pass notification suppression flag
        );

    // Note: onChange and validation are now handled within updateFieldValue
    // if (field?.onChange != null && !noOnChange) { ... } // No longer needed here
    // if (field?.validateLive ?? false) { ... } // No longer needed here
  }

  /// Helper function to toggle options on and off.
  void toggleMultiSelectValue(
    String fieldId, {
    List<String> toggleOn = const [],
    List<String> toggleOff = const [],
    bool noNotify = false,
    // bool noOnChange = false, // No longer explicitly needed here
  }) {
    // 1. Get the field definition
    final fieldDef = _fieldDefinitions[fieldId];

    // 2. Validate the field exists and is the correct type
    if (fieldDef == null || fieldDef is! ChampionOptionSelect) {
      debugPrint(
          "Warning: Tried to toggle values on field '$fieldId', but it's not found or not a ChampionOptionSelect.");
      return;
    }

    // 3. Get the currently selected options
    final List<MultiselectOption> currentSelectedOptions =
        getFieldValue<List<MultiselectOption>>(fieldId) ?? [];

    // 4. Create a mutable set of the *values* currently selected for efficient modification
    final Set<String> newSelectedValues =
        currentSelectedOptions.map((o) => o.value).toSet();

    // 5. Apply the toggle logic
    // Ensure specified options are selected
    for (final valueToSelect in toggleOn) {
      newSelectedValues.add(valueToSelect);
    }
    // Ensure specified options are deselected
    for (final valueToDeselect in toggleOff) {
      newSelectedValues.remove(valueToDeselect);
    }

    // 6. Convert the final set of string values back to MultiselectOption objects
    //    using the options defined in the field definition.
    final List<MultiselectOption> finalSelectedOptions = fieldDef.options
        .where((option) => newSelectedValues.contains(option.value))
        .toList();

    // 7. Update the field's value using the generic update method.
    //    This handles storing the value, triggering onChange (if value changed),
    //    running live validation, and notifying listeners (unless suppressed).
    updateFieldValue<List<MultiselectOption>>(
      fieldId,
      finalSelectedOptions,
      noNotify: noNotify, // Pass the notification suppression flag
    );

    // Manual onChange and notifyListeners calls are no longer needed here,
    // as updateFieldValue handles them based on whether the value actually changed.
  }

  /// Helper to clear all selected options for a multiselect field.
  /// Equivalent to setting the value to an empty list.
  /// Optionally triggers onChange and notifies listeners.
  void removeMultiSelectOptions(
    String fieldId, {
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    // Call updateMultiselectValues with an empty list and overwrite: true
    updateMultiselectValues(
      fieldId,
      [],
      overwrite: true,
      noNotify: noNotify, // Pass through notification flags
      noOnChange: noOnChange, // Pass through onChange flag
    );
  }

  /// Resets a multiselect field by clearing its selected values.
  /// This effectively calls `removeMultiSelectOptions`.
  void resetMultiselectChoices(
    String fieldId, {
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    // The concept of "removing the entry" is replaced by setting the value to empty list.
    removeMultiSelectOptions(
      fieldId,
      noNotify: noNotify,
      noOnChange: noOnChange,
    );
  }

  /// Get the currently selected options for a multiselect field.
  /// Returns `null` if the field hasn't been interacted with or has no value set.
  /// Returns an empty list `[]` if the field is set but has no options selected.
  List<MultiselectOption>? getMultiselectValue(String fieldId) {
    return getFieldValue<List<MultiselectOption>>(fieldId);
  }

  // ---------------------------------------------------------------------------
  // Error Management
  // ---------------------------------------------------------------------------

  /// Find all errors associated with a specific field ID.
  List<FormBuilderError> findErrors(String fieldId) {
    return formErrors.where((error) => error.fieldId == fieldId).toList();
  }

  /// Clear all errors for a specific field ID.
  void clearErrors(
    String fieldId, {
    bool noNotify = false,
  }) {
    final hadErrors = formErrors.any((error) => error.fieldId == fieldId);
    if (hadErrors) {
      formErrors =
          formErrors.where((error) => error.fieldId != fieldId).toList();
      _updateFieldState(fieldId); // Update state after clearing errors
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Clear a specific error based on its validator position.
  /// (Less common, usually clear all for the field)
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
      // If an error was actually removed
      _updateFieldState(fieldId); // Recalculate state
      if (!noNotify) {
        notifyListeners();
      }
    }
  }

  /// Add a new error to the form.
  void addError(
    FormBuilderError error, {
    bool noNotify = false,
  }) {
    // Avoid adding duplicate errors (same field, same validator position)
    final exists = formErrors.any((e) =>
        e.fieldId == error.fieldId &&
        e.validatorPosition == error.validatorPosition);
    if (!exists) {
      formErrors = [error, ...formErrors]; // Add to beginning
      _updateFieldState(error.fieldId); // Update state after adding error
      if (!noNotify) {
        notifyListeners();
      }
    }
  }
  // Lets Handle FocusNodes
  //

  // --- Focus Management Methods ---

  /// Sets focus to the specified field, removing focus from any other field.
  void addFocus(String fieldId) {
    final previouslyFocusedId = currentlyFocusedFieldId;

    // If the field is already focused, do nothing
    if (previouslyFocusedId == fieldId) {
      return;
    }

    // Remove focus from the previously focused field, if there was one
    if (previouslyFocusedId != null) {
      _fieldFocusStates[previouslyFocusedId] = false;
      _updateFieldState(
          previouslyFocusedId); // Update state for the unfocused field
    }

    // Set focus for the new field
    _fieldFocusStates[fieldId] = true;
    _updateFieldState(fieldId); // Update state for the newly focused field

    debugPrint(
        "Focus added to '$fieldId'. Previously focused: '$previouslyFocusedId'");
    notifyListeners();
  }

  /// Removes focus from the specified field.
  void removeFocus(String fieldId) {
    // Only act if the field is currently focused
    if (_fieldFocusStates[fieldId] == true) {
      _fieldFocusStates[fieldId] =
          false; // Or _fieldFocusStates.remove(fieldId);
      _updateFieldState(fieldId); // Update its state

      debugPrint("Focus removed from '$fieldId'");
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Focus Management
  // ---------------------------------------------------------------------------

  /// Called by field widgets when their focus changes.
  /// Manages the internal focus map (`_fieldFocusStates`) and updates field states.
  void setFieldFocus(String fieldId, bool isFocused) {
    // Ensure the field definition is tracked
    // This should ideally happen in addFields, but double-check
    if (!_fieldDefinitions.containsKey(fieldId)) {
      debugPrint("Warning: setFieldFocus called for unknown field '$fieldId'");
      // Optionally try to find the field def?
      // final field = fields.firstWhereOrNull((f) => f.id == fieldId);
      // if (field != null) _fieldDefinitions.putIfAbsent(field.id, () => field);
      // else return; // Exit if definition truly unknown
      return;
    }

    final currentlyFocused = currentlyFocusedFieldId;
    final bool alreadyHadFocus = _fieldFocusStates[fieldId] ?? false;

    if (isFocused) {
      // If this field is gaining focus
      if (currentlyFocused != fieldId) {
        // Remove focus from the previously focused field (if any)
        if (currentlyFocused != null) {
          _fieldFocusStates[currentlyFocused] = false;
          _updateFieldState(
              currentlyFocused); // Update state of unfocused field
        }
        // Set focus for the new field
        _fieldFocusStates[fieldId] = true;
        _updateFieldState(fieldId); // Update state of newly focused field
        debugPrint(
            "Focus CHANGED to '$fieldId'. Previously: '$currentlyFocused'");
        notifyListeners(); // Notify about the focus change
      } else {
        // Already focused, state likely calculated correctly, do nothing unless forced update needed
        debugPrint("Focus remained on '$fieldId'.");
      }
    } else {
      // If this field is losing focus
      // Only act if *this* field was the one losing focus
      if (currentlyFocused == fieldId) {
        _fieldFocusStates[fieldId] = false;
        _updateFieldState(fieldId); // Update state of unfocused field
        debugPrint("Focus REMOVED from '$fieldId'.");
        notifyListeners(); // Notify about the focus change
      } else {
        // A blur event occurred for a field that wasn't marked as focused.
        // This can happen. Ensure its state is non-active.
        if (alreadyHadFocus) {
          // If it was incorrectly marked as focused before
          _fieldFocusStates[fieldId] = false;
          _updateFieldState(fieldId); // Ensure state is updated
          debugPrint(
              "Focus corrected (removed) for '$fieldId' which wasn't the primary focus.");
          notifyListeners();
        } else {
          debugPrint(
              "Blur event for '$fieldId', but it wasn't the actively focused field ('$currentlyFocused'). No state change needed based on focus.");
        }
      }
    }
  }

  /// Checks if a specific field is currently marked as focused in the internal map.
  bool isFieldFocused(String fieldId) {
    return _fieldFocusStates[fieldId] ?? false;
  }

  /// Helper to get the ID of the field currently marked as focused.
  String? get currentlyFocusedFieldId {
    try {
      // Find the first entry where the value is true
      return _fieldFocusStates.entries
          .firstWhere((entry) => entry.value == true)
          .key;
    } catch (e) {
      // Handles case where no entry has value == true (NoSuchMethodError or similar)
      return null;
    }
  }
}
