import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/default_fields/address_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ensure FormFieldRegistry is initialized
  setUpAll(() {
    if (!FormFieldRegistry.instance.isInitialized) {
      FormFieldRegistry.instance.registerCoreBuilders();
    }
  });

  group('AddressField Tests', () {
    test('AddressField generates street, city, state, zip sub-fields by default', () {
      final addressField = AddressField(
        id: 'address',
        title: 'Mailing Address',
      );

      final subFields = addressField.buildSubFields();

      // Should have street, street2, city, state, zip by default (includeStreet2: true, includeCountry: false)
      expect(subFields.length, 5);
      expect(subFields[0].id, 'street');
      expect(subFields[1].id, 'street2');
      expect(subFields[2].id, 'city');
      expect(subFields[3].id, 'state');
      expect(subFields[4].id, 'zip');
    });

    test('AddressField with includeStreet2: false excludes street2', () {
      final addressField = AddressField(
        id: 'address',
        title: 'Mailing Address',
        includeStreet2: false,
      );

      final subFields = addressField.buildSubFields();

      // Should not include street2
      expect(subFields.length, 4);
      expect(subFields[0].id, 'street');
      expect(subFields[1].id, 'city');
      expect(subFields[2].id, 'state');
      expect(subFields[3].id, 'zip');
    });

    test('AddressField with includeCountry: true includes country', () {
      final addressField = AddressField(
        id: 'address',
        title: 'Mailing Address',
        includeCountry: true,
      );

      final subFields = addressField.buildSubFields();

      // Should include country at the end
      expect(subFields.length, 6);
      expect(subFields[0].id, 'street');
      expect(subFields[1].id, 'street2');
      expect(subFields[2].id, 'city');
      expect(subFields[3].id, 'state');
      expect(subFields[4].id, 'zip');
      expect(subFields[5].id, 'country');
    });

    test('AddressField with both includeStreet2: false and includeCountry: true', () {
      final addressField = AddressField(
        id: 'address',
        title: 'Mailing Address',
        includeStreet2: false,
        includeCountry: true,
      );

      final subFields = addressField.buildSubFields();

      // Should have street, city, state, zip, country
      expect(subFields.length, 5);
      expect(subFields[0].id, 'street');
      expect(subFields[1].id, 'city');
      expect(subFields[2].id, 'state');
      expect(subFields[3].id, 'zip');
      expect(subFields[4].id, 'country');
    });

    testWidgets('AddressField works in Form widget', (WidgetTester tester) async {
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                AddressField(
                  id: 'home_address',
                  title: 'Home Address',
                ),
              ],
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify sub-fields are registered with prefixed IDs
      // We verify by checking if the field value can be accessed
      final streetValue = controller.getFieldValue<String>('home_address_street');
      final street2Value = controller.getFieldValue<String>('home_address_street2');
      final cityValue = controller.getFieldValue<String>('home_address_city');
      final stateValue = controller.getFieldValue<String>('home_address_state');
      final zipValue = controller.getFieldValue<String>('home_address_zip');

      // These should not throw an error (fields exist)
      expect(streetValue, isA<String?>());
      expect(street2Value, isA<String?>());
      expect(cityValue, isA<String?>());
      expect(stateValue, isA<String?>());
      expect(zipValue, isA<String?>());
    });
  });
}
