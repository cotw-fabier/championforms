import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

import '../field/helpers.dart';

/// A task, a paragraph and a list item, with a text field after the
/// document to receive focus.
Future<DocHarness> _pump(WidgetTester tester) => pumpDocumentForm(
  tester,
  fields: [
    DocumentField(
      id: 'doc',
      initialDocument: DocSnapshot([
        const TaskNode(id: 't', text: DocText('Task')),
        const ParagraphNode(id: 'p', text: DocText('Para')),
        const ListItemNode(id: 'l', text: DocText('Item')),
      ]),
    ),
  ],
);

void main() {
  testWidgets('Tab does not indent a task or a paragraph (a snapshot cannot '
      'hold it), but still indents a list item', (tester) async {
    final h = await _pump(tester);

    await tester.placeCaretInParagraph('t', 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect((h.document.getNodeById('t')! as se.TaskNode).indent, 0);

    await tester.placeCaretInParagraph('p', 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect((h.document.getNodeById('p')! as se.ParagraphNode).indent, 0);

    await tester.placeCaretInParagraph('l', 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect((h.document.getNodeById('l')! as se.ListItemNode).indent, 1);
    expect((h.snapshot.nodes[2] as ListItemNode).indent, 1);
  }, variant: TargetPlatformVariant.desktop());

  testWidgets('indentation and alignment requests are refused whatever '
      'sends them, so nothing is shown that a save would drop', (tester) async {
    final h = await _pump(tester);
    final before = h.snapshot;
    h.editor.execute([
      const se.IndentTaskRequest('t'),
      const se.SetTaskIndentRequest('t', 2),
      const se.IndentParagraphRequest('p'),
      const se.SetParagraphIndentRequest('p', level: 3),
      se.ChangeParagraphAlignmentRequest(
        nodeId: 'p',
        alignment: TextAlign.center,
      ),
    ]);
    await tester.pumpAndSettle();
    expect((h.document.getNodeById('t')! as se.TaskNode).indent, 0);
    final p = h.document.getNodeById('p')! as se.ParagraphNode;
    expect(p.indent, 0);
    expect(p.getMetadataValue('textAlign'), isNull);
    expect(h.snapshot, before);

    // Left alignment is what a snapshot means anyway: allowed.
    h.editor.execute([
      se.ChangeParagraphAlignmentRequest(
        nodeId: 'p',
        alignment: TextAlign.left,
      ),
    ]);
    await tester.pumpAndSettle();
    expect(h.snapshot, before);
  });

  testWidgets('a list item never indents deeper than a snapshot holds', (
    tester,
  ) async {
    final h = await _pump(tester);
    for (var i = 0; i < 12; i++) {
      h.editor.execute([se.IndentListItemRequest(nodeId: 'l')]);
    }
    await tester.pumpAndSettle();
    final indent = (h.document.getNodeById('l')! as se.ListItemNode).indent;
    expect(indent, lessThanOrEqualTo(8));
    expect((h.snapshot.nodes[2] as ListItemNode).indent, indent);
  });
}
