import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/default_fields/name_field.dart';
import 'package:championforms/default_fields/address_field.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/textfield.dart' as cf_field;
import 'package:championforms/models/formbuildererrorclass.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Custom compound field for testing custom layouts
class CustomLayoutField extends CompoundField {
  CustomLayoutField({required String id}) : super(id: id);

  @override
  List<form.Field> buildSubFields() {
    return [
      cf_field.TextField(id: 'part1', title: 'Part 1'),
      cf_field.TextField(id: 'part2', title: 'Part 2'),
    ];
  }

  @override
  CustomLayoutField copyWith({
    String? id,
    String? title,
    String? description,
    bool? disabled,
    bool? hideField,
    bool? rollUpErrors,
    FormTheme? theme,
    List<form.Validator>? validators,
    bool? validateLive,
    Function(form.FormResults results)? onSubmit,
    Function(form.FormResults results)? onChange,
    Widget? icon,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldLayout,
    Widget Function(
      BuildContext context,
      form.Field fieldDetails,
      form.FormController controller,
      FieldColorScheme currentColors,
      Widget renderedField,
    )? fieldBackground,
    bool? requestFocus,
  }) {
    return CustomLayoutField(
      id: id ?? this.id,
    );
  }
}

/// Full integration tests for compound field feature covering complete workflows
///
/// These tests fill critical gaps in test coverage focusing on:
/// - Full forms with multiple compound fields
/// - Mixed standard and compound fields
/// - Results retrieval patterns
/// - Custom layouts
/// - Dynamic configuration
void main() {
  setUpAll(() {
    if (!FormFieldRegistry.instance.isInitialized) {
      FormFieldRegistry.instance.registerCoreBuilders();
    }
  });

  group('Full Form Integration Tests', () {
    testWidgets('Full form with NameField and AddressField together',
        (WidgetTester tester) async {
      // Arrange
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                NameField(
                  id: 'customer_name',
                  title: 'Customer Name',
                ),
                AddressField(
                  id: 'shipping_address',
                  title: 'Shipping Address',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Update values in both compound fields
      controller.updateFieldValue('customer_name_firstname', 'John');
      controller.updateFieldValue('customer_name_middlename', 'Q');
      controller.updateFieldValue('customer_name_lastname', 'Public');
      controller.updateFieldValue('shipping_address_street', '123 Main St');
      controller.updateFieldValue('shipping_address_city', 'Springfield');
      controller.updateFieldValue('shipping_address_state', 'IL');
      controller.updateFieldValue('shipping_address_zip', '62701');
      await tester.pumpAndSettle();

      // Get results
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      // Assert: Both compound fields should be accessible
      final fullName = results.grab('customer_name').asCompound(delimiter: ' ');
      final fullAddress =
          results.grab('shipping_address').asCompound(delimiter: ', ');

      expect(fullName, 'John Q Public');
      expect(fullAddress, contains('123 Main St'));
      expect(fullAddress, contains('Springfield'));

      // Verify individual sub-field access
      expect(
          results.grab('customer_name_firstname').asString(), equals('John'));
      expect(
          results.grab('shipping_address_city').asString(), equals('Springfield'));

      controller.dispose();
    });

    testWidgets('Mixed form with compound fields and standard TextField',
        (WidgetTester tester) async {
      // Arrange
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                cf_field.TextField(
                  id: 'email',
                  title: 'Email Address',
                ),
                NameField(
                  id: 'name',
                  includeMiddleName: false,
                ),
                cf_field.TextField(
                  id: 'phone',
                  title: 'Phone Number',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Update mixed field types
      controller.updateFieldValue('email', 'test@example.com');
      controller.updateFieldValue('name_firstname', 'Jane');
      controller.updateFieldValue('name_lastname', 'Doe');
      controller.updateFieldValue('phone', '555-1234');
      await tester.pumpAndSettle();

      // Get results
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      // Assert: Both standard and compound fields work together
      expect(results.grab('email').asString(), equals('test@example.com'));
      expect(results.grab('name').asCompound(delimiter: ' '), equals('Jane Doe'));
      expect(results.grab('phone').asString(), equals('555-1234'));

      // Verify all fields are in activeFields
      final activeFieldIds = controller.activeFields.map((f) => f.id).toList();
      expect(activeFieldIds, contains('email'));
      expect(activeFieldIds, contains('name_firstname'));
      expect(activeFieldIds, contains('name_lastname'));
      expect(activeFieldIds, contains('phone'));
      expect(activeFieldIds.length, equals(4)); // email, name_firstname, name_lastname, phone

      controller.dispose();
    });

    testWidgets('Results access with different delimiters',
        (WidgetTester tester) async {
      // Arrange
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                NameField(
                  id: 'author',
                  includeMiddleName: true,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Set values
      controller.updateFieldValue('author_firstname', 'Charles');
      controller.updateFieldValue('author_middlename', 'M');
      controller.updateFieldValue('author_lastname', 'Schulz');
      await tester.pumpAndSettle();

      // Get results
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      // Assert: Different delimiters produce different outputs
      expect(results.grab('author').asCompound(delimiter: ' '),
          equals('Charles M Schulz'));
      expect(results.grab('author').asCompound(delimiter: ', '),
          equals('Charles, M, Schulz'));
      expect(results.grab('author').asCompound(delimiter: '-'),
          equals('Charles-M-Schulz'));
      expect(results.grab('author').asCompound(delimiter: ''),
          equals('CharlesMSchulz'));

      controller.dispose();
    });
  });

  group('Theme and State Propagation Integration Tests', () {
    testWidgets('Theme propagation from compound field to all sub-fields',
        (WidgetTester tester) async {
      // Arrange
      final customTheme = FormTheme(
        colorScheme: FieldColorScheme(
          backgroundColor: Colors.blue.shade50,
          textColor: Colors.blue.shade900,
          borderColor: Colors.blue,
        ),
      );

      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                NameField(
                  id: 'styled_name',
                  theme: customTheme,
                  includeMiddleName: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Verify theme was propagated to sub-fields
      final firstNameField = controller.activeFields
          .firstWhere((f) => f.id == 'styled_name_firstname');
      final lastNameField = controller.activeFields
          .firstWhere((f) => f.id == 'styled_name_lastname');

      expect(firstNameField.theme, equals(customTheme));
      expect(lastNameField.theme, equals(customTheme));

      controller.dispose();
    });

    testWidgets('Disabled state propagation from compound field',
        (WidgetTester tester) async {
      // Arrange
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                AddressField(
                  id: 'locked_address',
                  disabled: true,
                  includeStreet2: false,
                  includeCountry: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: All sub-fields should be disabled
      final activeFields = controller.activeFields
          .where((f) => f.id.startsWith('locked_address_'))
          .toList();

      expect(activeFields.isNotEmpty, isTrue);
      for (final field in activeFields) {
        expect(field.disabled, isTrue,
            reason: 'Field ${field.id} should be disabled');
      }

      controller.dispose();
    });
  });

  group('Custom Layout Builder Integration Tests', () {
    testWidgets('Compound field with custom layout builder override',
        (WidgetTester tester) async {
      // Arrange: Register with custom layout
      FormFieldRegistry.registerCompound<CustomLayoutField>(
        'customLayout',
        (field) => field.buildSubFields(),
        (context, subFields, errors) {
          // Custom horizontal layout with specific keys for testing
          return Row(
            key: const Key('custom_layout_row'),
            children: [
              Expanded(
                key: const Key('custom_layout_part1'),
                child: subFields[0],
              ),
              const SizedBox(width: 20),
              Expanded(
                key: const Key('custom_layout_part2'),
                child: subFields[1],
              ),
            ],
          );
        },
      );

      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                CustomLayoutField(id: 'custom'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: Custom layout should be rendered
      expect(find.byKey(const Key('custom_layout_row')), findsOneWidget);
      expect(find.byKey(const Key('custom_layout_part1')), findsOneWidget);
      expect(find.byKey(const Key('custom_layout_part2')), findsOneWidget);

      // Verify fields are functional
      controller.updateFieldValue('custom_part1', 'Value 1');
      controller.updateFieldValue('custom_part2', 'Value 2');
      await tester.pumpAndSettle();

      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );

      expect(results.grab('custom_part1').asString(), equals('Value 1'));
      expect(results.grab('custom_part2').asString(), equals('Value 2'));
      expect(
          results.grab('custom').asCompound(delimiter: ' | '), equals('Value 1 | Value 2'));

      controller.dispose();
    });
  });

  group('Dynamic Configuration Tests', () {
    test('NameField sub-field count varies with includeMiddleName',
        () {
      // Test without middle name
      final nameField1 = NameField(
        id: 'name1',
        includeMiddleName: false,
      );
      expect(nameField1.buildSubFields().length, equals(2));

      // Test with middle name
      final nameField2 = NameField(
        id: 'name2',
        includeMiddleName: true,
      );
      expect(nameField2.buildSubFields().length, equals(3));
    });

    test('AddressField sub-field count varies with configuration options',
        () {
      // Default: street2 included, country excluded
      final addressField1 = AddressField(
        id: 'addr1',
        includeStreet2: true,
        includeCountry: false,
      );
      expect(addressField1.buildSubFields().length, equals(5)); // street, street2, city, state, zip

      // No street2, with country
      final addressField2 = AddressField(
        id: 'addr2',
        includeStreet2: false,
        includeCountry: true,
      );
      final subFields2 = addressField2.buildSubFields();
      expect(subFields2.length, equals(5)); // street, city, state, zip, country

      // Verify field IDs
      final fieldIds = subFields2.map((f) => f.id).toList();
      expect(fieldIds, contains('country'));
      expect(fieldIds, isNot(contains('street2')));
    });
  });
}
