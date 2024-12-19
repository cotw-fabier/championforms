class MultiselectOption {
  // Displayed text in dropdown, etc
  final String label;
  // Anything you'd like to pass through with selected objects. You will be able to access this in the Form Results if you request "additionalData".
  final Object? additionalData;
  // this might be some helpful text that default templates for dropdowns and checkboxes might display
  final String? hintText;
  // The value of the selection. Must be able to evaluate to a string.
  final Object value;

  MultiselectOption({
    required this.label,
    this.additionalData,
    this.hintText,
    required this.value,
  }) {
    testToString(
        value); // We want to make sure whatever value is passed contains a toString method so champion forms doesn't break. This should fail if the passed object doesn't contain a toString element.
  }
  void testToString(Object? value) {
    try {
      assert(value?.toString() is String, 'toString() did not return a String');
    } catch (e) {
      throw "Passed Form multiselect field value does not support the method toString. Please add the method toString to your form field value.";
    }
  }
}
