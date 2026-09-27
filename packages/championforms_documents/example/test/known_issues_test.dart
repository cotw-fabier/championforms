// Package bugs found while building the trial app. Each test demonstrates
// one and is skipped until the package fixes it; remove the `skip:` then.

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'two DocumentFields can be on screen at once',
    (tester) async {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: form.Form(
                controller: controller,
                fields: [
                  DocumentField(id: 'first'),
                  DocumentField(id: 'second'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // In debug builds super_editor throws "Found 2 duplicate input IDs
      // this frame" from a post-frame check, because DocumentEditor builds
      // its SuperEditor without an `inputRole` (both are `null`).
      expect(tester.takeException(), isNull);
      expect(find.byType(DocumentEditor), findsNWidgets(2));
    },
    skip:
        true, // blocked: DocumentEditor passes no inputRole to SuperEditor, so two mounted documents throw "duplicate input IDs" in debug builds
  );
}
