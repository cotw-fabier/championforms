import 'package:flutter/material.dart';

class ColoredBoxDecoratorWidget extends StatelessWidget {
  const ColoredBoxDecoratorWidget({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
  });

  final Widget child;

  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(30.0),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primaryContainer, // Lighter color
              theme.colorScheme.secondaryContainer // Darker color
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius ?? BorderRadius.circular(30.0),
          border: Border.all(
            color: theme.primaryColor, // Thin outline
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
