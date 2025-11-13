import 'package:championforms/championforms.dart' as form;
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/compound_field_registration.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test implementation of CompoundField for testing purposes
class TestCompoundField extends CompoundField {
  final List<form.Field> subFields;

  TestCompoundField({
    required String id,
    this.subFields = const [],
    String? title,
    String? description,
  }) : super(
          id: id,
          title: title,
          description: description,
        );

  @override
  List<form.Field> buildSubFields() {
    return subFields;
  }
}

/// Another test compound field type for multi-registration tests
class AnotherCompoundField extends CompoundField {
  AnotherCompoundField({required String id}) : super(id: id);

  @override
  List<form.Field> buildSubFields() => [];
}

void main() {
  group('CompoundField Base Class Tests', () {
    test('CompoundField instantiation with sub-field definitions', () {
      // Create a compound field with sub-fields
      final compoundField = TestCompoundField(
        id: 'test_compound',
        title: 'Test Compound Field',
        description: 'A test compound field',
        subFields: [
          form.TextField(id: 'field1', title: 'Field 1'),
          form.TextField(id: 'field2', title: 'Field 2'),
        ],
      );

      expect(compoundField.id, 'test_compound');
      expect(compoundField.title, 'Test Compound Field');
      expect(compoundField.description, 'A test compound field');

      final subFields = compoundField.buildSubFields();
      expect(subFields.length, 2);
      expect(subFields[0].id, 'field1');
      expect(subFields[1].id, 'field2');
    });

    test('Sub-field ID prefixing logic', () {
      final compoundField = TestCompoundField(
        id: 'address',
        subFields: [
          form.TextField(id: 'street', title: 'Street'),
          form.TextField(id: 'city', title: 'City'),
        ],
      );

      // Get prefixed IDs
      final prefixedIds = compoundField.getPrefixedSubFieldIds();

      expect(prefixedIds.length, 2);
      expect(prefixedIds[0], 'address_street');
      expect(prefixedIds[1], 'address_city');
    });

    test('Sub-field ID prefixing with already prefixed ID', () {
      // Test that already prefixed IDs are not double-prefixed
      final compoundField = TestCompoundField(
        id: 'address',
        subFields: [
          form.TextField(id: 'address_street', title: 'Street'),
          form.TextField(id: 'city', title: 'City'),
        ],
      );

      final prefixedIds = compoundField.getPrefixedSubFieldIds();

      expect(prefixedIds.length, 2);
      expect(prefixedIds[0], 'address_street'); // Should not be double-prefixed
      expect(prefixedIds[1], 'address_city');
    });
  });

  group('FormFieldRegistry.registerCompound Tests', () {
    setUp(() {
      // Clear any previous registrations before each test
      FormFieldRegistry.instance.clearCompoundRegistrations();
    });

    test('registerCompound<T>() method registration', () {
      // Register a compound field type
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null, // No custom layout
        rollUpErrors: false,
      );

      // Verify registration
      expect(FormFieldRegistry.hasCompoundBuilderFor<TestCompoundField>(), true);
    });

    test('Type safety with generic T extends CompoundField', () {
      // This test verifies type safety at compile time
      // If this compiles, the type safety is working
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (TestCompoundField field) => field.buildSubFields(),
        null,
      );

      expect(FormFieldRegistry.hasCompoundBuilderFor<TestCompoundField>(), true);
    });

    test('Registration lookup for compound fields', () {
      // Register a compound field
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => [
          form.TextField(id: 'sub1', title: 'Sub Field 1'),
          form.TextField(id: 'sub2', title: 'Sub Field 2'),
        ],
        null,
      );

      // Check if registration exists
      expect(FormFieldRegistry.hasCompoundBuilderFor<TestCompoundField>(), true);

      // Check that non-registered compound types return false
      expect(FormFieldRegistry.hasCompoundBuilderFor<AnotherCompoundField>(), false);
    });

    test('Compound field builder storage and retrieval', () {
      // Custom layout builder
      Widget customLayout(BuildContext context, List<Widget> subFields,
          List<FormBuilderError>? errors) {
        return Column(children: subFields);
      }

      // Register with custom layout
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        customLayout,
        rollUpErrors: true,
      );

      // Retrieve registration
      final registration =
          FormFieldRegistry.instance.getCompoundRegistration<TestCompoundField>();

      expect(registration, isNotNull);
      expect(registration!.typeName, 'testCompound');
      expect(registration.rollUpErrors, true);
      expect(registration.layoutBuilder, isNotNull);
    });

    test('Multiple compound field registrations', () {
      // Register multiple types
      FormFieldRegistry.registerCompound<TestCompoundField>(
        'testCompound',
        (field) => field.buildSubFields(),
        null,
      );

      FormFieldRegistry.registerCompound<AnotherCompoundField>(
        'anotherCompound',
        (field) => field.buildSubFields(),
        null,
      );

      // Both should be registered
      expect(FormFieldRegistry.hasCompoundBuilderFor<TestCompoundField>(), true);
      expect(
          FormFieldRegistry.hasCompoundBuilderFor<AnotherCompoundField>(), true);
    });
  });

  group('Default Layout Builder Tests', () {
    testWidgets('Default vertical layout builder stacks sub-fields',
        (WidgetTester tester) async {
      // Create sub-field widgets
      final subFields = [
        Container(key: const Key('field1'), height: 50),
        Container(key: const Key('field2'), height: 50),
        Container(key: const Key('field3'), height: 50),
      ];

      // Build using default layout - wrap in Builder to get context
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return CompoundField.buildDefaultCompoundLayout(
                  context,
                  subFields,
                  null,
                );
              },
            ),
          ),
        ),
      );

      // Verify all sub-fields are present
      expect(find.byKey(const Key('field1')), findsOneWidget);
      expect(find.byKey(const Key('field2')), findsOneWidget);
      expect(find.byKey(const Key('field3')), findsOneWidget);
    });

    testWidgets('Default layout shows errors when rollUpErrors is true',
        (WidgetTester tester) async {
      final subFields = [
        Container(key: const Key('field1'), height: 50),
      ];

      final errors = [
        const FormBuilderError(
          reason: 'Error 1',
          fieldId: 'test_field',
          validatorPosition: 0,
        ),
        const FormBuilderError(
          reason: 'Error 2',
          fieldId: 'test_field',
          validatorPosition: 1,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return CompoundField.buildDefaultCompoundLayout(
                  context,
                  subFields,
                  errors,
                );
              },
            ),
          ),
        ),
      );

      // Verify error messages are displayed
      expect(find.text('Error 1'), findsOneWidget);
      expect(find.text('Error 2'), findsOneWidget);
    });
  });
}
