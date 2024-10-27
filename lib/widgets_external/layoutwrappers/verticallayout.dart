import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';

class FieldVerticalLayout extends StatelessWidget {
  const FieldVerticalLayout({
    super.key,
    this.title,
    this.description,
    this.errors,
    this.fieldWrapper,
    this.icon,
    this.expanded = false,
    required this.colors,
    required this.field,
  });

  final Widget? title;
  final Widget? description;
  final Widget? errors;
  final Widget Function({required Widget child})? fieldWrapper;

  final Widget? icon;
  final bool expanded;
  final Widget field;
  final FieldColorScheme colors;

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

class FieldExpanded extends StatelessWidget {
  const FieldExpanded({
    super.key,
    required this.child,
    required this.expanded,
  });

  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return expanded ? Expanded(child: child) : child;
  }
}

class FieldScroll extends StatelessWidget {
  const FieldScroll({
    super.key,
    required this.child,
    required this.expanded,
  });

  final Widget child;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return expanded ? SingleChildScrollView(child: child) : child;
  }
}
