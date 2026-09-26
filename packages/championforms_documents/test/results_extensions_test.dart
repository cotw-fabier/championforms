import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final doc = DocSnapshot([
    const HeadingNode(id: 'h', text: DocText('Scope')),
    const ParagraphNode(
      id: 'p',
      text: DocText('Build it', [
        DocMark(type: DocMarkType.bold, start: 0, end: 5),
      ]),
    ),
    const EmbeddedFieldNode(id: 'n1', fieldJson: {'type': 'textField'}),
  ]);

  form.FormResults resultsOf(Map<String, dynamic> values) => form.FormResults(
    results: values,
    fieldDefinitions: {
      for (final id in values.keys) id: form.NullField(id: id),
    },
  );

  group('FieldResultAccessor', () {
    test('asDocument accepts a snapshot', () {
      final r = resultsOf({'agreement': doc});
      expect(r.grab('agreement').asDocument(), same(doc));
      expect(r.grab('agreement').asDocumentJson(), doc.toJson());
    });

    test('asDocument accepts the JSON map form', () {
      final r = resultsOf({'agreement': doc.toJson()});
      expect(r.grab('agreement').asDocument(), doc);
    });

    test('asDocument is null for missing, wrong-typed or malformed values', () {
      final r = resultsOf({
        'nullValue': null,
        'text': 'hello',
        'bad': {'schemaVersion': 99, 'nodes': <Object>[]},
        'badNode': {
          'nodes': [42],
        },
      });
      for (final id in ['nullValue', 'text', 'bad', 'badNode', 'absent']) {
        expect(r.grab(id).asDocument(), isNull, reason: id);
        expect(r.grab(id).asDocumentJson(), isNull, reason: id);
        expect(r.grab(id).asMarkdown(), '', reason: id);
      }
      expect(r.grab('text').asMarkdown(fallback: '-'), '-');
    });

    test('asMarkdown renders, with an embedded field callback', () {
      final r = resultsOf({'agreement': doc});
      expect(
        r.grab('agreement').asMarkdown(),
        '# Scope\n\n**Build** it\n\n[field: textField]',
      );
      expect(
        r.grab('agreement').asMarkdown(embeddedField: (n) => '(${n.id})'),
        endsWith('(n1)'),
      );
    });
  });

  group('FormResults.extracted', () {
    test('collects {docId}.{key} entries only', () {
      final r = resultsOf({
        'agreement': doc,
        'agreement.people': ['alice'],
        'agreement.start_date': '2026-10-01',
        'agreement.missing': null,
        'agreement.field.n1': 'embedded value',
        'agreement2.people': ['mallory'],
        'other': 'x',
        'agreement.': 'empty key',
      });
      expect(r.extracted('agreement'), {
        'people': ['alice'],
        'start_date': '2026-10-01',
        'missing': null,
      });
      expect(r.extracted('agreement2'), {
        'people': ['mallory'],
      });
      expect(r.extracted('nothing'), isEmpty);
    });

    test(
      'works with getResults on a real controller, skipping hidden fields',
      () {
        final controller = form.FormController();
        addTearDown(controller.dispose);
        controller.addFields([
          form.NullField(id: 'agreement'),
          form.NullField(id: 'agreement.people'),
          form.NullField(id: 'agreement.field.n1'),
          form.NullField(id: 'hidden'),
          form.NullField(id: 'hidden.people', hideField: true),
        ]);
        controller.updateFieldValue<DocSnapshot>('agreement', doc);
        controller.updateFieldValue<List<String>>('agreement.people', [
          'alice',
        ]);
        controller.updateFieldValue<String>('agreement.field.n1', 'v');
        controller.updateFieldValue<List<String>>('hidden.people', ['eve']);

        final results = form.FormResults.getResults(controller: controller);
        expect(results.grab('agreement').asDocument(), doc);
        expect(results.extracted('agreement'), {
          'people': ['alice'],
        });
        expect(results.extracted('hidden'), isEmpty);
        expect(results.grab('agreement.field.n1').asRaw<String>(), 'v');
      },
    );
  });
}
