import 'package:championforms/models/themes.dart';
import 'package:championforms/widgets_internal/fieldexpanded.dart';
import 'package:flutter/material.dart';

Widget fieldVerticalLayoutBuilder({
  Widget? title,
  Widget? description,
  Widget? errors,
  Widget? icon,
  bool? expanded,
  required FormTheme theme,
  required Widget layout,
  required Widget field,
}) {
  return FieldVerticalLayoutWidget(
    title: title,
    description: description,
    errors: errors,
    icon: icon,
    expanded: expanded ?? false,
    theme: theme,
    field: field,
  );
}

class FieldVerticalLayoutWidget extends StatelessWidget {
  const FieldVerticalLayoutWidget({
    super.key,
    this.title,
    this.description,
    this.errors,
    this.icon,
    this.expanded = false,
    required this.theme,
    required this.field,
  });

  final Widget? title;
  final Widget? description;
  final Widget? errors;

  final Widget? icon;
  final bool expanded;
  final Widget field;
  final FormTheme theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) title!,
        if (title != null) SizedBox(height: 10),
        if (description != null) description!,
        if (description != null) SizedBox(height: 10),
        if (errors != null) errors!,
        if (errors != null) SizedBox(height: 10),
        FieldExpanded(
          expanded: expanded,
          child: theme.fieldBuilder! != null
              ? theme.fieldBuilder!(
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
