import 'package:championforms/championforms.dart';
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/compound_field_registration.dart';
import 'package:championforms/models/field_types/textfield.dart' as cf_field;
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/widgets_external/form.dart' as cf;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test compound field implementation
class TestCompoundField extends CompoundField {
  final bool includeOptional;

  TestCompoundField({
    required String id,
    this.includeOptional = false,
    String? title,
    bool disabled = false,
    FormTheme? theme,
    List<Validator>? validators,
  }) : super(
          id: id,
          title: title,
          disabled: disabled,
          theme: theme,
          validators: validators,
        );

  @override
  List<Field> buildSubFields() {
    final List<Field> fields = [
      cf_field.TextField(id: 'first', title: 'First'),
      cf_field.TextField(id: 'last', title: 'Last'),
    ];

    if (includeOptional) {
      fields.insert(1, cf_field.TextField(id: 'middle', title: 'Middle'));
    }

    return fields;
  }

  @override
  TestCompoundField copyWith({
    String? id,
    bool? includeOptional,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? rollUpErrors,
    FormTheme? theme,
    List<Validator>? validators,
    bool? validateLive,
    Function(FormResults results)? onSubmit,
    Function(FormResults results)? onChange,
    Widget? icon,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      Field fieldDetails,
      FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    bool? requestFocus,
  }) {
    return TestCompoundField(
      id: id ?? this.id,
      includeOptional: includeOptional ?? this.includeOptional,
      title: title ?? this.title,
      disabled: disabled ?? this.disabled,
      theme: theme ?? this.theme,
      validators: validators ?? this.validators,
    );
  }
}

void main() {
  group('Task 2.1: Compound Field Controller Integration Tests', () {
    setUp(() {
      // Clear any previous registrations
      FormFieldRegistry.instance.clearCompoundRegistrations();
    });

    testWidgets('Form widget encounters CompoundField and generates sub-fields',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null, // Use default layout
      );

      final controller = FormController();
      final compoundField = TestCompoundField(id: 'name', title: 'Name');

      // Act: Build form with compound field
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Sub-fields should exist in controller with null or empty string values
      final firstName = controller.getFieldValue('name_first');
      final lastName = controller.getFieldValue('name_last');

      expect(firstName != null || firstName == '', isTrue);
      expect(lastName != null || lastName == '', isTrue);
    });

    testWidgets('Sub-fields registered individually with FormController',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(id: 'person');

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Compound field and each sub-field should be in activeFields
      final activeFieldIds = controller.activeFields.map((f) => f.id).toList();
      expect(activeFieldIds, contains('person')); // Compound field itself
      expect(activeFieldIds, contains('person_first'));
      expect(activeFieldIds, contains('person_last'));
      expect(activeFieldIds.length, equals(3)); // Compound field + 2 sub-fields
    });

    testWidgets(
        'Controller methods work on sub-field IDs: getFieldValue(), updateFieldValue()',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(id: 'user');

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Update sub-field values using controller methods
      controller.updateFieldValue('user_first', 'John');
      controller.updateFieldValue('user_last', 'Doe');
      await tester.pumpAndSettle();

      // Assert: Values should be retrievable
      expect(controller.getFieldValue('user_first'), equals('John'));
      expect(controller.getFieldValue('user_last'), equals('Doe'));
    });

    testWidgets('TextEditingController lifecycle management for sub-fields',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(id: 'profile');

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Check that controllers exist for text sub-fields
      final hasFirstController = controller.getFieldController<TextEditingController>('profile_first');
      final hasLastController = controller.getFieldController<TextEditingController>('profile_last');

      expect(hasFirstController, isNotNull);
      expect(hasLastController, isNotNull);

      // Act: Get and use the controllers
      final firstController = controller.getFieldController<TextEditingController>('profile_first');
      expect(firstController, isNotNull);

      if (firstController != null) {
        // Verify the controller is functional
        expect(firstController.text.isEmpty, isTrue);
        firstController.text = 'Jane';
        expect(firstController.text, equals('Jane'));
      }
    });

    testWidgets('FocusNode lifecycle management for sub-fields',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(id: 'contact');

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Focus nodes should be manageable via controller
      // Request focus on sub-field
      controller.setFieldFocus('contact_first', true);
      await tester.pumpAndSettle();

      // Assert: Focus state should be tracked
      expect(controller.isFieldFocused('contact_first'), isTrue);
      expect(controller.isFieldFocused('contact_last'), isFalse);
    });

    testWidgets('Theme propagation from compound field to sub-fields',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final customTheme = FormTheme(
        colorScheme: FieldColorScheme(
          backgroundColor: Colors.blue,
          textColor: Colors.white,
        ),
      );

      final controller = FormController();
      final compoundField = TestCompoundField(
        id: 'themed',
        theme: customTheme,
      );

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Sub-fields should inherit compound field theme
      final firstField =
          controller.activeFields.firstWhere((f) => f.id == 'themed_first');
      final lastField =
          controller.activeFields.firstWhere((f) => f.id == 'themed_last');

      expect(firstField.theme, equals(customTheme));
      expect(lastField.theme, equals(customTheme));
    });

    testWidgets('Disabled state propagation from compound field to sub-fields',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(
        id: 'disabled_test',
        disabled: true,
      );

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: All sub-fields should be disabled
      final firstField = controller.activeFields
          .firstWhere((f) => f.id == 'disabled_test_first');
      final lastField = controller.activeFields
          .firstWhere((f) => f.id == 'disabled_test_last');

      expect(firstField.disabled, isTrue);
      expect(lastField.disabled, isTrue);
    });

    testWidgets('Sub-fields with dynamic inclusion work correctly',
        (WidgetTester tester) async {
      // Arrange: Register compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      final controller = FormController();
      final compoundField = TestCompoundField(
        id: 'dynamic',
        includeOptional: true,
      );

      // Act: Build form with optional field included
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Compound field and all three sub-fields should exist
      final activeFieldIds = controller.activeFields.map((f) => f.id).toList();
      expect(activeFieldIds, contains('dynamic')); // Compound field itself
      expect(activeFieldIds, contains('dynamic_first'));
      expect(activeFieldIds, contains('dynamic_middle'));
      expect(activeFieldIds, contains('dynamic_last'));
      expect(activeFieldIds.length, equals(4)); // Compound field + 3 sub-fields
    });

    testWidgets('Compound field validators are executed during validation',
        (tester) async {
      // Arrange: Set up test to verify validators are called
      bool validatorCalled = false;
      final controller = FormController();

      // Register the test compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'test',
        (field) => field.buildSubFields(),
        null,
      );

      final compoundField = TestCompoundField(
        id: 'validated',
        validators: [
          Validator(
            validator: (results) {
              validatorCalled = true;
              // Access sub-field values to verify accessor works
              final first = results.grab('validated_first').asString();
              final last = results.grab('validated_last').asString();
              return first.isNotEmpty && last.isNotEmpty;
            },
            reason: 'Both first and last name are required',
          ),
        ],
      );

      // Act: Build form
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Set some values in sub-fields
      controller.updateFieldValue('validated_first', 'John');
      controller.updateFieldValue('validated_last', 'Doe');
      await tester.pumpAndSettle();

      // Trigger validation by getting results
      final results = FormResults.getResults(controller: controller);

      // Assert: Validator should have been called
      expect(validatorCalled, true,
          reason: 'Compound field validator should be executed');
      expect(results.errorState, false,
          reason: 'Validation should pass with both fields filled');
    });

    testWidgets('Compound field validation fails when sub-fields are empty',
        (tester) async {
      // Arrange
      final controller = FormController();

      FormFieldRegistry.registerCompound<TestCompoundField>(
        'test',
        (field) => field.buildSubFields(),
        null,
      );

      final compoundField = TestCompoundField(
        id: 'validated',
        validators: [
          Validator(
            validator: (results) {
              final first = results.grab('validated_first').asString();
              final last = results.grab('validated_last').asString();
              return first.isNotEmpty && last.isNotEmpty;
            },
            reason: 'Both first and last name are required',
          ),
        ],
      );

      // Act: Build form but don't fill fields
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cf.Form(
              controller: controller,
              fields: [compoundField],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger validation with empty fields
      final results = FormResults.getResults(controller: controller);
      await tester.pumpAndSettle(); // Wait for controller notifyListeners timer

      // Assert: Validation should fail
      expect(results.errorState, true,
          reason: 'Validation should fail with empty fields');
      expect(results.formErrors.length, greaterThan(0));
      expect(results.formErrors.first.fieldId, equals('validated'));
      expect(results.formErrors.first.reason,
          equals('Both first and last name are required'));
    });
  });
}
