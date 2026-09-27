import 'dart:convert';
import 'dart:typed_data';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms/models/mime_data.dart';
import 'package:flutter_test/flutter_test.dart';

/// A value computed from other fields; left out of `exportValues`.
class _TotalField extends form.TextField implements form.DerivedValueField {
  _TotalField({required super.id});
}

/// A value object that knows how to serialize itself.
class _Point {
  const _Point(this.x, this.y);
  final int x;
  final int y;
  Map<String, dynamic> toJson() => {'x': x, 'y': y};
}

final _colors = [
  form.FieldOption(value: 'red', label: 'Red'),
  form.FieldOption(value: 'green', label: 'Green'),
  form.FieldOption(value: 'blue', label: 'Blue'),
];

form.FieldOption _fileOption(String name, {List<int>? bytes}) =>
    form.FieldOption(
      value: name,
      label: name,
      additionalData: form.FileModel(
        fileName: name,
        fileBytes: bytes == null ? null : Uint8List.fromList(bytes),
        mimeData: MimeData(mime: 'application/pdf', extension: 'pdf'),
      ),
    );

List<form.Field> _fields() => [
  form.TextField(id: 'name'),
  form.OptionSelect(id: 'colors', multiselect: true, options: _colors),
  form.OptionSelect(id: 'favorite', options: _colors),
  form.FileUpload(id: 'files', multiselect: true),
  form.TextField(
    id: 'hiddenNote',
    conditional: const form.FieldCondition(
      rules: [
        form.ConditionRule(
          fieldId: 'name',
          operator: form.ConditionOperator.equals,
          value: 'show',
        ),
      ],
    ),
  ),
  _TotalField(id: 'total'),
];

void main() {
  late form.FormController controller;

  setUp(() {
    controller = form.FormController()..addFields(_fields());
  });

  tearDown(() => controller.dispose());

  group('FormResults.valueToJson', () {
    test('primitives, options, files, dates, collections, toJson objects', () {
      expect(form.FormResults.valueToJson(null), isNull);
      expect(form.FormResults.valueToJson('a'), 'a');
      expect(form.FormResults.valueToJson(3.5), 3.5);
      expect(form.FormResults.valueToJson(true), true);
      expect(form.FormResults.valueToJson(_colors.first), 'red');
      expect(
        form.FormResults.valueToJson(_fileOption('a.pdf', bytes: [1, 2])),
        {'name': 'a.pdf', 'mimeType': 'application/pdf', 'size': 2},
      );
      expect(
        form.FormResults.valueToJson(const form.FileModel(fileName: 'b.txt')),
        {'name': 'b.txt'},
      );
      expect(
        form.FormResults.valueToJson(DateTime.utc(2026, 9, 26)),
        '2026-09-26T00:00:00.000Z',
      );
      expect(
        form.FormResults.valueToJson({
          1: [const _Point(1, 2)],
        }),
        {
          '1': [
            {'x': 1, 'y': 2},
          ],
        },
      );
      expect(form.FormResults.valueToJson(Object()), "Instance of 'Object'");
    });
  });

  group('exportValues', () {
    test('is JSON-safe, keeps hidden fields, skips derived and empty ones', () {
      controller.setFieldValues({
        'name': 'Ada',
        'colors': [_colors[0], _colors[2]],
        'files': [
          _fileOption('a.pdf', bytes: [1, 2, 3]),
        ],
        'hiddenNote': 'kept while hidden',
        'total': '42',
      });
      expect(controller.isFieldIdHidden('hiddenNote'), isTrue);

      final exported = controller.exportValues();
      expect(exported, {
        'name': 'Ada',
        'colors': ['red', 'blue'],
        'files': [
          {'name': 'a.pdf', 'mimeType': 'application/pdf', 'size': 3},
        ],
        'hiddenNote': 'kept while hidden',
      });
      expect(() => jsonEncode(exported), returnsNormally);
    });

    test('runs pending-edit flushers first', () {
      controller.registerPendingEditFlusher(
        #flusher,
        () => controller.updateFieldValue('name', 'flushed', noNotify: true),
      );
      expect(controller.exportValues()['name'], 'flushed');
    });
  });

  group('FormResults.toJson', () {
    test('visible values, derived included unless asked not to', () {
      controller.setFieldValues({
        'name': 'Ada',
        'favorite': ['green'],
        'hiddenNote': 'hidden',
        'total': '42',
      });
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );
      final json = results.toJson();
      expect(json['name'], 'Ada');
      expect(json['favorite'], ['green']);
      expect(json['total'], '42');
      expect(json.containsKey('hiddenNote'), isFalse);
      expect(results.toJson(includeDerived: false).containsKey('total'), false);
      expect(() => jsonEncode(json), returnsNormally);
    });
  });

  group('setFieldValues with JSON-shaped values', () {
    test('option values become the field\'s options', () {
      controller.setFieldValues({
        'colors': ['blue', 'nope', 'red'],
        'favorite': 'green',
      });
      expect(
        controller
            .getFieldValue<List<form.FieldOption>>('colors')!
            .map((o) => o.value),
        ['blue', 'red'],
      );
      final favorite = controller.getFieldValue<List<form.FieldOption>>(
        'favorite',
      )!;
      expect(favorite.single, same(_colors[1]));
    });

    test('file metadata is skipped; live file options are stored', () {
      controller.setFieldValues({
        'files': [
          {'name': 'a.pdf', 'size': 3},
        ],
      });
      expect(controller.hasFieldValue('files'), isFalse);

      final live = [_fileOption('b.pdf')];
      controller.setFieldValues({'files': live});
      expect(controller.getFieldValue<List<form.FieldOption>>('files'), live);
    });

    test('export → encode → decode → load round-trips', () {
      controller.setFieldValues({
        'name': 'Ada',
        'colors': [_colors[1]],
        'favorite': [_colors[2]],
        'hiddenNote': 'note',
      });
      final saved = jsonEncode(controller.exportValues());

      final fresh = form.FormController()..addFields(_fields());
      addTearDown(fresh.dispose);
      fresh.setFieldValues((jsonDecode(saved) as Map).cast<String, dynamic>());
      expect(jsonEncode(fresh.exportValues()), saved);
    });
  });

  group('values for fields not registered yet', () {
    test('wait in pendingFieldValues and apply on registration', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setFieldValues({'name': 'Ada', 'later': 'soon'});
      expect(notifications, 1);
      expect(controller.pendingFieldValues, {'later': 'soon'});
      expect(controller.getAllFieldValues().containsKey('later'), isFalse);

      controller.addFields([form.TextField(id: 'later')]);
      expect(controller.getFieldValue<String>('later'), 'soon');
      expect(controller.pendingFieldValues, isEmpty);
    });

    test('are converted for the field they land in', () {
      controller.setFieldValues({
        'laterColors': ['green'],
      });
      controller.addFields([
        form.OptionSelect(id: 'laterColors', options: _colors),
      ]);
      expect(controller.getFieldValue<List<form.FieldOption>>('laterColors'), [
        _colors[1],
      ]);
    });

    test('also apply through updateField', () {
      controller.setFieldValues({'later': 'soon'});
      controller.updateField(form.TextField(id: 'later'));
      expect(controller.getFieldValue<String>('later'), 'soon');
    });

    test('a later write wins; reset and clear discard them', () {
      controller.setFieldValues({'a': 'old', 'b': 'x', 'c': 'y'});
      controller.createFieldValue('a', 'new');
      controller.addFields([form.TextField(id: 'a')]);
      expect(controller.getFieldValue<String>('a'), 'new');

      controller.resetAllFields();
      expect(controller.pendingFieldValues, isEmpty);

      controller.setFieldValues({'d': 'z'});
      controller.clearForm();
      expect(controller.pendingFieldValues, isEmpty);
    });

    test('run no onChange or live validation when applied', () {
      var changes = 0;
      controller.setFieldValues({'quiet': ''});
      controller.addFields([
        form.TextField(
          id: 'quiet',
          validateLive: true,
          onChange: (_) => changes++,
          validators: [
            form.Validator(
              validator: (v) => (v as String? ?? '').isNotEmpty,
              reason: 'required',
            ),
          ],
        ),
      ]);
      expect(controller.getFieldValue<String>('quiet'), '');
      expect(changes, 0);
      expect(controller.findErrors('quiet'), isEmpty);
    });
  });
}
