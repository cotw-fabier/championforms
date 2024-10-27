import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

/// This element controls text using build in or user supplied styles and colors.
/// This is intended for use with title / description / chips

class FieldTextElement extends StatelessWidget {
  const FieldTextElement({
    super.key,
    required this.color,
    required this.textStyle,
    required this.text,
  });

  final Color color;
  final TextStyle textStyle;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: textStyle.copyWith(color: color));
  }
}
