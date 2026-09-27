import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
// ignore: implementation_imports
import 'package:championforms_documents/src/field/document_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

EmbeddedFieldNode _textBlock(String id) =>
    EmbeddedFieldNode(id: id, fieldJson: const {'type': 'text'});

Widget _app(form.FormController controller, DocumentField doc) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: form.Form(controller: controller, fields: [doc]),
    ),
  ),
);

/// Inserts [text] at the caret without pumping, so it stays pending.
void _typeWithoutPumping(WidgetTester tester, String text) {
  tester.state<DocumentEditorState>(find.byType(DocumentEditor)).editor.execute(
    [se.InsertPlainTextAtCaretRequest(text)],
  );
}

void main() {
  setUpAll(DocumentFields.ensureInitialized);

  testWidgets('swapping the controller hands pending edits to the old one, '
      'unhooks its flush, and shows the new one', (tester) async {
    final a = form.FormController();
    final b = form.FormController();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    final doc = DocumentField(
      id: 'doc',
      initialDocument: DocSnapshot([
        const ParagraphNode(id: 'p', text: DocText('Start')),
      ]),
    );
    b.addFields([doc]);
    b.updateFieldValue<Object>(
      'doc',
      DocSnapshot([
        const ParagraphNode(id: 'n', text: DocText('From B')),
        _textBlock('blk'),
      ]),
    );

    await tester.pumpWidget(_app(a, doc));
    await tester.pumpAndSettle();
    await tester.placeCaretInParagraph('p', 5);
    _typeWithoutPumping(tester, '!');
    // Swap before the 150 ms throttle fires.
    await tester.pumpWidget(_app(b, doc));
    await tester.pumpAndSettle();

    final aDoc = DocumentField.coerce(a.getFieldValueOrNull<Object>('doc'))!;
    expect((aDoc.nodes.single as ParagraphNode).text.text, 'Start!');
    expect(DocumentRuntime.lookup(a, 'doc')!.flusher, isNull);
    expect(DocumentRuntime.lookup(b, 'doc')!.flusher, isNotNull);

    final state = tester.state<DocumentFieldWidgetState>(
      find.byType(DocumentFieldWidget),
    );
    expect(state.editorState!.snapshot().nodes.first.id, 'n');
    expect(b.hasFieldDefinition('doc.field.blk'), isTrue);

    // Typing now goes to B only.
    await tester.placeCaretInParagraph('n', 6);
    _typeWithoutPumping(tester, '?');
    DocumentFields.flushAll(a);
    expect(
      (DocumentField.coerce(b.getFieldValueOrNull<Object>('doc'))!.nodes.first
              as ParagraphNode)
          .text
          .text,
      'From B',
      reason: 'flushing A must not push B\'s editor',
    );
    DocumentFields.flushAll(b);
    expect(
      (DocumentField.coerce(b.getFieldValueOrNull<Object>('doc'))!.nodes.first
              as ParagraphNode)
          .text
          .text,
      'From B?',
    );
    expect(
      (DocumentField.coerce(a.getFieldValueOrNull<Object>('doc'))!.nodes.single
              as ParagraphNode)
          .text
          .text,
      'Start!',
    );
  });

  testWidgets('disposal leaves no timer, flush hook or listener behind', (
    tester,
  ) async {
    final c = form.FormController();
    addTearDown(c.dispose);
    final doc = DocumentField(
      id: 'doc',
      initialDocument: DocSnapshot([
        const ParagraphNode(id: 'p', text: DocText('Hi')),
      ]),
    );
    await tester.pumpWidget(_app(c, doc));
    await tester.pumpAndSettle();
    await tester.placeCaretInParagraph('p', 2);
    _typeWithoutPumping(tester, '!');
    final state = tester.state<DocumentFieldWidgetState>(
      find.byType(DocumentFieldWidget),
    );
    expect(state.hasPendingChanges, isTrue);

    await tester.pumpWidget(const SizedBox());
    // The pending keystroke was kept, the throttle timer is gone (a live
    // timer would fail the test), and the runtime no longer calls into the
    // disposed widget.
    final value = DocumentField.coerce(c.getFieldValueOrNull<Object>('doc'))!;
    expect((value.nodes.single as ParagraphNode).text.text, 'Hi!');
    expect(DocumentRuntime.lookup(c, 'doc')!.flusher, isNull);
    DocumentFields.flushAll(c);
    // Controller notifications after the widget is gone reach no state.
    c.updateFieldValue<Object>('doc', DocSnapshot.empty);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a controller disposed before the form unmounts is harmless', (
    tester,
  ) async {
    final c = form.FormController();
    final doc = DocumentField(
      id: 'doc',
      initialDocument: DocSnapshot([_textBlock('b')]),
    );
    await tester.pumpWidget(_app(c, doc));
    await tester.pumpAndSettle();
    c.dispose();
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
