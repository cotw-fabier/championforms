// Multi-page forms: pageName registration, page-scoped results, and the
// duplicate accumulation that used to corrupt both.
//
// Page scoping used to come for free from activeFields being render-scoped —
// only the mounted step's fields were in it. That was an accident of widget
// lifecycle, not a contract, and it broke any form that scrolled. Scoping is
// now something you ask for.

import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// A one-step-at-a-time wizard: only the current page's Form is mounted.
  Widget wizard(
    form.FormController controller,
    int Function() step,
    void Function(VoidCallback) register,
  ) =>
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              register(() => setState(() {}));
              final current = step();
              return form.Form(
                controller: controller,
                pageName: 'step-$current',
                fields: [
                  form.TextField(
                    id: 'field-$current',
                    defaultValue: 'value $current',
                  ),
                ],
              );
            },
          ),
        ),
      );

  testWidgets('pageName: scopes results, including for an unmounted page',
      (tester) async {
    final controller = form.FormController();
    var step = 1;
    late VoidCallback rebuild;

    await tester.pumpWidget(wizard(controller, () => step, (cb) => rebuild = cb));
    await settle(tester);

    step = 2;
    rebuild();
    await settle(tester);

    // Step 1's form is long gone from the tree.
    expect(controller.activeFields.map((f) => f.id), ['field-2']);

    final page1 = form.FormResults.getResults(
      controller: controller,
      pageName: 'step-1',
    );
    expect(page1.results.keys, ['field-1']);
    expect(page1.grab('field-1').asString(), 'value 1');
  });

  testWidgets('the unscoped call returns every step, which is what the docs '
      'have always promised', (tester) async {
    final controller = form.FormController();
    var step = 1;
    late VoidCallback rebuild;

    await tester.pumpWidget(wizard(controller, () => step, (cb) => rebuild = cb));
    await settle(tester);
    for (step = 2; step <= 3; step++) {
      rebuild();
      await settle(tester);
    }

    final all = form.FormResults.getResults(controller: controller);
    expect(all.results.keys, ['field-1', 'field-2', 'field-3']);
  });

  testWidgets('remounting a page does not duplicate its fields',
      (tester) async {
    // updatePageFields appended without dedupe and was called twice per mount,
    // so a page's list grew every visit and each duplicate got validated again
    // — one failure reported as several.
    final controller = form.FormController();
    var step = 1;
    late VoidCallback rebuild;

    await tester.pumpWidget(wizard(controller, () => step, (cb) => rebuild = cb));
    await settle(tester);

    for (final next in [2, 1, 2, 1]) {
      step = next;
      rebuild();
      await settle(tester);
    }

    final ids = controller.getPageFields('step-1').map((f) => f.id).toList();
    expect(ids, ['field-1'], reason: 'one visit or five, the page is the same');
    expect(controller.registeredFieldIds, ['field-1', 'field-2']);
  });

  testWidgets('a page reports each validation failure once', (tester) async {
    final controller = form.FormController();

    Widget app() => MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              pageName: 'step-1',
              fields: [
                form.TextField(
                  id: 'required',
                  validators: [
                    form.Validator(
                      validator: form.Validators.stringIsNotEmpty,
                      reason: 'is required',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );

    // Mount, unmount, mount again — the old code doubled the page list here.
    await tester.pumpWidget(app());
    await settle(tester);
    await tester.pumpWidget(const SizedBox());
    await settle(tester);
    await tester.pumpWidget(app());
    await settle(tester);

    final results = form.FormResults.getResults(
      controller: controller,
      pageName: 'step-1',
    );
    expect(results.formErrors.length, 1);
    await settle(tester);
  });

  testWidgets('"default" is an ordinary page name', (tester) async {
    // The two registration call sites used to disagree about "default": one
    // special-cased it, the other did not.
    final controller = form.FormController();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: form.Form(
          controller: controller,
          pageName: 'default',
          fields: [form.TextField(id: 'title', defaultValue: 'A')],
        ),
      ),
    ));
    await settle(tester);

    expect(controller.getPageFields('default').map((f) => f.id), ['title']);
    expect(
      form.FormResults.getResults(controller: controller, pageName: 'default')
          .grab('title')
          .asString(),
      'A',
    );
  });

  test('getPageFields never returns a withdrawn field', () {
    final controller = form.FormController();
    addTearDown(controller.dispose);

    final fields = [
      form.TextField(id: 'a'),
      form.TextField(id: 'b'),
    ];
    controller.addFields(fields);
    controller.updatePageFields('step-1', fields);
    expect(controller.getPageFields('step-1').map((f) => f.id), ['a', 'b']);

    controller.unregisterFields(['a']);
    expect(controller.getPageFields('step-1').map((f) => f.id), ['b']);

    controller.removeField('b');
    expect(controller.getPageFields('step-1'), isEmpty);
  });

  test('getPageFields resolves through the registry, not the stored copy', () {
    final controller = form.FormController();
    addTearDown(controller.dispose);

    final stale = form.TextField(id: 'a', defaultValue: 'old');
    controller.addFields([stale]);
    controller.updatePageFields('step-1', [stale]);

    controller.updateField(form.TextField(id: 'a', defaultValue: 'new'));

    expect(controller.getPageFields('step-1').single.defaultValue, 'new');
  });

  test('passing both fields: and pageName: is caught', () {
    final controller = form.FormController();
    addTearDown(controller.dispose);

    expect(
      () => form.FormResults.getResults(
        controller: controller,
        fields: const [],
        pageName: 'step-1',
      ),
      throwsAssertionError,
    );
  });
}
