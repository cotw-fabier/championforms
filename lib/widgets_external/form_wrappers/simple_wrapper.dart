import 'package:flutter/material.dart';

Widget simpleWrapper(
  BuildContext context,
  List<Widget> form,
) {
  // The default wrapper is now a non-scrolling Column. This makes it compose
  // better when placed inside another scrolling view by the user.
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: form,
  );
}
