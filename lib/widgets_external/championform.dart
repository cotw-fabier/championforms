import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

class ChampionForm extends StatelessWidget {
  const ChampionForm({
    super.key,
    this.fields = const [],
    required this.id,
    this.spacing = 10,
    this.formWidth,
    this.formHeight,
  });

  final List<FormFieldBase> fields;
  final String id;
  final double spacing;
  final double? formWidth;
  final double? formHeight;

  @override
  Widget build(BuildContext context) {
    return FormBuilderWidget(
      fields: fields,
      id: id,
      spacing: spacing,
      formWidth: formWidth,
      formHeight: formHeight,
    );
  }
}
