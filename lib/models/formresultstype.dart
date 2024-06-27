// Abstract base class

import 'package:championforms/providers/choicechipprovider.dart';

abstract class FormResults {
  String val();
  String valWithDefault(String defaultVal);
  List<String> valList();
  List<String> valListWithDefault(List<String> defaultVal);
}

// Subclass for handling single strings
class StringItem extends FormResults {
  final String value;

  StringItem(this.value);

  @override
  String val() {
    return value; // Simply return the single string
  }

  @override
  String valWithDefault(String defaultVal) {
    return value == "" ? defaultVal : value;
  }

  @override
  List<String> valList() {
    return [value];
  }

  @override
  List<String> valListWithDefault(List<String> defaultVal) {
    return value == "" ? defaultVal : [value];
  }
}

// Subclass for handling a list of strings
class StringListItem extends FormResults {
  final List<String> value;

  StringListItem(this.value);

  @override
  String val() {
    return value.join(
        ', '); // Join the list items into a single string, separated by commas
  }

  @override
  String valWithDefault(String defaultVal) {
    return value.isEmpty ? defaultVal : value.join(', ');
  }

  @override
  List<String> valList() {
    return value;
  }

  @override
  List<String> valListWithDefault(List<String> defaultVal) {
    return value.isEmpty ? defaultVal : value;
  }
}

// Subclass for handling a list of ChoiceChipValue
class ChoiceChipResultsList extends FormResults {
  final List<ChoiceChipValue> value;

  ChoiceChipResultsList(this.value);

  @override
  String val() {
    // Assuming ChoiceChipValue has a property 'label' that holds the string value
    return value.map((chip) => chip.id).join(', ');
  }

  @override
  String valWithDefault(String defaultVal) {
    return value.isNotEmpty ? defaultVal : value.join(', ');
  }

  @override
  List<String> valList() {
    return value
        .where(
          (element) => element.value == true,
        )
        .map((e) => e.id)
        .toList();
  }

  @override
  List<String> valListWithDefault(List<String> defaultVal) {
    final compressedList = value
        .where(
          (element) => element.value == true,
        )
        .map((e) => e.id)
        .toList();
    return compressedList.isEmpty ? defaultVal : compressedList;
  }
}
