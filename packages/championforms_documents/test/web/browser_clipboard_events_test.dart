// Browser clipboard event path of the document editor.
//
// Synthetic `ClipboardEvent`s carrying a writable `DataTransfer` are
// dispatched at the window while the editor is focused. The editor's
// capture-phase window listeners (lib/src/editor/web/) hand them to
// `DocumentClipboardActions.handleBrowserEvent`, which, for a
// `ChampionDocClipboard`, writes into / reads from the event's own
// clipboardData.
//
// Run with: flutter test --platform chrome test/web/
@TestOn('browser')
library;

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_documents/championforms_documents.dart';
// ignore: implementation_imports
import 'package:championforms_documents/src/editor/web/clipboard_events.dart'
    show BrowserClipboardListener;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

import '../field/helpers.dart';

DocSnapshot _doc() => DocSnapshot([
  const ParagraphNode(id: 'p1', text: DocText('Hello world')),
  const EmbeddedFieldNode(
    id: 'emb',
    fieldJson: {'type': 'text', 'title': 'Name'},
  ),
  const ParagraphNode(id: 'p2', text: DocText('Goodbye')),
]);

/// A cancelable clipboard event carrying [data] (a fresh, writable
/// DataTransfer when omitted).
web.ClipboardEvent _event(String type, [web.DataTransfer? data]) =>
    web.ClipboardEvent(
      type,
      web.ClipboardEventInit(
        clipboardData: data ?? web.DataTransfer(),
        cancelable: true,
        bubbles: true,
      ),
    );

class _Harness {
  _Harness(this.h, this.backend);

  final DocHarness h;

  /// The delegate's backend: the event path must never touch it.
  final FakeClipboardBackend backend;
}

Future<_Harness> _pump(WidgetTester tester) async {
  final controller = form.FormController();
  addTearDown(controller.dispose);
  final backend = FakeClipboardBackend();
  final delegate = ChampionDocClipboard(
    controller,
    backend: backend,
    cache: DocClipboardSessionCache(),
  );
  final h = await pumpDocumentForm(
    tester,
    controller: controller,
    fields: [
      DocumentField(
        id: 'doc',
        initialDocument: _doc(),
        clipboardDelegate: delegate,
      ),
    ],
  );
  controller.updateFieldValue<String>('doc.field.emb', 'Ada Lovelace');
  await tester.pump();
  return _Harness(h, backend);
}

Future<void> _focus(WidgetTester tester, DocHarness h) async {
  h.editorState.focusNode.requestFocus();
  await tester.pump();
  expect(h.editorState.focusNode.hasPrimaryFocus, isTrue);
}

/// Selects "world … Good", across the embedded block.
Future<void> _selectAcross(WidgetTester tester, DocHarness h) async {
  await _focus(tester, h);
  h.select('p1', 6, 'p2', 4);
  await tester.pump();
}

void main() {
  test('the browser clipboard listener is active on the web', () {
    expect(BrowserClipboardListener.supported, isTrue);
  });

  testWidgets('copy writes text/html and text/plain into clipboardData', (
    tester,
  ) async {
    final t = await _pump(tester);
    await _selectAcross(tester, t.h);
    final before = t.h.snapshot;

    final event = _event('copy');
    web.window.dispatchEvent(event);
    await tester.pump();

    expect(event.defaultPrevented, isTrue);
    final data = event.clipboardData!;
    final plain = data.getData('text/plain');
    final html = data.getData('text/html');
    expect(plain, contains('world'));
    expect(plain, contains('Ada Lovelace'));
    expect(plain, contains('Good'));
    expect(plain, isNot(contains('Hello')));
    expect(plain, isNot(contains('bye')));
    expect(html, contains('world'));
    expect(html, contains('Ada Lovelace'));
    expect(
      extractPayloadJsonFromHtml(html),
      isNotEmpty,
      reason: 'the ID payload is embedded in the HTML',
    );
    expect(t.backend.writes, isEmpty, reason: 'no async clipboard write');
    expect(t.h.snapshot, before, reason: 'copy leaves the document alone');
  });

  testWidgets('cut writes the formats and deletes the selection', (
    tester,
  ) async {
    final t = await _pump(tester);
    expect(t.h.controller.hasFieldDefinition('doc.field.emb'), isTrue);
    await _selectAcross(tester, t.h);

    final event = _event('cut');
    web.window.dispatchEvent(event);
    await tester.pumpAndSettle();

    expect(event.defaultPrevented, isTrue);
    expect(event.clipboardData!.getData('text/plain'), contains('world'));
    expect(event.clipboardData!.getData('text/html'), contains('world'));
    expect(t.h.snapshot.nodeById('emb'), isNull);
    expect((t.h.snapshot.nodes.single as ParagraphNode).text.text, 'Hello bye');
    await t.h.settleThrottle();
    expect(t.h.controller.hasFieldDefinition('doc.field.emb'), isFalse);
    expect(t.backend.writes, isEmpty);
  });

  testWidgets('paste of our own HTML recreates the nodes and field values', (
    tester,
  ) async {
    final t = await _pump(tester);
    await _selectAcross(tester, t.h);
    final copy = _event('copy');
    web.window.dispatchEvent(copy);
    await tester.pump();
    final html = copy.clipboardData!.getData('text/html');

    // Paste into a fresh transfer holding only the HTML, so the payload has
    // to come out of the HTML (no custom format exists on the web).
    t.h.placeCaret('p2', 7); // "Goodbye|"
    await tester.pump();
    final paste = _event(
      'paste',
      web.DataTransfer()
        ..setData('text/html', html)
        ..setData('text/plain', 'ignored'),
    );
    web.window.dispatchEvent(paste);
    await tester.pumpAndSettle();
    await t.h.settleThrottle();

    expect(paste.defaultPrevented, isTrue);
    final embedded = t.h.snapshot.nodes.whereType<EmbeddedFieldNode>().toList();
    expect(embedded, hasLength(2), reason: 'the original plus the pasted one');
    final pasted = embedded.firstWhere((n) => n.id != 'emb');
    expect(pasted.fieldJson['type'], 'text');
    final pastedId = pasted.controllerIdFor('doc');
    expect(t.h.controller.hasFieldDefinition(pastedId), isTrue);
    expect(
      t.h.controller.getFieldValueOrNull<Object>(pastedId),
      'Ada Lovelace',
    );
    final text = [
      for (final n in t.h.snapshot.nodes)
        if (n is ParagraphNode) n.text.text,
    ].join('|');
    expect(text, contains('world'));
  });

  testWidgets('paste of foreign HTML imports its structure', (tester) async {
    final t = await _pump(tester);
    await _focus(tester, t.h);
    t.h.placeCaret('p2', 7);
    await tester.pump();

    final paste = _event(
      'paste',
      web.DataTransfer()
        ..setData(
          'text/html',
          '<h1>Imported title</h1><ul><li>first</li><li>second</li></ul>',
        )
        ..setData('text/plain', 'Imported title\nfirst\nsecond'),
    );
    web.window.dispatchEvent(paste);
    await tester.pumpAndSettle();

    expect(paste.defaultPrevented, isTrue);
    final nodes = t.h.snapshot.nodes;
    expect(
      nodes.whereType<HeadingNode>().map((n) => n.text.text),
      contains('Imported title'),
    );
    expect(nodes.whereType<ListItemNode>().map((n) => n.text.text), [
      'first',
      'second',
    ]);
  });

  testWidgets('paste of plain text only inserts it at the caret', (
    tester,
  ) async {
    final t = await _pump(tester);
    await _focus(tester, t.h);
    t.h.placeCaret('p1', 5); // "Hello| world"
    await tester.pump();

    final paste = _event(
      'paste',
      web.DataTransfer()..setData('text/plain', ' there'),
    );
    web.window.dispatchEvent(paste);
    await tester.pumpAndSettle();

    expect(paste.defaultPrevented, isTrue);
    expect(
      (t.h.snapshot.nodes.first as ParagraphNode).text.text,
      'Hello there world',
    );
  });

  testWidgets('an event dispatched at the page body reaches the listener', (
    tester,
  ) async {
    final t = await _pump(tester);
    await _selectAcross(tester, t.h);
    final event = _event('copy');
    web.document.body!.dispatchEvent(event);
    await tester.pump();
    expect(event.defaultPrevented, isTrue);
    expect(event.clipboardData!.getData('text/plain'), contains('world'));
  });

  testWidgets('events are left to the browser while the editor is unfocused', (
    tester,
  ) async {
    final t = await _pump(tester);
    t.h.select('p1', 6, 'p2', 4);
    t.h.editorState.focusNode.unfocus();
    await tester.pump();
    expect(t.h.editorState.focusNode.hasPrimaryFocus, isFalse);
    final before = t.h.snapshot;

    final copy = _event('copy');
    web.window.dispatchEvent(copy);
    final paste = _event(
      'paste',
      web.DataTransfer()..setData('text/plain', 'nope'),
    );
    web.window.dispatchEvent(paste);
    await tester.pumpAndSettle();

    expect(copy.defaultPrevented, isFalse);
    expect(copy.clipboardData!.getData('text/plain'), isEmpty);
    expect(paste.defaultPrevented, isFalse);
    expect(t.h.snapshot, before);
  });

  testWidgets('the listeners are removed when the editor is disposed', (
    tester,
  ) async {
    final t = await _pump(tester);
    await _selectAcross(tester, t.h);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final event = _event('copy');
    web.window.dispatchEvent(event);
    expect(event.defaultPrevented, isFalse);
    expect(event.clipboardData!.getData('text/plain'), isEmpty);
    expect(t.backend.writes, isEmpty);
  });
}
