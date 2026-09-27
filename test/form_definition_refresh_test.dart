import 'package:championforms/championforms.dart' as form;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Form rebuilt with the same field ids but changed definitions must hand
/// the new definitions to the controller.
class _Host extends StatefulWidget {
  const _Host({required this.controller});
  final form.FormController controller;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  bool hidden = false;
  int builds = 0;

  void hide() => setState(() => hidden = true);

  @override
  Widget build(BuildContext context) {
    builds++;
    return MaterialApp(
      home: Scaffold(
        body: form.Form(
          controller: widget.controller,
          fields: [
            form.TextField(id: 'name'),
            form.TextField(id: 'secret', hideField: hidden),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('a hideField-only change reaches the controller', (tester) async {
    final controller = form.FormController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(controller: controller));
    await tester.pump();
    controller.updateFieldValue<String>('secret', 'shh');

    expect(
      form.FormResults.getResults(controller: controller).results,
      contains('secret'),
    );

    tester.state<_HostState>(find.byType(_Host)).hide();
    await tester.pump();

    expect(
      form.FormResults.getResults(controller: controller).results,
      isNot(contains('secret')),
    );
  });

  testWidgets('an unchanged rebuild does not loop', (tester) async {
    final controller = form.FormController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_Host(controller: controller));
    await tester.pumpAndSettle();
    final state = tester.state<_HostState>(find.byType(_Host));
    final before = state.builds;

    state.hide();
    await tester.pumpAndSettle();
    // One rebuild for the setState; nothing feeds back into more.
    expect(state.builds - before, 1);
  });
}
