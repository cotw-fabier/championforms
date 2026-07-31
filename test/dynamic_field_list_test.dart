// A Form whose `fields:` list changes while it stays mounted.
//
// Registration used to happen only in the initState post-frame callback, so a
// field added to a live list was never registered at all and updateFieldValue
// on it threw. didUpdateWidget fixes that.
//
// Removal is deliberately NOT automatic. A wizard swaps one Form's fields:
// list per step and Flutter reuses the State, so "no longer in the list" is
// indistinguishable from "you are on a later page" — withdrawing would delete
// steps the person already filled in. Withdrawal is explicit
// (FormController.unregisterFields) or, idiomatically, unnecessary:
// `conditional` / `hideField` keep a field declared while excluding it from
// results and validation.

import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Drains the controller's deferred rebuild (a zero-delay Future scheduled
  /// on every notification) so it does not outlive the widget tree.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// A form whose field list is driven by the enclosing state, so the Form
  /// widget is updated in place rather than recreated.
  Widget hostWith(
    form.FormController controller,
    List<form.FormElement> Function() fields,
    void Function(VoidCallback) register,
  ) =>
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              register(() => setState(() {}));
              return form.Form(controller: controller, fields: fields());
            },
          ),
        ),
      );

  testWidgets('a field added to a live list gets registered', (tester) async {
    final controller = form.FormController();
    var showOptional = false;
    late VoidCallback rebuild;

    await tester.pumpWidget(hostWith(
      controller,
      () => [
        form.TextField(id: 'title', defaultValue: 'A project'),
        if (showOptional) form.TextField(id: 'optional'),
      ],
      (cb) => rebuild = cb,
    ));
    await tester.pumpAndSettle();
    expect(controller.registeredFieldIds, ['title']);

    showOptional = true;
    rebuild();
    await settle(tester);

    expect(controller.registeredFieldIds, contains('optional'));
    // Previously this threw ArgumentError: the field was never registered.
    controller.updateFieldValue('optional', 'now works');
    await tester.pumpAndSettle();
    expect(
      form.FormResults.getResults(controller: controller)
          .grab('optional')
          .asString(),
      'now works',
    );
  });

  testWidgets('a field removed from a live list stays registered',
      (tester) async {
    final controller = form.FormController();
    var showOptional = true;
    late VoidCallback rebuild;

    await tester.pumpWidget(hostWith(
      controller,
      () => [
        form.TextField(id: 'title', defaultValue: 'A project'),
        if (showOptional) form.TextField(id: 'optional', defaultValue: 'x'),
      ],
      (cb) => rebuild = cb,
    ));
    await tester.pumpAndSettle();
    expect(controller.registeredFieldIds, ['title', 'optional']);

    showOptional = false;
    rebuild();
    await settle(tester);

    // Not withdrawn: a widget dropping a field from its list is not a
    // statement that the field is gone. This is what keeps a wizard's earlier
    // steps alive when it swaps one Form's fields per step.
    expect(controller.registeredFieldIds, ['title', 'optional']);
    expect(
      form.FormResults.getResults(controller: controller)
          .grab('optional')
          .asString(),
      'x',
    );

    // Explicit withdrawal is there for when the app really means it.
    controller.unregisterFields(['optional']);
    expect(controller.registeredFieldIds, ['title']);
    expect(
      form.FormResults.getResults(controller: controller).hasField('optional'),
      isFalse,
    );
    await settle(tester);
  });

  testWidgets('an explicitly withdrawn field keeps its value, so re-declaring '
      'it restores the answer', (tester) async {
    final controller = form.FormController();
    var showOptional = true;
    late VoidCallback rebuild;

    await tester.pumpWidget(hostWith(
      controller,
      () => [
        form.TextField(id: 'title', defaultValue: 'A project'),
        if (showOptional) form.TextField(id: 'optional'),
      ],
      (cb) => rebuild = cb,
    ));
    await tester.pumpAndSettle();

    controller.updateFieldValue('optional', 'typed by hand');
    await tester.pumpAndSettle();

    showOptional = false;
    rebuild();
    await tester.pumpAndSettle();
    controller.unregisterFields(['optional']);
    await tester.pumpAndSettle();
    expect(controller.registeredFieldIds, isNot(contains('optional')));

    showOptional = true;
    rebuild();
    await settle(tester);

    expect(
      form.FormResults.getResults(controller: controller)
          .grab('optional')
          .asString(),
      'typed by hand',
      reason: 'withdrawing a field keeps its value by default',
    );
  });

  testWidgets("an explicitly withdrawn field's errors are cleared",
      (tester) async {
    final controller = form.FormController();
    var showOptional = true;
    late VoidCallback rebuild;

    await tester.pumpWidget(hostWith(
      controller,
      () => [
        form.TextField(id: 'title', defaultValue: 'A project'),
        if (showOptional)
          form.TextField(
            id: 'optional',
            validators: [
              form.Validator(
                validator: form.Validators.stringIsNotEmpty,
                reason: 'required while shown',
              ),
            ],
          ),
      ],
      (cb) => rebuild = cb,
    ));
    await settle(tester);

    expect(form.FormResults.getResults(controller: controller).errorState,
        isTrue);
    expect(controller.formErrors, isNotEmpty);

    showOptional = false;
    rebuild();
    controller.unregisterFields(['optional']);
    await settle(tester);

    expect(controller.formErrors, isEmpty,
        reason: 'a field nobody can see must not hold the form invalid');
    expect(form.FormResults.getResults(controller: controller).errorState,
        isFalse);
  });

  testWidgets('rebuilding with an unchanged list does no registry work',
      (tester) async {
    // Guards against didUpdateWidget and _rebuildOnControllerUpdate feeding
    // each other: a notification triggers setState, which runs
    // didUpdateWidget, which must not notify again.
    final controller = form.FormController();
    late VoidCallback rebuild;

    await tester.pumpWidget(hostWith(
      controller,
      () => [form.TextField(id: 'title', defaultValue: 'A project')],
      (cb) => rebuild = cb,
    ));
    await tester.pumpAndSettle();

    var notifications = 0;
    void count() => notifications++;
    controller.addListener(count);
    addTearDown(() => controller.removeListener(count));

    rebuild();
    await settle(tester);

    expect(notifications, 0);
    expect(controller.registeredFieldIds, ['title']);
  });
}
