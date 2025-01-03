import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/material.dart';

FormTheme iconicColorTheme(BuildContext context) {
  // Colors derived from the provided image.
  // (E43D12, D6536D, FFA2B6, EFB11D, EBE9E1)

  const Color primaryColor = Color(0xFFE43D12); // Vibrant red-orange
  const Color secondaryColor = Color(0xFFD6536D); // Rich pink
  const Color tertiaryColor = Color(0xFFFFA2B6); // Light pink accent
  const Color lightColor = Color(0xFFEBE9E1); // Soft off-white background
  const Color hintColor = Color(0xFFEFB11D); // Bright gold/yellow accent

  // Default color scheme
  final defaultColorScheme = FieldColorScheme(
    backgroundColor: lightColor,
    borderColor: tertiaryColor,
    borderSize: 1,
    borderRadius: BorderRadius.circular(8),
    textColor: primaryColor,
    hintTextColor: hintColor,
    titleColor: primaryColor,
    descriptionColor: secondaryColor,
    textBackgroundColor: lightColor,
    iconColor: secondaryColor,
  );

  // Error color scheme
  final errorColorScheme = FieldColorScheme(
    backgroundColor: primaryColor.withOpacity(0.2), // Soft overlay of primary
    borderColor: primaryColor,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: primaryColor,
    hintTextColor: hintColor,
    titleColor: primaryColor,
    descriptionColor: primaryColor,
    textBackgroundColor: lightColor.withOpacity(0.9),
    iconColor: primaryColor,
  );

  // Disabled color scheme
  final disabledColorScheme = FieldColorScheme(
    backgroundColor: tertiaryColor.withOpacity(0.3),
    borderColor: tertiaryColor.withOpacity(0.6),
    borderSize: 1,
    borderRadius: BorderRadius.circular(8),
    textColor: tertiaryColor.withOpacity(0.7),
    hintTextColor: hintColor,
    titleColor: tertiaryColor.withOpacity(0.8),
    descriptionColor: tertiaryColor.withOpacity(0.6),
    textBackgroundColor: tertiaryColor.withOpacity(0.1),
    iconColor: tertiaryColor.withOpacity(0.5),
  );

  // Active color scheme
  final activeColorScheme = FieldColorScheme(
    backgroundColor: lightColor,
    borderColor: primaryColor,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: primaryColor,
    hintTextColor: lightColor.withOpacity(0.8),
    titleColor: primaryColor,
    descriptionColor: primaryColor,
    textBackgroundColor: hintColor,
    iconColor: primaryColor,
  );

  // Selected color scheme
  final selectedColorScheme = FieldColorScheme(
    backgroundColor: tertiaryColor,
    borderColor: secondaryColor,
    borderSize: 2,
    borderRadius: BorderRadius.circular(8),
    textColor: hintColor,
    hintTextColor: hintColor.withOpacity(0.9),
    titleColor: primaryColor,
    descriptionColor: secondaryColor,
    textBackgroundColor: tertiaryColor.withOpacity(0.8),
    iconColor: secondaryColor,
  );

  // Typography for the form fields.
  final titleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: primaryColor,
  );

  final descriptionStyle = TextStyle(
    fontSize: 14,
    color: tertiaryColor,
  );

  final hintTextStyle = TextStyle(
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: hintColor,
  );

  final chipTextStyle = TextStyle(
    fontSize: 12,
    color: lightColor,
  );

  // Combine all into the form theme.
  return FormTheme(
    colorScheme: defaultColorScheme,
    errorColorScheme: errorColorScheme,
    disabledColorScheme: disabledColorScheme,
    activeColorScheme: activeColorScheme,
    selectedColorScheme: selectedColorScheme,
    titleStyle: titleStyle,
    descriptionStyle: descriptionStyle,
    hintTextStyle: hintTextStyle,
    chipTextStyle: chipTextStyle,
  );
}
