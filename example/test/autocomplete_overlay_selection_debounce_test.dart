import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

void main() {
  group('ChampionAutocompleteWrapper Selection and Debounce Tests', () {
    testWidgets('Default selection callback updates TextEditingController',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(value: 'Apple', title: 'Apple'),
          AutoCompleteOption(value: 'Banana', title: 'Banana'),
          AutoCompleteOption(value: 'Cherry', title: 'Cherry'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Find and tap the first option
      final firstOption = find.text('Apple');
      expect(firstOption, findsOneWidget);
      await tester.tap(firstOption);
      await tester.pumpAndSettle();

      // Assert - Controller should be updated with selected value
      expect(textController.text, equals('Apple'));

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Custom onOptionSelected callback overrides default behavior',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      AutoCompleteOption? selectedOption;

      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(value: 'Apple', title: 'Apple'),
          AutoCompleteOption(value: 'Banana', title: 'Banana'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
              onOptionSelected: (option) {
                selectedOption = option;
              },
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Tap the first option
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Assert - Custom callback should be called
      expect(selectedOption, isNotNull);
      expect(selectedOption!.value, equals('Apple'));

      // Controller should NOT be updated (custom callback overrides default)
      expect(textController.text, equals('a'));

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Overlay dismisses after selection',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(value: 'Apple', title: 'Apple'),
          AutoCompleteOption(value: 'Banana', title: 'Banana'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Verify overlay is shown
      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);

      // Tap an option
      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      // Assert - Overlay should be dismissed (ListTile no longer visible in overlay)
      // The text "Apple" will still exist in the TextField, so we check for multiple
      final appleWidgets = find.text('Apple');
      // Should only find one (in TextField), not two (TextField + overlay)
      expect(appleWidgets, findsOneWidget);

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Option callback is invoked when provided',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      var callbackInvoked = false;

      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(
            value: 'Apple',
            title: 'Apple',
            callback: (option) {
              callbackInvoked = true;
            },
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Tap the option
      await tester.tap(find.text('Apple').last);
      await tester.pumpAndSettle();

      // Assert - Option callback should have been invoked
      expect(callbackInvoked, isTrue);

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Focus returns to field after selection',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(value: 'Apple', title: 'Apple'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Tap the option
      await tester.tap(find.text('Apple').last);
      await tester.pumpAndSettle();

      // Assert - Focus should return to field
      expect(focusNode.hasFocus, isTrue);

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Cursor positioned at end after selection',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          AutoCompleteOption(value: 'Apple Fruit', title: 'Apple Fruit'),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus first, then type to trigger overlay
      await tester.tap(find.byType(TextField));
      await tester.pump();

      textController.text = 'a';
      await tester.pump(); // Trigger controller listener
      await tester.pump(); // Allow postFrameCallback to run
      await tester.pump(); // Build overlay

      // Tap the option
      await tester.tap(find.text('Apple Fruit'));
      await tester.pumpAndSettle();

      // Assert - Cursor should be at end of text
      expect(textController.selection.baseOffset,
          equals(textController.text.length));
      expect(textController.selection.extentOffset,
          equals(textController.text.length));

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Debounce timing works with updateOptions callback',
        (WidgetTester tester) async {
      // Arrange
      final focusNode = FocusNode();
      final textController = TextEditingController();
      var updateOptionsCallCount = 0;

      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [],
        debounceWait: const Duration(milliseconds: 50),
        debounceDuration: const Duration(milliseconds: 200),
        updateOptions: (value) async {
          updateOptionsCallCount++;
          await Future.delayed(const Duration(milliseconds: 10));
          return [
            AutoCompleteOption(value: 'Result: $value', title: 'Result: $value'),
          ];
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChampionAutocompleteWrapper(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
              ),
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
            ),
          ),
        ),
      );

      // Act - Focus field
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Type first character - should use debounceWait (50ms)
      textController.text = 'a';
      await tester.pump();

      // Wait for first debounce to complete
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle();

      // Assert - First updateOptions should have been called
      expect(updateOptionsCallCount, equals(1));

      // Type second character - should use debounceDuration (200ms)
      textController.text = 'ab';
      await tester.pump();

      // Wait shorter than debounce duration
      await tester.pump(const Duration(milliseconds: 100));

      // Should not have called yet
      expect(updateOptionsCallCount, equals(1));

      // Wait for second debounce to complete
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpAndSettle();

      // Should have called second time
      expect(updateOptionsCallCount, equals(2));

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });
  });
}
