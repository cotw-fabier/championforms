import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'choicechipprovider.g.dart';

class ChoiceChipValue {
  final String id;
  final bool value;

  ChoiceChipValue({
    required this.id,
    required this.value,
  });
}

@riverpod
class ChoiceChipNotifier extends _$ChoiceChipNotifier {
  @override
  List<ChoiceChipValue> build(String id) {
    return [];
  }

  List<ChoiceChipValue> addChoice(ChoiceChipValue choice) {
    List<ChoiceChipValue> newValues = [...state];
    newValues.add(choice);
    state = newValues;
    return newValues;
  }

  List<ChoiceChipValue> replaceChoice(ChoiceChipValue choice) {
    state = [choice];
    return [choice];
  }

  List<ChoiceChipValue> removeChoice(String id) {
    final newState = state;
    final updated = newState.where((choice) => choice.id != id).toList();

    state = updated;
    return updated;
  }

  List<ChoiceChipValue> resetChoices() {
    state = [];
    return [];
  }
}
