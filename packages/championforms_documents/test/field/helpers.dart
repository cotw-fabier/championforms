import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart' as se;

/// A [DocClipboardDelegate] that records calls and pastes a queued result.
class FakeDocClipboard implements DocClipboardDelegate {
  final copies = <({String docId, DocSnapshot doc, DocSelection selection})>[];
  final pastes = <({String docId, DocSnapshot doc})>[];

  /// What the next paste returns.
  DocPasteResult? nextPaste;

  @override
  Future<void> copy({
    required String docId,
    required DocSnapshot doc,
    required DocSelection selection,
  }) async {
    copies.add((docId: docId, doc: doc, selection: selection));
  }

  @override
  Future<DocPasteResult?> paste({
    required String docId,
    required DocSnapshot doc,
  }) async {
    pastes.add((docId: docId, doc: doc));
    return nextPaste;
  }
}

/// A document form on screen.
class DocHarness {
  DocHarness(this.tester, this.controller);

  final WidgetTester tester;
  final form.FormController controller;

  DocumentFieldWidgetState get fieldState =>
      tester.state<DocumentFieldWidgetState>(find.byType(DocumentFieldWidget));

  DocumentEditorState get editorState => fieldState.editorState!;

  se.MutableDocument get document => editorState.document;

  se.Editor get editor => editorState.editor;

  DocSnapshot get snapshot => editorState.snapshot();

  /// The controller's value for [docId], as a snapshot.
  DocSnapshot? controllerDoc(String docId) =>
      DocumentField.coerce(controller.getFieldValueOrNull<Object>(docId));

  /// Lets the 150 ms throttle fire.
  Future<void> settleThrottle() async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  void select(String startId, int start, String endId, int end) {
    editor.execute([
      se.ChangeSelectionRequest(
        SuperEditorAdapter.toEditorSelection(
          document,
          DocSelection(
            startNodeId: startId,
            startOffset: start,
            endNodeId: endId,
            endOffset: end,
          ),
        ),
        se.SelectionChangeType.expandSelection,
        se.SelectionReason.userInteraction,
      ),
    ]);
  }

  void placeCaret(String nodeId, int offset) {
    editor.execute([
      se.ChangeSelectionRequest(
        se.DocumentSelection.collapsed(
          position: SuperEditorAdapter.toEditorPosition(
            document,
            nodeId,
            offset,
          ),
        ),
        se.SelectionChangeType.placeCaret,
        se.SelectionReason.userInteraction,
      ),
    ]);
  }
}

/// Pumps a `Form` holding [fields] (a DocumentField among them) in a
/// scrollable page.
Future<DocHarness> pumpDocumentForm(
  WidgetTester tester, {
  required List<form.Field> fields,
  form.FormController? controller,
  Size size = const Size(1000, 1600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  _installFakePlatformClipboard(tester);
  final c = controller ?? form.FormController();
  if (controller == null) addTearDown(c.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: form.Form(controller: c, fields: fields),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return DocHarness(tester, c);
}

String? fakePlatformClipboard;

void _installFakePlatformClipboard(WidgetTester tester) {
  fakePlatformClipboard = null;
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'Clipboard.setData') {
        fakePlatformClipboard = (call.arguments as Map)['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return {'text': fakePlatformClipboard};
      }
      if (call.method == 'Clipboard.hasStrings') {
        return {'value': fakePlatformClipboard != null};
      }
      return null;
    },
  );
}

/// A one-paragraph document.
DocSnapshot paragraphDoc(String id, [String text = '']) =>
    DocSnapshot([ParagraphNode(id: id, text: DocText(text))]);

/// Sends Cmd+key on Apple platforms and Ctrl+key elsewhere.
Future<void> pressShortcut(WidgetTester tester, LogicalKeyboardKey key) async {
  final apple =
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.iOS;
  final modifier = apple
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
}
