import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'field_focus.g.dart';

@riverpod
class FieldFocusNotifier extends _$FieldFocusNotifier {
  @override
  bool build(String fieldId) {
    return false;
  }

  void setFocus(bool focus) {
    debugPrint("Setting field $fieldId focus to $focus");
    state = focus;
  }
}
