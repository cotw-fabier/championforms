import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

/// Runs [rule] and applies its edit; null when it declines.
({DocSnapshot doc, DocCaret? caret})? run(
  TransformRule rule,
  DocSnapshot doc,
  DocInputEvent event,
) => TransformEngine([rule]).run(doc, event);

DocSnapshot single(DocNode node) => DocSnapshot([node]);

void main() {
  setUpAll(DocumentRules.ensureInitialized);

  group('markdownPrefix', () {
    const rule = MarkdownPrefixRule();

    ({DocSnapshot doc, DocCaret? caret})? typed(
      String text, {
      int? caret,
      List<DocMark> marks = const [],
    }) => run(
      rule,
      single(ParagraphNode(id: 'p', text: DocText(text, marks))),
      TextInserted('p', text: ' ', caretOffset: caret ?? text.length),
    );

    final cases = <String, DocNode Function(DocText)>{
      '- ': (t) => ListItemNode(id: 'p', text: t),
      '* ': (t) => ListItemNode(id: 'p', text: t),
      '1. ': (t) => ListItemNode(id: 'p', ordered: true, text: t),
      '7. ': (t) => ListItemNode(id: 'p', ordered: true, text: t),
      '# ': (t) => HeadingNode(id: 'p', level: 1, text: t),
      '## ': (t) => HeadingNode(id: 'p', level: 2, text: t),
      '### ': (t) => HeadingNode(id: 'p', level: 3, text: t),
      '#### ': (t) => HeadingNode(id: 'p', level: 4, text: t),
      '##### ': (t) => HeadingNode(id: 'p', level: 5, text: t),
      '###### ': (t) => HeadingNode(id: 'p', level: 6, text: t),
      '[] ': (t) => TaskNode(id: 'p', text: t),
      '[ ] ': (t) => TaskNode(id: 'p', text: t),
      '[x] ': (t) => TaskNode(id: 'p', checked: true, text: t),
      '> ': (t) => QuoteNode(id: 'p', text: t),
    };

    for (final e in cases.entries) {
      test('"${e.key}" converts an empty paragraph', () {
        final r = typed(e.key)!;
        expect(r.doc.nodes.single, e.value(DocText.empty));
        expect(r.caret!.nodeId, 'p');
        expect(r.caret!.offset, 0);
      });
    }

    test('keeps the text after the prefix when typed before existing text', () {
      // "-|foo" then a space typed at offset 1 -> "- foo", caret 2.
      final r = typed('- foo', caret: 2)!;
      expect(
        r.doc.nodes.single,
        const ListItemNode(id: 'p', text: DocText('foo')),
      );
    });

    test('strips the prefix and shifts marks left', () {
      final r = typed(
        '## bold then',
        caret: 3,
        marks: const [
          DocMark(type: DocMarkType.bold, start: 3, end: 7),
          DocMark(
            type: DocMarkType.italic,
            start: 0,
            end: 4,
          ), // overlaps prefix
          DocMark(type: DocMarkType.code, start: 0, end: 2), // inside prefix
          DocMark(
            type: DocMarkType.link,
            start: 8,
            end: 12,
            href: 'https://a.b',
          ),
        ],
      )!;
      expect(
        r.doc.nodes.single,
        const HeadingNode(
          id: 'p',
          level: 2,
          text: DocText('bold then', [
            DocMark(type: DocMarkType.bold, start: 0, end: 4),
            DocMark(type: DocMarkType.italic, start: 0, end: 1),
            DocMark(
              type: DocMarkType.link,
              start: 5,
              end: 9,
              href: 'https://a.b',
            ),
          ]),
        ),
      );
    });

    test('multi-byte text after the prefix survives intact', () {
      final r = typed(
        '- 👋🏽 zoë',
        caret: 2,
        marks: const [DocMark(type: DocMarkType.bold, start: 2, end: 6)],
      )!;
      final node = r.doc.nodes.single as ListItemNode;
      expect(node.text.text, '👋🏽 zoë');
      expect(
        node.text.marks.single,
        const DocMark(type: DocMarkType.bold, start: 0, end: 4),
      );
    });

    test('the longest prefix wins', () {
      expect(typed('[ ] ')!.doc.nodes.single, isA<TaskNode>());
      expect((typed('### ')!.doc.nodes.single as HeadingNode).level, 3);
    });

    test('declines when the caret is not right after the prefix', () {
      expect(typed('- foo', caret: 5), isNull);
      expect(typed('- foo', caret: 1), isNull);
    });

    test('declines without a prefix, off a paragraph, or on other events', () {
      expect(typed('hello'), isNull);
      expect(typed('-foo', caret: 1), isNull);
      expect(typed('#no'), isNull);
      expect(
        run(
          rule,
          single(const HeadingNode(id: 'p', text: DocText('- '))),
          const TextInserted('p', text: ' ', caretOffset: 2),
        ),
        isNull,
      );
      expect(
        run(
          rule,
          single(const ParagraphNode(id: 'p', text: DocText('- '))),
          const BackspaceAtStart('p'),
        ),
        isNull,
      );
      expect(
        run(
          rule,
          DocSnapshot.empty,
          const TextInserted('missing', text: ' ', caretOffset: 2),
        ),
        isNull,
      );
    });

    test('numberedLists can be turned off', () {
      const strict = MarkdownPrefixRule(numberedLists: false);
      final doc = single(const ParagraphNode(id: 'p', text: DocText('2. ')));
      expect(
        run(strict, doc, const TextInserted('p', text: ' ', caretOffset: 3)),
        isNull,
      );
      expect(
        run(rule, doc, const TextInserted('p', text: ' ', caretOffset: 3)),
        isNotNull,
      );
    });

    test('a custom prefix map replaces the defaults', () {
      const custom = MarkdownPrefixRule(
        prefixes: {'!! ': PrefixTarget.heading(2)},
        numberedLists: false,
      );
      final doc = single(const ParagraphNode(id: 'p', text: DocText('!! x')));
      final r = run(
        custom,
        doc,
        const TextInserted('p', text: ' ', caretOffset: 3),
      )!;
      expect(
        r.doc.nodes.single,
        const HeadingNode(id: 'p', level: 2, text: DocText('x')),
      );
      expect(
        run(
          custom,
          single(const ParagraphNode(id: 'p', text: DocText('- '))),
          const TextInserted('p', text: ' ', caretOffset: 2),
        ),
        isNull,
      );
    });

    group('divider', () {
      final doc = DocSnapshot(const [
        ParagraphNode(id: 'p', text: DocText('---')),
        ParagraphNode(id: 'after', text: DocText('next')),
      ]);

      test('--- then Enter makes a divider and a new paragraph', () {
        final r = run(rule, doc, const EnterPressed('p', caretOffset: 3))!;
        expect(r.doc.nodes[0], const DividerNode(id: 'p'));
        final fresh = r.doc.nodes[1] as ParagraphNode;
        expect(fresh.text, DocText.empty);
        expect(fresh.id, isNot(anyOf('p', 'after')));
        expect(r.doc.nodes[2].id, 'after');
        expect(r.caret!.nodeId, fresh.id);
        expect(r.caret!.offset, 0);
      });

      test('--- alone does not fire on typing', () {
        expect(
          run(rule, doc, const TextInserted('p', text: '-', caretOffset: 3)),
          isNull,
        );
      });

      test('declines mid-text or with extra text', () {
        expect(run(rule, doc, const EnterPressed('p', caretOffset: 1)), isNull);
        expect(
          run(
            rule,
            single(const ParagraphNode(id: 'p', text: DocText('--- x'))),
            const EnterPressed('p', caretOffset: 5),
          ),
          isNull,
        );
      });
    });

    test('convertLine handles prefixes, dividers and plain lines', () {
      expect(
        rule.convertLine(const ParagraphNode(id: 'a', text: DocText('# T'))),
        const HeadingNode(id: 'a', text: DocText('T')),
      );
      expect(
        rule.convertLine(const ParagraphNode(id: 'a', text: DocText('---'))),
        const DividerNode(id: 'a'),
      );
      expect(
        rule.convertLine(const ParagraphNode(id: 'a', text: DocText('plain'))),
        const ParagraphNode(id: 'a', text: DocText('plain')),
      );
    });

    test('JSON round-trip keeps the prefix map', () {
      const custom = MarkdownPrefixRule(
        prefixes: {
          '> ': PrefixTarget.quote(),
          '+ ': PrefixTarget.listItem(ordered: true),
          '[v] ': PrefixTarget.task(checked: true),
          '=== ': PrefixTarget.divider(),
          '#1 ': PrefixTarget.heading(1),
        },
        numberedLists: false,
      );
      final back =
          RuleRegistry.fromJson(RuleRegistry.toJson(custom))
              as MarkdownPrefixRule;
      expect(back.prefixes, custom.prefixes);
      expect(back.numberedLists, isFalse);
    });

    test('fromJson without prefixes uses the defaults; bad targets throw', () {
      DocumentRules.ensureInitialized();
      final back =
          RuleRegistry.fromJson({'rule': 'markdownPrefix'})
              as MarkdownPrefixRule;
      expect(back.prefixes, MarkdownPrefixRule.defaultPrefixes);
      expect(
        () => RuleRegistry.fromJson({
          'rule': 'markdownPrefix',
          'prefixes': {
            '# ': {'kind': 'heading', 'level': 9},
          },
        }),
        throwsFormatException,
      );
      expect(
        () => RuleRegistry.fromJson({
          'rule': 'markdownPrefix',
          'prefixes': {
            '# ': {'kind': 'table'},
          },
        }),
        throwsFormatException,
      );
    });
  });

  group('enterSplits', () {
    const rule = EnterSplitsRule();

    test('splits a paragraph at the caret, moving marks', () {
      final doc = DocSnapshot(const [
        ParagraphNode(
          id: 'p',
          text: DocText('hello world', [
            DocMark(type: DocMarkType.bold, start: 3, end: 8),
          ]),
        ),
        DividerNode(id: 'd'),
      ]);
      final r = run(rule, doc, const EnterPressed('p', caretOffset: 5))!;
      expect(
        r.doc.nodes[0],
        const ParagraphNode(
          id: 'p',
          text: DocText('hello', [
            DocMark(type: DocMarkType.bold, start: 3, end: 5),
          ]),
        ),
      );
      final next = r.doc.nodes[1] as ParagraphNode;
      expect(
        next.text,
        const DocText(' world', [
          DocMark(type: DocMarkType.bold, start: 0, end: 3),
        ]),
      );
      expect(r.doc.nodes[2].id, 'd');
      expect(r.caret!.nodeId, next.id);
      expect(r.caret!.offset, 0);
    });

    test('Enter at the end of a heading starts a paragraph', () {
      final doc = single(
        const HeadingNode(id: 'h', level: 2, text: DocText('Title')),
      );
      final r = run(rule, doc, const EnterPressed('h', caretOffset: 5))!;
      expect(r.doc.nodes[0], doc.nodes[0]);
      expect(r.doc.nodes[1], isA<ParagraphNode>());
      expect((r.doc.nodes[1] as ParagraphNode).text, DocText.empty);
    });

    test(
      'Enter in the middle of a heading or quote moves the rest to a paragraph',
      () {
        for (final node in const <TextDocNode>[
          HeadingNode(id: 'n', text: DocText('abcd')),
          QuoteNode(id: 'n', text: DocText('abcd')),
        ]) {
          final r = run(
            rule,
            single(node),
            const EnterPressed('n', caretOffset: 2),
          )!;
          expect(r.doc.nodes[0], node.withText(const DocText('ab')));
          expect(r.doc.nodes[1], isA<ParagraphNode>());
          expect((r.doc.nodes[1] as TextDocNode).text.text, 'cd');
        }
      },
    );

    test('a non-empty list item continues as a list item', () {
      final doc = single(
        const ListItemNode(
          id: 'l',
          ordered: true,
          indent: 2,
          text: DocText('item'),
        ),
      );
      final r = run(rule, doc, const EnterPressed('l', caretOffset: 4))!;
      final next = r.doc.nodes[1] as ListItemNode;
      expect(next.ordered, isTrue);
      expect(next.indent, 2);
      expect(next.text, DocText.empty);
    });

    test('a task continues as an unchecked task', () {
      final doc = single(
        const TaskNode(id: 't', checked: true, text: DocText('ab')),
      );
      final r = run(rule, doc, const EnterPressed('t', caretOffset: 1))!;
      expect(
        r.doc.nodes[0],
        const TaskNode(id: 't', checked: true, text: DocText('a')),
      );
      final next = r.doc.nodes[1] as TaskNode;
      expect(next.checked, isFalse);
      expect(next.text.text, 'b');
    });

    test('Enter on an empty list item or task converts it to a paragraph', () {
      for (final node in const <DocNode>[
        ListItemNode(id: 'n', ordered: true),
        TaskNode(id: 'n', checked: true),
      ]) {
        final r = run(
          rule,
          single(node),
          const EnterPressed('n', caretOffset: 0),
        )!;
        expect(r.doc.nodes.single, const ParagraphNode(id: 'n'));
        expect(r.caret!.nodeId, 'n');
      }
    });

    test('Enter at offset 0 of a non-empty node inserts before it', () {
      final doc = DocSnapshot(const [
        ParagraphNode(id: 'a'),
        HeadingNode(id: 'h', text: DocText('Title')),
        ListItemNode(id: 'l', text: DocText('x')),
      ]);
      final r = run(rule, doc, const EnterPressed('h', caretOffset: 0))!;
      expect(r.doc.nodes.map((n) => n.runtimeType), [
        ParagraphNode,
        ParagraphNode,
        HeadingNode,
        ListItemNode,
      ]);
      expect(r.doc.nodes[2], doc.nodes[1]);
      expect(r.caret!.nodeId, 'h');
      expect(r.caret!.offset, 0);

      final r2 = run(rule, doc, const EnterPressed('l', caretOffset: 0))!;
      expect(r2.doc.nodes[2], isA<ListItemNode>());
      expect(r2.doc.nodes[3], doc.nodes[2]);

      final first = run(
        rule,
        single(const ParagraphNode(id: 'p', text: DocText('x'))),
        const EnterPressed('p', caretOffset: 0),
      )!;
      expect(first.doc.nodes.last.id, 'p');
      expect(first.doc.nodes, hasLength(2));
    });

    test('Enter in an empty paragraph adds a paragraph after', () {
      final r = run(
        rule,
        single(const ParagraphNode(id: 'p')),
        const EnterPressed('p', caretOffset: 0),
      )!;
      expect(r.doc.nodes, hasLength(2));
      expect(r.doc.nodes.first.id, 'p');
    });

    test('splits between code units of multi-byte text', () {
      final doc = single(const ParagraphNode(id: 'p', text: DocText('a👋b')));
      final r = run(rule, doc, const EnterPressed('p', caretOffset: 3))!;
      expect((r.doc.nodes[0] as ParagraphNode).text.text, 'a👋');
      expect((r.doc.nodes[1] as ParagraphNode).text.text, 'b');
    });

    test('declines off text nodes, out of range, or on other events', () {
      final doc = DocSnapshot(const [
        DividerNode(id: 'd'),
        ParagraphNode(id: 'p', text: DocText('ab')),
      ]);
      expect(run(rule, doc, const EnterPressed('d', caretOffset: 0)), isNull);
      expect(run(rule, doc, const EnterPressed('p', caretOffset: 3)), isNull);
      expect(run(rule, doc, const EnterPressed('p', caretOffset: -1)), isNull);
      expect(run(rule, doc, const EnterPressed('x', caretOffset: 0)), isNull);
      expect(run(rule, doc, const BackspaceAtStart('p')), isNull);
    });
  });

  group('backspaceMerges', () {
    const rule = BackspaceMergesRule();

    test('converts a non-paragraph text node to a paragraph', () {
      for (final node in const <TextDocNode>[
        HeadingNode(id: 'n', level: 3, text: DocText('x')),
        ListItemNode(id: 'n', ordered: true, text: DocText('x')),
        TaskNode(id: 'n', checked: true, text: DocText('x')),
        QuoteNode(id: 'n', text: DocText('x')),
      ]) {
        final r = run(rule, single(node), const BackspaceAtStart('n'))!;
        expect(
          r.doc.nodes.single,
          const ParagraphNode(id: 'n', text: DocText('x')),
        );
        expect(r.caret!.offset, 0);
      }
    });

    test('merges a paragraph into the previous text node', () {
      final doc = DocSnapshot(const [
        HeadingNode(
          id: 'h',
          level: 2,
          text: DocText('Head', [
            DocMark(type: DocMarkType.bold, start: 0, end: 4),
          ]),
        ),
        ParagraphNode(
          id: 'p',
          text: DocText('Body', [
            DocMark(type: DocMarkType.italic, start: 1, end: 3),
          ]),
        ),
        ParagraphNode(id: 'z'),
      ]);
      final r = run(rule, doc, const BackspaceAtStart('p'))!;
      expect(r.doc.nodes.map((n) => n.id), ['h', 'z']);
      expect(
        r.doc.nodes.first,
        const HeadingNode(
          id: 'h',
          level: 2,
          text: DocText('HeadBody', [
            DocMark(type: DocMarkType.bold, start: 0, end: 4),
            DocMark(type: DocMarkType.italic, start: 5, end: 7),
          ]),
        ),
      );
      expect(r.caret!.nodeId, 'h');
      expect(r.caret!.offset, 4);
    });

    test('caret lands after multi-byte text', () {
      final doc = DocSnapshot(const [
        ParagraphNode(id: 'a', text: DocText('hi 👋')),
        ParagraphNode(id: 'b', text: DocText('there')),
      ]);
      final r = run(rule, doc, const BackspaceAtStart('b'))!;
      expect((r.doc.nodes.single as ParagraphNode).text.text, 'hi 👋there');
      expect(r.caret!.offset, 5);
    });

    test('an empty paragraph merges away', () {
      final doc = DocSnapshot(const [
        ParagraphNode(id: 'a', text: DocText('x')),
        ParagraphNode(id: 'b'),
      ]);
      final r = run(rule, doc, const BackspaceAtStart('b'))!;
      expect(r.doc.nodes.single, doc.nodes.first);
      expect(r.caret!.offset, 1);
    });

    test('removes a previous divider or embedded field', () {
      for (final block in const <DocNode>[
        DividerNode(id: 'blk'),
        EmbeddedFieldNode(id: 'blk', fieldJson: {'type': 'textField'}),
      ]) {
        final doc = DocSnapshot([
          const ParagraphNode(id: 'a', text: DocText('x')),
          block,
          const ParagraphNode(id: 'p', text: DocText('y')),
        ]);
        final r = run(rule, doc, const BackspaceAtStart('p'))!;
        expect(r.doc.nodes.map((n) => n.id), ['a', 'p']);
        expect(r.caret!.nodeId, 'p');
        expect(r.caret!.offset, 0);
      }
    });

    test(
      'declines on the first paragraph, non-text nodes and other events',
      () {
        final doc = DocSnapshot(const [
          ParagraphNode(id: 'p', text: DocText('x')),
          DividerNode(id: 'd'),
        ]);
        expect(run(rule, doc, const BackspaceAtStart('p')), isNull);
        expect(run(rule, doc, const BackspaceAtStart('d')), isNull);
        expect(run(rule, doc, const BackspaceAtStart('nope')), isNull);
        expect(run(rule, doc, const EnterPressed('p', caretOffset: 0)), isNull);
      },
    );
  });

  group('default transforms together', () {
    final engine = TransformEngine(DocumentRules.defaultTransforms);

    test('--- Enter hits markdownPrefix before enterSplits', () {
      final r = engine.run(
        single(const ParagraphNode(id: 'p', text: DocText('---'))),
        const EnterPressed('p', caretOffset: 3),
      )!;
      expect(r.doc.nodes.first, const DividerNode(id: 'p'));
    });

    test('type "- ", write, Enter, Enter leaves the list', () {
      var doc = single(const ParagraphNode(id: 'p', text: DocText('- ')));
      doc = engine
          .run(doc, const TextInserted('p', text: ' ', caretOffset: 2))!
          .doc;
      doc = DocSnapshot([
        (doc.nodes.single as ListItemNode).withText(const DocText('milk')),
      ]);
      final afterEnter = engine.run(
        doc,
        const EnterPressed('p', caretOffset: 4),
      )!;
      final second = afterEnter.caret!.nodeId;
      expect(afterEnter.doc.nodeById(second), isA<ListItemNode>());
      final left = engine.run(
        afterEnter.doc,
        EnterPressed(second, caretOffset: 0),
      )!;
      expect(left.doc.nodeById(second), isA<ParagraphNode>());
      expect(left.doc.nodes.first, isA<ListItemNode>());
    });
  });
}
