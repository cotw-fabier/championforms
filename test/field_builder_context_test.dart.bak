import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:flutter/material.dart' as material;
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FieldBuilderContext', () {
    late FormController controller;
    late TextField testField;
    late FormTheme testTheme;
    late FieldState testState;
    late FieldColorScheme testColors;

    setUp(() {
      controller = FormController();
      testField = TextField(
        id: 'test_field',
        title: 'Test Field',
        defaultValue: 'default_value',
      );
      controller.addFields([testField]);

      testTheme = const FormTheme();
      testState = FieldState.normal;
      testColors = const FieldColorScheme();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should expose controller and field properties', () {
      // Arrange & Act
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Assert
      expect(context.controller, equals(controller));
      expect(context.field, equals(testField));
      expect(context.theme, equals(testTheme));
      expect(context.state, equals(testState));
      expect(context.colors, equals(testColors));
    });

    test('getValue should return field value with type safety', () {
      // Arrange
      controller.updateFieldValue<String>(testField.id, 'test_value');
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act
      final value = context.getValue<String>();

      // Assert
      expect(value, equals('test_value'));
    });

    test('getValue should return null for non-existent value', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act
      final value = context.getValue<String>();

      // Assert - Should return default value
      expect(value, equals('default_value'));
    });

    test('setValue should update field value', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act
      context.setValue<String>('new_value');

      // Assert
      expect(controller.getFieldValue<String>(testField.id), equals('new_value'));
    });

    test('addError should add validation error', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act
      context.addError('Test error message');

      // Assert
      final errors = controller.formErrors
          .where((error) => error.fieldId == testField.id)
          .toList();
      expect(errors.length, equals(1));
      expect(errors.first.reason, equals('Test error message'));
    });

    test('clearErrors should remove all errors for field', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );
      // Note: addError only adds if fieldId+validatorPosition combo doesn't exist
      // Since we always use validatorPosition=0, only first error gets added
      context.addError('Error 1');
      // Manually add second error with different validator position
      controller.addError(
        FormBuilderError(
          fieldId: testField.id,
          reason: 'Error 2',
          validatorPosition: 1,
        ),
      );
      expect(controller.formErrors.length, equals(2));

      // Act
      context.clearErrors();

      // Assert
      final errors = controller.formErrors
          .where((error) => error.fieldId == testField.id)
          .toList();
      expect(errors.length, equals(0));
    });

    test('hasFocus should return focus state', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act & Assert - Initially not focused
      expect(context.hasFocus, equals(false));

      // Act - Set focus
      controller.setFieldFocus(testField.id, true);

      // Assert
      expect(context.hasFocus, equals(true));
    });

    test('getTextController should create TextEditingController lazily', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act - First call creates controller
      final textController1 = context.getTextController();

      // Assert - Controller exists
      expect(textController1, isNotNull);
      expect(textController1, isA<material.TextEditingController>());

      // Act - Second call returns same controller
      final textController2 = context.getTextController();

      // Assert - Same instance returned
      expect(textController2, equals(textController1));
    });

    test('getFocusNode should create FocusNode lazily and register with controller', () {
      // Arrange
      final context = FieldBuilderContext(
        controller: controller,
        field: testField,
        theme: testTheme,
        state: testState,
        colors: testColors,
      );

      // Act - First call creates FocusNode
      final focusNode1 = context.getFocusNode();

      // Assert - FocusNode exists
      expect(focusNode1, isNotNull);
      expect(focusNode1, isA<material.FocusNode>());

      // Act - Second call returns same FocusNode
      final focusNode2 = context.getFocusNode();

      // Assert - Same instance returned
      expect(focusNode2, equals(focusNode1));

      // Assert - Controller should have the FocusNode registered
      // Note: Must specify type parameter for composite key lookup
      final registeredFocusNode = controller.getFieldController<material.FocusNode>(testField.id);
      expect(registeredFocusNode, equals(focusNode1));

      // Note: tearDown() handles controller disposal
    });
  });
}
