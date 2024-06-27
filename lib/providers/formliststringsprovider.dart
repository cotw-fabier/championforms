import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'formliststringsprovider.g.dart';

@riverpod
class FormListStringsNotifier extends _$FormListStringsNotifier {
  @override
  List<String> build(String id) {
    return [];
  }

  void addChoice(String choice) {
    List<String> newValues = [...state];
    newValues.add(choice);
    state = newValues;
  }

  void populate(List<String>? choices) {
    debugPrint("Populated: ${choices?.join(", ") ?? ""}");
    state = choices ?? [];
  }

  void reset() {
    state = [];
  }

  void remove(String val) {
    state = state.where((e) => e != val).toList();
  }

  void removeChoice(String choice) {
    state = state.where((e) => e != choice).toList();
  }
}
