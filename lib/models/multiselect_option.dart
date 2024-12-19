class MultiselectOption {
  final String label;
  final String? hintText;
  final value;

  MultiselectOption({
    required this.label,
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
