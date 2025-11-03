import 'package:flutter_test/flutter_test.dart';
import 'package:championforms/models/field_types/fileupload.dart';

void main() {
  group('FileUpload clearOnUpload property', () {
    test('clearOnUpload defaults to false when not specified', () {
      // Arrange & Act
      final field = FileUpload(
        id: 'test_upload',
      );

      // Assert
      expect(field.clearOnUpload, false);
    });

    test('clearOnUpload accepts true value', () {
      // Arrange & Act
      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: true,
      );

      // Assert
      expect(field.clearOnUpload, true);
    });

    test('clearOnUpload accepts false value explicitly', () {
      // Arrange & Act
      final field = FileUpload(
        id: 'test_upload',
        clearOnUpload: false,
      );

      // Assert
      expect(field.clearOnUpload, false);
    });

    test('clearOnUpload property is accessible on existing field instances', () {
      // Arrange
      final fieldWithClear = FileUpload(
        id: 'upload_with_clear',
        clearOnUpload: true,
        displayUploadedFiles: false,
      );

      final fieldWithoutClear = FileUpload(
        id: 'upload_without_clear',
        displayUploadedFiles: true,
      );

      // Act & Assert
      expect(fieldWithClear.clearOnUpload, true);
      expect(fieldWithoutClear.clearOnUpload, false);
    });
  });
}
