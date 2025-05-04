import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/field_types/formfieldbase.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_external/form_wrappers/simple_wrapper.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

class ChampionForm extends StatefulWidget {
  const ChampionForm({
    super.key,
    required this.controller,
    required this.fields,
    this.pageName,
    this.spacing,
    this.formWidth,
    this.formHeight,
    this.theme,
    this.formWrapper = simpleWrapper,
    this.fieldPadding = const EdgeInsets.all(8),
  });

  /// Takes in a ChampionFormController() instance. Stores all fields and associated data in the controller.
  /// You can reuse the same controller for multiple ChampionForm() instances as long as all fields have unique IDs.
  /// This is encouraged behavior for building dynamic form layouts.
  final ChampionFormController controller;

  /// Form Fields. Takes in all the various types of form Fields.
  /// Base class is FormFieldBase, then various fields are built on top of that:
  /// ChampionRow(),
  /// ChampionColumn(),
  /// ChampionTextField(),
  /// ChampionDropDown(),
  /// ChampionOptionSelect(),
  /// ChampionCheckboxSelect(),
  /// etc
  final List<FormFieldBase> fields;

  /// pageName is a unique name for a page of fields.
  /// You can use the same name across widgets
  /// allows you to build a unique subset of fields
  /// for pulling results "by page" instead
  /// of grabbing all the results for the form at once
  /// this is useful if you have a multi-page form
  /// and only want to grab results for a specific "page"
  /// of your form.
  ///
  /// This is not required. Otherwise give a simple string
  /// ID to this "page".
  final String? pageName;

  /// Adds a little spacing between fields.
  /// Leave Blank to rely on other field layouts
  final double? spacing;

  /// Width of the Form
  final double? formWidth;

  /// Max height of the form. Will scroll if reach the edge of the height.
  final double? formHeight;

  /// Field Padding. Gives a default padding to all fields.
  /// Convienence feature to give all fields some simple padding.
  /// Defaults to EdgeInsets.all(8.0) for a nice clean look.
  final EdgeInsets fieldPadding;

  /// This is the form wrapper building. Will wrap the entire output of the form.
  /// Create any builder you like or leave it default.
  final Widget Function(
    BuildContext context,
    List<Widget> form,
  ) formWrapper;

  /// This is the form Theme. Takes a FormTheme object which defines fonts and colors for the form.
  /// Will try to default to material widget colors if no theme is given.
  final FormTheme? theme;

  @override
  State<StatefulWidget> createState() => _ChampionFormWidgetState();
}

class _ChampionFormWidgetState extends State<ChampionForm> {
  @override
  void initState() {
    super.initState();
    // Register the default builders on first launch.
    if (!ChampionFormFieldRegistry.instance.isInitialized) {
      ChampionFormFieldRegistry.instance.registerCoreBuilders();
    }
  }

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
      pageName: widget.pageName,
      theme: formTheme,
      formWrapper: widget.formWrapper,
      fieldPadding: widget.fieldPadding,
    );
  }
}
