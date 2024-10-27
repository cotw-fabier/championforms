import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/widgets_internal/fieldexpanded.dart';
import 'package:flutter/material.dart';

Widget fieldHorizontalLayout({
  Widget? title,
  Widget? description,
  Widget? errors,
  Widget Function({required Widget child})? fieldWrapper,
  Widget? icon,
  bool? expanded,
  FieldColorScheme? colors,
  required Widget field,
}) {
  return FieldHorizontalLayoutWidget(
    title: title,
    description: description,
    errors: errors,
    fieldWrapper: fieldWrapper,
    icon: icon,
    expanded: expanded ?? false,
    colors: colors,
    field: field,
  );
}

class FieldHorizontalLayoutWidget extends StatelessWidget {
  const FieldHorizontalLayoutWidget({
    super.key,
    this.title,
    this.description,
    this.errors,
    this.fieldWrapper,
    this.icon,
    this.expanded = false,
    this.colors,
    required this.field,
  });

  final Widget? title;
  final Widget? description;
  final Widget? errors;
  final Widget Function({required Widget child})? fieldWrapper;

  final Widget? icon;
  final bool expanded;
  final Widget field;
  final FieldColorScheme? colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) title!,
            if (title != null) SizedBox(height: 10),
            if (description != null) description!,
            if (description != null) SizedBox(height: 10),
            if (errors != null) errors!,
            if (errors != null) SizedBox(height: 10),
          ],
        ),
        FieldExpanded(
          expanded: expanded,
          child: fieldWrapper != null
              ? fieldWrapper!(
                  child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    //if (icon != null) icon!,
                    Expanded(
                      child: field,
                    ),
                  ],
                ))
              : field,
        ),
      ],
    );
  }
}
