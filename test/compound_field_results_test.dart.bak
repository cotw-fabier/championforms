import 'package:championforms/championforms.dart' as form;
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/field_types/textfield.dart' as cf_field;
import 'package:championforms/models/validatorclass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test helper compound field for results testing
class TestNameField extends CompoundField {
  final bool includeMiddleName;

  TestNameField({
    required String id,
    this.includeMiddleName = true,
    bool rollUpErrors = false,
    List<form.Validator>? validators,
  }) : super(
          id: id,
          rollUpErrors: rollUpErrors,
          validators: validators,
        );

  @override
  List<form.Field> buildSubFields() {
    final fields = <form.Field>[
      cf_field.TextField(
        id: 'firstname',
        title: 'First Name',
      ),
      cf_field.TextField(
        id: 'lastname',
        title: 'Last Name',
      ),
    ];

    if (includeMiddleName) {
      fields.insert(
        1,
        cf_field.TextField(
          id: 'middlename',
          title: 'Middle Name',
        ),
      );
    }

    return fields;
  }
}

void main() {
  // Register test compound field before tests
  setUpAll(() {
    FormFieldRegistry.registerCompound<TestNameField>(
      'testNameField',
      (field) => field.buildSubFields(),
      CompoundField.buildDefaultCompoundLayout,
    );
  });

  group('Compound Field Results Access', () {
    test('asCompound() joins sub-field values with default delimiter', () async {
      // Arrange
      final controller = form.FormController();

      // Create field definitions
      final fields = [
        cf_field.TextField(id: 'name_firstname'),
        cf_field.TextField(id: 'name_middlename'),
        cf_field.TextField(id: 'name_lastname'),
      ];

      // Create field values THEN register fields
      controller.createFieldValue('name_firstname', 'John');
      controller.createFieldValue('name_middlename', 'Michael');
      controller.createFieldValue('name_lastname', 'Doe');
      
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      final fullName = results.grab('name').asCompound();

      // Assert
      expect(fullName, 'John, Michael, Doe');
    });

    test('asCompound() joins sub-field values with custom delimiter', () async {
      // Arrange
      final controller = form.FormController();

      final fields = [
        cf_field.TextField(id: 'name_firstname'),
        cf_field.TextField(id: 'name_lastname'),
      ];

      controller.createFieldValue('name_firstname', 'Jane');
      controller.createFieldValue('name_lastname', 'Smith');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      final fullName = results.grab('name').asCompound(delimiter: ' ');

      // Assert
      expect(fullName, 'Jane Smith');
    });

    test('asCompound() detects compound fields by sub-field ID pattern',
        () async {
      // Arrange
      final controller = form.FormController();

      final fields = [
        cf_field.TextField(id: 'name_firstname'),
        cf_field.TextField(id: 'name_lastname'),
        cf_field.TextField(id: 'email'),
      ];

      controller.createFieldValue('name_firstname', 'Alice');
      controller.createFieldValue('name_lastname', 'Johnson');
      controller.createFieldValue('email', 'alice@example.com');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      final fullName = results.grab('name').asCompound();
      // Calling asCompound on a non-compound field should return fallback
      final emailAsCompound =
          results.grab('email').asCompound(fallback: 'NOT_COMPOUND');

      // Assert
      expect(fullName, 'Alice, Johnson');
      expect(emailAsCompound, 'NOT_COMPOUND');
    });

    test('asCompound() filters out empty sub-field values', () async {
      // Arrange
      final controller = form.FormController();

      final fields = [
        cf_field.TextField(id: 'name_firstname'),
        cf_field.TextField(id: 'name_middlename'),
        cf_field.TextField(id: 'name_lastname'),
      ];

      controller.createFieldValue('name_firstname', 'Bob');
      controller.createFieldValue('name_middlename', ''); // Empty
      controller.createFieldValue('name_lastname', 'Brown');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      final fullName = results.grab('name').asCompound();

      // Assert
      // Should only include non-empty values
      expect(fullName, 'Bob, Brown');
    });

    test('individual sub-field access via grab() works correctly', () async {
      // Arrange
      final controller = form.FormController();

      final fields = [
        cf_field.TextField(id: 'address_street'),
        cf_field.TextField(id: 'address_city'),
        cf_field.TextField(id: 'address_zip'),
      ];

      controller.createFieldValue('address_street', '123 Main St');
      controller.createFieldValue('address_city', 'New York');
      controller.createFieldValue('address_zip', '10001');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      final street = results.grab('address_street').asString();
      final city = results.grab('address_city').asString();
      final zip = results.grab('address_zip').asString();
      final fullAddress = results.grab('address').asCompound();

      // Assert
      expect(street, '123 Main St');
      expect(city, 'New York');
      expect(zip, '10001');
      expect(fullAddress, '123 Main St, New York, 10001');
    });

    test('validation executes independently on each sub-field', () async {
      // Arrange
      final controller = form.FormController();

      // Create sub-fields with validators
      final firstnameField = cf_field.TextField(
        id: 'name_firstname',
        validators: [
          form.Validator(
            validator: (value) {
              if (value == null || value.toString().isEmpty) {
                return false;
              }
              return true;
            },
            reason: 'First name is required',
          ),
        ],
      );

      final lastnameField = cf_field.TextField(
        id: 'name_lastname',
        validators: [
          form.Validator(
            validator: (value) {
              if (value == null || value.toString().isEmpty) {
                return false;
              }
              return true;
            },
            reason: 'Last name is required',
          ),
        ],
      );

      final fields = [firstnameField, lastnameField];

      controller.createFieldValue('name_firstname', 'Charlie');
      controller.createFieldValue('name_lastname', '');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: true,
      );

      // Assert
      expect(results.errorState, true);
      expect(results.formErrors.length, 1);
      expect(results.formErrors[0].fieldId, 'name_lastname');
      expect(results.formErrors[0].reason, 'Last name is required');

      // Verify error is stored under the correct sub-field ID in controller
      final lastnameErrors = controller.findErrors('name_lastname');
      expect(lastnameErrors.length, 1);
      expect(lastnameErrors[0].reason, 'Last name is required');
    });
  });

  group('Compound Field Error Rollup', () {
    test('error rollup collects errors from all sub-fields', () async {
      // Arrange
      final controller = form.FormController();

      // Create sub-fields with validators
      final firstnameField = cf_field.TextField(
        id: 'name_firstname',
        validators: [
          form.Validator(
            validator: (value) =>
                value != null && value.toString().isNotEmpty,
            reason: 'First name is required',
          ),
        ],
      );

      final lastnameField = cf_field.TextField(
        id: 'name_lastname',
        validators: [
          form.Validator(
            validator: (value) =>
                value != null && value.toString().isNotEmpty,
            reason: 'Last name is required',
          ),
        ],
      );

      final fields = [firstnameField, lastnameField];

      controller.createFieldValue('name_firstname', '');
      controller.createFieldValue('name_lastname', '');
      controller.addFields(fields);
      controller.updateActiveFields(fields);

      // Act - get results with validation
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: true,
      );

      // Assert
      expect(results.errorState, true);
      expect(results.formErrors.length, 2);

      // Verify both sub-field errors are captured
      final firstnameErrors = controller.findErrors('name_firstname');
      final lastnameErrors = controller.findErrors('name_lastname');

      expect(firstnameErrors.length, 1);
      expect(firstnameErrors[0].reason, 'First name is required');

      expect(lastnameErrors.length, 1);
      expect(lastnameErrors[0].reason, 'Last name is required');

      // Note: The actual error display is handled by the Form widget's
      // _buildCompoundField method, which collects these errors and passes
      // them to the layout builder when rollUpErrors is true.
    });
  });
}
