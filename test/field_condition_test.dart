import 'package:championforms/championforms.dart' as form;
import 'package:championforms/models/field_condition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [fields] in a real `Form`, so visibility is exercised through the
/// widget tree rather than only through the model.
Future<void> _pump(
  WidgetTester tester,
  form.FormController controller,
  List<form.FormElement> fields,
) async {
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
}

void main() {
  group('ConditionRule.evaluate', () {
    test('equals compares loosely across the text/number divide', () {
      // The left side came from a text field (a String); the right side came
      // from a document (a number). A strict == would never fire.
      const rule = ConditionRule(
        fieldId: 'qty',
        operator: ConditionOperator.equals,
        value: 2,
      );
      expect(rule.evaluate({'qty': '2'}), isTrue);
      expect(rule.evaluate({'qty': 2}), isTrue);
      expect(rule.evaluate({'qty': 2.0}), isTrue);
      expect(rule.evaluate({'qty': '3'}), isFalse);
    });

    test('equals reaches through a single selection', () {
      const rule = ConditionRule(
        fieldId: 'role',
        operator: ConditionOperator.equals,
        value: 'team',
      );
      expect(
        rule.evaluate({
          'role': [form.FieldOption(value: 'team', label: 'A team')],
        }),
        isTrue,
      );
      expect(
        rule.evaluate({
          'role': [form.FieldOption(value: 'solo', label: 'On my own')],
        }),
        isFalse,
      );
    });

    test('contains is membership for a selection and substring for text', () {
      const rule = ConditionRule(
        fieldId: 'topics',
        operator: ConditionOperator.contains,
        value: 'weekly',
      );
      expect(
        rule.evaluate({
          'topics': [
            form.FieldOption(value: 'weekly'),
            form.FieldOption(value: 'monthly'),
          ],
        }),
        isTrue,
      );
      expect(rule.evaluate({'topics': 'the weekly letter'}), isTrue);
      expect(rule.evaluate({'topics': 'monthly only'}), isFalse);
    });

    test('gt and lt are numeric only, and false when either side is not', () {
      const gt = ConditionRule(
        fieldId: 'n',
        operator: ConditionOperator.gt,
        value: 5,
      );
      expect(gt.evaluate({'n': '6'}), isTrue);
      expect(gt.evaluate({'n': 5}), isFalse);
      expect(gt.evaluate({'n': 'six'}), isFalse);
      expect(gt.evaluate(const {}), isFalse);

      const lt = ConditionRule(
        fieldId: 'n',
        operator: ConditionOperator.lt,
        value: 5,
      );
      expect(lt.evaluate({'n': 4.9}), isTrue);
    });

    test('isEmpty covers null, blank text, empty lists and false', () {
      const rule =
          ConditionRule(fieldId: 'x', operator: ConditionOperator.isEmpty);
      expect(rule.evaluate(const {}), isTrue);
      expect(rule.evaluate({'x': null}), isTrue);
      expect(rule.evaluate({'x': '  '}), isTrue);
      expect(rule.evaluate({'x': const <String>[]}), isTrue);
      expect(rule.evaluate({'x': false}), isTrue);
      expect(rule.evaluate({'x': 'a'}), isFalse);
      expect(rule.evaluate({'x': 0}), isFalse);
    });

    test('startsWith and endsWith', () {
      expect(
        const ConditionRule(
          fieldId: 'e',
          operator: ConditionOperator.startsWith,
          value: 'ad',
        ).evaluate({'e': 'admin@example.com'}),
        isTrue,
      );
      expect(
        const ConditionRule(
          fieldId: 'e',
          operator: ConditionOperator.endsWith,
          value: '.edu',
        ).evaluate({'e': 'a@b.edu'}),
        isTrue,
      );
    });

    test('a rule naming a deleted field evaluates against null', () {
      // A form has to keep working while its author is halfway through an
      // edit, so this must not throw.
      const rule = ConditionRule(
        fieldId: 'gone',
        operator: ConditionOperator.equals,
        value: 'x',
      );
      expect(rule.evaluate(const {}), isFalse);
    });
  });

  group('FieldCondition', () {
    const showsWhenTeam = FieldCondition(rules: [
      ConditionRule(
        fieldId: 'role',
        operator: ConditionOperator.equals,
        value: 'team',
      ),
    ]);

    test('show and hide are inverses', () {
      expect(showsWhenTeam.isVisible({'role': 'team'}), isTrue);
      expect(showsWhenTeam.isVisible({'role': 'solo'}), isFalse);

      const hides = FieldCondition(
        action: ConditionAction.hide,
        rules: [
          ConditionRule(
            fieldId: 'role',
            operator: ConditionOperator.equals,
            value: 'team',
          ),
        ],
      );
      expect(hides.isVisible({'role': 'team'}), isFalse);
      expect(hides.isVisible({'role': 'solo'}), isTrue);
    });

    test('all vs any', () {
      const rules = [
        ConditionRule(
          fieldId: 'a',
          operator: ConditionOperator.equals,
          value: '1',
        ),
        ConditionRule(
          fieldId: 'b',
          operator: ConditionOperator.equals,
          value: '2',
        ),
      ];
      const all = FieldCondition(rules: rules);
      const any = FieldCondition(match: ConditionMatch.any, rules: rules);

      expect(all.isVisible({'a': '1', 'b': '2'}), isTrue);
      expect(all.isVisible({'a': '1'}), isFalse);
      expect(any.isVisible({'a': '1'}), isTrue);
      expect(any.isVisible(const {}), isFalse);
    });

    test('an empty rule list is inert, not hiding', () {
      // A half-written condition in a builder must show its field, or the
      // author loses the field with no way to get it back.
      expect(const FieldCondition(rules: []).isVisible(const {}), isTrue);
    });

    test('round-trips through JSON', () {
      final json = showsWhenTeam.toJson();
      expect(json, {
        'match': 'all',
        'action': 'show',
        'rules': [
          {'fieldId': 'role', 'operator': 'equals', 'value': 'team'},
        ],
      });
      final decoded = FieldCondition.fromJson(json);
      expect(decoded.isVisible({'role': 'team'}), isTrue);
      expect(decoded.isVisible({'role': 'solo'}), isFalse);
    });

    test('an unknown operator throws rather than silently never matching', () {
      expect(
        () => FieldCondition.fromJson({
          'rules': [
            {'fieldId': 'a', 'operator': 'equalz', 'value': 1},
          ],
        }),
        throwsFormatException,
      );
    });

    test('dependencies names every field a condition reads', () {
      expect(showsWhenTeam.dependencies, {'role'});
    });
  });

  group('FormController integration', () {
    test('isFieldHidden unions hideField and conditional', () {
      final controller = form.FormController();
      final conditional = form.TextField(
        id: 'team_size',
        conditional: const FieldCondition(rules: [
          ConditionRule(
            fieldId: 'role',
            operator: ConditionOperator.equals,
            value: 'team',
          ),
        ]),
      );
      final statically = form.TextField(id: 'secret', hideField: true);
      final plain = form.TextField(id: 'name');
      // The controlling field has to exist before its value can be set — the
      // controller refuses an id it has never been given a definition for.
      final role = form.TextField(id: 'role');

      controller.addFields([role, conditional, statically, plain],
          noNotify: true);

      expect(controller.isFieldHidden(plain), isFalse);
      expect(controller.isFieldHidden(statically), isTrue);
      expect(controller.isFieldHidden(conditional), isTrue,
          reason: 'role is unset, so the show-condition is unsatisfied');

      controller.updateFieldValue('role', 'team', noNotify: true);
      expect(controller.isFieldHidden(conditional), isFalse);

      controller.updateFieldValue('role', 'solo', noNotify: true);
      expect(controller.isFieldHidden(conditional), isTrue);
    });

    test('isFieldIdHidden returns false for an id it has never seen', () {
      expect(form.FormController().isFieldIdHidden('nope'), isFalse);
    });
  });

  group('rendering and validation', () {
    testWidgets('a conditional field appears and disappears as values change',
        (tester) async {
      final controller = form.FormController();
      final fields = <form.FormElement>[
        form.TextField(id: 'role', title: 'Are you a team?'),
        form.TextField(
          id: 'team_size',
          title: 'How many people?',
          conditional: const FieldCondition(rules: [
            ConditionRule(
              fieldId: 'role',
              operator: ConditionOperator.equals,
              value: 'team',
            ),
          ]),
        ),
      ];

      await _pump(tester, controller, fields);
      expect(find.text('How many people?'), findsNothing);

      controller.updateFieldValue('role', 'team');
      await tester.pumpAndSettle();
      expect(find.text('How many people?'), findsOneWidget);

      controller.updateFieldValue('role', 'solo');
      await tester.pumpAndSettle();
      expect(find.text('How many people?'), findsNothing);
    });

    testWidgets('a hidden required field does not block validation',
        (tester) async {
      final controller = form.FormController();
      final fields = <form.FormElement>[
        form.TextField(id: 'role'),
        form.TextField(
          id: 'team_size',
          validators: [
            form.Validator(
              validator: form.Validators.stringIsNotEmpty,
              reason: 'is required',
            ),
          ],
          conditional: const FieldCondition(rules: [
            ConditionRule(
              fieldId: 'role',
              operator: ConditionOperator.equals,
              value: 'team',
            ),
          ]),
        ),
      ];

      await _pump(tester, controller, fields);

      // Hidden: the empty required field must not fail the form, because the
      // person was never shown it.
      expect(form.FormResults.getResults(controller: controller).errorState,
          isFalse);

      controller.updateFieldValue('role', 'team');
      await tester.pumpAndSettle();

      // Visible now, and empty: it must fail.
      expect(form.FormResults.getResults(controller: controller).errorState,
          isTrue);

      controller.updateFieldValue('team_size', '4');
      await tester.pumpAndSettle();
      expect(form.FormResults.getResults(controller: controller).errorState,
          isFalse);

      // `getResults` clears and re-adds errors, which notifies, which schedules
      // the builder's deferred rebuild. Drain it before the tree is torn down.
      await tester.pumpAndSettle();
    });

    testWidgets('a hidden field is absent from the collected results',
        (tester) async {
      final controller = form.FormController();
      await _pump(tester, controller, <form.FormElement>[
        form.TextField(id: 'role'),
        form.TextField(
          id: 'team_size',
          defaultValue: '9',
          conditional: const FieldCondition(rules: [
            ConditionRule(
              fieldId: 'role',
              operator: ConditionOperator.equals,
              value: 'team',
            ),
          ]),
        ),
      ]);

      final results = form.FormResults.getResults(controller: controller);
      // A person who never saw the question must not have an answer stored
      // for it, even a defaulted one.
      expect(results.results.keys, isNot(contains('team_size')));
      expect(results.results.keys, contains('role'));
    });
  });
}
