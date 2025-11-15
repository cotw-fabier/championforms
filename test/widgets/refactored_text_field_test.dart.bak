import 'package:championforms/championforms.dart' as form;
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Refactored TextField Widget Tests', () {
    late FormController controller;
    late form.TextField field;
    late FieldBuilderContext context;

    setUp(() {
      controller = FormController();
      field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        hintText: 'Enter text',
        validateLive: true,
      );

      // Create a context for the field
      context = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );
    });

    tearDown(() async {
      // IMPORTANT: Unmount widget tree BEFORE disposing controller
      // This prevents "FormController was used after being disposed" errors
      // No need to do this in tearDown since each test builds its own widget tree
    });

    testWidgets('TextField renders correctly', (WidgetTester tester) async {
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

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Test Field'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('TextEditingController integration works',
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

      // Act - Enter text
      await tester.enterText(find.byType(TextField), 'Test Value');
      await tester.pumpAndSettle();

      // Assert - Value is stored in controller
      final value = controller.getFieldValue<String>('test_field');
      expect(value, equals('Test Value'));

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('FocusNode integration works', (WidgetTester tester) async {
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

      // Act - Tap to focus
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Assert - Field has focus
      expect(controller.isFieldFocused('test_field'), isTrue);

      // Act - Unfocus the FocusNode
      // Note: We need to unfocus the actual FocusNode, not just update controller tracking
      final focusNode = controller.getFieldController<FocusNode>('test_field');
      focusNode!.unfocus();
      await tester.pumpAndSettle();

      // Assert - Field lost focus
      expect(controller.isFieldFocused('test_field'), isFalse);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('onChange callback fires', (WidgetTester tester) async {
      // Arrange
      int callCount = 0;
      String? lastValue;

      field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        onChange: (results) {
          callCount++;
          lastValue = results.grab('test_field').asString();
        },
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

      // onChange is called during initial build with empty string
      expect(callCount, greaterThan(0), reason: 'onChange called during initial build');
      final initialCallCount = callCount;

      // Act - Enter text
      await tester.enterText(find.byType(TextField), 'Test');
      await tester.pumpAndSettle();

      // Assert - onChange was called again with new value
      expect(callCount, greaterThan(initialCallCount), reason: 'onChange called after text input');
      expect(lastValue, equals('Test'), reason: 'onChange receives correct value');

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });

    testWidgets('Validation behavior works on focus loss',
        (WidgetTester tester) async {
      // Arrange
      field = form.TextField(
        id: 'test_field',
        textFieldTitle: 'Test Field',
        validateLive: true,
        validators: [
          form.Validator(
            // Validator receives the field value directly (NOT FieldResultAccessor)
            // Returns TRUE when valid, FALSE when invalid
            validator: (value) {
              if (value == null) return false;
              if (value is String) return value.isNotEmpty;
              return false;
            },
            reason: 'Field is required',
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

      // Act - Focus then blur without entering text
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Lose focus by unfocusing the actual FocusNode
      // Note: controller.setFieldFocus() only updates tracking, not the FocusNode itself
      final focusNode = controller.getFieldController<FocusNode>('test_field');
      focusNode!.unfocus();
      await tester.pumpAndSettle();

      // Assert - Validation error appears
      expect(controller.formErrors.length, greaterThan(0),
          reason: 'Validation should create errors');
      expect(
        controller.formErrors.any((e) => e.fieldId == 'test_field'),
        isTrue,
        reason: 'Error should be for test_field',
      );

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });

    test('TextEditingController is created lazily', () {
      // Arrange - Create context without accessing controller
      final ctx = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      // Assert - No controller exists yet
      expect(
        controller.getFieldController<TextEditingController>('test_field'),
        isNull,
      );

      // Act - Access text controller
      final textController = ctx.getTextController();

      // Assert - Controller now exists and is registered
      expect(textController, isNotNull);
      expect(
        controller.getFieldController<TextEditingController>('test_field'),
        equals(textController),
      );

      // Cleanup
      controller.dispose();
    });

    test('FocusNode is created lazily', () {
      // Arrange - Create context without accessing focus node
      final ctx = FieldBuilderContext(
        controller: controller,
        field: field,
        theme: const FormTheme(),
        state: FieldState.normal,
        colors: const FieldColorScheme(),
      );

      // Assert - No focus node exists yet
      expect(
        controller.getFieldController<FocusNode>('test_field'),
        isNull,
      );

      // Act - Access focus node
      final focusNode = ctx.getFocusNode();

      // Assert - Focus node now exists and is registered
      expect(focusNode, isNotNull);
      expect(
        controller.getFieldController<FocusNode>('test_field'),
        equals(focusNode),
      );

      // Cleanup
      controller.dispose();
    });
  });
}
