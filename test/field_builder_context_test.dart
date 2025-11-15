import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/multiselect_option.dart';
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

    group('Multiselect Helper Methods', () {
      late OptionSelect multiselectField;
      late FieldBuilderContext context;
      late FieldOption option1;
      late FieldOption option2;
      late FieldOption option3;

      setUp(() {
        option1 = FieldOption(value: 'opt1', label: 'Option 1');
        option2 = FieldOption(value: 'opt2', label: 'Option 2');
        option3 = FieldOption(value: 'opt3', label: 'Option 3');

        multiselectField = OptionSelect(
          id: 'multiselect_field',
          title: 'Multi Select',
          multiselect: true,
          options: [option1, option2, option3],
          defaultValue: <FieldOption>[],
        );

        // Don't add field to controller yet - test unregistered field handling
        context = FieldBuilderContext(
          controller: controller,
          field: multiselectField,
          theme: testTheme,
          state: testState,
          colors: testColors,
        );
      });

      test('toggleValue should handle unregistered field', () {
        // Act - Toggle on unregistered field
        context.toggleValue(option1);

        // Assert - Field should be initialized and option selected
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
        final selected = context.getSelectedOptions();
        expect(selected, isNotNull);
        expect(selected!.length, equals(1));
        expect(selected.first.value, equals('opt1'));
      });

      test('selectOption should handle unregistered field', () {
        // Act - Select on unregistered field
        context.selectOption(option1);

        // Assert - Field should be initialized and option selected
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
        final selected = context.getSelectedOptions();
        expect(selected, isNotNull);
        expect(selected!.length, equals(1));
        expect(selected.first.value, equals('opt1'));
      });

      test('deselectOption should handle unregistered field', () {
        // Act - Deselect on unregistered field (should not throw)
        context.deselectOption(option1);

        // Assert - Field should be initialized
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
      });

      test('selectOptions should handle unregistered field', () {
        // Act - Select multiple on unregistered field
        context.selectOptions([option1, option2]);

        // Assert - Field should be initialized and options selected
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
        final selected = context.getSelectedOptions();
        expect(selected, isNotNull);
        expect(selected!.length, equals(2));
        expect(selected.map((o) => o.value).toList(), containsAll(['opt1', 'opt2']));
      });

      test('deselectOptions should handle unregistered field', () {
        // Act - Deselect multiple on unregistered field (should not throw)
        context.deselectOptions([option1, option2]);

        // Assert - Field should be initialized
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
      });

      test('setSelectedOptions should handle unregistered field', () {
        // Act - Set options on unregistered field
        context.setSelectedOptions([option2, option3]);

        // Assert - Field should be initialized and options set
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
        final selected = context.getSelectedOptions();
        expect(selected, isNotNull);
        expect(selected!.length, equals(2));
        expect(selected.map((o) => o.value).toList(), containsAll(['opt2', 'opt3']));
      });

      test('clearSelections should handle unregistered field', () {
        // Act - Clear on unregistered field (should not throw)
        context.clearSelections();

        // Assert - Field should be initialized
        expect(controller.hasFieldDefinition(multiselectField.id), isTrue);
      });

      test('isOptionSelected should handle unregistered field', () {
        // Act & Assert - Check selection on unregistered field (should not throw)
        final isSelected = context.isOptionSelected('opt1');

        // Should return false for unregistered/uninitialized field
        expect(isSelected, isFalse);
      });

      test('toggleValue should work with registered field', () {
        // Arrange - Register field first
        controller.addFields([multiselectField]);

        // Act - Toggle option on
        context.toggleValue(option1);
        expect(context.isOptionSelected('opt1'), isTrue);

        // Act - Toggle same option off
        context.toggleValue(option1);
        expect(context.isOptionSelected('opt1'), isFalse);
      });

      test('multiselect methods should work together', () {
        // Act - Chain operations on unregistered field
        context.selectOption(option1);
        context.selectOption(option2);
        expect(context.getSelectedOptions()!.length, equals(2));

        context.deselectOption(option1);
        expect(context.getSelectedOptions()!.length, equals(1));
        expect(context.isOptionSelected('opt2'), isTrue);

        context.clearSelections();
        expect(context.getSelectedOptions()!.length, equals(0));
      });
    });
  });
}
