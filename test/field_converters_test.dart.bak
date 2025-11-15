import 'package:championforms/models/field_converters.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/file_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:typed_data';

// Test implementations to expose the mixin converters
class TestTextFieldConverters with TextFieldConverters {}

class TestMultiselectFieldConverters with MultiselectFieldConverters {}

class TestFileFieldConverters with FileFieldConverters {}

class TestNumericFieldConverters with NumericFieldConverters {}

void main() {
  group('TextFieldConverters', () {
    late TestTextFieldConverters converter;

    setUp(() {
      converter = TestTextFieldConverters();
    });

    test('asStringConverter should convert String to String', () {
      // Act
      final result = converter.asStringConverter('hello');

      // Assert
      expect(result, equals('hello'));
    });

    test('asStringConverter should convert null to empty string', () {
      // Act
      final result = converter.asStringConverter(null);

      // Assert
      expect(result, equals(''));
    });

    test('asStringConverter should throw on invalid type', () {
      // Act & Assert
      expect(
        () => converter.asStringConverter(123),
        throwsA(isA<TypeError>()),
      );
    });

    test('asStringListConverter should convert String to List<String>', () {
      // Act
      final result = converter.asStringListConverter('hello');

      // Assert
      expect(result, equals(['hello']));
    });

    test('asStringListConverter should convert null to empty list', () {
      // Act
      final result = converter.asStringListConverter(null);

      // Assert
      expect(result, equals([]));
    });

    test('asBoolConverter should convert non-empty String to true', () {
      // Act
      final result = converter.asBoolConverter('hello');

      // Assert
      expect(result, equals(true));
    });

    test('asBoolConverter should convert empty String to false', () {
      // Act
      final result = converter.asBoolConverter('');

      // Assert
      expect(result, equals(false));
    });

    test('asBoolConverter should convert null to false', () {
      // Act
      final result = converter.asBoolConverter(null);

      // Assert
      expect(result, equals(false));
    });

    test('asFileListConverter should be null for text fields', () {
      // Assert
      expect(converter.asFileListConverter, isNull);
    });
  });

  group('MultiselectFieldConverters', () {
    late TestMultiselectFieldConverters converter;

    setUp(() {
      converter = TestMultiselectFieldConverters();
    });

    test('asStringConverter should convert List<FieldOption> to comma-separated labels', () {
      // Arrange
      final options = [
        FieldOption(value: 'opt1', label: 'Option 1'),
        FieldOption(value: 'opt2', label: 'Option 2'),
        FieldOption(value: 'opt3', label: 'Option 3'),
      ];

      // Act
      final result = converter.asStringConverter(options);

      // Assert
      expect(result, equals('Option 1, Option 2, Option 3'));
    });

    test('asStringConverter should convert null to empty string', () {
      // Act
      final result = converter.asStringConverter(null);

      // Assert
      expect(result, equals(''));
    });

    test('asStringConverter should throw on invalid type', () {
      // Act & Assert
      expect(
        () => converter.asStringConverter('invalid'),
        throwsA(isA<TypeError>()),
      );
    });

    test('asStringListConverter should convert List<FieldOption> to List<String> values', () {
      // Arrange
      final options = [
        FieldOption(value: 'value1', label: 'Label 1'),
        FieldOption(value: 'value2', label: 'Label 2'),
        FieldOption(value: 'value3', label: 'Label 3'),
      ];

      // Act
      final result = converter.asStringListConverter(options);

      // Assert
      expect(result, equals(['value1', 'value2', 'value3']));
    });

    test('asStringListConverter should convert null to empty list', () {
      // Act
      final result = converter.asStringListConverter(null);

      // Assert
      expect(result, equals([]));
    });

    test('asBoolConverter should return true for non-empty list', () {
      // Arrange
      final options = [
        FieldOption(value: 'opt1', label: 'Option 1'),
      ];

      // Act
      final result = converter.asBoolConverter(options);

      // Assert
      expect(result, equals(true));
    });

    test('asBoolConverter should return false for empty list', () {
      // Act
      final result = converter.asBoolConverter([]);

      // Assert
      expect(result, equals(false));
    });

    test('asBoolConverter should return false for null', () {
      // Act
      final result = converter.asBoolConverter(null);

      // Assert
      expect(result, equals(false));
    });

    test('asFileListConverter should be null for multiselect fields', () {
      // Assert
      expect(converter.asFileListConverter, isNull);
    });
  });

  group('FileFieldConverters', () {
    late TestFileFieldConverters converter;

    setUp(() {
      converter = TestFileFieldConverters();
    });

    test('asStringConverter should convert List<FileModel> to comma-separated filenames', () {
      // Arrange
      final files = [
        FileModel(fileName: 'file1.pdf', fileBytes: Uint8List(0)),
        FileModel(fileName: 'file2.jpg', fileBytes: Uint8List(0)),
        FileModel(fileName: 'file3.png', fileBytes: Uint8List(0)),
      ];

      // Act
      final result = converter.asStringConverter(files);

      // Assert
      expect(result, equals('file1.pdf, file2.jpg, file3.png'));
    });

    test('asStringConverter should convert null to empty string', () {
      // Act
      final result = converter.asStringConverter(null);

      // Assert
      expect(result, equals(''));
    });

    test('asStringConverter should throw on invalid type', () {
      // Act & Assert
      expect(
        () => converter.asStringConverter('invalid'),
        throwsA(isA<TypeError>()),
      );
    });

    test('asStringListConverter should convert List<FileModel> to List<String> filenames', () {
      // Arrange
      final files = [
        FileModel(fileName: 'doc.pdf', fileBytes: Uint8List(0)),
        FileModel(fileName: 'image.jpg', fileBytes: Uint8List(0)),
      ];

      // Act
      final result = converter.asStringListConverter(files);

      // Assert
      expect(result, equals(['doc.pdf', 'image.jpg']));
    });

    test('asStringListConverter should convert null to empty list', () {
      // Act
      final result = converter.asStringListConverter(null);

      // Assert
      expect(result, equals([]));
    });

    test('asBoolConverter should return true for non-empty file list', () {
      // Arrange
      final files = [
        FileModel(fileName: 'file.pdf', fileBytes: Uint8List(0)),
      ];

      // Act
      final result = converter.asBoolConverter(files);

      // Assert
      expect(result, equals(true));
    });

    test('asBoolConverter should return false for empty list', () {
      // Act
      final result = converter.asBoolConverter([]);

      // Assert
      expect(result, equals(false));
    });

    test('asBoolConverter should return false for null', () {
      // Act
      final result = converter.asBoolConverter(null);

      // Assert
      expect(result, equals(false));
    });

    test('asFileListConverter should return List<FileModel>', () {
      // Arrange
      final files = [
        FileModel(fileName: 'file.pdf', fileBytes: Uint8List(0)),
      ];

      // Act
      final result = converter.asFileListConverter!(files);

      // Assert
      expect(result, equals(files));
    });

    test('asFileListConverter should return null for null input', () {
      // Act
      final result = converter.asFileListConverter!(null);

      // Assert
      expect(result, isNull);
    });

    test('asFileListConverter should throw on invalid type', () {
      // Act & Assert
      expect(
        () => converter.asFileListConverter!('invalid'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('NumericFieldConverters', () {
    late TestNumericFieldConverters converter;

    setUp(() {
      converter = TestNumericFieldConverters();
    });

    test('asStringConverter should convert int to String', () {
      // Act
      final result = converter.asStringConverter(42);

      // Assert
      expect(result, equals('42'));
    });

    test('asStringConverter should convert double to String', () {
      // Act
      final result = converter.asStringConverter(3.14);

      // Assert
      expect(result, equals('3.14'));
    });

    test('asStringConverter should convert null to empty string', () {
      // Act
      final result = converter.asStringConverter(null);

      // Assert
      expect(result, equals(''));
    });

    test('asStringConverter should throw on invalid type', () {
      // Act & Assert
      expect(
        () => converter.asStringConverter('invalid'),
        throwsA(isA<TypeError>()),
      );
    });

    test('asStringListConverter should convert int to List<String>', () {
      // Act
      final result = converter.asStringListConverter(42);

      // Assert
      expect(result, equals(['42']));
    });

    test('asStringListConverter should convert null to empty list', () {
      // Act
      final result = converter.asStringListConverter(null);

      // Assert
      expect(result, equals([]));
    });

    test('asBoolConverter should return true for non-zero int', () {
      // Act
      final result = converter.asBoolConverter(5);

      // Assert
      expect(result, equals(true));
    });

    test('asBoolConverter should return false for zero int', () {
      // Act
      final result = converter.asBoolConverter(0);

      // Assert
      expect(result, equals(false));
    });

    test('asBoolConverter should return false for null', () {
      // Act
      final result = converter.asBoolConverter(null);

      // Assert
      expect(result, equals(false));
    });

    test('asFileListConverter should be null for numeric fields', () {
      // Assert
      expect(converter.asFileListConverter, isNull);
    });
  });
}
