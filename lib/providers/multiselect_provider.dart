import 'package:championforms/models/multiselect_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:collection/collection.dart';

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

    // Remove the choice if it already exists.
    if (newValues.firstWhereOrNull(
            (MultiselectOption option) => option.value == choice.value) !=
        null) {
      newValues = newValues.where((val) => val.value != choice.value).toList();
    } else {
      newValues.add(choice);
    }

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
