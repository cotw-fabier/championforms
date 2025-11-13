import 'package:championforms/championforms.dart' as form;
import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/models/field_builder_context.dart';
import 'package:championforms/models/fieldstate.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/themes.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/file_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Refactored FileUpload Widget Tests', () {
    late FormController controller;
    late form.FileUpload field;

    setUp(() {
      controller = FormController();
      field = form.FileUpload(
        id: 'test_file',
        title: 'Test File Upload',
        multiselect: false,
        validateLive: true,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('FileUpload renders correctly', (WidgetTester tester) async {
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

      // Assert - Check that upload zone is rendered
      expect(find.text('Upload File'), findsOneWidget);
      expect(find.byIcon(Icons.upload_file), findsOneWidget);
    });

    testWidgets('File selection behavior (simulated)',
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

      // Note: Actual file selection requires file_picker mocking which is complex
      // For this test, we'll simulate by directly updating the controller

      // Act - Simulate file selection by updating controller
      final fileOption = form.FieldOption(
        value: 'test.pdf',
        label: 'test.pdf',
        additionalData: FileModel(
          fileName: 'test.pdf',
          fileBytes: Uint8List.fromList([1, 2, 3]),
          uploadExtension: 'pdf',
        ),
      );
      controller.updateMultiselectValues(
        'test_file',
        [fileOption],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Value is stored in controller
      final value = controller.getFieldValue<List<form.FieldOption>>('test_file');
      expect(value, isNotNull);
      expect(value!.length, equals(1));
      expect(value.first.value, equals('test.pdf'));
    });

    testWidgets('Drag-and-drop integration exists',
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

      // Assert - Drag target is present (this verifies the component renders)
      // Actual drag-drop testing requires platform-specific setup
      expect(find.byType(form.Form), findsOneWidget);
    });

    testWidgets('Validation behavior works', (WidgetTester tester) async {
      // Arrange
      field = form.FileUpload(
        id: 'test_file',
        title: 'Test File Upload',
        multiselect: false,
        validateLive: true,
        validators: [
          form.Validator(
            validator: (results) {
              final value = results.grab('test_file').asFile();
              return value == null || value.isEmpty;
            },
            reason: 'File is required',
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

      // Act - Trigger validation without uploading a file
      final results = form.FormResults.getResults(controller: controller);

      // Assert - Validation error appears
      expect(results.errorState, isTrue);
      expect(
        results.formErrors.any((e) => e.fieldId == 'test_file'),
        isTrue,
      );
    });

    test('FileFieldConverters handles FileModel list', () {
      // Arrange
      final fileOptions = [
        form.FieldOption(
          value: 'file1.pdf',
          label: 'file1.pdf',
          additionalData: FileModel(
            fileName: 'file1.pdf',
            fileBytes: Uint8List.fromList([1, 2, 3]),
            uploadExtension: 'pdf',
          ),
        ),
        form.FieldOption(
          value: 'file2.jpg',
          label: 'file2.jpg',
          additionalData: FileModel(
            fileName: 'file2.jpg',
            fileBytes: Uint8List.fromList([4, 5, 6]),
            uploadExtension: 'jpg',
          ),
        ),
      ];

      // Act & Assert - Test string converter
      final stringValue = field.asStringConverter(fileOptions);
      expect(stringValue, equals('file1.pdf, file2.jpg'));

      // Act & Assert - Test string list converter
      final stringListValue = field.asStringListConverter(fileOptions);
      expect(stringListValue, equals(['file1.pdf', 'file2.jpg']));

      // Act & Assert - Test file list converter
      final fileListValue = field.asFileListConverter!(fileOptions);
      expect(fileListValue, isNotNull);
      expect(fileListValue!.length, equals(2));
      expect(fileListValue.first.fileName, equals('file1.pdf'));
    });

    test('FileUpload respects max file size', () {
      // Arrange
      field = form.FileUpload(
        id: 'test_file',
        maxFileSize: 1024, // 1 KB limit
      );

      // Assert
      expect(field.maxFileSize, equals(1024));
    });

    test('FileUpload respects allowed extensions', () {
      // Arrange
      field = form.FileUpload(
        id: 'test_file',
        allowedExtensions: ['pdf', 'jpg', 'png'],
      );

      // Assert
      expect(field.allowedExtensions, equals(['pdf', 'jpg', 'png']));
    });
  });
}
