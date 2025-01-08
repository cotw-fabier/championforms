import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

class ChampionForm extends StatefulWidget {
  const ChampionForm({
    super.key,
    required this.controller,
    required this.fields,
    this.spacing,
    this.formWidth,
    this.formHeight,
    this.theme,
    this.formWrapper = simpleWrapper,
  });
  final ChampionFormController controller;
  final List<FormFieldBase> fields;
  final double? spacing;
  final double? formWidth;
  final double? formHeight;

  final Widget Function(
    BuildContext context,
    List<Widget> form,
  ) formWrapper;
  final FormTheme? theme;

  @override
  State<StatefulWidget> createState() => _ChampionFormWidgetState();
}

class _ChampionFormWidgetState extends State<ChampionForm> {
  @override
  Widget build(BuildContext context) {
    // Setup defaults for the theme. This allows us to pass Theme.of(context) into the build.
    // We merge it with the theme given to the widget during build so it matches up.

    final formTheme = FormTheme().withDefaults(
      inputTheme: widget.theme,
      textInfo: Theme.of(context).textTheme,
      colorInfo: Theme.of(context).colorScheme,
    );

    return FormBuilderWidget(
      controller: widget.controller,
      spacer: widget.spacing,
      fields: widget.fields,
      theme: formTheme,
      formWrapper: widget.formWrapper,
    );
  }
}
