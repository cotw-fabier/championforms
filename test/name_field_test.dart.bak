import 'package:championforms/championforms.dart' as form;
import 'package:championforms/championforms_themes.dart';
import 'package:championforms/default_fields/name_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Ensure FormFieldRegistry is initialized
  setUpAll(() {
    if (!FormFieldRegistry.instance.isInitialized) {
      FormFieldRegistry.instance.registerCoreBuilders();
    }
  });

  group('NameField Tests', () {
    test('NameField generates firstname and lastname sub-fields by default', () {
      final nameField = NameField(
        id: 'name',
        title: 'Full Name',
      );

      final subFields = nameField.buildSubFields();

      // Should have firstname, middlename, and lastname by default (includeMiddleName: true)
      expect(subFields.length, 3);
      expect(subFields[0].id, 'firstname');
      expect(subFields[1].id, 'middlename');
      expect(subFields[2].id, 'lastname');
    });

    test('NameField with includeMiddleName: false generates only firstname and lastname', () {
      final nameField = NameField(
        id: 'name',
        title: 'Full Name',
        includeMiddleName: false,
      );

      final subFields = nameField.buildSubFields();

      // Should have only firstname and lastname
      expect(subFields.length, 2);
      expect(subFields[0].id, 'firstname');
      expect(subFields[1].id, 'lastname');
    });

    test('NameField with includeMiddleName: true includes middlename', () {
      final nameField = NameField(
        id: 'name',
        title: 'Full Name',
        includeMiddleName: true,
      );

      final subFields = nameField.buildSubFields();

      // Should have firstname, middlename, and lastname
      expect(subFields.length, 3);
      expect(subFields[0].id, 'firstname');
      expect(subFields[1].id, 'middlename');
      expect(subFields[2].id, 'lastname');
    });

    testWidgets('NameField works in Form widget', (WidgetTester tester) async {
      final controller = form.FormController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: form.Form(
              controller: controller,
              fields: [
                NameField(
                  id: 'fullname',
                  title: 'Full Name',
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
      final firstnameValue = controller.getFieldValue<String>('fullname_firstname');
      final middlenameValue = controller.getFieldValue<String>('fullname_middlename');
      final lastnameValue = controller.getFieldValue<String>('fullname_lastname');

      // These should not throw an error (fields exist)
      expect(firstnameValue, isA<String?>());
      expect(middlenameValue, isA<String?>());
      expect(lastnameValue, isA<String?>());
    });
  });
}
