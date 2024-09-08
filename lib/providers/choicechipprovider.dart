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

  void addChoice(ChoiceChipValue choice) {
    List<ChoiceChipValue> newValues = [...state];
    newValues.add(choice);
    state = newValues;
  }

  void replaceChoice(ChoiceChipValue choice) {
    state = [choice];
  }

  void removeChoice(String id) {
    state = state.where((choice) => choice.id != id).toList();
  }
}
