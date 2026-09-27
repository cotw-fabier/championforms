import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

const _platforms = TargetPlatformVariant({
  TargetPlatform.macOS,
  TargetPlatform.android,
  TargetPlatform.iOS,
});

/// A form in a ListView: a text field, then a document far taller than the
/// 800 x 600 window.
Future<(form.FormController, ScrollController)> _pumpTallForm(
  WidgetTester tester,
) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final controller = form.FormController();
  addTearDown(controller.dispose);
  final scroll = ScrollController();
  addTearDown(scroll.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          controller: scroll,
          children: [
            form.Form(
              controller: controller,
              fields: [
                form.TextField(id: 'title', title: 'Title'),
                DocumentField(
                  id: 'doc',
                  initialDocument: DocSnapshot([
                    for (var i = 0; i < 60; i++)
                      ParagraphNode(id: 'p$i', text: DocText('Line $i')),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (controller, scroll);
}

DocumentEditorState _editor(WidgetTester tester) =>
    tester.state<DocumentEditorState>(find.byType(DocumentEditor));

/// The caret's rect in global coordinates.
Rect _caretRect(WidgetTester tester) {
  final editor = _editor(tester);
  final layout = SuperEditorInspector.findDocumentLayout();
  final rect = layout.getRectForPosition(editor.composer.selection!.extent)!;
  final topLeft = layout.getGlobalOffsetFromDocumentOffset(rect.topLeft);
  return topLeft & rect.size;
}

void _placeCaretAtEnd(WidgetTester tester) {
  final editor = _editor(tester);
  editor.editor.execute([
    se.ChangeSelectionRequest(
      se.DocumentSelection.collapsed(
        position: SuperEditorAdapter.toEditorPosition(
          editor.document,
          'p59',
          'Line 59'.length,
        ),
      ),
      se.SelectionChangeType.placeCaret,
      se.SelectionReason.userInteraction,
    ),
  ]);
}

void main() {
  testWidgets('typing at the end of a tall document scrolls the page to the '
      'caret', (tester) async {
    final (_, scroll) = await _pumpTallForm(tester);
    // Focus the editor with a tap on a visible line.
    await tester.placeCaretInParagraph('p0', 0);
    expect(scroll.offset, 0);

    _placeCaretAtEnd(tester);
    await tester.pumpAndSettle();
    expect(
      scroll.offset,
      greaterThan(0),
      reason: 'moving the caret reveals it',
    );

    // Scroll away, then type: the edit brings the caret back.
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.typeImeText('!');
    await tester.pumpAndSettle();
    expect(
      SuperEditorInspector.findTextInComponent('p59').toPlainText(),
      'Line 59!',
    );
    expect(scroll.offset, greaterThan(0));
    final caret = _caretRect(tester);
    expect(caret.top, greaterThanOrEqualTo(0));
    expect(caret.bottom, lessThanOrEqualTo(600));
  }, variant: _platforms);

  testWidgets('the keyboard opening reveals the caret again', (tester) async {
    final (_, scroll) = await _pumpTallForm(tester);
    await tester.placeCaretInParagraph('p0', 0);
    _placeCaretAtEnd(tester);
    await tester.pumpAndSettle();
    final before = scroll.offset;
    // A 300 px keyboard shrinks the page; the caret was near the bottom.
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(before));
    expect(_caretRect(tester).bottom, lessThanOrEqualTo(300));
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('an unfocused document does not scroll the page', (tester) async {
    final (_, scroll) = await _pumpTallForm(tester);
    _placeCaretAtEnd(tester);
    await tester.pumpAndSettle();
    expect(scroll.offset, 0);
  });
}
