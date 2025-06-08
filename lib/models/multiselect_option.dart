class MultiselectOption {
  // Displayed text in dropdown, etc
  final String label;
  // Anything you'd like to pass through with selected objects. You will be able to access this in the Form Results if you request "additionalData".
  final Object? additionalData;
  // this might be some helpful text that default templates for dropdowns and checkboxes might display
  final String? hintText;
  // The value of the selection. Must be able to evaluate to a string.
  final String value;

  MultiselectOption({
    required this.value,
    this.label = this.value,
    this.additionalData,
    this.hintText,
  });
}
