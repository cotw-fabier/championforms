// Regression tests for package bugs found while building the trial app.

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('two DocumentFields can be on screen at once', (tester) async {
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
    // super_editor used to throw "Found 2 duplicate input IDs this frame"
    // here, because both editors had the default (null) inputRole.
    expect(tester.takeException(), isNull);
    expect(find.byType(DocumentEditor), findsNWidgets(2));
  });
}
