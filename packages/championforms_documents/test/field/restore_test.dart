import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

EmbeddedFieldNode _block(String id, Map<String, dynamic> json) =>
    EmbeddedFieldNode(id: id, fieldJson: json);

/// The template's document: one select block that every fresh form has.
final _template = DocSnapshot([
  const ParagraphNode(id: 'p', text: DocText('Currency and sign-off:')),
  _block('cur', {
    'type': 'select',
    'title': 'Currency',
    'options': ['USD', 'EUR'],
  }),
]);

List<form.Field> _fields() => [
  form.TextField(id: 'title'),
  DocumentField(
    id: 'doc',
    initialDocument: _template,
    ruleSet: const RuleSet(extracts: [MentionsExtract(key: 'people')]),
  ),
];

/// A document the person built on top of the template: new text, and two
/// blocks the template does not have (so their ids are unknown to a fresh
/// form until the document is restored).
final _edited = DocSnapshot([
  const ParagraphNode(id: 'p', text: DocText('Currency and sign-off: @ada')),
  _block('cur', {
    'type': 'select',
    'title': 'Currency',
    'options': ['USD', 'EUR'],
  }),
  _block('agree', {
    'type': 'checkboxSelect',
    'multiselect': true,
    'options': ['terms', 'privacy'],
  }),
  _block('who', {'type': 'name'}),
  _block('note', {'type': 'text'}),
]);

Future<form.FormController> _pumpFresh(WidgetTester tester) async {
  final controller = form.FormController();
  addTearDown(controller.dispose);
  await pumpDocumentForm(tester, fields: _fields(), controller: controller);
  return controller;
}

String _resultsJson(form.FormController controller) => jsonEncode(
  form.FormResults.getResults(
    controller: controller,
    checkForErrors: false,
  ).toJson(),
);

void main() {
  testWidgets('save, reset, one setFieldValues: identical results', (
    tester,
  ) async {
    // Fill a form.
    final first = await _pumpFresh(tester);
    first.setFieldValues({'doc': _edited});
    await tester.pumpAndSettle();
    first.setFieldValues({
      'title': 'Agreement',
      'doc.field.cur': ['EUR'],
      'doc.field.agree': ['privacy', 'terms'],
      'doc.field.who_firstname': 'Ada',
      'doc.field.who_lastname': 'Lovelace',
      'doc.field.note': 'hello',
    });
    await tester.pumpAndSettle();

    final saved = jsonEncode(first.exportValues());
    final before = _resultsJson(first);
    final exported = jsonDecode(saved) as Map<String, dynamic>;
    expect(exported['doc'], isA<Map>(), reason: 'the document as JSON');
    expect(exported.containsKey('doc.people'), isFalse, reason: 'derived');
    expect(exported['doc.field.agree'], ['privacy', 'terms']);
    expect(jsonDecode(before)['doc.people'], ['ada']);

    // Reset: a fresh controller and form, as a template reset would do.
    final second = await _pumpFresh(tester);
    expect(second.hasFieldDefinition('doc.field.agree'), isFalse);

    // One call restores the document and its blocks' values.
    second.setFieldValues(jsonDecode(saved) as Map<String, dynamic>);
    expect(
      second.getFieldValue<String>('doc.field.note'),
      'hello',
      reason: 'applied in the same call, before any frame',
    );
    expect(second.pendingFieldValues, isEmpty);
    await tester.pumpAndSettle();

    expect(jsonDecode(_resultsJson(second)), jsonDecode(before));
    expect(jsonDecode(jsonEncode(second.exportValues())), exported);
    final editor = tester.state<DocumentFieldWidgetState>(
      find.byType(DocumentFieldWidget),
    );
    expect(editor.editorState!.snapshot(), _edited);
  });

  testWidgets('blocks restore while the document is off screen', (
    tester,
  ) async {
    final controller = await _pumpFresh(tester);
    // Unmount the form; the document's runtime stays on the controller.
    await tester.pumpWidget(const SizedBox());

    controller.setFieldValues({
      'doc': _edited.toJson(),
      'doc.field.note': 'while away',
      'doc.field.agree': ['terms'],
    });
    expect(controller.getFieldValue<String>('doc.field.note'), 'while away');
    final results = form.FormResults.getResults(
      controller: controller,
      checkForErrors: false,
    );
    expect(results.grab('doc.field.agree').asStringList(), ['terms']);
    expect(results.extracted('doc')['people'], ['ada']);
  });

  testWidgets('values for blocks the document does not have stay pending', (
    tester,
  ) async {
    final controller = await _pumpFresh(tester);
    controller.setFieldValues({'doc.field.ghost': 'boo'});
    await tester.pumpAndSettle();
    expect(controller.hasFieldDefinition('doc.field.ghost'), isFalse);
    expect(controller.pendingFieldValues, {'doc.field.ghost': 'boo'});
  });
}
