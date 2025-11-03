import 'package:championforms/championforms.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/mime_data.dart';
import 'package:championforms/models/field_types/textfield.dart' as cf;
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/material.dart' hide TextField;
import 'package:flutter/widgets.dart' hide Column;
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('FormResults.grab() API verification', () {
    testWidgets('asFile() returns single FileModel for single file upload',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'single_file',
        multiselect: false,
      );

      controller.addFields([field]);

      // Act - Add single file
      final testFile = FileModel(
        fileName: 'test.pdf',
        uploadExtension: 'pdf',
        fileBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        mimeData: MimeData(
          extension: 'pdf',
          mime: 'application/pdf',
        ),
      );

      final fileOption = FieldOption(
        label: 'test.pdf',
        value: 'path/test.pdf',
        additionalData: testFile,
      );

      controller.updateMultiselectValues(
        field.id,
        [fileOption],
        overwrite: true,
      );

      // Get results
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );

      // Assert - asFile() returns FileModel
      final retrievedFile = results.grab(field.id).asFile();
      expect(retrievedFile, isNotNull);
      expect(retrievedFile, isA<FileModel>());
      expect(retrievedFile?.fileName, 'test.pdf');
      expect(retrievedFile?.uploadExtension, 'pdf');
      expect(retrievedFile?.fileBytes, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
      expect(retrievedFile?.mimeData?.mime, 'application/pdf');
    });

    testWidgets('asFile() returns null for empty file field',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'empty_file',
        multiselect: false,
      );

      controller.addFields([field]);

      // Get results without adding files
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );

      // Assert - asFile() returns null
      final retrievedFile = results.grab(field.id).asFile();
      expect(retrievedFile, isNull);
    });

    testWidgets(
        'asFile() returns first file when multiple files in multiselect field',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'multi_file',
        multiselect: true,
      );

      controller.addFields([field]);

      // Act - Add multiple files
      final file1 = FileModel(
        fileName: 'first.txt',
        uploadExtension: 'txt',
        fileBytes: Uint8List.fromList([1, 2, 3]),
      );

      final file2 = FileModel(
        fileName: 'second.txt',
        uploadExtension: 'txt',
        fileBytes: Uint8List.fromList([4, 5, 6]),
      );

      final fileOptions = [
        FieldOption(
          label: 'first.txt',
          value: 'path/first.txt',
          additionalData: file1,
        ),
        FieldOption(
          label: 'second.txt',
          value: 'path/second.txt',
          additionalData: file2,
        ),
      ];

      controller.updateMultiselectValues(
        field.id,
        fileOptions,
        overwrite: true,
      );

      // Get results
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );

      // Assert - asFile() returns first file
      final retrievedFile = results.grab(field.id).asFile();
      expect(retrievedFile, isNotNull);
      expect(retrievedFile?.fileName, 'first.txt');
    });

    testWidgets('asFileList() returns List<FileModel> for multiselect upload',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'multi_files',
        multiselect: true,
      );

      controller.addFields([field]);

      // Act - Add multiple files
      final files = [
        FileModel(
          fileName: 'doc1.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([1, 2, 3]),
          mimeData: MimeData(
            extension: 'pdf',
            mime: 'application/pdf',
          ),
        ),
        FileModel(
          fileName: 'doc2.pdf',
          uploadExtension: 'pdf',
          fileBytes: Uint8List.fromList([4, 5, 6]),
          mimeData: MimeData(
            extension: 'pdf',
            mime: 'application/pdf',
          ),
        ),
        FileModel(
          fileName: 'image.png',
          uploadExtension: 'png',
          fileBytes: Uint8List.fromList([7, 8, 9]),
          mimeData: MimeData(
            extension: 'png',
            mime: 'image/png',
          ),
        ),
      ];

      final fileOptions = files
          .map((file) => FieldOption(
                label: file.fileName,
                value: 'path/${file.fileName}',
                additionalData: file,
              ))
          .toList();

      controller.updateMultiselectValues(
        field.id,
        fileOptions,
        overwrite: true,
      );

      // Get results
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );

      // Assert - asFileList() returns List<FileModel>
      final retrievedFiles = results.grab(field.id).asFileList();
      expect(retrievedFiles, isA<List<FileModel>>());
      expect(retrievedFiles.length, 3);
      expect(retrievedFiles[0].fileName, 'doc1.pdf');
      expect(retrievedFiles[1].fileName, 'doc2.pdf');
      expect(retrievedFiles[2].fileName, 'image.png');

      // Verify all properties accessible
      for (final file in retrievedFiles) {
        expect(file.fileName, isNotEmpty);
        expect(file.fileBytes, isNotNull);
        expect(file.fileBytes, isA<Uint8List>());
        expect(file.mimeData, isNotNull);
        expect(file.uploadExtension, isNotNull);
      }
    });

    testWidgets('asFileList() returns empty list for empty file field',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final field = FileUpload(
        id: 'empty_list',
        multiselect: true,
      );

      controller.addFields([field]);

      // Get results without adding files
      final results = FormResults.getResults(
        controller: controller,
        fields: [field],
      );

      // Assert - asFileList() returns empty list
      final retrievedFiles = results.grab(field.id).asFileList();
      expect(retrievedFiles, isA<List<FileModel>>());
      expect(retrievedFiles, isEmpty);
    });

    testWidgets('FileModel.getFileBytes() returns Future<Uint8List?> immediately',
        (WidgetTester tester) async {
      // Arrange
      final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileModel = FileModel(
        fileName: 'test.bin',
        uploadExtension: 'bin',
        fileBytes: testBytes,
      );

      // Act & Assert - getFileBytes() returns immediately
      final byteFuture = fileModel.getFileBytes();
      expect(byteFuture, isA<Future<Uint8List?>>());

      final bytes = await byteFuture;
      expect(bytes, equals(testBytes));
    });

    testWidgets('FileModel.getFileBytes() returns null for null fileBytes',
        (WidgetTester tester) async {
      // Arrange
      final fileModel = FileModel(
        fileName: 'test.bin',
        uploadExtension: 'bin',
        fileBytes: null,
      );

      // Act & Assert
      final bytes = await fileModel.getFileBytes();
      expect(bytes, isNull);
    });

    testWidgets('FileModel.copyWith() creates correct copies',
        (WidgetTester tester) async {
      // Arrange
      final original = FileModel(
        fileName: 'original.txt',
        uploadExtension: 'txt',
        fileBytes: Uint8List.fromList([1, 2, 3]),
        mimeData: MimeData(
          extension: 'txt',
          mime: 'text/plain',
        ),
      );

      // Act - Copy with new fileName
      final copied = original.copyWith(fileName: 'copied.txt');

      // Assert
      expect(copied.fileName, 'copied.txt');
      expect(copied.uploadExtension, original.uploadExtension);
      expect(copied.fileBytes, equals(original.fileBytes));
      expect(copied.mimeData, equals(original.mimeData));

      // Act - Copy with new fileBytes
      final newBytes = Uint8List.fromList([4, 5, 6]);
      final copiedBytes = original.copyWith(fileBytes: newBytes);

      // Assert
      expect(copiedBytes.fileName, original.fileName);
      expect(copiedBytes.fileBytes, equals(newBytes));
    });

    testWidgets('multiselect flag behavior unchanged',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final singleField = FileUpload(
        id: 'single',
        multiselect: false,
      );
      final multiField = FileUpload(
        id: 'multi',
        multiselect: true,
      );

      // Assert
      expect(singleField.multiselect, false);
      expect(multiField.multiselect, true);
    });

    testWidgets('clearOnUpload flag behavior unchanged',
        (WidgetTester tester) async {
      // Arrange
      final defaultField = FileUpload(id: 'default');
      final clearField = FileUpload(
        id: 'clear',
        clearOnUpload: true,
      );
      final noClearField = FileUpload(
        id: 'noclear',
        clearOnUpload: false,
      );

      // Assert
      expect(defaultField.clearOnUpload, false);
      expect(clearField.clearOnUpload, true);
      expect(noClearField.clearOnUpload, false);
    });

    testWidgets('allowedExtensions filtering unchanged',
        (WidgetTester tester) async {
      // Arrange
      final field = FileUpload(
        id: 'filtered',
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      // Assert
      expect(field.allowedExtensions, isNotNull);
      expect(field.allowedExtensions, ['pdf', 'doc', 'docx']);
    });

    testWidgets('displayUploadedFiles flag unchanged',
        (WidgetTester tester) async {
      // Arrange
      final defaultField = FileUpload(id: 'default');
      final displayField = FileUpload(
        id: 'display',
        displayUploadedFiles: true,
      );
      final hideField = FileUpload(
        id: 'hide',
        displayUploadedFiles: false,
      );

      // Assert
      expect(defaultField.displayUploadedFiles, true);
      expect(displayField.displayUploadedFiles, true);
      expect(hideField.displayUploadedFiles, false);
    });

    testWidgets('dropDisplayWidget custom builder accessible',
        (WidgetTester tester) async {
      // Arrange
      Widget customBuilder(FieldColorScheme colors, FileUpload field) {
        return Container(
          child: const Text('Custom Drop Zone'),
        );
      }

      final field = FileUpload(
        id: 'custom',
        dropDisplayWidget: customBuilder,
      );

      // Assert
      expect(field.dropDisplayWidget, isNotNull);
      expect(field.dropDisplayWidget, equals(customBuilder));
    });

    testWidgets('fileUploadBuilder custom builder accessible',
        (WidgetTester tester) async {
      // Arrange
      Widget customBuilder(List<FieldOption> files) {
        return Container(
          child: const Text('Custom File List'),
        );
      }

      final field = FileUpload(
        id: 'custom',
        fileUploadBuilder: customBuilder,
      );

      // Assert
      expect(field.fileUploadBuilder, isNotNull);
      expect(field.fileUploadBuilder, equals(customBuilder));
    });
  });

  group('Full form submission integration test', () {
    testWidgets('Form with file upload field submits correctly',
        (WidgetTester tester) async {
      // Arrange - Create form controller and fields
      final controller = FormController();
      final fileField = FileUpload(
        id: 'document',
        multiselect: true,
        displayUploadedFiles: true,
      );

      final textField = cf.TextField(
        id: 'name',
        title: 'Name',
      );

      controller.addFields([fileField, textField]);

      // Build widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Material(
              child: FileUploadWidget(
                id: fileField.id,
                controller: controller,
                field: fileField,
                currentColors: const FieldColorScheme(),
                onFocusChange: (_) {},
                onFileOptionChange: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act - Add files via controller (simulating drag-drop)
      final file1 = FileModel(
        fileName: 'resume.pdf',
        uploadExtension: 'pdf',
        fileBytes: Uint8List.fromList([1, 2, 3]),
        mimeData: MimeData(
          extension: 'pdf',
          mime: 'application/pdf',
        ),
      );

      final file2 = FileModel(
        fileName: 'cover_letter.docx',
        uploadExtension: 'docx',
        fileBytes: Uint8List.fromList([4, 5, 6]),
        mimeData: MimeData(
          extension: 'docx',
          mime:
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );

      final fileOptions = [
        FieldOption(
          label: file1.fileName,
          value: 'path/${file1.fileName}',
          additionalData: file1,
        ),
        FieldOption(
          label: file2.fileName,
          value: 'path/${file2.fileName}',
          additionalData: file2,
        ),
      ];

      controller.updateMultiselectValues(
        fileField.id,
        fileOptions,
        overwrite: true,
      );

      // Set text field value
      controller.updateFieldValue(textField.id, 'John Doe');

      await tester.pumpAndSettle();

      // Act - Submit form
      final results = FormResults.getResults(
        controller: controller,
        fields: [fileField, textField],
      );

      // Assert - FormResults contains correct file data
      expect(results.errorState, false);
      expect(results.hasField(fileField.id), true);
      expect(results.hasField(textField.id), true);

      // Verify files accessible via asFile()
      final firstFile = results.grab(fileField.id).asFile();
      expect(firstFile, isNotNull);
      expect(firstFile?.fileName, 'resume.pdf');

      // Verify files accessible via asFileList()
      final allFiles = results.grab(fileField.id).asFileList();
      expect(allFiles.length, 2);
      expect(allFiles[0].fileName, 'resume.pdf');
      expect(allFiles[0].uploadExtension, 'pdf');
      expect(allFiles[0].fileBytes, equals(Uint8List.fromList([1, 2, 3])));
      expect(allFiles[0].mimeData?.mime, 'application/pdf');

      expect(allFiles[1].fileName, 'cover_letter.docx');
      expect(allFiles[1].uploadExtension, 'docx');
      expect(allFiles[1].fileBytes, equals(Uint8List.fromList([4, 5, 6])));
      expect(
          allFiles[1].mimeData?.mime,
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document');

      // Verify text field still works
      final name = results.grab(textField.id).asString();
      expect(name, 'John Doe');
    });

    testWidgets('Form with multiple file fields submits independently',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final documentsField = FileUpload(
        id: 'documents',
        multiselect: true,
      );
      final photoField = FileUpload(
        id: 'photo',
        multiselect: false,
        allowedExtensions: ['jpg', 'png'],
      );

      controller.addFields([documentsField, photoField]);

      // Act - Add files to both fields
      final document = FileModel(
        fileName: 'doc.pdf',
        uploadExtension: 'pdf',
        fileBytes: Uint8List.fromList([1, 2, 3]),
      );

      final photo = FileModel(
        fileName: 'photo.jpg',
        uploadExtension: 'jpg',
        fileBytes: Uint8List.fromList([4, 5, 6]),
      );

      controller.updateMultiselectValues(
        documentsField.id,
        [
          FieldOption(
            label: document.fileName,
            value: 'path/${document.fileName}',
            additionalData: document,
          ),
        ],
        overwrite: true,
      );

      controller.updateMultiselectValues(
        photoField.id,
        [
          FieldOption(
            label: photo.fileName,
            value: 'path/${photo.fileName}',
            additionalData: photo,
          ),
        ],
        overwrite: true,
      );

      // Get results
      final results = FormResults.getResults(
        controller: controller,
        fields: [documentsField, photoField],
      );

      // Assert - Each field has its own files
      final documents = results.grab(documentsField.id).asFileList();
      expect(documents.length, 1);
      expect(documents[0].fileName, 'doc.pdf');

      final photoFile = results.grab(photoField.id).asFile();
      expect(photoFile, isNotNull);
      expect(photoFile?.fileName, 'photo.jpg');

      // Verify independence
      expect(documents[0].fileName, isNot(equals(photoFile?.fileName)));
    });

    testWidgets('Empty file field returns empty results correctly',
        (WidgetTester tester) async {
      // Arrange
      final controller = FormController();
      final optionalFileField = FileUpload(
        id: 'optional',
        multiselect: true,
      );

      controller.addFields([optionalFileField]);

      // Get results without adding files
      final results = FormResults.getResults(
        controller: controller,
        fields: [optionalFileField],
      );

      // Assert - Empty field returns empty/null results
      expect(results.errorState, false);
      expect(results.hasField(optionalFileField.id), true);

      final file = results.grab(optionalFileField.id).asFile();
      expect(file, isNull);

      final fileList = results.grab(optionalFileField.id).asFileList();
      expect(fileList, isEmpty);
    });
  });

  group('FileModel properties accessibility', () {
    test('All FileModel properties accessible', () {
      // Arrange
      final fileModel = FileModel(
        fileName: 'test_file.txt',
        uploadExtension: 'txt',
        fileBytes: Uint8List.fromList([1, 2, 3, 4, 5]),
        mimeData: MimeData(
          extension: 'txt',
          mime: 'text/plain',
        ),
      );

      // Assert - All properties accessible
      expect(fileModel.fileName, 'test_file.txt');
      expect(fileModel.uploadExtension, 'txt');
      expect(fileModel.fileBytes, isNotNull);
      expect(fileModel.fileBytes, isA<Uint8List>());
      expect(fileModel.fileBytes, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
      expect(fileModel.mimeData, isNotNull);
      expect(fileModel.mimeData?.extension, 'txt');
      expect(fileModel.mimeData?.mime, 'text/plain');
    });

    test('FileModel with null optional properties', () {
      // Arrange
      final fileModel = FileModel(
        fileName: 'test.bin',
        uploadExtension: null,
        fileBytes: null,
        mimeData: null,
      );

      // Assert - Null properties handled correctly
      expect(fileModel.fileName, 'test.bin');
      expect(fileModel.uploadExtension, isNull);
      expect(fileModel.fileBytes, isNull);
      expect(fileModel.mimeData, isNull);
    });
  });
}
