import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

InputDecoration? getInputDecorationFromScheme(FieldColorScheme? scheme) {
  // If null return nothing
  if (scheme == null) return null;

  // Helper function to create a BoxDecoration with gradients or solid colors
  BoxDecoration? _createGradientDecoration(
      FieldGradientColors? gradient, Color? color) {
    if (gradient != null) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [gradient.colorOne, gradient.colorTwo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    } else if (color != null) {
      return BoxDecoration(color: color);
    }
    return null;
  }

  // Create border decoration with gradients or solid color
  InputBorder _createBorder(
      FieldGradientColors? gradient, Color color, int borderSize) {
    if (gradient != null) {
      return OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(borderSize.toDouble()),
        gapPadding: 0,
      );
    }
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: borderSize.toDouble()),
      borderRadius: BorderRadius.circular(borderSize.toDouble()),
    );
  }

  return InputDecoration(
    hintStyle: TextStyle(color: scheme.hintTextColor),
    labelStyle: TextStyle(color: scheme.titleColor),
    helperStyle: TextStyle(color: scheme.descriptionColor),

    // Text input colors
    filled: true,
    fillColor: scheme.backgroundGradient != null
        ? null // Gradient applied directly to decoration
        : scheme.backgroundColor,

    // Border colors or gradients
    enabledBorder: _createBorder(
        scheme.borderGradient, scheme.borderColor, scheme.borderSize),
    focusedBorder: _createBorder(
        scheme.borderGradient, scheme.borderColor, scheme.borderSize),
    errorBorder: _createBorder(
        scheme.borderGradient, scheme.borderColor, scheme.borderSize),

    // Icon colors
    prefixIconColor: scheme.iconColor,
    suffixIconColor: scheme.iconColor,

    // Chip field and dropdown colors
    suffixStyle: scheme.textBackgroundGradient != null
        ? TextStyle(
            background: Paint()
              ..shader = LinearGradient(
                colors: [
                  scheme.textBackgroundGradient!.colorOne,
                  scheme.textBackgroundGradient!.colorTwo
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(Rect.fromLTWH(0, 0, 200, 30)),
          )
        : TextStyle(backgroundColor: scheme.textBackgroundColor),
  );
}
