// What field set does getResults collect, and when?
//
// The bug these guard: getResults used to default to controller.activeFields,
// which is render-scoped — a Form inside a ListView drops out of it the moment
// the list culls the element. A person's answer would silently become "" while
// controller.getFieldValue() still returned it. Membership is now a function of
// what the app declared, never of what Flutter kept mounted.

import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A form as the first child of a lazy list, with enough filler after it
  /// that scrolling to the bottom culls it. `cacheExtent: 0` removes the
  /// off-screen keep-warm window so the teardown is deterministic.
  Widget lazyListWith(form.Form formWidget) => MaterialApp(
        home: Scaffold(
          body: ListView.builder(
            cacheExtent: 0.0,
            itemCount: 20,
            itemBuilder: (context, i) =>
                i == 0 ? formWidget : const SizedBox(height: 400),
          ),
        ),
      );

  Future<void> scrollToBottom(WidgetTester tester) async {
    // byType(ListView), not byType(Scrollable) — every text field carries its
    // own internal Scrollable.
    await tester.drag(find.byType(ListView), const Offset(0, -6000));
    await tester.pumpAndSettle();
  }

  group('a form culled by a lazy list', () {
    testWidgets('still reports a value seeded from defaultValue that was '
        'never focused', (tester) async {
      final controller = form.FormController();
      await tester.pumpWidget(lazyListWith(form.Form(
        controller: controller,
        fields: [
          form.TextField(id: 'title', defaultValue: 'Seeded Project'),
        ],
      )));
      await tester.pumpAndSettle();

      await scrollToBottom(tester);

      // Precondition. Without this the test is vacuous — it would pass against
      // the buggy build simply because the form never got culled.
      expect(controller.activeFields, isEmpty,
          reason: 'the form should have been disposed by the lazy list');
      expect(controller.registeredFieldIds, contains('title'));

      final results = form.FormResults.getResults(controller: controller);
      expect(results.hasField('title'), isTrue);
      expect(results.grab('title').asString(), 'Seeded Project');

      await tester.pumpAndSettle();
    });

    testWidgets('still reports a typed value after focus moves away',
        (tester) async {
      // The case that actually regressed downstream. EditableText pins itself
      // alive while focused, so the loss only showed once focus left — which
      // made the bug look intermittent.
      final controller = form.FormController();
      final elsewhere = FocusNode();
      addTearDown(elsewhere.dispose);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SizedBox(height: 40, child: TextField(focusNode: elsewhere)),
              Expanded(
                child: ListView.builder(
                  cacheExtent: 0.0,
                  itemCount: 20,
                  itemBuilder: (context, i) => i == 0
                      ? form.Form(
                          controller: controller,
                          fields: [form.TextField(id: 'title')],
                        )
                      : const SizedBox(height: 400),
                ),
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(EditableText).at(1), 'Typed Project');
      await tester.pumpAndSettle();

      elsewhere.requestFocus();
      await tester.pumpAndSettle();

      await scrollToBottom(tester);

      expect(controller.activeFields, isEmpty);
      expect(
        form.FormResults.getResults(controller: controller)
            .grab('title')
            .asString(),
        'Typed Project',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('is still validated by validateForm', (tester) async {
      // validateForm iterated activeFields too, so a culled form validated
      // nothing and returned true — a submit guard sailing through unchecked.
      final controller = form.FormController();
      await tester.pumpWidget(lazyListWith(form.Form(
        controller: controller,
        fields: [
          form.TextField(
            id: 'title',
            validators: [
              form.Validator(
                validator: form.Validators.stringIsNotEmpty,
                reason: 'Title is required',
              ),
            ],
          ),
        ],
      )));
      await tester.pumpAndSettle();

      await scrollToBottom(tester);
      expect(controller.activeFields, isEmpty);

      expect(controller.validateForm(), isFalse,
          reason: 'an empty required field must fail even when culled');

      await tester.pumpAndSettle();
    });

    testWidgets('leaves activeFields empty while registeredFields survives',
        (tester) async {
      // Pins both meanings: activeFields is still "what is painted right now".
      final controller = form.FormController();
      await tester.pumpWidget(lazyListWith(form.Form(
        controller: controller,
        fields: [
          form.TextField(id: 'a'),
          form.TextField(id: 'b'),
        ],
      )));
      await tester.pumpAndSettle();
      expect(controller.activeFields.map((f) => f.id), ['a', 'b']);

      await scrollToBottom(tester);

      expect(controller.activeFields, isEmpty);
      expect(controller.registeredFieldIds, ['a', 'b']);

      await tester.pumpAndSettle();
    });
  });

  group('scope and filtering', () {
    testWidgets('results follow declaration order', (tester) async {
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(id: 'first'),
              form.TextField(id: 'second'),
              form.TextField(id: 'third'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(controller.registeredFieldIds, ['first', 'second', 'third']);
      expect(
        form.FormResults.getResults(controller: controller)
            .fieldDefinitions
            .keys,
        ['first', 'second', 'third'],
      );
    });

    testWidgets('a hideField field is excluded from results but stays '
        'registered', (tester) async {
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(id: 'shown', defaultValue: 'yes'),
              form.TextField(id: 'hidden', defaultValue: 'no', hideField: true),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final results = form.FormResults.getResults(controller: controller);
      expect(results.results.keys, ['shown']);
      expect(results.fieldDefinitions.keys, ['shown']);
      expect(results.hasField('hidden'), isFalse);
      // Still part of the schema — hidden is about the question being asked,
      // not about the field existing.
      expect(controller.registeredFieldIds, contains('hidden'));
    });

    testWidgets('a disabled field IS collected but is not validated',
        (tester) async {
      // Locks the decision: disabled means "shown but locked", not HTML's
      // "not submitted". A server-populated value must round-trip.
      var validatorRan = false;
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(
                id: 'locked',
                defaultValue: 'from-the-server',
                disabled: true,
                validators: [
                  form.Validator(
                    validator: (dynamic value) {
                      validatorRan = true;
                      return false;
                    },
                    reason: 'never reported',
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final results = form.FormResults.getResults(controller: controller);
      expect(results.grab('locked').asString(), 'from-the-server');
      expect(validatorRan, isFalse);
      expect(results.errorState, isFalse);
    });

    testWidgets('an explicit fields: list still narrows the scope',
        (tester) async {
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(id: 'a', defaultValue: 'A'),
              form.TextField(id: 'b', defaultValue: 'B'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final results = form.FormResults.getResults(
        controller: controller,
        fields: [controller.registeredFields.first],
      );
      expect(results.results.keys, ['a']);
    });

    test('an unregistered field definition does not throw', () {
      // getFieldValue throws ArgumentError for an unknown id; getResults must
      // absorb that rather than blow up the whole call.
      final controller = form.FormController();
      addTearDown(controller.dispose);

      final results = form.FormResults.getResults(
        controller: controller,
        fields: [form.TextField(id: 'never-declared', defaultValue: 'fallback')],
      );
      expect(results.grab('never-declared').asString(), 'fallback');
    });

    test('grabOrNull distinguishes absent from empty', () {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      controller.addFields([form.TextField(id: 'present')]);

      final results = form.FormResults.getResults(controller: controller);
      expect(results.grabOrNull('present'), isNotNull);
      expect(results.grabOrNull('absent'), isNull);
      // grab still fails soft.
      expect(results.grab('absent').asString(), '');
    });
  });

  group('checkForErrors', () {
    testWidgets('false runs no validator and mutates no controller state',
        (tester) async {
      var validatorRan = false;
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(
                id: 'title',
                validators: [
                  form.Validator(
                    validator: (dynamic value) {
                      validatorRan = true;
                      return false;
                    },
                    reason: 'always fails',
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      expect(validatorRan, isFalse);
      expect(controller.formErrors, isEmpty);
      expect(results.errorState, isFalse);
      expect(results.hasField('title'), isTrue);
    });

    testWidgets('getResultsReadOnly is equivalent, and its errorState is '
        'scoped to the fields it collected', (tester) async {
      final controller = form.FormController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: form.Form(
            controller: controller,
            fields: [
              form.TextField(
                id: 'bad',
                validators: [
                  form.Validator(
                    validator: (dynamic value) => false,
                    reason: 'always fails',
                  ),
                ],
              ),
              form.TextField(id: 'good', defaultValue: 'fine'),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Put a real error on the controller.
      expect(form.FormResults.getResults(controller: controller).errorState,
          isTrue);

      // A read scoped to the healthy field must not inherit the other's error.
      final scoped = form.FormResults.getResultsReadOnly(
        controller: controller,
        fields: [controller.registeredFields.last],
      );
      expect(scoped.results.keys, ['good']);
      expect(scoped.errorState, isFalse);

      await tester.pumpAndSettle();
    });
  });
}
