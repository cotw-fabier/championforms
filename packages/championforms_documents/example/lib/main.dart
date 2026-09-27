import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/templates.dart';

void main() {
  // Register the document field type, the built-in rules and the app's
  // rating field before any template JSON is decoded.
  ensureFieldTypes();
  runApp(const AgreementBuilderApp());
}
