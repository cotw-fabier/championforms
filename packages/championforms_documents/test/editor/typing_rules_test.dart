import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

import '../field/helpers.dart';

const _platforms = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.android,
  TargetPlatform.iOS,
});

Future<DocHarness> _pump(
  WidgetTester tester, {
  DocSnapshot? doc,
  RuleSet ruleSet = RuleSet.empty,
}) => pumpDocumentForm(
  tester,
  fields: [
    DocumentField(
      id: 'doc',
      initialDocument: doc ?? paragraphDoc('p'),
      ruleSet: ruleSet,
    ),
  ],
);

void main() {
  group('markdown shortcuts through the rules (real typing)', () {
    testWidgets('"- " makes a bullet list item', (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('- item');
      final node = h.snapshot.nodes.single;
      expect(node, isA<ListItemNode>());
      expect((node as ListItemNode).ordered, isFalse);
      expect(node.text.text, 'item');
      expect(node.id, 'p', reason: 'conversion keeps the node id');
    }, variant: _platforms);

    testWidgets('"# " makes a heading', (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('# Title');
      final node = h.snapshot.nodes.single;
      expect(node, isA<HeadingNode>());
      expect((node as HeadingNode).level, 1);
      expect(node.text.text, 'Title');
    }, variant: _platforms);

    testWidgets('"[] " makes a task', (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('[] todo');
      final node = h.snapshot.nodes.single;
      expect(node, isA<TaskNode>());
      expect((node as TaskNode).checked, isFalse);
      expect(node.text.text, 'todo');
    }, variant: _platforms);

    testWidgets('hardware keyboard typing converts too', (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeTextAdaptive('> quoted');
      final node = h.snapshot.nodes.single;
      expect(node, isA<QuoteNode>());
      expect((node as QuoteNode).text.text, 'quoted');
    });

    testWidgets('the rule set decides: no markdown rule, no conversion', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        ruleSet: const RuleSet(transforms: [EnterSplitsRule()]),
      );
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('- item');
      final node = h.snapshot.nodes.single;
      expect(node, isA<ParagraphNode>());
      expect((node as ParagraphNode).text.text, '- item');
    });

    testWidgets("super_editor's own markdown reactions are off", (
      tester,
    ) async {
      // Only headings configured: "- " must stay text.
      final h = await _pump(
        tester,
        ruleSet: const RuleSet(
          transforms: [
            MarkdownPrefixRule(prefixes: {'# ': PrefixTarget.heading(1)}),
          ],
        ),
      );
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('- x');
      expect(h.snapshot.nodes.single, isA<ParagraphNode>());
    });
  });

  group('Enter and Backspace', () {
    testWidgets('Enter in a list item continues the list', (tester) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([
          const ListItemNode(id: 'li', text: DocText('one')),
        ]),
      );
      await tester.placeCaretInParagraph('li', 3);
      await tester.pressEnter();
      await tester.typeImeText('two');
      final nodes = h.snapshot.nodes;
      expect(nodes, hasLength(2));
      expect(nodes[1], isA<ListItemNode>());
      expect((nodes[1] as ListItemNode).text.text, 'two');
    }, variant: _platforms);

    testWidgets('Enter on an empty list item leaves the list', (tester) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([const ListItemNode(id: 'li')]),
      );
      await tester.placeCaretInParagraph('li', 0);
      await tester.pressEnter();
      expect(h.snapshot.nodes.single, isA<ParagraphNode>());
      expect(h.snapshot.nodes.single.id, 'li');
    }, variant: _platforms);

    testWidgets('Enter at the end of a heading starts a paragraph', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([
          const HeadingNode(id: 'h', text: DocText('Title')),
        ]),
      );
      await tester.placeCaretInParagraph('h', 5);
      await tester.pressEnter();
      await tester.typeImeText('body');
      final nodes = h.snapshot.nodes;
      expect(nodes[0], isA<HeadingNode>());
      expect(nodes[1], isA<ParagraphNode>());
      expect((nodes[1] as ParagraphNode).text.text, 'body');
    });

    testWidgets('"---" then Enter makes a divider', (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('---');
      await tester.pressEnter();
      final nodes = h.snapshot.nodes;
      expect(nodes[0], isA<DividerNode>());
      expect(nodes[1], isA<ParagraphNode>());
    });

    testWidgets('Backspace at the start of a heading makes it a paragraph', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([
          const HeadingNode(id: 'h', text: DocText('Title')),
        ]),
      );
      await tester.placeCaretInParagraph('h', 0);
      await tester.pressBackspace();
      final node = h.snapshot.nodes.single;
      expect(node, isA<ParagraphNode>());
      expect((node as ParagraphNode).text.text, 'Title');
    });

    testWidgets('Backspace at the start of a paragraph merges it up', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([
          const ParagraphNode(id: 'a', text: DocText('ab')),
          const ParagraphNode(id: 'b', text: DocText('cd')),
        ]),
      );
      await tester.placeCaretInParagraph('b', 0);
      await tester.pressBackspace();
      final node = h.snapshot.nodes.single as ParagraphNode;
      expect(node.id, 'a');
      expect(node.text.text, 'abcd');
      final caret = h.editorState.composer.selection!.extent;
      expect(caret.nodeId, 'a');
      expect((caret.nodePosition as se.TextNodePosition).offset, 2);
    });

    testWidgets('Backspace after a divider removes the divider', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([
          const ParagraphNode(id: 'a', text: DocText('x')),
          const DividerNode(id: 'hr'),
          const ParagraphNode(id: 'b', text: DocText('y')),
        ]),
      );
      await tester.placeCaretInParagraph('b', 0);
      await tester.pressBackspace();
      expect(h.snapshot.nodes.map((n) => n.id), ['a', 'b']);
    });

    testWidgets('Backspace mid-text still deletes a character natively', (
      tester,
    ) async {
      final h = await _pump(tester, doc: paragraphDoc('p', 'abc'));
      await tester.placeCaretInParagraph('p', 3);
      await tester.pressBackspace();
      expect((h.snapshot.nodes.single as ParagraphNode).text.text, 'ab');
    });

    testWidgets('IME deletion at the start goes through the rules', (
      tester,
    ) async {
      final h = await _pump(
        tester,
        doc: DocSnapshot([const TaskNode(id: 't', text: DocText('x'))]),
      );
      await tester.placeCaretInParagraph('t', 0);
      h.editor.execute([
        se.DeleteUpstreamAtBeginningOfNodeRequest(h.document.getNodeById('t')!),
      ]);
      await tester.pump();
      expect(h.snapshot.nodes.single, isA<ParagraphNode>());
    });
  });

  testWidgets('Undo reverts a rule conversion', (tester) async {
    final h = await _pump(tester);
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('# ');
    expect(h.snapshot.nodes.single, isA<HeadingNode>());
    h.editor.undo();
    await tester.pump();
    expect(h.snapshot.nodes.single, isA<ParagraphNode>());
  });

  test('unused key import guard', () {
    expect(LogicalKeyboardKey.enter, isNotNull);
  });
}
