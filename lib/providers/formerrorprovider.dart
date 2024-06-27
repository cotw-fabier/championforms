import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'formerrorprovider.g.dart';

@riverpod
class FormBuilderErrorNotifier extends _$FormBuilderErrorNotifier {
  @override
  FormBuilderError? build(
    String formId,
    String fieldId,
    int validatorPosition,
  ) {
    return null;
  }

  void setError(FormBuilderError error) {
    state = error;
  }

  void clearError() {
    final error = state;
    if (error != null) {
      state = null;
    }
  }
}
