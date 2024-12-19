import 'package:championforms/models/multiselect_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'multiselect_provider.g.dart';

@riverpod
class MultiSelectOptionNotifier extends _$MultiSelectOptionNotifier {
  @override
  List<MultiselectOption> build(String id) {
    return [];
  }

  List<MultiselectOption> addChoice(
      MultiselectOption choice, bool? multiSelect) {
    List<MultiselectOption> newValues = multiSelect == true ? [...state] : [];
    newValues.add(choice);
    state = newValues;
    return newValues;
  }

  List<MultiselectOption> replaceChoice(MultiselectOption choice) {
    state = [choice];
    return [choice];
  }

  List<MultiselectOption> removeChoice(String value) {
    final newState = state;
    final updated = newState.where((choice) => choice.value != value).toList();

    state = updated;
    return updated;
  }

  List<MultiselectOption> resetChoices() {
    ref.invalidateSelf();
    return [];
  }
}
