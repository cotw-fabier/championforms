import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'formbuilderprovider.g.dart';

// Text Editing Controller provider
@riverpod
class FieldControllerNotifier extends _$FieldControllerNotifier {
  @override
  TextEditingController build(String id) {
    final controller = TextEditingController();
    ref.onDispose(() => controller.dispose());
    return controller;
  }
}

// Focus Controller
@riverpod
class FieldFocusNotifier extends _$FieldFocusNotifier {
  @override
  FocusNode build(String id) {
    final controller = FocusNode();
    ref.onDispose(() => controller.dispose());
    return controller;
  }
}
