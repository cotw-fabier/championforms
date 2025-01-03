import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

class FormTheme {
  final Widget Function({
    Widget? title,
    Widget? description,
    Widget? errors,
    Widget? icon,
    bool? expanded,
    FormTheme theme,
    Widget layout,
    Widget field,
  })? layoutBuilder;
  final FormFieldBuilder? fieldBuilder;
  final FormFieldBuilder? nonTextFieldBuilder;

  // Color Schemes
  final FieldColorScheme? colorScheme;
  final FieldColorScheme? errorColorScheme;
  final FieldColorScheme? activeColorScheme;
  final FieldColorScheme? disabledColorScheme;
  final FieldColorScheme? selectedColorScheme;

  // For directly accessing InputDecoration on text and textarea
  final InputDecoration? inputDecoration;

  // Text Themes
  final TextStyle? titleStyle;
  final TextStyle? descriptionStyle;
  final TextStyle? hintTextStyle;
  final TextStyle? chipTextStyle;

  const FormTheme({
    this.layoutBuilder,
    this.fieldBuilder,
    this.nonTextFieldBuilder,
    this.colorScheme,
    this.errorColorScheme,
    this.activeColorScheme,
    this.disabledColorScheme,
    this.selectedColorScheme,
    this.inputDecoration,
    this.titleStyle,
    this.descriptionStyle,
    this.hintTextStyle,
    this.chipTextStyle,
  });

  FormTheme withDefaults({
    FormTheme? inputTheme,
    required TextTheme textInfo,
    required ColorScheme colorInfo,
  }) {
// This is the main color scheme.
    final passColorScheme = colorScheme ??
        FieldColorScheme(
          backgroundColor: colorInfo.primaryContainer,
          borderColor: colorInfo.tertiary,
          borderSize: 1,
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
          borderRadius: BorderRadius.all(Radius.circular(8)),
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
          borderRadius: BorderRadius.all(Radius.circular(8)),
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

    FormTheme outputTheme = FormTheme(
      colorScheme: passColorScheme,
      errorColorScheme: passErrorColorScheme,
      disabledColorScheme: passDisabledColorScheme,
      selectedColorScheme: passSelectedColorScheme,
      activeColorScheme: passActiveColorScheme,
      titleStyle: passTitleTextStyle,
      descriptionStyle: passDescriptionTextStyle,
      hintTextStyle: passHintTextStyle,
      chipTextStyle: passChipTextStyle,
    );

    if (inputTheme != null) {
      return outputTheme.copyWith(theme: inputTheme);
    }

    return outputTheme;
  }

  // This is a special copywith which allows us to enter an entire theme as a possible override. It will add all properties from that theme or use defaults set here. You can also override both by naming properties specifically.
  // This idea is so we can just pass in an entire theme object and not have to name every specific property making the front-end API simpler
  FormTheme copyWith({
    FormTheme? theme,
    Widget Function({
      Widget? title,
      Widget? description,
      Widget? errors,
      Widget? icon,
      bool? expanded,
      FormTheme theme,
      Widget layout,
      Widget field,
    })? layoutBuilder,
    FormFieldBuilder? fieldBuilder,
    FormFieldBuilder? nonTextFieldBuilder,
    FieldColorScheme? colorScheme,
    FieldColorScheme? errorColorScheme,
    FieldColorScheme? activeColorScheme,
    FieldColorScheme? disabledColorScheme,
    FieldColorScheme? selectedColorScheme,
    InputDecoration? inputDecoration,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    TextStyle? hintTextStyle,
    TextStyle? chipTextStyle,
  }) {
    final source = theme ?? this;
    return FormTheme(
      layoutBuilder:
          layoutBuilder ?? source.layoutBuilder ?? this.layoutBuilder,
      fieldBuilder: fieldBuilder ?? source.fieldBuilder ?? this.fieldBuilder,
      nonTextFieldBuilder: nonTextFieldBuilder ??
          source.nonTextFieldBuilder ??
          this.nonTextFieldBuilder,
      colorScheme: colorScheme ?? source.colorScheme ?? this.colorScheme,
      errorColorScheme:
          errorColorScheme ?? source.errorColorScheme ?? this.errorColorScheme,
      activeColorScheme: activeColorScheme ??
          source.activeColorScheme ??
          this.activeColorScheme,
      disabledColorScheme: disabledColorScheme ??
          source.disabledColorScheme ??
          this.disabledColorScheme,
      selectedColorScheme: selectedColorScheme ??
          source.selectedColorScheme ??
          this.selectedColorScheme,
      inputDecoration:
          inputDecoration ?? source.inputDecoration ?? this.inputDecoration,
      titleStyle: titleStyle ?? source.titleStyle ?? this.titleStyle,
      descriptionStyle:
          descriptionStyle ?? source.descriptionStyle ?? this.descriptionStyle,
      hintTextStyle:
          hintTextStyle ?? source.hintTextStyle ?? this.hintTextStyle,
      chipTextStyle:
          chipTextStyle ?? source.chipTextStyle ?? this.chipTextStyle,
    );
  }
}
