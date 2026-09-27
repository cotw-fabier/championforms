// A one-field page for checking Enter / Backspace typing rules in a real
// browser, where the keys arrive from Chrome itself (IME deltas, the newline
// input action and real key events) instead of flutter_test's simulation.
//
// Serve it:
//   cd packages/championforms_documents/example
//   flutter run -d web-server --web-port 8123 \
//     -t integration_test/web_typing_rules_app.dart
//
// then drive it with integration_test/web_typing_rules_drive.mjs (Puppeteer,
// real CDP key events). The page publishes the field's document as JSON on
// `window.championDoc()`.
import 'dart:convert';
import 'dart:js_interop';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';

@JS('championDoc')
external set _championDoc(JSFunction value);

void main() {
  final controller = form.FormController();
  _championDoc = (() {
    final doc = DocumentField.coerce(
      controller.getFieldValueOrNull<Object>('doc'),
    );
    return jsonEncode(doc?.toJson()).toJS;
  }).toJS;
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: form.Form(
            controller: controller,
            fields: [
              DocumentField(
                id: 'doc',
                initialDocument: DocSnapshot([const ParagraphNode(id: 'p')]),
                minHeight: 200,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
