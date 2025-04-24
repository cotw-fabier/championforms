// We are going to build one giant controller to handle all aspects of our form.

import 'package:championforms/models/field_types/championoptionselect.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/formcontroller/field_controller.dart';
import 'package:championforms/models/formcontroller/field_focus.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/formresults.dart';
import 'package:championforms/models/formvalues/multiselect_form_field_value_by_id.dart';
import 'package:championforms/models/formvalues/text_form_field_value_by_id.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

class ChampionFormController extends ChangeNotifier {
  /// field ID. This differentiates this field from other fields.
  final String id;

  /// Link Fields to this controller
  List<FormFieldDef> fields;

  /// Handle text field default values
  List<TextFormFieldValueById> textFieldValues;

  /// Handle multiselect field default values
  List<MultiselectFormFieldValueById> multiselectValues;

  /// Handle form focus controllers
  List<FieldFocus> fieldFocus;

  /// Form Error Data
  List<FormBuilderError> formErrors;

  /// Currently active field. This follows field focus
  FormFieldDef? activeField;

  /// List of texteditingcontrollers for direct access to text fields
  final List<FieldController> _textControllers = [];

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
    this.textFieldValues = const [],
    this.multiselectValues = const [],
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
    for (final fc in _textControllers) {
      fc.controller.dispose();
    }
    _textControllers.clear();

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
    removeActiveFields(fields, notify: false);

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

  // ---------------------------------------------------------------------------
  // Text Field public Functions.
  // These functions manage text fields.
  // ---------------------------------------------------------------------------

  /// Query if a text editing controller exists for a field
  bool textEditingControllerExists(String fieldId) {
    return _textControllers.firstWhereOrNull((fc) => fc.fieldId == fieldId) !=
        null;
  }

  /// Get Text Field Controller
  /// This gives you direct access to the TextFieldController for a
  /// given field ID. This can be useful if you want to manipulate any functions
  /// associated with that controller. For example, moving the cursor position or highlighting text.
  ///
  /// Generally, it may be better to modify the field value using updateTextFieldValue().
  /// It is possible that by calling this directly you may unsync the values in ChampionFormController
  /// and the TextFieldController.
  TextEditingController getTextEditingController(String fieldId) {
    // Check if we already have a FieldController for this field:
    final existing =
        _textControllers.firstWhereOrNull((fc) => fc.fieldId == fieldId);
    if (existing != null) {
      return existing.controller;
    }

    // Otherwise, create a new TextEditingController:
    final newController = TextEditingController();
    _textControllers.add(
      FieldController(fieldId: fieldId, controller: newController),
    );

    return newController;
  }

  /// Update text field values
  /// Call this to force a field update to a text field. This will
  /// update the text field value and also update anything listening
  /// to the controller.
  void updateTextFieldValue(String id, String newValue,
      {bool noNotify = false}) {
    final reference = findTextFieldValueIndex(id);
    if (reference != null) {
      textFieldValues[reference] =
          TextFormFieldValueById(id: id, value: newValue);
    } else {
      textFieldValues = [
        TextFormFieldValueById(id: id, value: newValue),
        ...textFieldValues
      ];
    }

    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Use this function to find the value of a text field.
  /// Returned value is a TextFormFieldValueById which
  /// has the properties of id and value. Simple class
  /// so you can track which value is associated with which field.
  TextFormFieldValueById? findTextFieldValue(String id) {
    final reference = findTextFieldValueIndex(id);
    if (reference != null) {
      return textFieldValues[reference];
    }
    return null;
  }

  int? findTextFieldValueIndex(String id) {
    for (int i = 0; i < textFieldValues.length; i++) {
      if (textFieldValues[i].id == id) {
        return i;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Multiselect public Functions. Checkboxes, Dropdowns, File Uploads, and more.
  // These functions manage text fields.
  // ---------------------------------------------------------------------------

  /// This is a helper function so you can find the field options and then toggle them via a list of string values.
  /// toggleOn to enable the values and toggleOff to disable the values.
  /// This is different than updateMultiSelectValues() because this assumes the values have already been established
  /// in the controller via the "options:" parameter when creating
  /// a multiselect field. This simply enables or disables the values that are already in the controller.
  void toggleMultiSelectValue(
    String fieldId, {
    List<String> toggleOn = const [],
    List<String> toggleOff = const [],
    bool noNotify = false,
  }) {
    final field =
        fields.firstWhereOrNull((fieldData) => fieldData.id == fieldId);

    if (field == null || field is! ChampionOptionSelect) {
      debugPrint(
          "Tried to toggle values on a field that doesn't seem to exist: $fieldId");
      return;
    }

    final List<MultiselectOption> selectOptions = field.options
        .where((option) => toggleOn.contains(option.value))
        .toList();

    final List<MultiselectOption> deSelectOptions = field.options
        .where((option) => toggleOn.contains(option.value))
        .toList();
    // Run the logic to add and remove these values
    final reference = findMultiselectValueIndex(id);

    if (reference == null) {
      multiselectValues = [
        MultiselectFormFieldValueById(
          id: field.id,
          values: selectOptions,
        ),
        ...multiselectValues,
      ];
    } else {
      multiselectValues[reference] = MultiselectFormFieldValueById(
          id: multiselectValues[reference].id,
          values: [
            // original values minus the addition and subtracted values
            // Leave original selections intact
            ...multiselectValues[reference].values.where((value) =>
                !selectOptions
                    .any((selected) => selected.value == value.value) &&
                !deSelectOptions
                    .any((deSelected) => deSelected.value == value.value)),

            // The new values we're adding in
            ...selectOptions,
          ]);
    }

    // Trigger any onChange functions
    if (field.onChange != null) {
      field
          .onChange!(FormResults.getResults(controller: this, fields: [field]));
    }
    // Notify listeners
    if (!noNotify) {
      notifyListeners();
    }
  }

  /// This takes in a list of MultiselectOptions and will toggle those values on and off.
  /// If the values are not in the controller as options then it will add them.
  /// If the values are already present then they will be updated to the reverse toggle
  /// as they were before running this function (true -> false and vice versa).
  ///
  /// If you want to force their setting on and off, then set the bool overwrite to
  /// ensure they are set with the value being on when being added.
  void updateMultiselectValues(
    String id,
    List<MultiselectOption> newValue, {
    bool multiselect = false,
    bool overwrite = false,
    bool noNotify = false,
  }) {
    final reference = findMultiselectValueIndex(id);
    final field = fields.firstWhereOrNull((fieldData) => fieldData.id == id);

    // if overwrite is true then we don't need to merge, just replace the current list
    // This is used for file uploads
    if (overwrite) {
      if (reference != null) {
        multiselectValues[reference] = MultiselectFormFieldValueById(
            id: id,
            values: multiselect
                ? newValue
                : newValue.isNotEmpty
                    ? [newValue.first]
                    : []);
      } else {
        multiselectValues = [
          ...multiselectValues,
          MultiselectFormFieldValueById(
              id: id,
              values: multiselect
                  ? newValue
                  : newValue.isNotEmpty
                      ? [newValue.first]
                      : [])
        ];
      }
      return;
    }

    if (reference != null) {
      // Lets do some massaging to the values to see if we need to remove some items based on this list.

      // Lets subtract any values that are already stored, and then add any values which should be added.
      final listToRemove = newValue
          .where((value) => multiselectValues[reference]
              .values
              .any((existingValue) => existingValue.value == value.value))
          .toList();

      final updatedValue = [
        // Any Additional new values minus the ones which we removed.
        ...newValue.where((value) =>
            !listToRemove.any((removeVar) => removeVar.value == value.value)),
        // original values minus the values we should be removing (because they were selected again)
        ...multiselectValues[reference].values.where((value) =>
            !listToRemove.any((removeVar) => removeVar.value == value.value)),
      ];

      multiselectValues[reference] = MultiselectFormFieldValueById(
          id: id,
          values: multiselect
              ? updatedValue
              : updatedValue.isNotEmpty
                  ? [updatedValue.first]
                  : []);
    } else {
      multiselectValues = [
        ...multiselectValues,
        MultiselectFormFieldValueById(
            id: id,
            values: multiselect
                ? newValue
                : newValue.isNotEmpty
                    ? [newValue.first]
                    : [])
      ];
    }
    // Trigger any onChange functions
    if (field?.onChange != null) {
      field!
          .onChange!(FormResults.getResults(controller: this, fields: [field]));
    }
    // Notify listeners
    if (!noNotify) {
      notifyListeners();
    }
  }

  /// Reset a multi-select field to zero options. Useful for removing choices from a MultiSelect field.
  /// or resetting a field to zero files.
  void removeMultiSelectOptions(String fieldId) {
    updateMultiselectValues(
      fieldId,
      [],
      overwrite: true,
    );
  }

  /// Resets all choices on any multiselect field to false.
  void resetMultiselectChoices(
    String fieldId, {
    // Disable notify listeners. This can prevent notification loops breaking widgets.
    bool noNotify = false,
  }) {
    final reference = findMultiselectValueIndex(fieldId);
    if (reference != null) {
      multiselectValues.removeAt(reference);

      final field =
          fields.firstWhereOrNull((fieldData) => fieldData.id == fieldId);

      // Trigger any onChange functions
      if (field?.onChange != null) {
        field!.onChange!(
            FormResults.getResults(controller: this, fields: [field]));
      }

      if (!noNotify) {
        notifyListeners();
      }
    }

    return;
  }

  MultiselectFormFieldValueById? findMultiselectValue(String id) {
    final reference = findMultiselectValueIndex(id);
    if (reference != null) {
      return multiselectValues[reference];
    }
    return null;
  }

  int? findMultiselectValueIndex(String id) {
    for (int i = 0; i < multiselectValues.length; i++) {
      if (multiselectValues[i].id == id) {
        return i;
      }
    }
    return null;
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
