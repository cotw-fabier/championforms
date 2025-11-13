import 'package:championforms/championforms.dart' as form;
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Refactored OptionSelect Widget Tests', () {
    late FormController controller;
    late form.OptionSelect field;

    setUp(() {
      controller = FormController();
      field = form.OptionSelect(
        id: 'test_select',
        title: 'Test Select',
        options: [
          form.FieldOption(value: '1', label: 'Option 1'),
          form.FieldOption(value: '2', label: 'Option 2'),
          form.FieldOption(value: '3', label: 'Option 3'),
        ],
        multiselect: true,
        validateLive: true,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('OptionSelect renders correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert - Check that options are rendered
      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
      expect(find.text('Option 3'), findsOneWidget);
    });

    testWidgets('Multiselect value handling works',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Select first option
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();

      // Assert - Value is stored in controller
      final value = controller.getFieldValue<List<form.FieldOption>>('test_select');
      expect(value, isNotNull);
      expect(value!.length, equals(1));
      expect(value.first.value, equals('1'));
    });

    testWidgets('Option selection behavior works',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Select multiple options
      await tester.tap(find.text('Option 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Option 2'));
      await tester.pumpAndSettle();

      // Assert - Both values are stored
      final value = controller.getFieldValue<List<form.FieldOption>>('test_select');
      expect(value, isNotNull);
      expect(value!.length, equals(2));
      expect(value.map((o) => o.value).toList(), containsAll(['1', '2']));
    });

    testWidgets('Validation behavior works', (WidgetTester tester) async {
      // Arrange
      field = form.OptionSelect(
        id: 'test_select',
        title: 'Test Select',
        options: [
          form.FieldOption(value: '1', label: 'Option 1'),
          form.FieldOption(value: '2', label: 'Option 2'),
        ],
        multiselect: false,
        validateLive: true,
        validators: [
          form.Validator(
            validator: (results) {
              final value =
                  results.grab('test_select').asMultiselectList();
              return value.isEmpty;
            },
            reason: 'Selection is required',
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [field],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Trigger validation without selecting anything
      final results = form.FormResults.getResults(controller: controller);

      // Assert - Validation error appears
      expect(results.errorState, isTrue);
      expect(
        results.formErrors.any((e) => e.fieldId == 'test_select'),
        isTrue,
      );
    });

    test('MultiselectFieldConverters handles FieldOption list', () {
      // Arrange
      final options = [
        form.FieldOption(value: '1', label: 'Option 1'),
        form.FieldOption(value: '2', label: 'Option 2'),
      ];

      // Act & Assert - Test string converter
      final stringValue = field.asStringConverter(options);
      expect(stringValue, equals('1, 2'));

      // Act & Assert - Test string list converter
      final stringListValue = field.asStringListConverter(options);
      expect(stringListValue, equals(['1', '2']));

      // Act & Assert - Test bool converter
      final boolValue = field.asBoolConverter(options);
      expect(boolValue, isTrue);
    });
  });
}
