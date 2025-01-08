import 'package:flutter/material.dart';

class GradientTextFormField extends StatelessWidget {
  const GradientTextFormField(
      {super.key,
      required this.id,
      this.controller,
      this.focusNode,
      this.onComplete,
      this.icon,
      this.hintText});
  final String id;
  final TextEditingController? controller;
  final Function(String)? onComplete;
  final Icon? icon;
  final FocusNode? focusNode;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 250,
      height: 35,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer, // Lighter color
            theme.colorScheme.secondaryContainer // Darker color
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: theme.primaryColor, // Thin outline
          width: 0.5,
        ),
      ),
      child: TextFormField(
        focusNode: focusNode,
        controller: controller,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          prefixIcon: icon,
          filled: true,
          fillColor: Colors.transparent, // To ensure the gradient is visible
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none, // No additional border needed
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
          hintText: hintText,
          hintStyle: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
        ),
        onFieldSubmitted: (value) {
          if (onComplete != null) onComplete!(value);
        },
      ),
    );
  }
}
