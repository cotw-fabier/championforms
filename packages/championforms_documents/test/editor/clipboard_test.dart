import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;

import '../field/helpers.dart';

DocSnapshot _doc() => DocSnapshot([
  const ParagraphNode(id: 'p1', text: DocText('Hello world')),
  const EmbeddedFieldNode(
    id: 'emb',
    fieldJson: {'type': 'text', 'title': 'Name'},
  ),
  const ParagraphNode(id: 'p2', text: DocText('Goodbye')),
]);

Future<(DocHarness, FakeDocClipboard)> _pump(WidgetTester tester) async {
  final delegate = FakeDocClipboard();
  final h = await pumpDocumentForm(
    tester,
    fields: [
      DocumentField(
        id: 'doc',
        initialDocument: _doc(),
        clipboardDelegate: delegate,
      ),
    ],
  );
  return (h, delegate);
}

/// Focuses the editor and selects "world … Good" across the embedded block.
Future<void> _selectAcross(WidgetTester tester, DocHarness h) async {
  h.editorState.focusNode.requestFocus();
  await tester.pump();
  h.select('p1', 6, 'p2', 4);
  await tester.pump();
}

void _expectAcross(DocSelection selection) {
  expect(selection.startNodeId, 'p1');
  expect(selection.startOffset, 6);
  expect(selection.endNodeId, 'p2');
  expect(selection.endOffset, 4);
}

void main() {
  testWidgets(
    'Cmd/Ctrl+C sends the selection to the delegate',
    (tester) async {
      final (h, delegate) = await _pump(tester);
      await _selectAcross(tester, h);
      await pressShortcut(tester, LogicalKeyboardKey.keyC);
      await tester.pumpAndSettle();
      expect(delegate.copies, hasLength(1));
      final copy = delegate.copies.single;
      expect(copy.docId, 'doc');
      _expectAcross(copy.selection);
      expect(copy.doc, h.snapshot);
      expect(
        fakePlatformClipboard,
        isNull,
        reason: "super_editor's copy never ran",
      );
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    }),
  );

  testWidgets(
    'Cmd/Ctrl+X copies, deletes, and unregisters the block',
    (tester) async {
      final (h, delegate) = await _pump(tester);
      expect(h.controller.hasFieldDefinition('doc.field.emb'), isTrue);
      await _selectAcross(tester, h);
      await pressShortcut(tester, LogicalKeyboardKey.keyX);
      await tester.pumpAndSettle();
      expect(delegate.copies, hasLength(1));
      _expectAcross(delegate.copies.single.selection);
      expect(
        delegate.copies.single.doc.nodeById('emb'),
        isNotNull,
        reason: 'the delegate sees the document before the delete',
      );
      expect(h.snapshot.nodeById('emb'), isNull);
      expect((h.snapshot.nodes.single as ParagraphNode).text.text, 'Hello bye');
      expect(h.controller.hasFieldDefinition('doc.field.emb'), isFalse);
      final results = form.FormResults.getResults(controller: h.controller);
      expect(results.results.containsKey('doc.field.emb'), isFalse);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Cmd/Ctrl+V inserts the pasted nodes and restores values',
    (tester) async {
      final (h, delegate) = await _pump(tester);
      delegate.nextPaste = const DocPasteResult(
        nodes: [
          ParagraphNode(id: 'n1', text: DocText('AA')),
          EmbeddedFieldNode(
            id: 'n2',
            fieldJson: {'type': 'text', 'title': 'Pasted'},
            sourceId: 'emb',
          ),
          EmbeddedFieldNode(
            id: 'n3',
            fieldJson: {
              'type': 'checkboxSelect',
              'multiselect': true,
              'options': [
                {'value': 'a', 'label': 'A'},
                {'value': 'b', 'label': 'B'},
              ],
            },
          ),
          ParagraphNode(id: 'n4', text: DocText('ZZ')),
        ],
        fieldValues: {
          'n2': 'restored text',
          'n3': ['b'],
        },
      );
      h.editorState.focusNode.requestFocus();
      await tester.pump();
      h.placeCaret('p1', 5); // "Hello| world"
      await tester.pump();
      await pressShortcut(tester, LogicalKeyboardKey.keyV);
      await tester.pumpAndSettle();

      expect(delegate.pastes, hasLength(1));
      expect(delegate.pastes.single.docId, 'doc');
      final nodes = h.snapshot.nodes;
      expect(nodes.map((n) => n.id).take(4), ['p1', 'n2', 'n3', 'n4']);
      expect((nodes[0] as ParagraphNode).text.text, 'HelloAA');
      expect((nodes[3] as ParagraphNode).text.text, 'ZZ world');
      expect(
        h.controller.getFieldValue<String>('doc.field.n2'),
        'restored text',
      );
      expect(
        h.controller
            .getFieldValue<List<form.FieldOption>>('doc.field.n3')!
            .map((o) => o.value),
        ['b'],
      );
      final caret = h.editorState.composer.selection!.extent;
      expect(caret.nodeId, 'n4');
      expect((caret.nodePosition as se.TextNodePosition).offset, 2);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.linux,
    }),
  );

  testWidgets('pasted ids that collide are re-keyed, values follow', (
    tester,
  ) async {
    final (h, delegate) = await _pump(tester);
    delegate.nextPaste = const DocPasteResult(
      nodes: [
        EmbeddedFieldNode(id: 'emb', fieldJson: {'type': 'text'}),
      ],
      fieldValues: {'emb': 'copy'},
    );
    h.controller.updateFieldValue<String>('doc.field.emb', 'original');
    h.placeCaret('p2', 7);
    await tester.pump();
    await h.editorState.clipboard!.paste();
    await tester.pumpAndSettle();
    final blocks = h.snapshot.embeddedFields.toList();
    expect(blocks, hasLength(2));
    expect(blocks[1].id, isNot('emb'));
    expect(h.controller.getFieldValue<String>('doc.field.emb'), 'original');
    expect(
      h.controller.getFieldValue<String>(blocks[1].controllerIdFor('doc')),
      'copy',
    );
  });

  testWidgets('paste over a selection replaces it', (tester) async {
    final (h, delegate) = await _pump(tester);
    delegate.nextPaste = const DocPasteResult(
      nodes: [ParagraphNode(id: 'x', text: DocText('X'))],
    );
    await _selectAcross(tester, h);
    await h.editorState.clipboard!.paste();
    await tester.pumpAndSettle();
    expect((h.snapshot.nodes.single as ParagraphNode).text.text, 'Hello Xbye');
    expect(h.controller.hasFieldDefinition('doc.field.emb'), isFalse);
  });

  testWidgets('the iOS toolbar copies through the delegate', (tester) async {
    final (h, delegate) = await _pump(tester);
    await _selectAcross(tester, h);
    h.editorState.iosControls!.showToolbar();
    await tester.pumpAndSettle();
    expect(find.byType(se.IOSTextEditingFloatingToolbar), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    _expectAcross(delegate.copies.single.selection);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('the Android toolbar copies through the delegate', (
    tester,
  ) async {
    final (h, delegate) = await _pump(tester);
    await _selectAcross(tester, h);
    h.editorState.androidControls!.showToolbar();
    await tester.pumpAndSettle();
    expect(find.byType(se.AndroidTextEditingFloatingToolbar), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    _expectAcross(delegate.copies.single.selection);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('desktop right-click menu: Copy and Paste', (tester) async {
    final (h, delegate) = await _pump(tester);
    delegate.nextPaste = const DocPasteResult(
      nodes: [ParagraphNode(id: 'x', text: DocText('!'))],
    );
    await _selectAcross(tester, h);
    final at =
        tester.getTopLeft(find.byType(DocumentEditor)) + const Offset(60, 18);
    final gesture = await tester.startGesture(
      at,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('document-menu-copy')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('document-menu-copy')));
    await tester.pumpAndSettle();
    _expectAcross(delegate.copies.single.selection);

    h.placeCaret('p2', 7);
    await tester.pump();
    final again = await tester.startGesture(
      at,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await again.up();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('document-menu-paste')));
    await tester.pumpAndSettle();
    expect(delegate.pastes, hasLength(1));
    expect((h.snapshot.nodes.last as ParagraphNode).text.text, 'Goodbye!');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('without a delegate super_editor copies plain text', (
    tester,
  ) async {
    final h = await pumpDocumentForm(
      tester,
      fields: [DocumentField(id: 'doc', initialDocument: _doc())],
    );
    expect(h.editorState.clipboard, isNull);
    h.editorState.focusNode.requestFocus();
    await tester.pump();
    h.select('p1', 0, 'p1', 5);
    await tester.pump();
    await pressShortcut(tester, LogicalKeyboardKey.keyC);
    await tester.pumpAndSettle();
    expect(fakePlatformClipboard, 'Hello');
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  group('pasteEdit (DocPasteResult semantics)', () {
    DocSnapshot apply(
      DocSnapshot doc,
      String id,
      int offset,
      List<DocNode> nodes,
    ) => DocEditApplier.apply(doc, pasteEdit(doc, id, offset, nodes)!);

    test('a single paragraph pastes inline', () {
      final doc = paragraphDoc('p', 'abcd');
      final edit = pasteEdit(doc, 'p', 2, [
        const ParagraphNode(id: 'x', text: DocText('XY')),
      ])!;
      final result = DocEditApplier.apply(doc, edit);
      expect((result.nodes.single as ParagraphNode).text.text, 'abXYcd');
      expect(edit.caret!.offset, 4);
    });

    test('an incompatible first node splits instead of merging', () {
      final result = apply(paragraphDoc('p', 'abcd'), 'p', 2, [
        const HeadingNode(id: 'h', text: DocText('H')),
      ]);
      // The heading is the last node, so "cd" joins it.
      expect(result.nodes.map((n) => n.type), ['paragraph', 'heading']);
      expect((result.nodes[0] as ParagraphNode).text.text, 'ab');
      expect((result.nodes[1] as HeadingNode).text.text, 'Hcd');
    });

    test('blocks at the start of an empty line replace it', () {
      final result = apply(paragraphDoc('p'), 'p', 0, [
        const DividerNode(id: 'hr'),
      ]);
      expect(result.nodes.map((n) => n.type), ['divider', 'paragraph']);
      expect(result.nodeById('p'), isNull);
    });

    test('a trailing block keeps the rest as a node of the same kind', () {
      final doc = DocSnapshot([
        const ListItemNode(id: 'li', text: DocText('abcd')),
      ]);
      final result = apply(doc, 'li', 2, [const DividerNode(id: 'hr')]);
      expect(result.nodes.map((n) => n.type), [
        'listItem',
        'divider',
        'listItem',
      ]);
      expect((result.nodes[2] as ListItemNode).text.text, 'cd');
    });

    test('marks survive the merge', () {
      final doc = paragraphDoc('p', 'ab');
      final result = apply(doc, 'p', 1, [
        const ParagraphNode(
          id: 'x',
          text: DocText('B', [
            DocMark(type: DocMarkType.bold, start: 0, end: 1),
          ]),
        ),
      ]);
      final text = (result.nodes.single as ParagraphNode).text;
      expect(text.text, 'aBb');
      expect(
        text.marks.single,
        const DocMark(type: DocMarkType.bold, start: 1, end: 2),
      );
    });

    test('on a block: before (upstream) or after (downstream)', () {
      final doc = DocSnapshot([
        const ParagraphNode(id: 'a'),
        const DividerNode(id: 'hr'),
      ]);
      final before = apply(doc, 'hr', 0, [const ParagraphNode(id: 'x')]);
      expect(before.nodes.map((n) => n.id), ['a', 'x', 'hr']);
      final after = apply(doc, 'hr', 1, [const ParagraphNode(id: 'x')]);
      expect(after.nodes.map((n) => n.id), ['a', 'hr', 'x']);
    });

    test('rekeyPaste renames only colliding ids and re-keys values', () {
      final doc = paragraphDoc('p');
      final result = rekeyPaste(
        doc,
        const DocPasteResult(
          nodes: [
            ParagraphNode(id: 'p'),
            EmbeddedFieldNode(id: 'e', fieldJson: {'type': 'text'}),
          ],
          fieldValues: {'e': 'v'},
        ),
      );
      expect(result.nodes[0].id, isNot('p'));
      expect(result.nodes[1].id, 'e');
      expect(result.fieldValues, {'e': 'v'});
    });
  });
}
