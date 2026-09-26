import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

import 'helpers/autocomplete_test_harness.dart';

// AutocompleteWrapper listens to the FormController, not to the
// TextEditingController, so these tests type through the library's own
// TextField (see helpers/autocomplete_test_harness.dart). A bare Material
// TextField is not wired to the controller and never opens the overlay.

AutoCompleteBuilder _options(int count) => AutoCompleteBuilder(
      type: AutoCompleteType.dropdown,
      initialOptions: [
        for (var i = 1; i <= count; i++)
          CompleteOption(value: 'Option $i', title: 'Option $i'),
      ],
    );

/// Whether the overlay option titled [title] holds primary focus.
bool _optionHasFocus(String title) {
  return find
      .ancestor(of: find.text(title), matching: find.byType(Focus))
      .evaluate()
      .any((e) => (e.widget as Focus).focusNode?.hasPrimaryFocus ?? false);
}

Future<AutocompleteFormHarness> _openOverlay(
  WidgetTester tester,
  int optionCount,
) async {
  final h = await AutocompleteFormHarness.pump(
    tester,
    autoComplete: _options(optionCount),
  );
  await h.type('Opt');
  await tester.pumpAndSettle();
  expect(find.text('Option 1'), findsOneWidget);
  return h;
}

void main() {
  group('AutocompleteWrapper Keyboard and Accessibility Tests', () {
    testWidgets('Tab key moves focus to first option',
        (WidgetTester tester) async {
      final h = await _openOverlay(tester, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_optionHasFocus('Option 1'), isTrue);
      expect(h.focusNode.hasPrimaryFocus, isFalse);
    });

    testWidgets('Arrow Down navigates to next option',
        (WidgetTester tester) async {
      await _openOverlay(tester, 3);

      // Field -> first option
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_optionHasFocus('Option 1'), isTrue);

      // First -> second option
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_optionHasFocus('Option 2'), isTrue);
      expect(_optionHasFocus('Option 1'), isFalse);
    });

    testWidgets('Arrow Up navigates to previous option',
        (WidgetTester tester) async {
      await _openOverlay(tester, 3);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_optionHasFocus('Option 2'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_optionHasFocus('Option 1'), isTrue);
    });

    testWidgets('Enter key selects focused option',
        (WidgetTester tester) async {
      final h = await _openOverlay(tester, 2);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_optionHasFocus('Option 2'), isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(h.value, equals('Option 2'));
      expect(h.textController.text, equals('Option 2'));
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Escape key dismisses overlay', (WidgetTester tester) async {
      final h = await _openOverlay(tester, 1);
      expect(find.byType(ListView), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsNothing);
      // Dismissing does not change the typed text or drop focus.
      expect(h.textController.text, equals('Opt'));
      expect(h.focusNode.hasFocus, isTrue);
    });

    testWidgets('Semantics widget is present for accessibility',
        (WidgetTester tester) async {
      await _openOverlay(tester, 3);

      expect(find.bySemanticsLabel('3 options available'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Option 1, option 1 of 3'),
        findsOneWidget,
      );
    });

    testWidgets('FocusTraversalGroup ensures logical navigation order',
        (WidgetTester tester) async {
      await _openOverlay(tester, 3);

      expect(
        find.ancestor(
          of: find.text('Option 1'),
          matching: find.byType(FocusTraversalGroup),
        ),
        findsWidgets,
      );
    });
  });
}
