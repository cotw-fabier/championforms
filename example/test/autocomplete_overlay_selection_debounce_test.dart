import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

import 'package:championforms/championforms.dart' as form;
import '../../test/test_helpers.dart';
import 'helpers/autocomplete_test_harness.dart';

// AutocompleteWrapper listens to the FormController, not to the
// TextEditingController, so these tests type through a host that syncs the
// two (see helpers/autocomplete_test_harness.dart). Assigning
// `textController.text` directly bypasses the controller and never opens the
// overlay.

void main() {
  group('AutocompleteWrapper Selection and Debounce Tests', () {
    testWidgets('Default selection callback updates TextEditingController',
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

      final firstOption = find.text('Apple');
      expect(firstOption, findsOneWidget);
      await tester.tap(firstOption);
      await tester.pumpAndSettle();

      // The selection reaches the controller and the visible text.
      expect(h.value, equals('Apple'));
      expect(h.textController.text, equals('Apple'));
    });

    testWidgets('Custom onOptionSelected callback overrides default behavior',
        (WidgetTester tester) async {
      final controller = form.FormController();
      addTearDown(controller.dispose);
      CompleteOption? selectedOption;

      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          CompleteOption(value: 'Apple', title: 'Apple'),
          CompleteOption(value: 'Banana', title: 'Banana'),
        ],
      );

      final field = form.TextField(id: 'test', autoComplete: autoComplete);
      controller.addFields([field]);
      final ctx = createTestContext(controller: controller, field: field);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: wiredAutocompleteWrapper(
              ctx: ctx,
              autoComplete: autoComplete,
              onOptionSelected: (option) {
                selectedOption = option;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'a');
      await tester.pump();
      await tester.pump();

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Custom callback is called...
      expect(selectedOption, isNotNull);
      expect(selectedOption!.value, equals('Apple'));

      // ...and replaces the default write-back.
      expect(controller.getFieldValue<String>('test'), equals('a'));
      expect(ctx.getTextController().text, equals('a'));
    });

    testWidgets('Overlay dismisses after selection',
        (WidgetTester tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Apple', title: 'Apple'),
            CompleteOption(value: 'Banana', title: 'Banana'),
          ],
        ),
      );

      await h.type('a');

      // Overlay is shown
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Only the TextField's own "Apple" remains; the overlay list is gone.
      expect(find.byType(ListView), findsNothing);
      expect(find.text('Banana'), findsNothing);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('Option callback is invoked when provided',
        (WidgetTester tester) async {
      var callbackInvoked = false;

      await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(
              value: 'Apple',
              title: 'Apple',
              callback: (option) {
                callbackInvoked = true;
              },
            ),
          ],
        ),
      ).then((h) => h.type('a'));

      await tester.tap(find.text('Apple').last);
      await tester.pumpAndSettle();

      expect(callbackInvoked, isTrue);
    });

    testWidgets('Focus returns to field after selection',
        (WidgetTester tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Apple', title: 'Apple'),
          ],
        ),
      );

      await h.type('a');

      await tester.tap(find.text('Apple').last);
      await tester.pumpAndSettle();

      expect(h.focusNode.hasFocus, isTrue);
    });

    testWidgets('Cursor positioned at end after selection',
        (WidgetTester tester) async {
      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [
            CompleteOption(value: 'Apple Fruit', title: 'Apple Fruit'),
          ],
        ),
      );

      await h.type('a');

      await tester.tap(find.text('Apple Fruit'));
      await tester.pumpAndSettle();

      expect(h.textController.text, equals('Apple Fruit'));
      expect(h.textController.selection.baseOffset,
          equals(h.textController.text.length));
      expect(h.textController.selection.extentOffset,
          equals(h.textController.text.length));
    });

    testWidgets('Debounce timing works with updateOptions callback',
        (WidgetTester tester) async {
      var updateOptionsCallCount = 0;

      final h = await AutocompleteFormHarness.pump(
        tester,
        autoComplete: AutoCompleteBuilder(
          type: AutoCompleteType.dropdown,
          initialOptions: [],
          debounceWait: const Duration(milliseconds: 50),
          debounceDuration: const Duration(milliseconds: 200),
          updateOptions: (value) async {
            updateOptionsCallCount++;
            await Future.delayed(const Duration(milliseconds: 10));
            return [
              CompleteOption(value: 'Result: $value', title: 'Result: $value'),
            ];
          },
        ),
      );

      // First character uses debounceWait (50ms).
      await h.type('a');
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      expect(updateOptionsCallCount, equals(1));
      expect(find.text('Result: a'), findsOneWidget);

      // Subsequent characters use debounceDuration (200ms).
      await tester.enterText(h.textField, 'ab');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(updateOptionsCallCount, equals(1));

      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      expect(updateOptionsCallCount, equals(2));
      expect(find.text('Result: ab'), findsOneWidget);
    });
  });
}
