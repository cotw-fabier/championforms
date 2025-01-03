import 'package:flutter/material.dart';

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
