import 'package:flutter/material.dart';

Widget simpleWrapper(
  BuildContext context,
  List<Widget> form,
) {
  return SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: form,
    ),
  );
}
