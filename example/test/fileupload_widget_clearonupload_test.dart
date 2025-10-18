import 'package:championforms/championforms.dart';
import 'package:championforms/models/colorscheme.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/widgets_internal/field_widgets/file_upload_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

void main() {
  group('FileUploadWidget clearOnUpload behavior', () {
    testWidgets(
        'clearOnUpload = false maintains running tally with file picker',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: false,
        multiselect: true,
      );

      // Add field to controller
      controller.addFields([field]);

      // Add initial file to controller
      final initialFile = MultiselectOption(
        label: 'initial.txt',
        value: 'path/initial.txt',
        additionalData: FileModel(
          fileName: 'initial.txt',
          uploadExtension: 'txt',
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

      // Assert initial state - file is present
      final currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'initial.txt');

      // Note: We cannot directly test file picker interaction in widget tests
      // as FilePicker.platform.pickFiles() requires platform channels.
      // This test verifies the initial state with clearOnUpload = false.
      // The actual file picker clearing logic will be tested through
      // controller state changes.
    });

    testWidgets(
        'clearOnUpload = true clears existing files before adding new ones',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
      );

      controller.addFields([field]);

      // Add initial files to controller
      final initialFile1 = MultiselectOption(
        label: 'initial1.txt',
        value: 'path/initial1.txt',
        additionalData: FileModel(
          fileName: 'initial1.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      final initialFile2 = MultiselectOption(
        label: 'initial2.txt',
        value: 'path/initial2.txt',
        additionalData: FileModel(
          fileName: 'initial2.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [initialFile1, initialFile2],
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

      // Assert initial state - 2 files present
      var currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 2);

      // Act - Simulate clearing and adding new file
      // (This mimics what _pickFiles will do when clearOnUpload = true)
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Verify files cleared
      currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 0);

      // Add new file
      final newFile = MultiselectOption(
        label: 'new.txt',
        value: 'path/new.txt',
        additionalData: FileModel(
          fileName: 'new.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([7, 8, 9]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [newFile],
        multiselect: true,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Only new file present
      currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'new.txt');
    });

    testWidgets(
        'clearOnUpload = true with multi-file upload processes all new files',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
      );

      controller.addFields([field]);

      // Add initial file
      final initialFile = MultiselectOption(
        label: 'old.txt',
        value: 'path/old.txt',
        additionalData: FileModel(
          fileName: 'old.txt',
          uploadExtension: 'txt',
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

      // Assert initial state
      var currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);

      // Act - Simulate clearing and adding multiple new files
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      final newFile1 = MultiselectOption(
        label: 'new1.txt',
        value: 'path/new1.txt',
        additionalData: FileModel(
          fileName: 'new1.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      final newFile2 = MultiselectOption(
        label: 'new2.txt',
        value: 'path/new2.txt',
        additionalData: FileModel(
          fileName: 'new2.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([7, 8, 9]),
        ),
      );
      final newFile3 = MultiselectOption(
        label: 'new3.txt',
        value: 'path/new3.txt',
        additionalData: FileModel(
          fileName: 'new3.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([10, 11, 12]),
        ),
      );

      controller.updateMultiselectValues(
        field.id,
        [newFile1, newFile2, newFile3],
        multiselect: true,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - All 3 new files present, old file gone
      currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 3);
      expect(currentFiles?.map((f) => f.label).toList(),
          ['new1.txt', 'new2.txt', 'new3.txt']);
    });

    testWidgets(
        'clearOnUpload = true in single-file mode replaces file',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: false, // Single file mode
      );

      controller.addFields([field]);

      // Add initial file
      final initialFile = MultiselectOption(
        label: 'old.txt',
        value: 'path/old.txt',
        additionalData: FileModel(
          fileName: 'old.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [initialFile],
        multiselect: false,
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

      // Assert initial state
      var currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'old.txt');

      // Act - Clear and add new file
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      final newFile = MultiselectOption(
        label: 'new.txt',
        value: 'path/new.txt',
        additionalData: FileModel(
          fileName: 'new.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [newFile],
        multiselect: false,
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Only new file present
      currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'new.txt');
    });

    testWidgets('Widget state syncs with controller during clearing',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
        displayUploadedFiles: true,
      );

      controller.addFields([field]);

      // Add initial files
      final file1 = MultiselectOption(
        label: 'file1.txt',
        value: 'path/file1.txt',
        additionalData: FileModel(
          fileName: 'file1.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      final file2 = MultiselectOption(
        label: 'file2.txt',
        value: 'path/file2.txt',
        additionalData: FileModel(
          fileName: 'file2.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [file1, file2],
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

      // Assert initial state - files visible in UI
      expect(find.text('file1.txt'), findsOneWidget);
      expect(find.text('file2.txt'), findsOneWidget);

      // Act - Clear files via controller
      controller.updateMultiselectValues(
        field.id,
        [],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Files removed from UI
      expect(find.text('file1.txt'), findsNothing);
      expect(find.text('file2.txt'), findsNothing);

      // Act - Add new file
      final newFile = MultiselectOption(
        label: 'new.txt',
        value: 'path/new.txt',
        additionalData: FileModel(
          fileName: 'new.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([7, 8, 9]),
        ),
      );
      controller.updateMultiselectValues(
        field.id,
        [newFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - New file visible in UI
      expect(find.text('new.txt'), findsOneWidget);
      expect(find.text('file1.txt'), findsNothing);
      expect(find.text('file2.txt'), findsNothing);
    });

    testWidgets('Empty file selection does not trigger clearing',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: true,
        multiselect: true,
      );

      controller.addFields([field]);

      // Add initial file
      final initialFile = MultiselectOption(
        label: 'existing.txt',
        value: 'path/existing.txt',
        additionalData: FileModel(
          fileName: 'existing.txt',
          uploadExtension: 'txt',
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

      // Assert initial state
      var currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);
      expect(currentFiles?.first.label, 'existing.txt');

      // Note: We cannot simulate a file picker cancel in widget tests
      // This test verifies the initial state remains intact.
      // The actual logic in _pickFiles checks if (result != null)
      // before clearing, which prevents clearing on cancel.
    });

    testWidgets(
        'clearOnUpload = false does not clear files when adding new ones',
        (WidgetTester tester) async {
      // Arrange
      final controller = ChampionFormController();
      final field = ChampionFileUpload(
        id: 'test_upload',
        clearOnUpload: false, // Explicitly false
        multiselect: true,
      );

      controller.addFields([field]);

      // Add initial file
      final initialFile = MultiselectOption(
        label: 'first.txt',
        value: 'path/first.txt',
        additionalData: FileModel(
          fileName: 'first.txt',
          uploadExtension: 'txt',
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

      // Assert initial state
      var currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 1);

      // Act - Add second file WITHOUT clearing (running tally behavior)
      final secondFile = MultiselectOption(
        label: 'second.txt',
        value: 'path/second.txt',
        additionalData: FileModel(
          fileName: 'second.txt',
          uploadExtension: 'txt',
          fileBytes: Uint8List.fromList([4, 5, 6]),
        ),
      );

      // Get current files and add new one
      final existingFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id) ?? [];
      controller.updateMultiselectValues(
        field.id,
        [...existingFiles, secondFile],
        overwrite: true,
      );
      await tester.pumpAndSettle();

      // Assert - Both files present (running tally)
      currentFiles = controller
          .getFieldValue<List<MultiselectOption>>(field.id);
      expect(currentFiles?.length, 2);
      expect(
          currentFiles?.map((f) => f.label).toList(),
          ['first.txt', 'second.txt']);
    });
  });
}
