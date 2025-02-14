import 'package:flutter/widgets.dart';

/// A small struct (data class) that ties a field ID to a TextEditingController.
class FieldController {
  final String fieldId;
  final TextEditingController controller;

  FieldController({
    required this.fieldId,
    required this.controller,
  });
}
