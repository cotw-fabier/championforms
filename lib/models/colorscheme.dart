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
    this.textBackgroundColor,
    this.textBackgroundGradient,
  });
}
