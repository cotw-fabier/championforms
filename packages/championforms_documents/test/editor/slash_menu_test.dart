import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor_test.dart';

import '../field/helpers.dart';

Future<DocHarness> _pump(
  WidgetTester tester, {
  DocSnapshot? doc,
  List<DocumentBlockTemplate> templates = const [],
}) => pumpDocumentForm(
  tester,
  fields: [
    DocumentField(
      id: 'doc',
      initialDocument: doc ?? paragraphDoc('p'),
      blockTemplates: templates,
    ),
  ],
);

EmbeddedFieldNode _embedded(DocHarness h) =>
    h.snapshot.nodes.whereType<EmbeddedFieldNode>().single;

void main() {
  testWidgets('typing "/" opens the menu at the caret; tapping an item '
      'inserts a field block that is registered on the controller', (
    tester,
  ) async {
    final h = await _pump(tester);
    expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('/');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slash-menu')), findsOneWidget);
    // Text kinds and field blocks are both offered.
    expect(find.byKey(const ValueKey('slash-item-heading-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('slash-item-divider')), findsOneWidget);

    await tester.typeImeText('textin');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slash-item-heading-1')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('slash-item-text-input')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
    final node = _embedded(h);
    expect(node.fieldType, 'text');
    final controllerId = node.controllerIdFor('doc');
    expect(controllerId, 'doc.field.${node.id}');
    expect(h.controller.hasFieldDefinition(controllerId), isTrue);
    for (final n in h.snapshot.nodes.whereType<TextDocNode>()) {
      expect(n.text.text, isNot(contains('/')), reason: 'query removed');
    }
    // The block renders the real field.
    expect(find.byKey(ValueKey('embedded-${node.id}')), findsOneWidget);
  });

  testWidgets(
    'the menu opens below the caret on desktop, above on mobile',
    (tester) async {
      await _pump(
        tester,
        doc: DocSnapshot([
          for (var i = 0; i < 12; i++)
            ParagraphNode(id: 'l$i', text: DocText('Line $i')),
          const ParagraphNode(id: 'p'),
        ]),
      );
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('/');
      await tester.pumpAndSettle();
      final menu = find.byKey(const ValueKey('slash-menu'));
      expect(menu, findsOneWidget);
      final layout = SuperEditorInspector.findDocumentLayout();
      final caret = layout.getRectForPosition(
        SuperEditorAdapter.toEditorPosition(
          tester
              .state<DocumentFieldWidgetState>(find.byType(DocumentFieldWidget))
              .editorState!
              .document,
          'p',
          0,
        ),
      )!;
      final caretTop = layout.getGlobalOffsetFromDocumentOffset(caret.topLeft);
      final caretBottom = layout.getGlobalOffsetFromDocumentOffset(
        caret.bottomLeft,
      );
      final mobile =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;
      if (mobile) {
        final gap = caretTop.dy - tester.getBottomLeft(menu).dy;
        expect(gap, inInclusiveRange(0, 40));
      } else {
        final gap = tester.getTopLeft(menu).dy - caretBottom.dy;
        expect(gap, inInclusiveRange(0, 40));
      }
      expect((tester.getTopLeft(menu).dx - caretTop.dx).abs(), lessThan(40));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('on mobile the menu flips below when there is no room above', (
    tester,
  ) async {
    await _pump(tester);
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('/');
    await tester.pumpAndSettle();
    final menu = find.byKey(const ValueKey('slash-menu'));
    // The document is at the very top of the screen: no room above.
    final editorTop = tester.getTopLeft(find.byType(DocumentEditor)).dy;
    expect(tester.getTopLeft(menu).dy, greaterThan(editorTop));
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('typing into the embedded field updates the controller', (
    tester,
  ) async {
    final h = await _pump(tester);
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('/text');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slash-item-text-input')));
    await tester.pumpAndSettle();
    final node = _embedded(h);
    final editable = find.descendant(
      of: find.byKey(ValueKey('embedded-${node.id}')),
      matching: find.byType(EditableText),
    );
    expect(editable, findsOneWidget);
    await tester.tap(editable);
    await tester.pumpAndSettle();
    await tester.enterText(editable, 'Ada');
    await tester.pumpAndSettle();
    expect(
      h.controller.getFieldValue<String>(node.controllerIdFor('doc')),
      'Ada',
    );
    // The document text is untouched by field typing.
    expect(
      h.snapshot.nodes.whereType<TextDocNode>().every(
        (n) => !n.text.text.contains('Ada'),
      ),
      isTrue,
    );
  });

  testWidgets(
    'Enter picks the highlighted item; arrows move it',
    (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('/head');
      await tester.pumpAndSettle();
      // Heading 1, 2, 3 match; move down to Heading 2.
      await tester.pressDownArrow();
      await tester.pumpAndSettle();
      await tester.pressEnter();
      await tester.pumpAndSettle();
      final node = h.snapshot.nodes.single;
      expect(node, isA<HeadingNode>());
      expect((node as HeadingNode).level, 2);
      expect(node.id, 'p', reason: 'text kinds convert in place');
      expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'a software keyboard Enter (IME newline) picks the highlighted item',
    (tester) async {
      final h = await _pump(tester);
      await tester.placeCaretInParagraph('p', 0);
      await tester.typeImeText('/textin');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('slash-menu')), findsOneWidget);

      if (defaultTargetPlatform == TargetPlatform.android) {
        // Android reports the action key only as a "\n" insertion delta.
        await tester.ime.typeText('\n', getter: imeClientGetter);
      } else {
        // iOS reports a "\n" delta (which super_editor skips) and then a
        // newline action.
        await tester.pressEnterWithIme(getter: imeClientGetter);
      }
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
      final node = _embedded(h);
      expect(node.fieldType, 'text');
      expect(
        h.controller.hasFieldDefinition(node.controllerIdFor('doc')),
        true,
      );
      final texts = h.snapshot.nodes.whereType<TextDocNode>().toList();
      for (final n in texts) {
        expect(n.text.text, isEmpty, reason: 'no query text, no newline');
      }
      // The block replaced the empty paragraph and one follows it: no
      // extra paragraph from a newline.
      expect(h.snapshot.nodes, hasLength(2));

      // With the menu closed, Enter is a newline again.
      await tester.placeCaretInParagraph(texts.last.id, 0);
      await tester.typeImeText('x');
      if (defaultTargetPlatform == TargetPlatform.android) {
        await tester.ime.typeText('\n', getter: imeClientGetter);
      } else {
        await tester.pressEnterWithIme(getter: imeClientGetter);
      }
      await tester.pumpAndSettle();
      expect(h.snapshot.nodes, hasLength(3));
    },
    variant: const TargetPlatformVariant({
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets('Escape closes the menu and keeps the text', (tester) async {
    final h = await _pump(tester);
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('/quo');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slash-menu')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('slash-menu')), findsNothing);
    expect((h.snapshot.nodes.single as ParagraphNode).text.text, '/quo');
  });

  testWidgets('a custom template is offered and inserted', (tester) async {
    final h = await _pump(
      tester,
      templates: [
        DocumentBlockTemplate(
          id: 'email',
          label: 'Email address',
          icon: Icons.email,
          fieldJson: () => {'type': 'email', 'title': 'Email'},
        ),
      ],
    );
    await tester.placeCaretInParagraph('p', 0);
    await tester.typeImeText('/email');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slash-item-email')));
    await tester.pumpAndSettle();
    final node = _embedded(h);
    expect(node.fieldType, 'email');
    expect(
      h.controller.registeredFields.firstWhere(
        (f) => f.id == node.controllerIdFor('doc'),
      ),
      isA<form.TextField>(),
    );
  });

  testWidgets('each built-in field block registers its field type', (
    tester,
  ) async {
    final h = await _pump(tester);
    final expected = {
      'checkbox': form.CheckboxSelect,
      'select': form.OptionSelect,
      'file-upload': form.FileUpload,
    };
    for (final e in expected.entries) {
      final last = h.snapshot.nodes.last;
      await tester.placeCaretInParagraph(last.id, 0);
      await tester.typeImeText('/${e.key.split('-').first}');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('slash-item-${e.key}')));
      await tester.pumpAndSettle();
    }
    final types = [
      for (final n in h.snapshot.nodes.whereType<EmbeddedFieldNode>())
        h.controller.registeredFields
            .firstWhere((f) => f.id == n.controllerIdFor('doc'))
            .runtimeType,
    ];
    expect(types, [form.CheckboxSelect, form.OptionSelect, form.FileUpload]);
    expect(find.byType(UnsupportedBlockPlaceholder), findsNothing);
  });

  test('insertBlockEdit splits a paragraph around the block', () {
    final doc = DocSnapshot([
      const ParagraphNode(id: 'p', text: DocText('abcd')),
    ]);
    final block = const DividerNode(id: 'hr');
    final edit = insertBlockEdit(doc, 'p', 2, block)!;
    final result = DocEditApplier.apply(doc, edit);
    expect(result.nodes.map((n) => n.type), [
      'paragraph',
      'divider',
      'paragraph',
    ]);
    expect((result.nodes[0] as ParagraphNode).text.text, 'ab');
    expect((result.nodes[2] as ParagraphNode).text.text, 'cd');
    expect(edit.caret!.nodeId, result.nodes[2].id);
  });

  test('insertBlockEdit replaces an empty paragraph and adds one after', () {
    final doc = paragraphDoc('p');
    final edit = insertBlockEdit(doc, 'p', 0, const DividerNode(id: 'hr'))!;
    final result = DocEditApplier.apply(doc, edit);
    expect(result.nodes.map((n) => n.type), ['divider', 'paragraph']);
    expect(result.nodeById('p'), isNull);
    expect(edit.caret!.nodeId, result.nodes[1].id);
  });
}
