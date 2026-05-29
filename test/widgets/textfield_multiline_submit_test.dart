import 'package:championforms/championforms.dart' as form;
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for multi-line TextField submission via Ctrl/Cmd+Enter
/// (`submitOnControlEnter`) and the mobile `textInputAction` passthrough.
void main() {
  group('Multi-line TextField submission', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      // Always restore the global default so tests don't leak state.
      FormFieldDefaults.instance.reset();
    });

    Future<void> pumpField(WidgetTester tester, form.TextField field) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> teardownTree(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    }

    testWidgets(
        'Ctrl+Enter fires onSubmit when submitOnControlEnter is true (multiline)',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnControlEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('Cmd+Enter (meta) also fires onSubmit', (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnControlEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('plain Enter does NOT submit and inserts a newline (multiline)',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnControlEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.enterText(find.byType(TextField), 'line one');
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitCount, 0,
          reason: 'Plain Enter must not submit a multiline field.');

      await teardownTree(tester);
    });

    testWidgets(
        'Ctrl+Enter does nothing when submitOnControlEnter is off (default)',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        // submitOnControlEnter left null -> falls through to default (false)
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 0);

      await teardownTree(tester);
    });

    testWidgets('FormFieldDefaults.submitOnControlEnter enables it app-wide',
        (tester) async {
      FormFieldDefaults.instance.submitOnControlEnter = true;

      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        // No field-level value: should pick up the global default.
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('field-level submitOnControlEnter:false overrides global true',
        (tester) async {
      FormFieldDefaults.instance.submitOnControlEnter = true;

      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnControlEnter: false,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 0);

      await teardownTree(tester);
    });

    testWidgets('submitOnEnter: plain Enter submits a multiline field',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('submitOnEnter: Shift+Enter does NOT submit (newline)',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        submitOnEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();

      expect(submitCount, 0,
          reason: 'Shift+Enter must insert a newline, not submit.');

      await teardownTree(tester);
    });

    testWidgets(
        'submitOnEnter does NOT double-submit on a single-line field',
        (tester) async {
      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 1,
        submitOnEnter: true,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // On a single-line field Enter submits via the TextField's own
      // onSubmitted; the Focus wrapper must not also fire (would be 2).
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('FormFieldDefaults.submitOnEnter enables it app-wide',
        (tester) async {
      FormFieldDefaults.instance.submitOnEnter = true;

      var submitCount = 0;
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        onSubmit: (_) => submitCount++,
      );

      await pumpField(tester, field);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(submitCount, 1);

      await teardownTree(tester);
    });

    testWidgets('textInputAction passes through to the Material TextField',
        (tester) async {
      final field = form.TextField(
        id: 'message',
        maxLines: 5,
        textInputAction: TextInputAction.send,
      );

      await pumpField(tester, field);

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.textInputAction, TextInputAction.send);

      await teardownTree(tester);
    });
  });
}
