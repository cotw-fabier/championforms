import 'package:flutter/material.dart';

class FormFieldWrapperDesignWidget extends StatelessWidget {
  const FormFieldWrapperDesignWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      //color: Colors.white,
      child: child,
    );
  }
}
