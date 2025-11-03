import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/mime_data.dart';

void main() {
  group('FileModel', () {
    test('creates FileModel with fileName and fileBytes', () {
      // Arrange
      final fileName = 'test.txt';
      final fileBytes = Uint8List.fromList([72, 101, 108, 108, 111]); // "Hello"

      // Act
      final fileModel = FileModel(
        fileName: fileName,
        fileBytes: fileBytes,
      );

      // Assert
      expect(fileModel.fileName, fileName);
      expect(fileModel.fileBytes, fileBytes);
      expect(fileModel.mimeData, null);
      expect(fileModel.uploadExtension, null);
    });

    test('getFileBytes returns fileBytes directly', () async {
      // Arrange
      final fileBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final fileModel = FileModel(
        fileName: 'data.bin',
        fileBytes: fileBytes,
      );

      // Act
      final result = await fileModel.getFileBytes();

      // Assert
      expect(result, fileBytes);
      expect(result, same(fileBytes)); // Verify it's the same instance
    });

    test('getFileBytes returns null when fileBytes is null', () async {
      // Arrange
      final fileModel = FileModel(
        fileName: 'empty.txt',
        fileBytes: null,
      );

      // Act
      final result = await fileModel.getFileBytes();

      // Assert
      expect(result, null);
    });

    test('readMimeData detects text file MIME type', () async {
      // Arrange
      final textContent = 'Hello, World!';
      final fileBytes = Uint8List.fromList(textContent.codeUnits);
      final fileModel = FileModel(
        fileName: 'document.txt',
        fileBytes: fileBytes,
      );

      // Act
      final mimeData = await fileModel.readMimeData();

      // Assert
      expect(mimeData.mime, 'text/plain');
      expect(mimeData.extension, 'txt');
    });

    test('readMimeData detects JSON file MIME type', () async {
      // Arrange
      final jsonContent = '{"key": "value"}';
      final fileBytes = Uint8List.fromList(jsonContent.codeUnits);
      final fileModel = FileModel(
        fileName: 'data.json',
        fileBytes: fileBytes,
      );

      // Act
      final mimeData = await fileModel.readMimeData();

      // Assert
      expect(mimeData.mime, 'application/json');
      expect(mimeData.extension, 'json');
    });

    test('readMimeData falls back to application/octet-stream for unknown types', () async {
      // Arrange
      // File with unrecognized extension and generic binary content
      final fileBytes = Uint8List.fromList([0xAB, 0xCD, 0xEF]);
      final fileModel = FileModel(
        fileName: 'file.unknownextension',
        fileBytes: fileBytes,
      );

      // Act
      final mimeData = await fileModel.readMimeData();

      // Assert
      expect(mimeData.mime, 'application/octet-stream');
      expect(mimeData.extension, '');
    });

    test('copyWith creates correct copy with new values', () {
      // Arrange
      final originalBytes = Uint8List.fromList([1, 2, 3]);
      final original = FileModel(
        fileName: 'original.txt',
        fileBytes: originalBytes,
        mimeData: MimeData(mime: 'text/plain', extension: 'txt'),
        uploadExtension: 'txt',
      );

      final newBytes = Uint8List.fromList([4, 5, 6]);
      final newMimeData = MimeData(mime: 'application/json', extension: 'json');

      // Act
      final copy = original.copyWith(
        fileName: 'updated.json',
        fileBytes: newBytes,
        mimeData: newMimeData,
        uploadExtension: 'json',
      );

      // Assert
      expect(copy.fileName, 'updated.json');
      expect(copy.fileBytes, newBytes);
      expect(copy.mimeData?.mime, 'application/json');
      expect(copy.uploadExtension, 'json');

      // Verify original unchanged
      expect(original.fileName, 'original.txt');
      expect(original.fileBytes, originalBytes);
    });

    test('copyWith maintains original values when no parameters provided', () {
      // Arrange
      final fileBytes = Uint8List.fromList([1, 2, 3]);
      final mimeData = MimeData(mime: 'text/plain', extension: 'txt');
      final original = FileModel(
        fileName: 'test.txt',
        fileBytes: fileBytes,
        mimeData: mimeData,
        uploadExtension: 'txt',
      );

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.fileName, original.fileName);
      expect(copy.fileBytes, original.fileBytes);
      expect(copy.mimeData, original.mimeData);
      expect(copy.uploadExtension, original.uploadExtension);
    });
  });
}
