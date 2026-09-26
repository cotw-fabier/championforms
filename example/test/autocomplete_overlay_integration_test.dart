import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

import 'helpers/autocomplete_test_harness.dart';

// AutocompleteWrapper listens to the FormController, not to the
// TextEditingController, so these tests run it inside a real Form TextField
// (see helpers/autocomplete_test_harness.dart). A bare Material TextField is
// not wired to the controller and never opens the overlay.

void main() {
  group('AutocompleteWrapper Integration Tests', () {
    testWidgets('Overlay dismisses on tap outside',
        (WidgetTester tester) async {
      await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Test Option', title: 'Test Option'),
          ],
        ),
        // Pinned to the bottom of the screen, clear of the dropdown (which
        // opens below the field and is up to 300px tall).
        below: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              key: const Key('outside-area'),
              height: 50,
              color: Colors.blue,
              child: const Text('Click here'),
            ),
          ),
        ),
      ).then((h) => h.type('test'));

      expect(find.text('Test Option'), findsOneWidget);

      // A mouse click outside closes the dropdown (and, on desktop/web,
      // EditableText also unfocuses the field). Touch taps are covered in
      // autocomplete_tap_outside_test.dart.
      await tester.tap(
        find.byKey(const Key('outside-area')),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // The field holds "test"; "Test Option" only ever lived in the overlay.
      expect(find.text('Test Option'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Overlay updates when value changes',
        (WidgetTester tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Apple', title: 'Apple'),
            CompleteOption(value: 'Banana', title: 'Banana'),
            CompleteOption(value: 'Cherry', title: 'Cherry'),
          ],
        ),
      );

      await h.type('a');
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      await tester.enterText(h.textField, 'c');
      await tester.pump();
      await tester.pump();

      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Banana'), findsNothing);
    });

    testWidgets('Theming with custom FieldColorScheme',
        (WidgetTester tester) async {
      const colorScheme = FieldColorScheme(
        surfaceBackground: Color(0xFFE1BEE7), // purple[100]
        surfaceText: Color(0xFF4A148C), // purple[900]
      );

      // The overlay is only open while the field is focused, so it renders
      // with the field's active color scheme.
      await AutocompleteFormHarness.pump(
        tester,
        theme: const FormTheme(
          colorScheme: colorScheme,
          activeColorScheme: colorScheme,
        ),
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Themed Option', title: 'Themed Option'),
          ],
        ),
      ).then((h) => h.type('themed'));

      expect(find.text('Themed Option'), findsOneWidget);

      // The overlay surface is the Material with elevation 4 around the list.
      final overlayMaterial = tester
          .widgetList<Material>(
            find.ancestor(
              of: find.text('Themed Option'),
              matching: find.byType(Material),
            ),
          )
          .firstWhere((m) => m.elevation == 4.0);
      expect(overlayMaterial.color, equals(const Color(0xFFE1BEE7)));
    });

    testWidgets('Overlay handles rapid text changes with debounce',
        (WidgetTester tester) async {
      var updateCallCount = 0;

      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [],
          debounceWait: const Duration(milliseconds: 50),
          debounceDuration: const Duration(milliseconds: 100),
          updateOptions: (value) async {
            updateCallCount++;
            await Future.delayed(const Duration(milliseconds: 10));
            return [
              CompleteOption(
                value: 'Result for: $value',
                title: 'Result for: $value',
              ),
            ];
          },
        ),
      );

      // Type rapidly: each keystroke lands inside the previous debounce window.
      await tester.tap(h.textField);
      await tester.pump();
      await tester.enterText(h.textField, 'a');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(h.textField, 'ab');
      await tester.pump(const Duration(milliseconds: 10));
      await tester.enterText(h.textField, 'abc');
      await tester.pump();

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      // Collapsed into a single lookup for the final text.
      expect(updateCallCount, equals(1));
      expect(find.text('Result for: abc'), findsOneWidget);
    });

    testWidgets('Overlay shows only dropdown type autocomplete',
        (WidgetTester tester) async {
      await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.none, // Non-dropdown type
          initialOptions: [
            CompleteOption(value: 'Should Not Show', title: 'Should Not Show'),
          ],
        ),
      ).then((h) => h.type('Should'));

      expect(find.text('Should Not Show'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Empty text clears overlay options',
        (WidgetTester tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Test', title: 'Test'),
          ],
        ),
      );

      await h.type('test');
      expect(find.text('Test'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      await tester.enterText(h.textField, '');
      await tester.pump();
      await tester.pump();

      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('Accessibility: Semantics widgets are present',
        (WidgetTester tester) async {
      await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Option 1', title: 'Option 1'),
            CompleteOption(value: 'Option 2', title: 'Option 2'),
          ],
        ),
      ).then((h) => h.type('opt'));

      expect(find.bySemanticsLabel('2 options available'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Option 2, option 2 of 2'),
        findsOneWidget,
      );
    });

    testWidgets('CompositedTransformFollower maintains overlay connection',
        (WidgetTester tester) async {
      await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Test', title: 'Test'),
          ],
        ),
      ).then((h) => h.type('test'));

      expect(
        find.ancestor(
          of: find.text('Test'),
          matching: find.byType(CompositedTransformFollower),
        ),
        findsOneWidget,
      );
      expect(find.byType(CompositedTransformTarget), findsWidgets);
    });
  });
}
