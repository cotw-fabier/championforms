import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

TextStyle? getTextStyleFromScheme(FieldColorScheme? scheme) {
  // If null return nothing
  if (scheme == null) return null;

  return TextStyle(
    // Text colors
    color: scheme.textColor,
  );
}
