// We are going to build one giant controller to handle all aspects of our form.

import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formcontroller/field_focus.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';
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

  /// Handle text field default values
  /// depreciated
  // List<TextFormFieldValueById> textFieldValues;

  /// Handle multiselect field default values
  /// depreciated
  // List<MultiselectFormFieldValueById> multiselectValues;

  /// Handle form focus controllers
  List<FieldFocus> fieldFocus;

  /// Form Error Data
  List<FormBuilderError> formErrors;

  /// Currently active field. This follows field focus
  FormFieldDef? activeField;

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
    this.fieldFocus = const [],
    this.formErrors = const [],
    this.activeField,
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
    // Dispose text controllers:
    _fieldControllers.forEach((key, controller) {
      if (controller is ChangeNotifier) {
        controller.dispose();
      }
    });
    _fieldControllers.clear();

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
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    fields = [...fields, ...newFields];
    if (!noNotify) {
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
    // Optional: Handle type mismatch (e.g., log warning, return null)
    return null;
  }

  /// Update the value for any field ID.
  /// Notifies listeners unless noNotify is true.
  void updateFieldValue<T>(String id, T newValue, {bool noNotify = false}) {
    // final reference = findTextFieldValueIndex(id);
    _fieldValues[id] = newValue;

    if (!noNotify) {
      notifyListeners();
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
  // Multiselect public Functions. Checkboxes, Dropdowns, File Uploads, and more.
  // These functions manage text fields.
  // ---------------------------------------------------------------------------

  /// Updates the selected value(s) for a field.
  ///
  /// - `id`: The ID of the field to update.
  /// - `newValue`: The list of `MultiselectOption` to set.
  /// - `multiselect`: If `true`, allows multiple selections. If `false`, only the first item in `newValue` (if any) is kept.
  /// - `overwrite`:
  ///    - If `true`, `newValue` completely replaces the current selection. (Useful for file uploads or direct replacements).
  ///    - If `false` (default), the function toggles the selection state of items in `newValue`:
  ///      - If an option from `newValue` is already selected, it's deselected.
  ///      - If an option from `newValue` is not selected, it's selected.
  /// - `noNotify`: If `true`, suppresses the `notifyListeners()` call.
  /// - `noOnChange`: If `true`, suppresses the field's `onChange` callback.
  void updateMultiselectValues(
    String id,
    List<MultiselectOption> newValue, {
    bool multiselect = false, // Default consistent with previous behavior
    bool overwrite = false,
    bool noNotify = false,
    bool noOnChange = false,
  }) {
    final field = fields.firstWhereOrNull((fieldData) => fieldData.id == id);
    // It's good practice to check if the field exists, though onChange might fail silently if not.
    // if (field == null) {
    //   debugPrint("ChampionFormController: Attempted to update non-existent field $id");
    //  return;
    // }

    // Get current values or default to empty list
    List<MultiselectOption> currentValues = List<MultiselectOption>.from(
        getFieldValue<List<MultiselectOption>>(id) ?? []);
    List<MultiselectOption> finalValue;

    if (overwrite) {
      // Directly replace the current list with the new list (respecting multiselect flag)
      if (multiselect) {
        finalValue = newValue;
      } else {
        finalValue = newValue.isNotEmpty ? [newValue.first] : [];
      }
    } else {
      // Toggle logic based on current selection
      final Set<String> newValueValues = newValue.map((o) => o.value).toSet();
      final Set<String> currentValuesSet =
          currentValues.map((o) => o.value).toSet();

      List<MultiselectOption> mergedValues = [];

      if (multiselect) {
        // Add options from currentValues that are NOT in newValue (keep untoggled ones)
        mergedValues.addAll(currentValues
            .where((option) => !newValueValues.contains(option.value)));
        // Add options from newValue that are NOT in currentValues (add newly toggled ones)
        mergedValues.addAll(newValue
            .where((option) => !currentValuesSet.contains(option.value)));
      } else {
        // Single select toggle:
        // If newValue is empty, deselect everything.
        // If newValue has items, check if the *first* item is already selected.
        // If it is selected, deselect it (resulting in empty).
        // If it's not selected, select it (replacing any previous single selection).
        if (newValue.isNotEmpty) {
          final firstNewOption = newValue.first;
          if (!currentValuesSet.contains(firstNewOption.value)) {
            mergedValues = [firstNewOption]; // Select the new one
          } else {
            mergedValues = []; // Deselect if it was already selected
          }
        } else {
          mergedValues = []; // Deselect if newValue is empty
        }
      }
      finalValue = mergedValues;
    }

    // Update the central value store
    updateFieldValue<List<MultiselectOption>>(id, finalValue,
        noNotify: true); // Use internal method, notify later

    // Trigger any onChange functions if the field definition exists
    if (field?.onChange != null && !noOnChange) {
      field!
          .onChange!(FormResults.getResults(controller: this, fields: [field]));
    }

    // Notify listeners if required
    if (!noNotify) {
      notifyListeners();
    }
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

  // Manage Errors
  List<FormBuilderError> findErrors(String fieldId) {
    return formErrors.where((error) => error.fieldId == fieldId).toList();
  }

  void clearErrors(
    String fieldId, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    formErrors = formErrors.where((error) => error.fieldId != fieldId).toList();
    if (!noNotify) {
      notifyListeners();
    }

    return;
  }

  void clearError(
    String fieldId,
    int errorPosition, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    formErrors = formErrors
        .where((error) => error.validatorPosition != errorPosition)
        .toList();

    if (!noNotify) {
      notifyListeners();
    }
    return;
  }

  void addError(
    FormBuilderError error, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    formErrors = [error, ...formErrors];
    if (!noNotify) {
      notifyListeners();
    }
  }

  // Lets Handle FocusNodes

  bool isFieldFocused(String fieldId) {
    return fieldFocus.firstWhereOrNull((field) => field.id == fieldId)?.focus ??
        false;
  }

  /// This updates the focused field in the controller.
  /// Use this so the controller can track which field has focus
  void updateFocusedField(FormFieldDef newField) {
    activeField = newField;
  }

  // Set field focus
  void setFieldFocus(
    String fieldId,
    bool focused,
    FormFieldDef activeField, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    // Update the active field
    updateFocusedField(activeField);

    final reference = findFieldFocusIndex(fieldId);
    if (reference != null) {
      fieldFocus[reference] = FieldFocus(
        id: fieldId,
        focus: focused,
      );
    } else {
      fieldFocus = [
        FieldFocus(
          id: fieldId,
          focus: focused,
        ),
        ...fieldFocus
      ];
    }
    if (!noNotify) {
      notifyListeners();
    }
  }

  int? findFieldFocusIndex(String fieldId) {
    for (int i = 0; i < fieldFocus.length; i++) {
      if (fieldFocus[i].id == id) {
        return i;
      }
    }
    return null;
  }
}
