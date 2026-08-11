import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter_test/flutter_test.dart';

/// requestFocus on text fields.
///
/// Historically only the multiselect family (checkbox/radio/chip/dropdown)
/// honored `requestFocus: true`; text fields silently ignored it, so every
/// consumer passing the flag on a TextField got nothing. The flag is now
/// honored by StatefulFieldWidget-based fields via a post-frame focus
/// request in the shared state class — these tests pin that behavior.
void main() {
  Future<form.FormController> pumpForm(
    WidgetTester tester,
    List<form.Field> fields,
  ) async {
    final controller = form.FormController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: form.Form(controller: controller, fields: fields),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('TextField with requestFocus: true is focused after mount',
      (tester) async {
    final controller = await pumpForm(tester, [
      form.TextField(id: 'plain'),
      form.TextField(id: 'wanted', requestFocus: true),
    ]);

    final node = controller.getFieldController<FocusNode>('wanted');
    expect(node, isNotNull);
    expect(node!.hasFocus, isTrue);
    expect(
      controller.getFieldController<FocusNode>('plain')?.hasFocus ?? false,
      isFalse,
    );
  });

  testWidgets('TextField without requestFocus stays unfocused', (tester) async {
    final controller = await pumpForm(tester, [
      form.TextField(id: 'quiet'),
    ]);

    final node = controller.getFieldController<FocusNode>('quiet');
    // The node may not even exist until something touches the field; either
    // way, nothing may hold focus.
    expect(node?.hasFocus ?? false, isFalse);
  });
}
