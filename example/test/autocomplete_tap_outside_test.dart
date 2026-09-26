import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

import 'helpers/autocomplete_test_harness.dart';

// An outside tap dismisses the dropdown on every platform, including touch,
// where Flutter keeps a text field focused on an outside tap. The field stays
// focused (keyboard up) so typing brings the suggestions straight back.

AutoCompleteBuilder _fruit() => AutoCompleteBuilder(
  type: AutoCompleteType.dropdown,
  initialOptions: [
    CompleteOption(value: 'Apple', title: 'Apple'),
    CompleteOption(value: 'Apricot', title: 'Apricot'),
  ],
);

// Pinned to the bottom of the screen, clear of the dropdown.
final Widget _outsideArea = Expanded(
  child: Align(
    alignment: Alignment.bottomCenter,
    child: Container(key: const Key('outside'), height: 50, color: Colors.blue),
  ),
);

void main() {
  final touch = TargetPlatformVariant({
    TargetPlatform.android,
    TargetPlatform.iOS,
  });

  group('outside tap on touch platforms', () {
    testWidgets('an outside tap closes the dropdown but keeps focus', (
      tester,
    ) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: _fruit(),
        below: _outsideArea,
      );
      await h.type('ap');
      expect(find.text('Apricot'), findsOneWidget);

      await tester.tap(find.byKey(const Key('outside')));
      await tester.pump();

      expect(find.text('Apricot'), findsNothing);
      expect(h.focusNode.hasFocus, isTrue);
      expect(h.value, 'ap', reason: 'dismissing must not change the value');
    }, variant: touch);

    testWidgets('a tap inside the dropdown still selects', (tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: _fruit(),
        below: _outsideArea,
      );
      await h.type('ap');

      await tester.tap(find.text('Apricot'));
      await tester.pump();
      await tester.pump();

      expect(h.value, 'Apricot');
    }, variant: touch);

    testWidgets('typing after a dismissal reopens the suggestions', (
      tester,
    ) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: _fruit(),
        below: _outsideArea,
      );
      await h.type('ap');
      await tester.tap(find.byKey(const Key('outside')));
      await tester.pump();
      expect(find.text('Apricot'), findsNothing);

      await tester.enterText(h.textField, 'apr');
      await tester.pump();
      await tester.pump();

      expect(find.text('Apricot'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
    }, variant: touch);

    testWidgets('a tap on the field itself leaves the dropdown open', (
      tester,
    ) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: _fruit(),
        below: _outsideArea,
      );
      await h.type('ap');

      await tester.tap(h.textField);
      await tester.pump();

      expect(find.text('Apricot'), findsOneWidget);
    }, variant: touch);
  });
}
