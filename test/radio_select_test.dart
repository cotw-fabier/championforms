import 'package:championforms/championforms.dart' as cf;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  cf.FormController controller,
  List<cf.FormElement> fields,
) async {
  await tester.pumpWidget(
    MaterialApp(
      // The default Material 3 ink sparkle loads a fragment shader that the
      // test binding cannot decode; the splash is irrelevant to what is being
      // asserted here.
      theme: ThemeData(splashFactory: InkSplash.splashFactory),
      home: Scaffold(
        body: cf.Form(controller: controller, fields: fields),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    cf.FormFieldRegistry.ensureInitialized();
    cf.ValidatorRegistry.ensureInitialized();
  });

  test('multiselect is fixed to false', () {
    // A multi-select radio group is not a thing; leaving the parameter open
    // would allow a control whose appearance lies about its behaviour.
    final field = cf.RadioSelect(
      id: 'plan',
      options: [cf.FieldOption(value: 'a')],
    );
    expect(field.multiselect, isFalse);
    expect(field.copyWith(multiselect: true).multiselect, isFalse);
  });

  test('decodes from JSON under both "radioSelect" and "radio"', () {
    for (final name in const ['radioSelect', 'radio']) {
      final field = cf.FormFieldRegistry.fieldFromJson({
        'id': 'plan',
        'type': name,
        'title': 'Which plan?',
        'options': [
          'monthly',
          {'value': 'annual', 'label': 'Annual', 'hintText': 'Two months free'},
        ],
        'defaultValue': 'annual',
      });

      expect(field, isA<cf.RadioSelect>(), reason: 'type "$name"');
      final radio = field! as cf.RadioSelect;
      expect(radio.options, hasLength(2));
      expect(radio.defaultValue.single.value, 'annual');
      expect(radio.multiselect, isFalse);
    }
    expect(cf.FormFieldRegistry.nameForType(cf.RadioSelect), 'radioSelect');
  });

  testWidgets('renders real Radio controls, not checkboxes', (tester) async {
    // The entire point of this field. A single-select CheckboxSelect already
    // behaved correctly and looked wrong, and the look is the only signal a
    // person gets about what the control will let them do.
    final controller = cf.FormController();
    await _pump(tester, controller, [
      cf.RadioSelect(
        id: 'plan',
        title: 'Which plan?',
        options: [
          cf.FieldOption(value: 'monthly', label: 'Monthly'),
          cf.FieldOption(value: 'annual', label: 'Annual'),
        ],
      ),
    ]);

    expect(find.byType(RadioListTile<String>), findsNWidgets(2));
    expect(find.byType(CheckboxListTile), findsNothing);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Annual'), findsOneWidget);
  });

  testWidgets('selecting one option clears the other', (tester) async {
    final controller = cf.FormController();
    await _pump(tester, controller, [
      cf.RadioSelect(
        id: 'plan',
        options: [
          cf.FieldOption(value: 'monthly', label: 'Monthly'),
          cf.FieldOption(value: 'annual', label: 'Annual'),
        ],
      ),
    ]);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(
      controller.getFieldValue<List<cf.FieldOption>>('plan')!.single.value,
      'monthly',
    );

    await tester.tap(find.text('Annual'));
    await tester.pumpAndSettle();
    final selected = controller.getFieldValue<List<cf.FieldOption>>('plan')!;
    expect(selected, hasLength(1));
    expect(selected.single.value, 'annual');
  });

  testWidgets('tapping the selected option does not clear it', (tester) async {
    // Native radio groups behave this way, and a group that can be emptied by
    // accident is a required field that quietly becomes unanswered.
    final controller = cf.FormController();
    await _pump(tester, controller, [
      cf.RadioSelect(
        id: 'plan',
        options: [cf.FieldOption(value: 'monthly', label: 'Monthly')],
      ),
    ]);

    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    expect(
      controller.getFieldValue<List<cf.FieldOption>>('plan')!.single.value,
      'monthly',
    );
  });
}
