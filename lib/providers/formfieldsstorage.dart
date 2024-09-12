import 'package:championforms/models/formfieldclass.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'formfieldsstorage.g.dart';

@riverpod
class FormFieldsStorageNotifier extends _$FormFieldsStorageNotifier {
  @override
  List<FormFieldDef> build(String formId) {
    return [];
  }

  void addFields(List<FormFieldDef> fields) {
    final merged = [...state, ...fields];
    state = merged.toList();
  }
}
