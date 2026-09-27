import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

final _doc = DocSnapshot([
  const ParagraphNode(id: 'p', text: DocText('Hello world')),
  const EmbeddedFieldNode(id: 'cur', fieldJson: {'type': 'text'}),
  const ParagraphNode(id: 'q', text: DocText('Bye')),
]);

void main() {
  group('blocks from JSON', () {
    test('carry an icon name, an id and keywords', () {
      DocumentFields.ensureInitialized();
      final field =
          form.FormFieldRegistry.fieldFromJson({
                'type': 'document',
                'id': 'doc',
                'blocks': [
                  {
                    'label': 'Rating',
                    'icon': 'star',
                    'id': 'rating',
                    'keywords': ['stars', 3, 'score'],
                    'field': {'type': 'text'},
                  },
                  {
                    'label': 'Mystery',
                    'icon': 'no_such_icon',
                    'field': {'type': 'text'},
                  },
                  {
                    'label': 'Plain',
                    'field': {'type': 'text'},
                  },
                ],
              })
              as DocumentField;
      final [rating, mystery, plain] = field.blockTemplates;
      expect(rating.icon, DocumentBlockIcons.named['star']);
      expect(rating.key, 'rating');
      expect(rating.keywords, ['stars', 'score']);
      expect(mystery.icon, DocumentBlockIcons.fallback);
      expect(mystery.key, 'mystery');
      expect(plain.icon, isNull, reason: 'the menu default icon');
    });

    test('apps can add icon names', () {
      DocumentBlockIcons.named['contract_test'] = Icons.gavel;
      addTearDown(() => DocumentBlockIcons.named.remove('contract_test'));
      expect(DocumentBlockIcons.resolve('contract_test'), Icons.gavel);
      expect(DocumentBlockIcons.resolve(42), DocumentBlockIcons.fallback);
    });
  });

  group('defaultClipboardDelegate', () {
    tearDown(() => DocumentFields.defaultClipboardDelegate = null);

    DocClipboardDelegate? editorDelegate(WidgetTester tester) => tester
        .widget<DocumentEditor>(find.byType(DocumentEditor))
        .clipboardDelegate;

    testWidgets('is used when a field has none, built once per controller', (
      tester,
    ) async {
      final built = <form.FormController>[];
      final fake = FakeDocClipboard();
      DocumentFields.defaultClipboardDelegate = (controller) {
        built.add(controller);
        return fake;
      };
      final h = await pumpDocumentForm(
        tester,
        fields: [DocumentField(id: 'doc', initialDocument: _doc)],
      );
      expect(editorDelegate(tester), same(fake));
      expect(built, [h.controller]);

      tester.element(find.byType(DocumentFieldWidget)).markNeedsBuild();
      await tester.pump();
      expect(built, hasLength(1));
    });

    testWidgets("a field's own delegate wins", (tester) async {
      var calls = 0;
      DocumentFields.defaultClipboardDelegate = (_) {
        calls++;
        return FakeDocClipboard();
      };
      final own = FakeDocClipboard();
      await pumpDocumentForm(
        tester,
        fields: [
          DocumentField(
            id: 'doc',
            initialDocument: _doc,
            clipboardDelegate: own,
          ),
        ],
      );
      expect(editorDelegate(tester), same(own));
      expect(calls, 0);
    });

    testWidgets('none set keeps the plain-text clipboard', (tester) async {
      await pumpDocumentForm(
        tester,
        fields: [DocumentField(id: 'doc', initialDocument: _doc)],
      );
      expect(editorDelegate(tester), isNull);
    });
  });

  group('live document issues', () {
    late form.FormController controller;

    setUp(() {
      controller = form.FormController()
        ..addFields([
          form.TextField(id: 'title'),
          DocumentField(
            id: 'doc',
            ruleSet: const RuleSet(
              extracts: [MentionsExtract(key: 'people', required: true)],
              constraints: [RequiredSectionRule(title: 'Scope')],
            ),
          ),
        ]);
    });
    tearDown(() => controller.dispose());

    test('issuesOf reads the current value without validating', () {
      final issues = DocumentFields.issuesOf(controller, 'doc');
      expect(issues, hasLength(2));
      expect(controller.formErrors, isEmpty);

      controller.updateFieldValue(
        'doc',
        DocSnapshot([
          const HeadingNode(id: 'h', text: DocText('Scope')),
          const ParagraphNode(id: 'p', text: DocText('Ask @ada')),
        ]),
      );
      expect(DocumentFields.issuesOf(controller, 'doc'), isEmpty);
    });

    test('issuesOf is empty for unknown and non-document ids', () {
      expect(DocumentFields.issuesOf(controller, 'nope'), isEmpty);
      expect(DocumentFields.issuesOf(controller, 'title'), isEmpty);
    });

    test('results.documentIssues works on unvalidated results', () {
      final results = form.FormResults.getResults(
        controller: controller,
        checkForErrors: false,
      );
      expect(results.errorState, isFalse);
      expect(
        results.documentIssues('doc').map((i) => i.message),
        DocumentFields.issuesOf(controller, 'doc').map((i) => i.message),
      );
      expect(results.documentIssues('title'), isEmpty);
      expect(results.documentIssues('nope'), isEmpty);
    });
  });

  group('programmatic selection', () {
    testWidgets('selectNode selects a text block or a field block whole', (
      tester,
    ) async {
      final h = await pumpDocumentForm(
        tester,
        fields: [DocumentField(id: 'doc', initialDocument: _doc)],
      );
      final editor = h.editorState;

      expect(editor.selectNode('p'), isTrue);
      await tester.pump();
      expect(editor.focusNode.hasPrimaryFocus, isTrue);
      var s = editor.selection!;
      expect(
        (s.startNodeId, s.startOffset, s.endNodeId, s.endOffset),
        ('p', 0, 'p', 11),
      );

      expect(editor.selectNode('cur'), isTrue);
      s = editor.selection!;
      expect(
        (s.startNodeId, s.startOffset, s.endNodeId, s.endOffset),
        ('cur', 0, 'cur', 1),
      );

      expect(editor.selectNode('missing'), isFalse);
      expect(editor.selection!.startNodeId, 'cur', reason: 'unchanged');
    });

    testWidgets('selectRange spans blocks, clamps, and places carets', (
      tester,
    ) async {
      final h = await pumpDocumentForm(
        tester,
        fields: [DocumentField(id: 'doc', initialDocument: _doc)],
      );
      final editor = h.editorState;

      expect(
        editor.selectRange(
          const DocSelection(
            startNodeId: 'p',
            startOffset: 6,
            endNodeId: 'q',
            endOffset: 99,
          ),
        ),
        isTrue,
      );
      var s = editor.selection!;
      expect(
        (s.startNodeId, s.startOffset, s.endNodeId, s.endOffset),
        ('p', 6, 'q', 3),
      );

      editor.selectRange(
        const DocSelection(
          startNodeId: 'q',
          startOffset: 1,
          endNodeId: 'q',
          endOffset: 1,
        ),
      );
      expect(editor.selection!.isCollapsed, isTrue);

      expect(
        editor.selectRange(
          const DocSelection(
            startNodeId: 'p',
            startOffset: 0,
            endNodeId: 'gone',
            endOffset: 0,
          ),
        ),
        isFalse,
      );
    });

    testWidgets('a selected block is what copy copies', (tester) async {
      final clipboard = FakeDocClipboard();
      final h = await pumpDocumentForm(
        tester,
        fields: [
          DocumentField(
            id: 'doc',
            initialDocument: _doc,
            clipboardDelegate: clipboard,
          ),
        ],
      );
      h.editorState.selectNode('cur');
      await h.editorState.clipboard!.copy();
      final copied = clipboard.copies.single.selection;
      expect((copied.startNodeId, copied.endNodeId), ('cur', 'cur'));
    });
  });
}
