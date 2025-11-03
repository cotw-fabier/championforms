import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/widgets_internal/autocomplete_overlay_widget.dart';
import 'package:championforms/models/autocomplete/autocomplete_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_option_class.dart';
import 'package:championforms/models/autocomplete/autocomplete_type.dart';

void main() {
  group('AutocompleteWrapper Structure Tests', () {
    test('Widget instantiates with required parameters', () {
      // Arrange
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          CompleteOption(value: 'Option 1'),
          CompleteOption(value: 'Option 2'),
        ],
      );
      final focusNode = FocusNode();
      final child = TextField();

      // Act & Assert - should not throw
      expect(
        () => AutocompleteWrapper(
          child: child,
          autoComplete: autoComplete,
          focusNode: focusNode,
        ),
        returnsNormally,
      );

      // Cleanup
      focusNode.dispose();
    });

    testWidgets('Widget builds without errors when wrapped around TextField',
        (WidgetTester tester) async {
      // Arrange
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [
          CompleteOption(value: 'Test 1'),
          CompleteOption(value: 'Test 2'),
        ],
      );
      final focusNode = FocusNode();
      final textController = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteWrapper(
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

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(AutocompleteWrapper), findsOneWidget);

      // Cleanup
      focusNode.dispose();
      textController.dispose();
    });

    testWidgets('Widget wraps child with CompositedTransformTarget',
        (WidgetTester tester) async {
      // Arrange
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [CompleteOption(value: 'Test')],
      );
      final focusNode = FocusNode();
      final child = Container(key: const Key('test-child'));

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteWrapper(
              child: child,
              autoComplete: autoComplete,
              focusNode: focusNode,
            ),
          ),
        ),
      );

      // Assert - CompositedTransformTarget should wrap the child
      expect(find.byType(CompositedTransformTarget), findsOneWidget);
      expect(find.byKey(const Key('test-child')), findsOneWidget);

      // Cleanup
      focusNode.dispose();
    });

    testWidgets('Widget accepts optional parameters',
        (WidgetTester tester) async {
      // Arrange
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [CompleteOption(value: 'Test')],
      );
      final focusNode = FocusNode();
      final textController = TextEditingController();
      final valueNotifier = ValueNotifier<String>('');
      final child = TextField();
      var selectionCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutocompleteWrapper(
              child: child,
              autoComplete: autoComplete,
              focusNode: focusNode,
              textEditingController: textController,
              valueNotifier: valueNotifier,
              onOptionSelected: (option) {
                selectionCalled = true;
              },
            ),
          ),
        ),
      );

      // Assert - Widget should build successfully with all optional params
      expect(find.byType(AutocompleteWrapper), findsOneWidget);

      // Cleanup
      focusNode.dispose();
      textController.dispose();
      valueNotifier.dispose();
    });

    test('Widget constructor uses named parameters', () {
      // Arrange
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [CompleteOption(value: 'Test')],
      );
      final focusNode = FocusNode();
      final child = Container();

      // Act - Testing named parameter syntax
      final widget = AutocompleteWrapper(
        child: child,
        autoComplete: autoComplete,
        focusNode: focusNode,
      );

      // Assert
      expect(widget.child, equals(child));
      expect(widget.autoComplete, equals(autoComplete));
      expect(widget.focusNode, equals(focusNode));

      // Cleanup
      focusNode.dispose();
    });

    test('Widget accepts Key parameter', () {
      // Arrange
      const key = Key('autocomplete-wrapper-key');
      final autoComplete = AutoCompleteBuilder(
        type: AutoCompleteType.dropdown,
        initialOptions: [CompleteOption(value: 'Test')],
      );
      final focusNode = FocusNode();
      final child = Container();

      // Act
      final widget = AutocompleteWrapper(
        key: key,
        child: child,
        autoComplete: autoComplete,
        focusNode: focusNode,
      );

      // Assert
      expect(widget.key, equals(key));

      // Cleanup
      focusNode.dispose();
    });
  });
}
