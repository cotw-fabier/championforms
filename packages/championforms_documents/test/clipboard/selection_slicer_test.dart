import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bold = DocMark(type: DocMarkType.bold, start: 0, end: 5);
  final doc = DocSnapshot([
    const HeadingNode(id: 'h', level: 2, text: DocText('Title')),
    const ParagraphNode(id: 'p1', text: DocText('Hello world', [bold])),
    const DividerNode(id: 'd'),
    const ListItemNode(id: 'l', ordered: true, text: DocText('Item')),
    const EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'textField'}),
    const ParagraphNode(id: 'p2', text: DocText('Tail text')),
  ]);

  List<DocNode> slice(String s, int so, String e, int eo) => sliceSelection(
    doc,
    DocSelection(startNodeId: s, startOffset: so, endNodeId: e, endOffset: eo),
  );

  test('collapsed selection gives nothing', () {
    expect(slice('p1', 3, 'p1', 3), isEmpty);
    expect(slice('e', 0, 'e', 0), isEmpty);
  });

  test('unknown ids or reversed order give nothing', () {
    expect(slice('nope', 0, 'p1', 3), isEmpty);
    expect(slice('p2', 0, 'p1', 3), isEmpty);
  });

  test('partial text inside one node keeps the id and clips marks', () {
    final result = slice('p1', 3, 'p1', 8);
    expect(result, hasLength(1));
    final p = result.single as ParagraphNode;
    expect(p.id, 'p1');
    expect(p.text.text, 'lo wo');
    expect(p.text.marks, [
      const DocMark(type: DocMarkType.bold, start: 0, end: 2),
    ]);
  });

  test('multi-node selection trims the edges and keeps the middle whole', () {
    final result = slice('h', 2, 'p2', 4);
    expect(result.map((n) => n.id), ['h', 'p1', 'd', 'l', 'e', 'p2']);
    expect((result.first as HeadingNode).text.text, 'tle');
    expect((result.first as HeadingNode).level, 2);
    expect(result[1], same(doc.nodes[1]));
    expect((result.last as ParagraphNode).text.text, 'Tail');
  });

  test('offsets are clamped to the text', () {
    final result = slice('p1', -4, 'p1', 99);
    expect((result.single as ParagraphNode).text.text, 'Hello world');
  });

  test('edge text nodes only touched at their boundary are dropped', () {
    // From the very end of p1 to the very start of p2.
    final result = slice('p1', 11, 'p2', 0);
    expect(result.map((n) => n.id), ['d', 'l', 'e']);
  });

  group('block nodes', () {
    test('a block is included when the selection covers it', () {
      expect(slice('e', 0, 'e', 1).single.id, 'e');
      expect(slice('d', 0, 'l', 2).map((n) => n.id), ['d', 'l']);
      expect(slice('l', 0, 'e', 1).map((n) => n.id), ['l', 'e']);
    });

    test('a block at an edge that the selection does not cover is dropped', () {
      // Starts after the divider.
      expect(slice('d', 1, 'l', 4).map((n) => n.id), ['l']);
      // Ends before the embedded field.
      expect(slice('l', 0, 'e', 0).map((n) => n.id), ['l']);
    });
  });
}
