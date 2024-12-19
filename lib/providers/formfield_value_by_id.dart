import 'package:championforms/models/multiselect_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'formfield_value_by_id.g.dart';

@riverpod
class TextFormFieldValueById extends _$TextFormFieldValueById {
  @override
  String build(String id) {
    return '';
  }

  void updateValue(String value) {
    state = value;
  }
}
