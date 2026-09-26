import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/widgets_internal/field_wiggle_animator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FieldView` renders one registered field outside a `form.Form`.
void main() {
  setUp(() => FormFieldDefaults.instance.reset());

  late form.FormController controller;
  setUp(() => controller = form.FormController());
  tearDown(() => controller.dispose());

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  /// A text field whose layout records the palette and counts builds.
  form.TextField recordingField(
    String id, {
    List<FieldColorScheme>? seenColors,
    List<form.Validator>? validators,
    bool? animateValidationErrors,
    FormTheme? theme,
  }) {
    return form.TextField(
      id: id,
      title: 'Title $id',
      validators: validators,
      animateValidationErrors: animateValidationErrors,
      theme: theme,
      fieldLayout: (context, field, controller, colors, rendered) {
        seenColors?.add(colors);
        return rendered;
      },
    );
  }

  final failing = [
    form.Validator(validator: (_) => false, reason: 'Always wrong'),
  ];

  testWidgets('renders a registered field outside a Form', (tester) async {
    final field = form.TextField(id: 'note', title: 'A note');
    controller.addFields(form.FieldView.fieldsToRegister(field));
    controller.updateFieldValue<String>('note', 'hello there');

    await tester.pumpWidget(
      host(form.FieldView(controller: controller, field: field)),
    );
    await tester.pump();

    expect(find.byType(form.Form), findsNothing);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('hello there'), findsOneWidget);
  });

  testWidgets('reflects the error state with the error palette', (
    tester,
  ) async {
    final errorScheme = const FieldColorScheme(borderColor: Colors.purple);
    final normalScheme = const FieldColorScheme(borderColor: Colors.teal);
    final seen = <FieldColorScheme>[];
    final field = recordingField(
      'email',
      seenColors: seen,
      validators: failing,
    );
    controller.addFields([field]);

    await tester.pumpWidget(
      host(
        form.FieldView(
          controller: controller,
          field: field,
          theme: FormTheme(
            colorScheme: normalScheme,
            errorColorScheme: errorScheme,
          ),
        ),
      ),
    );
    expect(seen.last.borderColor, Colors.teal);

    controller.validateField('email');
    await tester.pump();
    expect(seen.last.borderColor, Colors.purple);
  });

  testWidgets('a field theme is applied over the passed theme', (tester) async {
    final seen = <FieldColorScheme>[];
    final field = recordingField(
      'themed',
      seenColors: seen,
      theme: const FormTheme(
        colorScheme: FieldColorScheme(borderColor: Colors.orange),
      ),
    );
    controller.addFields([field]);

    await tester.pumpWidget(
      host(
        form.FieldView(
          controller: controller,
          field: field,
          theme: const FormTheme(
            colorScheme: FieldColorScheme(borderColor: Colors.teal),
          ),
        ),
      ),
    );
    expect(seen.last.borderColor, Colors.orange);
  });

  testWidgets('honors a passed theme and otherwise falls back to defaults', (
    tester,
  ) async {
    final seen = <FieldColorScheme>[];
    final field = recordingField('plain', seenColors: seen);
    controller.addFields([field]);

    await tester.pumpWidget(
      host(
        form.FieldView(
          controller: controller,
          field: field,
          theme: const FormTheme(
            colorScheme: FieldColorScheme(borderColor: Colors.indigo),
          ),
        ),
      ),
    );
    expect(seen.last.borderColor, Colors.indigo);

    seen.clear();
    await tester.pumpWidget(
      host(
        form.FieldView(
          key: const ValueKey('unthemed'),
          controller: controller,
          field: field,
        ),
      ),
    );
    // Defaults come from the Material color scheme, never null.
    expect(seen.last.borderColor, isNotNull);
    expect(seen.last.borderColor, isNot(Colors.indigo));
  });

  testWidgets('wiggles on a validation error', (tester) async {
    final field = recordingField('wiggle', validators: failing);
    controller.addFields([field]);

    await tester.pumpWidget(
      host(form.FieldView(controller: controller, field: field)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(FieldWiggleAnimator), findsOneWidget);

    double offsetX() => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(FieldWiggleAnimator),
            matching: find.byType(Transform),
          ),
        )
        .first
        .transform
        .getTranslation()
        .x;

    expect(offsetX(), 0);
    controller.validateField('wiggle');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(offsetX(), isNot(0));
    await tester.pumpAndSettle();
    expect(offsetX(), 0);
  });

  testWidgets('animateValidationErrors: false skips the wiggle', (
    tester,
  ) async {
    final field = recordingField(
      'still',
      validators: failing,
      animateValidationErrors: false,
    );
    controller.addFields([field]);

    await tester.pumpWidget(
      host(form.FieldView(controller: controller, field: field)),
    );
    expect(find.byType(FieldWiggleAnimator), findsNothing);
  });

  testWidgets('rebuilds on its own value change, not on other fields', (
    tester,
  ) async {
    final seen = <FieldColorScheme>[];
    final field = recordingField('mine', seenColors: seen);
    final other = form.TextField(id: 'other');
    controller.addFields([field, other]);
    controller.updateFieldValue<String>('mine', 'start');

    await tester.pumpWidget(
      host(form.FieldView(controller: controller, field: field)),
    );
    await tester.pumpAndSettle();
    final builds = seen.length;

    controller.updateFieldValue<String>('other', 'unrelated');
    await tester.pump();
    expect(seen.length, builds, reason: 'another field changed');

    controller.updateFieldValue<String>('mine', 'changed');
    await tester.pump();
    expect(seen.length, greaterThan(builds));
    expect(find.text('changed'), findsOneWidget);
  });

  testWidgets('renders a compound field and its sub-fields', (tester) async {
    final field = form.NameField(id: 'person', includeMiddleName: false);
    final toRegister = form.FieldView.fieldsToRegister(field);
    expect(toRegister.map((f) => f.id), [
      'person',
      'person_firstname',
      'person_lastname',
    ]);
    controller.addFields(toRegister);
    controller.updateFieldValue<String>('person_firstname', 'Ada');

    await tester.pumpWidget(
      host(form.FieldView(controller: controller, field: field)),
    );
    await tester.pump();

    expect(find.byType(form.FieldView), findsNWidgets(3));
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('a Form still renders every field through FieldView', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        form.Form(
          controller: controller,
          fields: [
            form.TextField(id: 'a'),
            form.TextField(id: 'b'),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(form.FieldView), findsNWidgets(2));
  });
}
