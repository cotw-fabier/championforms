import 'package:championforms/championforms.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('FileUploadWidget clearOnUpload integration tests', () {
    testWidgets(
        'clearOnUpload with validateLive triggers validation on new files',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();

      // Validator that requires at least one file
      final fileValidator = Validator(
        validator: (dynamic value) {
          if (value == null || (value as List).isEmpty) {
            return false;
          }
          return true;
        },
        reason: 'At least one file is required',
      );

      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        validateLive: true,
        validators: [fileValidator],
      );

      controller.addFields([field]);

      // Add initial file
      final initialFile = FieldOption(
        label: 'initial.pdf',
        value: 'path/initial.pdf',
        additionalData: FileModel(
          fileName: 'initial.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [initialFile],
        overwrite: true,
      );

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial validation - should pass (has file)
      var results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);

      // Act - Clear files (simulating clearOnUpload behavior)
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation should fail after clearing
      results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, true);
      expect(results.formErrors.length, 1);
      expect(results.formErrors.first.reason, 'At least one file is required');

      // Act - Add new file
      final newFile = FieldOption(
        label: 'new.pdf',
        value: 'path/new.pdf',
        additionalData: FileModel(
          fileName: 'new.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [newFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation should pass with new file
      results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);
    });

    testWidgets(
        'clearOnUpload with custom file type validator clears errors correctly',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();

      // Validator that checks file type
      final pdfOnlyValidator = Validator(
        validator: (dynamic value) {
          if (value == null || (value as List).isEmpty) {
            return true; // Allow empty
          }

          final files = value as List<FieldOption>;
          for (final file in files) {
            final fileModel = file.additionalData as FileModel;
            if (fileModel.uploadExtension?.toLowerCase() != 'pdf') {
              return false;
            }
          }
          return true;
        },
        reason: 'Only PDF files are allowed',
      );

      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        validateLive: true,
        validators: [pdfOnlyValidator],
      );

      controller.addFields([field]);

      // Add initial invalid file (non-PDF)
      final invalidFile = FieldOption(
        label: 'document.txt',
        value: 'path/document.txt',
        additionalData: FileModel(
          fileName: 'document.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [invalidFile],
        overwrite: true,
      );

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Validation should fail (has txt file)
      var results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, true);
      expect(results.formErrors.first.reason, 'Only PDF files are allowed');

      // Act - Clear files and add valid PDF
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      final validFile = FieldOption(
        label: 'document.pdf',
        value: 'path/document.pdf',
        additionalData: FileModel(
          fileName: 'document.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [validFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation error cleared, now passes
      results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);
      expect(results.formErrors.isEmpty, true);
    });

    testWidgets(
        'Sequential uploads with clearOnUpload = true replace files each time',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
      );

      controller.addFields([field]);

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - First upload
      final upload1Files = [
        FieldOption(
          label: 'upload1_file1.txt',
          value: 'path/upload1_file1.txt',
          additionalData: FileModel(
            fileName: 'upload1_file1.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([1]),
          ),
        ),
        FieldOption(
          label: 'upload1_file2.txt',
          value: 'path/upload1_file2.txt',
          additionalData: FileModel(
            fileName: 'upload1_file2.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([2]),
          ),
        ),
      ];
      controller.updateMultiselectValues(
        field.id,
        upload1Files,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - First upload
      var currentFiles =
          controller.getFieldValue<List<FieldOption>>(field.id);
      expect(currentFiles?.length, 2);
      expect(currentFiles?.map((f) => f.label).toList(),
          ['upload1_file1.txt', 'upload1_file2.txt']);

      // Act - Second upload (simulate clearOnUpload behavior)
      controller.updateMultiselectValues(field.id, [], overwrite: true);
      await tester.pumpAndSettle();

      final upload2Files = [
        FieldOption(
          label: 'upload2_file1.txt',
          value: 'path/upload2_file1.txt',
          additionalData: FileModel(
            fileName: 'upload2_file1.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([3]),
          ),
        ),
      ];
      controller.updateMultiselectValues(
        field.id,
        upload2Files,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Second upload replaced first
      currentFiles = controller.getFieldValue<List<FieldOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'upload2_file1.txt');

      // Act - Third upload (simulate clearOnUpload behavior)
      controller.updateMultiselectValues(field.id, [], overwrite: true);
      await tester.pumpAndSettle();

      final upload3Files = [
        FieldOption(
          label: 'upload3_file1.txt',
          value: 'path/upload3_file1.txt',
          additionalData: FileModel(
            fileName: 'upload3_file1.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([4]),
          ),
        ),
        FieldOption(
          label: 'upload3_file2.txt',
          value: 'path/upload3_file2.txt',
          additionalData: FileModel(
            fileName: 'upload3_file2.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([5]),
          ),
        ),
        FieldOption(
          label: 'upload3_file3.txt',
          value: 'path/upload3_file3.txt',
          additionalData: FileModel(
            fileName: 'upload3_file3.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([6]),
          ),
        ),
      ];
      controller.updateMultiselectValues(
        field.id,
        upload3Files,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Third upload replaced second
      currentFiles = controller.getFieldValue<List<FieldOption>>(field.id);
      expect(currentFiles?.length, 3);
      expect(
          currentFiles?.map((f) => f.label).toList(),
          [
            'upload3_file1.txt',
            'upload3_file2.txt',
            'upload3_file3.txt'
          ]);
    });

    testWidgets(
        'clearOnUpload with multiple validators clears all errors',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();

      // Multiple validators
      final minFilesValidator = Validator(
        validator: (dynamic value) {
          if (value == null || (value as List).length < 2) {
            return false;
          }
          return true;
        },
        reason: 'At least 2 files required',
      );

      final maxFilesValidator = Validator(
        validator: (dynamic value) {
          if (value != null && (value as List).length > 5) {
            return false;
          }
          return true;
        },
        reason: 'Maximum 5 files allowed',
      );

      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        validateLive: true,
        validators: [minFilesValidator, maxFilesValidator],
      );

      controller.addFields([field]);

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Add only 1 file (violates minFilesValidator)
      final singleFile = [
        FieldOption(
          label: 'single.txt',
          value: 'path/single.txt',
          additionalData: FileModel(
            fileName: 'single.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([1]),
          ),
        ),
      ];
      controller.updateMultiselectValues(
        field.id,
        singleFile,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation fails
      var results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, true);
      expect(results.formErrors.first.reason, 'At least 2 files required');

      // Act - Clear and add 3 valid files
      controller.updateMultiselectValues(field.id, [], overwrite: true);
      await tester.pumpAndSettle();

      final validFiles = [
        FieldOption(
          label: 'file1.txt',
          value: 'path/file1.txt',
          additionalData: FileModel(
            fileName: 'file1.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([1]),
          ),
        ),
        FieldOption(
          label: 'file2.txt',
          value: 'path/file2.txt',
          additionalData: FileModel(
            fileName: 'file2.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([2]),
          ),
        ),
        FieldOption(
          label: 'file3.txt',
          value: 'path/file3.txt',
          additionalData: FileModel(
            fileName: 'file3.txt',
            uploadExtension: 'txt',
            fileBytes: Uint8List.fromList([3]),
          ),
        ),
      ];
      controller.updateMultiselectValues(
        field.id,
        validFiles,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation passes
      results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);
      expect(results.formErrors.isEmpty, true);
    });

    testWidgets(
        'clearOnUpload clears previous validation errors with new upload',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();

      final sizeValidator = Validator(
        validator: (dynamic value) {
          if (value != null) {
            final files = value as List<FieldOption>;
            for (final file in files) {
              final fileModel = file.additionalData as FileModel;
              // Simulating size check - files with > 100 bytes fail
              if (fileModel.fileBytes != null && fileModel.fileBytes!.length > 100) {
                return false;
              }
            }
          }
          return true;
        },
        reason: 'File size too large',
      );

      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        validateLive: true,
        validators: [sizeValidator],
      );

      controller.addFields([field]);

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Add large file (fails validation)
      final largeFile = FieldOption(
        label: 'large.txt',
        value: 'path/large.txt',
        additionalData: FileModel(
          fileName: 'large.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList(List.generate(150, (i) => i)),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [largeFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Validation fails
      var results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, true);
      expect(results.formErrors.first.reason, 'File size too large');

      // Act - Clear and upload small file (simulate clearOnUpload)
      controller.updateMultiselectValues(field.id, [], overwrite: true);
      await tester.pumpAndSettle();

      final smallFile = FieldOption(
        label: 'small.txt',
        value: 'path/small.txt',
        additionalData: FileModel(
          fileName: 'small.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [smallFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Previous error cleared, validation passes
      results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);
      expect(results.formErrors.isEmpty, true);

      // Verify only small file present
      final currentFiles =
          controller.getFieldValue<List<FieldOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'small.txt');
    });

    testWidgets(
        'clearOnUpload = true with validateLive and displayUploadedFiles updates UI correctly',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();

      final fileRequiredValidator = Validator(
        validator: (dynamic value) {
          if (value == null || (value as List).isEmpty) {
            return false;
          }
          return true;
        },
        reason: 'File is required',
      );

      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        validateLive: true,
        displayUploadedFiles: true,
        validators: [fileRequiredValidator],
      );

      controller.addFields([field]);

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadWidget(
              id: field.id,
              controller: controller,
              field: field,
              currentColors: const FieldColorScheme(),
              onFocusChange: (_) {},
              onFileOptionChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Add first file
      final file1 = FieldOption(
        label: 'document1.pdf',
        value: 'path/document1.pdf',
        additionalData: FileModel(
          fileName: 'document1.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [file1],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - First file visible
      expect(find.text('document1.pdf'), findsOneWidget);

      // Act - Clear and add new file (simulate clearOnUpload)
      controller.updateMultiselectValues(field.id, [], overwrite: true);
      await tester.pumpAndSettle();

      final file2 = FieldOption(
        label: 'document2.pdf',
        value: 'path/document2.pdf',
        additionalData: FileModel(
          fileName: 'document2.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [file2],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Only new file visible, old file gone
      expect(find.text('document2.pdf'), findsOneWidget);
      expect(find.text('document1.pdf'), findsNothing);

      // Assert - Validation passes
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );
      expect(results.errorState, false);
    });
  });
}
