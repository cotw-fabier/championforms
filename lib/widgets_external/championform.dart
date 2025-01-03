import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

class ChampionForm extends StatelessWidget {
  const ChampionForm({
    super.key,
    this.fields = const [],
    required this.id,
    this.spacing,
    this.formWidth,
    this.formHeight,
    this.theme,
    this.formWrapper = simpleWrapper,
  });

  final List<FormFieldBase> fields;
  final String id;
  final double? spacing;
  final double? formWidth;
  final double? formHeight;

  final Widget Function(
    BuildContext context,
    List<Widget> form,
  ) formWrapper;
  final FormTheme? theme;

  @override
  Widget build(BuildContext context) {
    // Setup defaults for the theme. This allows us to pass Theme.of(context) into the build.
    // We merge it with the theme given to the widget during build so it matches up.

    final formTheme = FormTheme().withDefaults(
      inputTheme: theme,
      textInfo: Theme.of(context).textTheme,
      colorInfo: Theme.of(context).colorScheme,
    );

    return FormBuilderWidget(
      spacer: spacing,
      fields: fields,
      id: id,
      theme: formTheme,
      formWrapper: formWrapper,
    );
  }
}
