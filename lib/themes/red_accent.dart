import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/material.dart';

FormTheme redAccentFormTheme(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  // Define colors for light and dark themes
  final isDark = colorScheme.brightness == Brightness.dark;

  final FieldColorScheme baseColorScheme = FieldColorScheme(
    backgroundColor: isDark ? Colors.black : Colors.white,
    borderColor: isDark ? Colors.redAccent : Colors.red,
    borderSize: 2,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    textColor: isDark ? Colors.redAccent : Colors.black,
    hintTextColor: isDark ? Colors.red.withOpacity(0.7) : Colors.grey,
    titleColor: isDark ? Colors.red : Colors.black,
    descriptionColor: isDark ? Colors.red.withOpacity(0.8) : Colors.black54,
    textBackgroundColor: isDark ? Colors.red.withOpacity(0.1) : Colors.white,
    iconColor: isDark ? Colors.red : Colors.black,
  );

  final FieldColorScheme errorColorScheme = FieldColorScheme(
    backgroundColor: colorScheme.errorContainer,
    borderColor: colorScheme.error,
    borderSize: 2,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    textColor: Colors.white,
    hintTextColor: colorScheme.onError.withOpacity(0.7),
    titleColor: colorScheme.error,
    descriptionColor: colorScheme.onError,
    textBackgroundColor: colorScheme.error.withOpacity(0.1),
    iconColor: colorScheme.error,
  );

  return FormTheme(
    colorScheme: baseColorScheme,
    errorColorScheme: errorColorScheme,
    activeColorScheme: baseColorScheme.copyWith(
      borderColor: isDark ? Colors.redAccent : Colors.red,
      textBackgroundColor:
          isDark ? Colors.redAccent : Colors.red.withOpacity(0.1),
    ),
    disabledColorScheme: baseColorScheme.copyWith(
      backgroundColor: isDark ? Colors.black54 : Colors.grey[300],
      textColor: isDark ? Colors.red.withOpacity(0.5) : Colors.grey,
    ),
    selectedColorScheme: baseColorScheme.copyWith(
      backgroundColor: isDark
          ? Colors.redAccent.withOpacity(0.2)
          : Colors.red.withOpacity(0.1),
      textColor: isDark ? Colors.red : Colors.redAccent,
    ),
    titleStyle: textTheme.titleMedium?.copyWith(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.redAccent : Colors.red,
    ),
    descriptionStyle: textTheme.bodySmall?.copyWith(
      fontSize: 14,
      color: isDark ? Colors.redAccent.withOpacity(0.8) : Colors.black54,
    ),
    hintTextStyle: textTheme.bodyMedium?.copyWith(
      fontSize: 12,
      color: isDark ? Colors.red.withOpacity(0.7) : Colors.grey,
    ),
    chipTextStyle: textTheme.bodySmall?.copyWith(
      fontSize: 12,
      color: isDark ? Colors.redAccent : Colors.red,
    ),
  );
}
