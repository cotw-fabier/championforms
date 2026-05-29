import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/widgets_internal/field_interaction_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpField(
  WidgetTester tester, {
  required form.FormController controller,
  required form.TextField field,
}) async {
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

void main() {
  group('TextField focus animation (animateInteractions)', () {
    setUp(() {
      // Reset global defaults so each test starts from the package baseline.
      FormFieldDefaults.instance.reset();
    });

    tearDown(() {
      FormFieldDefaults.instance.reset();
    });

    testWidgets('wraps with FieldInteractionAnimator by default',
        (tester) async {
      final controller = form.FormController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        field: form.TextField(id: 'name'),
      );

      expect(find.byType(FieldInteractionAnimator), findsOneWidget);
    });

    testWidgets('field-level animateInteractions=false skips the animator',
        (tester) async {
      final controller = form.FormController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        field: form.TextField(id: 'name', animateInteractions: false),
      );

      expect(find.byType(FieldInteractionAnimator), findsNothing);
    });

    testWidgets(
        'global FormFieldDefaults.animateInteractions=false disables by default',
        (tester) async {
      FormFieldDefaults.instance.animateInteractions = false;

      final controller = form.FormController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        field: form.TextField(id: 'name'),
      );

      expect(find.byType(FieldInteractionAnimator), findsNothing);
    });

    testWidgets(
        'field-level animateInteractions=true wins over global false',
        (tester) async {
      FormFieldDefaults.instance.animateInteractions = false;

      final controller = form.FormController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        field: form.TextField(id: 'name', animateInteractions: true),
      );

      expect(find.byType(FieldInteractionAnimator), findsOneWidget);
    });

    testWidgets('animator runs to completion on focus and reverses on blur',
        (tester) async {
      final controller = form.FormController();
      addTearDown(controller.dispose);

      await _pumpField(
        tester,
        controller: controller,
        field: form.TextField(id: 'name'),
      );

      // Focus the field — the animator should animate forward and settle.
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.byType(FieldInteractionAnimator), findsOneWidget);

      // Tap outside (or rather: unfocus by tapping a different focus target).
      // FocusScope.of(context).unfocus() via a fresh focus request:
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // No exceptions, no leftover timers — animator survives both transitions.
      expect(tester.takeException(), isNull);
    });

    testWidgets('copyWith preserves and overrides animateInteractions',
        (tester) async {
      final base = form.TextField(id: 'name', animateInteractions: false);
      final preserved = base.copyWith();
      final overridden = base.copyWith(animateInteractions: true);

      expect(preserved.animateInteractions, isFalse);
      expect(overridden.animateInteractions, isTrue);
    });
  });
}
