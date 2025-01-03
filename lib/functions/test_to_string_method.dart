void testToString(Object? value) {
  try {
    assert(value?.toString() is String, 'toString() did not return a String');
  } catch (e) {
    throw "Passed Form multiselect field value does not support the method toString. Please add the method toString to your form field value.";
  }
}
