import 'package:championforms/models/multiselect_option.dart';

class MultiselectFormFieldValueById {
  final String id;
  final List<MultiselectOption> values;

  const MultiselectFormFieldValueById({
    required this.id,
    required this.values,
  });
}