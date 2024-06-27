import 'package:flutter_riverpod/flutter_riverpod.dart';

final textFormFieldValueById =
    StateProvider.family.autoDispose<String, String>((ref, id) {
  return '';
});
