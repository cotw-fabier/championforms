import 'package:flutter/material.dart';

class FieldGradientColors {
  final Color colorOne;
  final Color colorTwo;

  const FieldGradientColors({
    required this.colorOne,
    required this.colorTwo,
  });
}

// This color scheme can be added to any field to be used for defining the field colors. Otherwise we will use a default version of this which is defined using MediaQuery.of(context).colorScheme when the ChampionForm widget is initalized.

// The order of application is: default theme colors -> form widget colors -> field colors. They will override going from general to specific.

class FieldColorScheme {
  final Color backgroundColor;
  final FieldGradientColors? backgroundGradient;

  final Color borderColor;
  final FieldGradientColors? borderGradient;
  final int borderSize;

  final Color textColor;
  final Color hintTextColor;
  final Color titleColor;
  final Color descriptionColor;

  final Color iconColor;

  // Used for the chip field and selected dropdown field
  final Color? textBackgroundColor;
  final FieldGradientColors? textBackgroundGradient;

  const FieldColorScheme({
    this.backgroundColor = Colors.white,
    this.backgroundGradient,
    this.borderColor = Colors.grey,
    this.borderGradient,
    this.borderSize = 1,
    this.textColor = Colors.black,
    this.hintTextColor = Colors.black,
    this.titleColor = Colors.black,
    this.descriptionColor = Colors.black,
    this.iconColor = Colors.white,
    this.textBackgroundColor,
    this.textBackgroundGradient,
  });

  FieldColorScheme copyWith({
    Color? backgroundColor,
    FieldGradientColors? backgroundGradient,
    Color? borderColor,
    FieldGradientColors? borderGradient,
    int? borderSize,
    Color? textColor,
    Color? hintTextColor,
    Color? titleColor,
    Color? descriptionColor,
    Color? iconColor,
    Color? textBackgroundColor,
    FieldGradientColors? textBackgroundGradient,
  }) {
    return FieldColorScheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      borderColor: borderColor ?? this.borderColor,
      borderGradient: borderGradient ?? this.borderGradient,
      borderSize: borderSize ?? this.borderSize,
      textColor: textColor ?? this.textColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      titleColor: titleColor ?? this.titleColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      iconColor: iconColor ?? this.iconColor,
      textBackgroundColor: textBackgroundColor ?? this.textBackgroundColor,
      textBackgroundGradient:
          textBackgroundGradient ?? this.textBackgroundGradient,
    );
  }
}
