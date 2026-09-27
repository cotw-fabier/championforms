import 'package:championforms/championforms.dart' as cf;
import 'package:championforms/core/field_builder_registry.dart';
import 'package:file_picker/file_picker.dart' show FileType;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(FormFieldRegistry.ensureInitialized);

  group('FileUpload.fromJson', () {
    test('decodes through the registry with every JSON-expressible option', () {
      final field = FormFieldRegistry.fieldFromJson({
        'type': 'fileUpload',
        'id': 'docs',
        'title': 'Attachments',
        'multiselect': true,
        'allowedExtensions': ['pdf', 'png'],
        'fileType': 'custom',
        'maxFileSize': 1024,
        'displayUploadedFiles': false,
        'clearOnUpload': true,
      });
      expect(field, isA<cf.FileUpload>());
      final f = field! as cf.FileUpload;
      expect(f.id, 'docs');
      expect(f.title, 'Attachments');
      expect(f.multiselect, isTrue);
      expect(f.allowedExtensions, ['pdf', 'png']);
      expect(f.fileType, FileType.custom);
      expect(f.maxFileSize, 1024);
      expect(f.displayUploadedFiles, isFalse);
      expect(f.clearOnUpload, isTrue);
    });

    test('defaults match the constructor', () {
      final f = cf.FileUpload.fromJson({'id': 'x'});
      expect(f.multiselect, isFalse);
      expect(f.maxFileSize, 52428800);
      expect(f.displayUploadedFiles, isTrue);
      expect(f.fileType, isNull);
    });

    test('rejects a wrong-typed or unknown value', () {
      expect(() => cf.FileUpload.fromJson({'id': 'x', 'fileType': 'nope'}),
          throwsFormatException);
      expect(
          () => cf.FileUpload.fromJson({
                'id': 'x',
                'allowedExtensions': ['pdf', 3],
              }),
          throwsFormatException);
    });
  });

  group('compound fromJson', () {
    test('NameField decodes through the registry', () {
      final field = FormFieldRegistry.fieldFromJson(
          {'type': 'name', 'id': 'who', 'includeMiddleName': false});
      expect(field, isA<cf.NameField>());
      expect((field! as cf.NameField).includeMiddleName, isFalse);
    });

    test('AddressField decodes through the registry', () {
      final field = FormFieldRegistry.fieldFromJson({
        'type': 'address',
        'id': 'where',
        'includeStreet2': false,
        'includeCountry': true,
      });
      expect(field, isA<cf.AddressField>());
      final a = field! as cf.AddressField;
      expect(a.includeStreet2, isFalse);
      expect(a.includeCountry, isTrue);
    });
  });
}
