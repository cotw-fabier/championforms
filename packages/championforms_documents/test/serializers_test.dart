import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

DocText t(String text, [List<DocMark> marks = const []]) =>
    DocText(text, marks);
DocMark m(DocMarkType type, int start, int end, [String? href]) =>
    DocMark(type: type, start: start, end: end, href: href);

void main() {
  group('markdownInline', () {
    test('each mark type', () {
      expect(markdownInline(t('a b', [m(DocMarkType.bold, 0, 1)])), '**a** b');
      expect(markdownInline(t('a b', [m(DocMarkType.italic, 2, 3)])), 'a _b_');
      expect(
        markdownInline(t('run x', [m(DocMarkType.code, 0, 3)])),
        '`run` x',
      );
      expect(
        markdownInline(
          t('see docs', [m(DocMarkType.link, 4, 8, 'https://d.io')]),
        ),
        'see [docs](https://d.io)',
      );
      expect(
        markdownInline(t('old', [m(DocMarkType.strikethrough, 0, 3)])),
        '~~old~~',
      );
      expect(
        markdownInline(t('u', [m(DocMarkType.underline, 0, 1)])),
        '<u>u</u>',
      );
    });

    test('nested marks: link outermost, code innermost', () {
      expect(
        markdownInline(
          t('click', [
            m(DocMarkType.code, 0, 5),
            m(DocMarkType.bold, 0, 5),
            m(DocMarkType.link, 0, 5, 'u'),
          ]),
        ),
        '[**`click`**](u)',
      );
    });

    test('overlapping marks are closed and reopened', () {
      expect(
        markdownInline(
          t('abcdef', [m(DocMarkType.bold, 0, 4), m(DocMarkType.italic, 2, 6)]),
        ),
        '**ab_cd_**_ef_',
      );
      // A mark that should nest outside an open inner one reopens it.
      expect(
        markdownInline(
          t('abcd', [m(DocMarkType.code, 0, 4), m(DocMarkType.bold, 2, 4)]),
        ),
        '`ab`**`cd`**',
      );
    });

    test('escapes punctuation outside code only', () {
      expect(
        markdownInline(t(r'a*b_c`d[e]f~g<h\', [m(DocMarkType.code, 0, 1)])),
        r'`a`\*b\_c\`d\[e\]f\~g\<h\\',
      );
      expect(markdownInline(t('x*y', [m(DocMarkType.code, 0, 3)])), '`x*y`');
    });

    test('marks past the end are clipped; empty marks ignored', () {
      expect(
        markdownInline(
          t('ab', [m(DocMarkType.bold, 1, 9), m(DocMarkType.italic, 1, 1)]),
        ),
        'a**b**',
      );
    });

    test('emoji inside marks', () {
      expect(
        markdownInline(t('hi 👋🏽!', [m(DocMarkType.bold, 3, 7)])),
        'hi **👋🏽**!',
      );
    });
  });

  group('toMarkdown', () {
    final doc = DocSnapshot([
      HeadingNode(
        id: 'h',
        level: 2,
        text: t('Plan', [m(DocMarkType.italic, 0, 4)]),
      ),
      ParagraphNode(
        id: 'p',
        text: t('Hello world', [m(DocMarkType.bold, 6, 11)]),
      ),
      const ParagraphNode(id: 'blank'),
      const ListItemNode(id: 'l1', ordered: true, text: DocText('one')),
      const ListItemNode(
        id: 'l2',
        ordered: true,
        indent: 1,
        text: DocText('nested'),
      ),
      const ListItemNode(id: 'l3', ordered: true, text: DocText('two')),
      const ListItemNode(id: 'l4', text: DocText('bullet')),
      const TaskNode(id: 't1', checked: true, text: DocText('done')),
      const TaskNode(id: 't2', text: DocText('todo')),
      const QuoteNode(id: 'q', text: DocText('wise')),
      const DividerNode(id: 'd'),
      const EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'fileUpload'}),
      const ListItemNode(id: 'l5', ordered: true, text: DocText('restart')),
    ]);

    test('renders every block', () {
      expect(toMarkdown(doc), '''
## _Plan_

Hello **world**

1. one
  1. nested
2. two
- bullet
- [x] done
- [ ] todo

> wise

---

[field: fileUpload]

1. restart''');
    });

    test('embedded field callback', () {
      expect(
        toMarkdown(
          DocSnapshot(const [
            EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'x'}),
          ]),
          embeddedField: (n) => '<${n.id}:${n.fieldType}>',
        ),
        '<e:x>',
      );
      expect(
        toMarkdown(
          DocSnapshot(const [EmbeddedFieldNode(id: 'e', fieldJson: {})]),
        ),
        '[field: unknown]',
      );
    });

    test('paragraphs that look like blocks are escaped', () {
      final d = DocSnapshot(const [
        ParagraphNode(id: 'a', text: DocText('# not a heading')),
        ParagraphNode(id: 'b', text: DocText('- not a list')),
        ParagraphNode(id: 'c', text: DocText('3. not ordered')),
        ParagraphNode(id: 'd', text: DocText('---')),
        ParagraphNode(id: 'e', text: DocText('> no')),
        ParagraphNode(id: 'f', text: DocText('#hashtag')),
      ]);
      expect(toMarkdown(d).split('\n\n'), [
        r'\# not a heading',
        r'\- not a list',
        r'3\. not ordered',
        r'\---',
        r'\> no',
        r'\#hashtag',
      ]);
    });

    test('empty document', () {
      expect(toMarkdown(DocSnapshot.empty), '');
      expect(toMarkdown(DocSnapshot(const [ParagraphNode(id: 'a')])), '');
    });
  });

  group('toPlainText', () {
    test('one line per block with plain markers; marks dropped', () {
      final doc = DocSnapshot([
        const HeadingNode(id: 'h', text: DocText('Title')),
        ParagraphNode(id: 'p', text: t('bold 👋', [m(DocMarkType.bold, 0, 4)])),
        const ListItemNode(id: 'l1', ordered: true, text: DocText('a')),
        const ListItemNode(id: 'l2', ordered: true, text: DocText('b')),
        const ListItemNode(id: 'l3', indent: 1, text: DocText('c')),
        const TaskNode(id: 't', checked: true, text: DocText('d')),
        const TaskNode(id: 't2', text: DocText('e')),
        const QuoteNode(id: 'q', text: DocText('f')),
        const DividerNode(id: 'd'),
        const EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'textField'}),
        const ParagraphNode(id: 'z'),
      ]);
      expect(
        toPlainText(doc),
        'Title\nbold 👋\n1. a\n2. b\n  - c\n[x] d\n[ ] e\n> f\n---\n[field: textField]\n',
      );
      expect(
        toPlainText(doc, embeddedField: (_) => 'FILE').contains('FILE'),
        isTrue,
      );
    });

    test('empty document', () {
      expect(toPlainText(DocSnapshot.empty), '');
    });
  });

  group('fromPlainText', () {
    test('runs lines through the markdown prefixes', () {
      final doc = fromPlainText(
        '# Title\r\nplain\n- a\n  * nested\n\t\t- deeper\n3. c\n[ ] todo\n[x] done\n> q\n---\n\n   indented\n',
      );
      final summary = [
        for (final n in doc.nodes)
          switch (n) {
            HeadingNode(:final level, :final text) => 'h$level:${text.text}',
            ListItemNode(:final ordered, :final indent, :final text) =>
              '${ordered ? 'ol' : 'ul'}$indent:${text.text}',
            TaskNode(:final checked, :final text) =>
              'task$checked:${text.text}',
            QuoteNode(:final text) => 'q:${text.text}',
            DividerNode() => 'hr',
            ParagraphNode(:final text) => 'p:${text.text}',
            EmbeddedFieldNode() => 'field',
          },
      ];
      expect(summary, [
        'h1:Title',
        'p:plain',
        'ul0:a',
        'ul1:nested',
        'ul2:deeper',
        'ol0:c',
        'taskfalse:todo',
        'tasktrue:done',
        'q:q',
        'hr',
        'p:',
        'p:   indented',
      ]);
      expect(doc.nodes.map((n) => n.id).toSet(), hasLength(doc.nodes.length));
    });

    test('empty string, lone newline and a custom rule', () {
      expect(fromPlainText('').nodes, isEmpty);
      expect(fromPlainText('\n').nodes.single, isA<ParagraphNode>());
      final doc = fromPlainText(
        '- x',
        rule: const MarkdownPrefixRule(prefixes: {}, numberedLists: false),
      );
      expect((doc.nodes.single as ParagraphNode).text.text, '- x');
    });

    test(
      'round-trips list, task, quote and divider blocks via toPlainText',
      () {
        final original = DocSnapshot(const [
          ParagraphNode(id: '1', text: DocText('intro 👋')),
          ListItemNode(id: '2', text: DocText('a')),
          ListItemNode(id: '3', indent: 1, text: DocText('b')),
          ListItemNode(id: '4', ordered: true, text: DocText('c')),
          TaskNode(id: '5', checked: true, text: DocText('d')),
          QuoteNode(id: '6', text: DocText('e')),
          DividerNode(id: '7'),
        ]);
        final back = fromPlainText(toPlainText(original));
        expect(
          back.nodes.map((n) => n.toJson()..remove('id')),
          original.nodes.map((n) => n.toJson()..remove('id')),
        );
      },
    );
  });
}
