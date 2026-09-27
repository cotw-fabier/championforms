import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;

/// Every node kind and every mark type, marks in canonical order.
DocSnapshot _everything() => DocSnapshot([
  const ParagraphNode(
    id: 'p',
    text: DocText('bold italic under strike code link', [
      DocMark(type: DocMarkType.bold, start: 0, end: 4),
      DocMark(type: DocMarkType.italic, start: 5, end: 11),
      DocMark(type: DocMarkType.underline, start: 12, end: 17),
      DocMark(type: DocMarkType.strikethrough, start: 18, end: 24),
      DocMark(type: DocMarkType.code, start: 25, end: 29),
      DocMark(
        type: DocMarkType.link,
        start: 30,
        end: 34,
        href: 'https://example.com',
      ),
    ]),
  ),
  const HeadingNode(id: 'h1', level: 1, text: DocText('One')),
  const HeadingNode(id: 'h2', level: 2, text: DocText('Two')),
  const HeadingNode(id: 'h3', level: 3, text: DocText('Three')),
  const HeadingNode(id: 'h6', level: 6, text: DocText('Six')),
  const ListItemNode(id: 'ul', text: DocText('bullet')),
  const ListItemNode(id: 'ol', ordered: true, indent: 2, text: DocText('n')),
  const TaskNode(id: 't0', text: DocText('open')),
  const TaskNode(id: 't1', checked: true, text: DocText('done')),
  const QuoteNode(id: 'q', text: DocText('quoted')),
  const DividerNode(id: 'hr'),
  const EmbeddedFieldNode(
    id: 'emb',
    fieldJson: {
      'type': 'text',
      'title': 'Name',
      'validators': ['required'],
    },
    sourceId: 'orig',
  ),
  const ParagraphNode(
    id: 'overlap',
    text: DocText('overlapping', [
      DocMark(type: DocMarkType.bold, start: 0, end: 7),
      DocMark(type: DocMarkType.italic, start: 3, end: 11),
    ]),
  ),
  const ParagraphNode(id: 'empty'),
]);

void main() {
  group('SuperEditorAdapter', () {
    test('snapshot -> MutableDocument -> snapshot is lossless', () {
      final original = _everything();
      final document = SuperEditorAdapter.toMutableDocument(original);
      final back = SuperEditorAdapter.toSnapshot(document);
      expect(back, original);
      expect(back.toJson(), original.toJson());
    });

    test('text conversion alone (no node cache) is lossless', () {
      for (final node in _everything().nodes.whereType<TextDocNode>()) {
        final back = SuperEditorAdapter.toDocText(
          SuperEditorAdapter.toAttributedText(node.text),
        );
        expect(back, node.text, reason: node.id);
      }
    });

    test('an equal editor document built independently converts equal', () {
      // Rebuild every editor node by hand-copying it, so nothing comes from
      // the conversion cache.
      final original = _everything();
      final document = SuperEditorAdapter.toMutableDocument(original);
      final copy = se.MutableDocument(
        nodes: [
          for (final n in document) n.copyAndReplaceMetadata({...n.metadata}),
        ],
      );
      expect(SuperEditorAdapter.toSnapshot(copy), original);
    });

    test('node ids are preserved in the editor', () {
      final original = _everything();
      final document = SuperEditorAdapter.toMutableDocument(original);
      expect(
        document.map((n) => n.id).toList(),
        original.nodes.map((n) => n.id).toList(),
      );
    });

    test('editor node kinds are the super_editor ones', () {
      final document = SuperEditorAdapter.toMutableDocument(_everything());
      expect(document.getNodeById('p'), isA<se.ParagraphNode>());
      expect(
        document.getNodeById('h2')!.metadata[se.NodeMetadata.blockType],
        se.header2Attribution,
      );
      expect(
        document.getNodeById('q')!.metadata[se.NodeMetadata.blockType],
        se.blockquoteAttribution,
      );
      final ol = document.getNodeById('ol') as se.ListItemNode;
      expect(ol.type, se.ListItemType.ordered);
      expect(ol.indent, 2);
      expect((document.getNodeById('t1') as se.TaskNode).isComplete, isTrue);
      expect(document.getNodeById('hr'), isA<se.HorizontalRuleNode>());
      expect(document.getNodeById('emb'), isA<EmbeddedFieldBlock>());
    });

    test('marks convert exclusive <-> inclusive', () {
      final document = SuperEditorAdapter.toMutableDocument(_everything());
      final text = (document.getNodeById('p') as se.TextNode).text;
      final bold = text
          .getAttributionSpansByFilter((a) => a == se.boldAttribution)
          .single;
      expect(bold.start, 0);
      expect(bold.end, 3, reason: 'inclusive end of [0, 4)');
      final link = text
          .getAttributionSpansByFilter((a) => a is se.LinkAttribution)
          .single;
      expect(
        (link.attribution as se.LinkAttribution).plainTextUri,
        'https://example.com',
      );
    });

    test('marks read from the editor come back in canonical order', () {
      final text = SuperEditorAdapter.toAttributedText(
        const DocText('abcdef', [
          DocMark(type: DocMarkType.italic, start: 2, end: 4),
          DocMark(type: DocMarkType.bold, start: 0, end: 3),
        ]),
      );
      final marks = SuperEditorAdapter.toDocText(text).marks;
      expect(marks.map((m) => m.type), [DocMarkType.bold, DocMarkType.italic]);
    });

    test('empty marks are dropped, out-of-range marks clamped', () {
      final text = SuperEditorAdapter.toAttributedText(
        const DocText('abc', [
          DocMark(type: DocMarkType.bold, start: 1, end: 1),
          DocMark(type: DocMarkType.italic, start: 1, end: 99),
        ]),
      );
      final back = SuperEditorAdapter.toDocText(text);
      expect(back.marks, [
        const DocMark(type: DocMarkType.italic, start: 1, end: 3),
      ]);
    });

    test('editor-only nodes degrade: a code block becomes a paragraph', () {
      final document = se.MutableDocument(
        nodes: [
          se.ParagraphNode(
            id: 'c',
            text: se.AttributedText('code'),
            metadata: {se.NodeMetadata.blockType: se.codeAttribution},
          ),
        ],
      );
      final snapshot = SuperEditorAdapter.toSnapshot(document);
      expect(snapshot.nodes.single, isA<ParagraphNode>());
    });

    test('selections convert both ways, normalized', () {
      final document = SuperEditorAdapter.toMutableDocument(_everything());
      // Backwards selection from the quote into the paragraph.
      final editorSelection = se.DocumentSelection(
        base: const se.DocumentPosition(
          nodeId: 'q',
          nodePosition: se.TextNodePosition(offset: 3),
        ),
        extent: const se.DocumentPosition(
          nodeId: 'p',
          nodePosition: se.TextNodePosition(offset: 5),
        ),
      );
      final selection = SuperEditorAdapter.toDocSelection(
        document,
        editorSelection,
      );
      expect(selection.startNodeId, 'p');
      expect(selection.startOffset, 5);
      expect(selection.endNodeId, 'q');
      expect(selection.endOffset, 3);

      final blockSelection = SuperEditorAdapter.toEditorSelection(
        document,
        const DocSelection(
          startNodeId: 'hr',
          startOffset: 0,
          endNodeId: 'emb',
          endOffset: 1,
        ),
      );
      expect(
        blockSelection.base.nodePosition,
        const se.UpstreamDownstreamNodePosition.upstream(),
      );
      expect(
        blockSelection.extent.nodePosition,
        const se.UpstreamDownstreamNodePosition.downstream(),
      );
      final roundTrip = SuperEditorAdapter.toDocSelection(
        document,
        blockSelection,
      );
      expect(roundTrip.startNodeId, 'hr');
      expect(roundTrip.startOffset, 0);
      expect(roundTrip.endNodeId, 'emb');
      expect(roundTrip.endOffset, 1);
    });

    test('an edited node converts freshly (no stale cache)', () {
      final document = SuperEditorAdapter.toMutableDocument(
        DocSnapshot([const ParagraphNode(id: 'p', text: DocText('a'))]),
      );
      expect(
        SuperEditorAdapter.toSnapshot(document).nodes.single,
        isA<ParagraphNode>(),
      );
      document.replaceNodeById(
        'p',
        se.ParagraphNode(id: 'p', text: se.AttributedText('b')),
      );
      final node = SuperEditorAdapter.toSnapshot(document).nodes.single;
      expect((node as ParagraphNode).text.text, 'b');
    });
  });
}
