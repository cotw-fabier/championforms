import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/formfieldbase.dart';
import 'package:championforms/widgets_internal/formbuilder.dart';
import 'package:flutter/material.dart';

class ChampionForm extends StatelessWidget {
  const ChampionForm(
      {super.key,
      this.fields = const [],
      required this.id,
      this.spacing = 10,
      this.formWidth,
      this.formHeight,
      this.colorScheme,
      this.activeColorScheme,
      this.errorColorScheme,
      this.disabledColorScheme,
      this.selectedColorScheme,
      this.titleStyle,
      this.descriptionStyle,
      this.hintTextStyle,
      this.chipTextStyle,
      this.fieldBuilder,
      this.fieldLayoutBuilder});

  final List<FormFieldBase> fields;
  final String id;
  final double spacing;
  final double? formWidth;
  final double? formHeight;

  // Color Styles
  final FieldColorScheme? colorScheme;
  final FieldColorScheme? errorColorScheme;
  final FieldColorScheme? disabledColorScheme;
  final FieldColorScheme? selectedColorScheme;
  final FieldColorScheme? activeColorScheme;

  // Text Styles
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? hintTextStyle;
  final TextStyle? chipTextStyle;

// Add a builder for defining the field style
  final Widget Function({required Widget child})? fieldBuilder;

  // This is the widget requirements for a widget layout other than the default.
  final Widget Function({
    Widget? title,
    Widget? description,
    Widget? errors,
    Widget Function({required Widget child})? fieldWrapper,
    Widget? icon,
    bool? expanded,
    FieldColorScheme? colors,
    required Widget field,
  })? fieldLayoutBuilder;

  @override
  Widget build(BuildContext context) {
    // Setup defaults for the colorscheme or use the objects that were passed.
    final colorInfo = Theme.of(context).colorScheme;
    final textInfo = Theme.of(context).textTheme;

    // This is the main color scheme.
    final passColorScheme = colorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.primaryContainer,
          borderColor: colorInfo.tertiary,
          borderSize: 1,
          textColor: colorInfo.primary,
          hintTextColor: colorInfo.secondary,
          titleColor: colorInfo.primary,
          descriptionColor: colorInfo.primary,
          textBackgroundColor: colorInfo.secondaryContainer,
          iconColor: colorInfo.tertiary,
        );
    // This is the error color state.
    final passErrorColorScheme = errorColorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.errorContainer,
          borderColor: colorInfo.error,
          borderSize: 1,
          textColor: colorInfo.primary,
          hintTextColor: colorInfo.secondary,
          titleColor: colorInfo.error,
          descriptionColor: colorInfo.primary,
          textBackgroundColor: colorInfo.secondaryContainer,
          iconColor: colorInfo.error,
        );
    // This is the color scheme for disabled fields.
    final passDisabledColorScheme = errorColorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.tertiaryContainer,
          borderColor: colorInfo.primaryContainer,
          borderSize: 1,
          textColor: colorInfo.primary,
          hintTextColor: colorInfo.secondary,
          titleColor: colorInfo.primary,
          descriptionColor: colorInfo.primary,
          textBackgroundColor: colorInfo.secondaryContainer,
          iconColor: colorInfo.primary,
        );

    // This is the color scheme for selected elements.
    final passSelectedColorScheme = colorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.tertiaryContainer,
          borderColor: colorInfo.primary,
          borderSize: 1,
          textColor: colorInfo.primary,
          hintTextColor: colorInfo.secondary,
          titleColor: colorInfo.primary,
          descriptionColor: colorInfo.primary,
          textBackgroundColor: colorInfo.secondaryContainer,
          iconColor: colorInfo.tertiary,
        );

    // This is the color scheme for fields which are currently active.
    final passActiveColorScheme = colorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.primaryContainer,
          borderColor: colorInfo.secondary,
          borderSize: 1,
          textColor: colorInfo.primary,
          hintTextColor: colorInfo.secondary,
          titleColor: colorInfo.primary,
          descriptionColor: colorInfo.primary,
          textBackgroundColor: colorInfo.secondaryContainer,
          iconColor: colorInfo.tertiary,
        );

    // Create some default text Styles in case we didn't define anything
    final passTitleTextStyle = titleStyle ??
        textInfo.titleMedium ??
        TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    final passDescriptionTextStyle = descriptionStyle ??
        textInfo.bodySmall ??
        TextStyle(
          fontSize: 12,
        );
    final passHintTextStyle = hintTextStyle ??
        textInfo.bodyMedium ??
        TextStyle(
          fontSize: 12,
        );
    final passChipTextStyle = chipTextStyle ??
        textInfo.bodySmall ??
        TextStyle(
          fontSize: 12,
        );

    return FormBuilderWidget(
      fields: fields,
      fieldLayoutBuilder: fieldLayoutBuilder,
      id: id,
      spacing: spacing,
      formWidth: formWidth,
      formHeight: formHeight,
      colorScheme: passColorScheme,
      activeColorScheme: passActiveColorScheme,
      errorColorScheme: passErrorColorScheme,
      disabledColorScheme: passDisabledColorScheme,
      selectedColorScheme: passSelectedColorScheme,
      titleStyle: passTitleTextStyle,
      descriptionStyle: passDescriptionTextStyle,
      hintTextStyle: passHintTextStyle,
      chipTextStyle: passChipTextStyle,
      fieldBuilder: fieldBuilder,
    );
  }
}
