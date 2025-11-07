import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/field_types/convienence_classes/checkboxselect.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FormController - createFieldValue', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('should create field value without field definition', () {
      // Act - Create a value without defining the field first
      controller.createFieldValue<String>('email', 'test@example.com');

      // Assert - Value should be stored (use hasFieldValue since no field definition exists yet)
      expect(controller.hasFieldValue('email'), isTrue);
      expect(controller.getAllFieldValues()['email'], equals('test@example.com'));

      // Act - Add field definition later
      final field = TextField(id: 'email', title: 'Email');
      controller.addFields([field]);

      // Assert - Now getFieldValue should work
      expect(controller.getFieldValue<String>('email'), equals('test@example.com'));
    });

    test('should overwrite existing value silently', () {
      // Arrange - Create initial value
      controller.createFieldValue<String>('name', 'John');
      expect(controller.getAllFieldValues()['name'], equals('John'));

      // Act - Overwrite with new value
      controller.createFieldValue<String>('name', 'Jane');

      // Assert - Value should be updated
      expect(controller.getAllFieldValues()['name'], equals('Jane'));

      // Act - Add field definition to use getFieldValue
      final field = TextField(id: 'name', title: 'Name');
      controller.addFields([field]);

      // Assert - getFieldValue should return the updated value
      expect(controller.getFieldValue<String>('name'), equals('Jane'));
    });

    test('should default to noNotify=true', () {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act - Create value without explicitly setting noNotify
      controller.createFieldValue<String>('field1', 'value1');

      // Assert - Should not have notified listeners
      expect(notificationCount, equals(0));
    });

    test('should notify listeners when noNotify=false', () {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act - Create value with noNotify: false
      controller.createFieldValue<String>('field1', 'value1', noNotify: false);

      // Assert - Should have notified listeners once
      expect(notificationCount, equals(1));
    });

    test('should default to triggerCallbacks=false', () {
      // Arrange - Create a field definition with onChange callback
      var onChangeCallCount = 0;
      final field = TextField(
        id: 'test',
        title: 'Test',
        onChange: (results) {
          onChangeCallCount++;
        },
      );
      controller.addFields([field]);

      // Act - Create value without explicitly setting triggerCallbacks
      controller.createFieldValue<String>('test', 'value');

      // Assert - onChange should not have been called
      expect(onChangeCallCount, equals(0));
    });

    test('should trigger onChange callback when triggerCallbacks=true', () {
      // Arrange - Create a field definition with onChange callback
      var onChangeCallCount = 0;
      final field = TextField(
        id: 'test',
        title: 'Test',
        onChange: (results) {
          onChangeCallCount++;
        },
      );
      controller.addFields([field]);

      // Act - Create value with triggerCallbacks: true
      controller.createFieldValue<String>(
        'test',
        'value',
        triggerCallbacks: true,
        noNotify: false,
      );

      // Assert - onChange should have been called once
      expect(onChangeCallCount, equals(1));
    });

    test('should run validation when triggerCallbacks=true and validateLive=true', () {
      // Arrange - Create field with validator and validateLive enabled
      final field = TextField(
        id: 'email',
        title: 'Email',
        validateLive: true,
        validators: [
          Validator(
            reason: 'Invalid email',
            validator: (value) => (value as String?)?.contains('@') ?? false,
          ),
        ],
      );
      controller.addFields([field]);

      // Act - Create invalid value with triggerCallbacks: true
      controller.createFieldValue<String>(
        'email',
        'invalid',
        triggerCallbacks: true,
        noNotify: false,
      );

      // Assert - Should have validation error
      expect(controller.formErrors.length, equals(1));
      expect(controller.formErrors.first.fieldId, equals('email'));
      expect(controller.formErrors.first.reason, equals('Invalid email'));
    });

    test('should allow null value to remove field', () {
      // Arrange - Create initial value
      controller.createFieldValue<String>('field1', 'value1');
      expect(controller.hasFieldValue('field1'), isTrue);

      // Act - Set to null
      controller.createFieldValue<String>('field1', null);

      // Assert - Value should be removed
      expect(controller.hasFieldValue('field1'), isFalse);
      expect(controller.getAllFieldValues().containsKey('field1'), isFalse);
    });

    test('should support batch operations with noNotify=true', () {
      // Arrange
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act - Create multiple values without notifications
      controller.createFieldValue<String>('field1', 'value1', noNotify: true);
      controller.createFieldValue<String>('field2', 'value2', noNotify: true);
      controller.createFieldValue<String>('field3', 'value3', noNotify: true);
      controller.notifyListeners();

      // Assert - Should only notify once at the end
      expect(notificationCount, equals(1));
      final allValues = controller.getAllFieldValues();
      expect(allValues['field1'], equals('value1'));
      expect(allValues['field2'], equals('value2'));
      expect(allValues['field3'], equals('value3'));
    });
  });

  group('FormController - updateFieldValue integration', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('updateFieldValue should throw ArgumentError if field does not exist', () {
      // Act & Assert - Should throw when field doesn't exist
      expect(
        () => controller.updateFieldValue<String>('nonexistent', 'value'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updateFieldValue should work after field is added', () {
      // Arrange - Add field definition
      final field = TextField(id: 'test', title: 'Test');
      controller.addFields([field]);

      // Act - Update value
      controller.updateFieldValue<String>('test', 'value');

      // Assert - Value should be set
      expect(controller.getFieldValue<String>('test'), equals('value'));
    });

    test('updateFieldValue should trigger callbacks by default', () {
      // Arrange - Add field with onChange callback
      var onChangeCallCount = 0;
      final field = TextField(
        id: 'test',
        title: 'Test',
        onChange: (results) {
          onChangeCallCount++;
        },
      );
      controller.addFields([field]);

      // Act - Update value
      controller.updateFieldValue<String>('test', 'value');

      // Assert - onChange should have been called
      expect(onChangeCallCount, equals(1));
    });

    test('updateFieldValue should run validation if validateLive is true', () {
      // Arrange - Add field with validator and validateLive
      final field = TextField(
        id: 'email',
        title: 'Email',
        validateLive: true,
        validators: [
          Validator(
            reason: 'Invalid email',
            validator: (value) => (value as String?)?.contains('@') ?? false,
          ),
        ],
      );
      controller.addFields([field]);

      // Act - Update with invalid value
      controller.updateFieldValue<String>('email', 'invalid');

      // Assert - Should have validation error
      expect(controller.formErrors.length, equals(1));
      expect(controller.formErrors.first.fieldId, equals('email'));
    });

    test('updateFieldValue should default to noNotify=false', () {
      // Arrange
      final field = TextField(id: 'test', title: 'Test');
      controller.addFields([field]);
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      // Act - Update value without explicitly setting noNotify
      controller.updateFieldValue<String>('test', 'value');

      // Assert - Should have notified listeners
      expect(notificationCount, equals(1));
    });
  });

  group('FormController - createFieldValue vs updateFieldValue comparison', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('createFieldValue works without field, updateFieldValue requires field', () {
      // Act & Assert - createFieldValue works
      expect(
        () => controller.createFieldValue<String>('field1', 'value1'),
        returnsNormally,
      );
      expect(controller.hasFieldValue('field1'), isTrue);
      expect(controller.getAllFieldValues()['field1'], equals('value1'));

      // Act & Assert - updateFieldValue throws
      expect(
        () => controller.updateFieldValue<String>('field2', 'value2'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pre-populate with createFieldValue, then add fields later', () {
      // Arrange - Pre-populate values before fields exist
      controller.createFieldValue<String>('email', 'user@example.com');
      controller.createFieldValue<String>('name', 'John Doe');

      // Assert - Values exist before fields are defined (use hasFieldValue and getAllFieldValues)
      expect(controller.hasFieldValue('email'), isTrue);
      expect(controller.hasFieldValue('name'), isTrue);
      final preValues = controller.getAllFieldValues();
      expect(preValues['email'], equals('user@example.com'));
      expect(preValues['name'], equals('John Doe'));

      // Act - Add field definitions later
      final emailField = TextField(id: 'email', title: 'Email');
      final nameField = TextField(id: 'name', title: 'Name');
      controller.addFields([emailField, nameField]);

      // Assert - Values are still accessible after fields are added (now getFieldValue works)
      expect(controller.getFieldValue<String>('email'), equals('user@example.com'));
      expect(controller.getFieldValue<String>('name'), equals('John Doe'));

      // Act - Now updateFieldValue should work since fields exist
      expect(
        () => controller.updateFieldValue<String>('email', 'newemail@example.com'),
        returnsNormally,
      );
      expect(controller.getFieldValue<String>('email'), equals('newemail@example.com'));
    });

    test('both methods should update the same internal storage', () {
      // Arrange - Add field
      final field = TextField(id: 'test', title: 'Test');
      controller.addFields([field]);

      // Act - Set value with createFieldValue
      controller.createFieldValue<String>('test', 'value1', noNotify: false);
      expect(controller.getFieldValue<String>('test'), equals('value1'));

      // Act - Update with updateFieldValue
      controller.updateFieldValue<String>('test', 'value2');
      expect(controller.getFieldValue<String>('test'), equals('value2'));

      // Act - Update again with createFieldValue
      controller.createFieldValue<String>('test', 'value3', noNotify: false);
      expect(controller.getFieldValue<String>('test'), equals('value3'));
    });
  });

  group('FormController - toggleMultiSelectValue single-select fix', () {
    late FormController controller;

    setUp(() {
      controller = FormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('toggleMultiSelectValue with multiselect=true allows multiple selections', () {
      // Arrange - Create multiselect field
      final option1 = FieldOption(label: 'Option 1', value: 'opt1');
      final option2 = FieldOption(label: 'Option 2', value: 'opt2');
      final option3 = FieldOption(label: 'Option 3', value: 'opt3');

      final field = CheckboxSelect(
        id: 'multi',
        options: [option1, option2, option3],
        multiselect: true,
      );
      controller.addFields([field]);

      // Act - Select multiple options
      controller.toggleMultiSelectValue('multi', toggleOn: ['opt1']);
      controller.toggleMultiSelectValue('multi', toggleOn: ['opt2']);
      controller.toggleMultiSelectValue('multi', toggleOn: ['opt3']);

      // Assert - All three should be selected
      final selected = controller.getFieldValue<List<FieldOption>>('multi');
      expect(selected?.length, equals(3));
      expect(selected?.any((o) => o.value == 'opt1'), isTrue);
      expect(selected?.any((o) => o.value == 'opt2'), isTrue);
      expect(selected?.any((o) => o.value == 'opt3'), isTrue);
    });

    test('toggleMultiSelectValue with multiselect=false only allows one selection', () {
      // Arrange - Create single-select field
      final option1 = FieldOption(label: 'Option 1', value: 'opt1');
      final option2 = FieldOption(label: 'Option 2', value: 'opt2');
      final option3 = FieldOption(label: 'Option 3', value: 'opt3');

      final field = CheckboxSelect(
        id: 'single',
        options: [option1, option2, option3],
        multiselect: false,  // Single-select mode
      );
      controller.addFields([field]);

      // Act - Try to select first option
      controller.toggleMultiSelectValue('single', toggleOn: ['opt1']);

      // Assert - Only opt1 should be selected
      var selected = controller.getFieldValue<List<FieldOption>>('single');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('opt1'));

      // Act - Select second option
      controller.toggleMultiSelectValue('single', toggleOn: ['opt2']);

      // Assert - Only opt2 should be selected (opt1 cleared)
      selected = controller.getFieldValue<List<FieldOption>>('single');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('opt2'));

      // Act - Select third option
      controller.toggleMultiSelectValue('single', toggleOn: ['opt3']);

      // Assert - Only opt3 should be selected
      selected = controller.getFieldValue<List<FieldOption>>('single');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('opt3'));
    });

    test('toggleMultiSelectValue with multiselect=false replaces previous selection', () {
      // Arrange - Create single-select field with initial selection
      final option1 = FieldOption(label: 'Low', value: 'low');
      final option2 = FieldOption(label: 'Medium', value: 'medium');
      final option3 = FieldOption(label: 'High', value: 'high');

      final field = CheckboxSelect(
        id: 'priority',
        options: [option1, option2, option3],
        multiselect: false,
        defaultValue: [option1],
      );
      controller.addFields([field]);

      // Assert - Initial state
      var selected = controller.getFieldValue<List<FieldOption>>('priority');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('low'));

      // Act - Select high priority
      controller.toggleMultiSelectValue('priority', toggleOn: ['high']);

      // Assert - Only high should be selected, low cleared
      selected = controller.getFieldValue<List<FieldOption>>('priority');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('high'));
      expect(selected?.any((o) => o.value == 'low'), isFalse);
    });

    test('toggleMultiSelectValue with multiselect=false and toggleOff deselects', () {
      // Arrange - Create single-select field with initial selection
      final option1 = FieldOption(label: 'Yes', value: 'yes');
      final option2 = FieldOption(label: 'No', value: 'no');

      final field = CheckboxSelect(
        id: 'confirm',
        options: [option1, option2],
        multiselect: false,
        defaultValue: [option1],
      );
      controller.addFields([field]);

      // Act - Toggle off the current selection
      controller.toggleMultiSelectValue('confirm', toggleOff: ['yes']);

      // Assert - Nothing should be selected
      final selected = controller.getFieldValue<List<FieldOption>>('confirm');
      expect(selected?.isEmpty, isTrue);
    });

    test('toggleMultiSelectValue with multiselect=false ignores multiple toggleOn values', () {
      // Arrange - Create single-select field
      final option1 = FieldOption(label: 'Option 1', value: 'opt1');
      final option2 = FieldOption(label: 'Option 2', value: 'opt2');
      final option3 = FieldOption(label: 'Option 3', value: 'opt3');

      final field = CheckboxSelect(
        id: 'single',
        options: [option1, option2, option3],
        multiselect: false,
      );
      controller.addFields([field]);

      // Act - Try to toggle on multiple values at once
      controller.toggleMultiSelectValue('single', toggleOn: ['opt1', 'opt2', 'opt3']);

      // Assert - Only the first value should be selected
      final selected = controller.getFieldValue<List<FieldOption>>('single');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('opt1'));
    });

    test('CheckboxSelect with multiselect=false behaves like radio buttons', () {
      // Arrange - Create single-select checkbox field (radio button behavior)
      final optionA = FieldOption(label: 'Choice A', value: 'a');
      final optionB = FieldOption(label: 'Choice B', value: 'b');
      final optionC = FieldOption(label: 'Choice C', value: 'c');

      final field = CheckboxSelect(
        id: 'radio-style',
        options: [optionA, optionB, optionC],
        multiselect: false,
      );
      controller.addFields([field]);

      // Simulate user clicking checkboxes in sequence

      // Click A
      controller.toggleMultiSelectValue('radio-style', toggleOn: ['a']);
      var selected = controller.getFieldValue<List<FieldOption>>('radio-style');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('a'));

      // Click B (should deselect A)
      controller.toggleMultiSelectValue('radio-style', toggleOn: ['b']);
      selected = controller.getFieldValue<List<FieldOption>>('radio-style');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('b'));

      // Click C (should deselect B)
      controller.toggleMultiSelectValue('radio-style', toggleOn: ['c']);
      selected = controller.getFieldValue<List<FieldOption>>('radio-style');
      expect(selected?.length, equals(1));
      expect(selected?.first.value, equals('c'));

      // Click C again (should deselect it - toggle off)
      controller.toggleMultiSelectValue('radio-style', toggleOff: ['c']);
      selected = controller.getFieldValue<List<FieldOption>>('radio-style');
      expect(selected?.isEmpty, isTrue);
    });
  });
}
