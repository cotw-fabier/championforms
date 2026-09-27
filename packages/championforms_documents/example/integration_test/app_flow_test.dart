// End-to-end flow on a real device with the REAL system clipboard:
//
//   tool/macos_integration_test.sh packages/championforms_documents/example \
//       integration_test/app_flow_test.dart
//
// (Run macOS integration tests through the wrapper, never plain
// `flutter test -d macos`; see CLAUDE.md.) This test overwrites the system
// clipboard.

import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_documents/championforms_documents.dart';
import 'package:championforms_documents_example/src/app.dart';
import 'package:championforms_documents_example/src/draft_storage.dart';
import 'package:championforms_documents_example/src/home_page.dart';
import 'package:championforms_documents_example/src/templates.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:super_editor/super_editor.dart' as se;
import 'package:super_editor/super_editor_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('template → type → slash Select → pick → copy → paste in the '
      'scratch tab → submit', (tester) async {
    ensureFieldTypes();
    final library = await TemplateLibrary.load();
    await tester.pumpWidget(
      AgreementBuilderApp(library: library, storage: MemoryDraftStorage()),
    );
    await tester.pumpAndSettle();
    final home = tester.state<HomePageState>(find.byType(HomePage));
    expect(home.template.id, 'service_agreement');

    DocumentEditorState editorOf(String docId) => tester
        .state<DocumentFieldWidgetState>(find.byKey(ValueKey(docId)))
        .editorState!;
    Finder superEditorOf(String docId) => find.descendant(
      of: find.byKey(ValueKey(docId)),
      matching: find.byType(se.SuperEditor),
    );
    // The document switcher on wide windows, the bottom bar on narrow ones.
    Future<void> showTab(String name) async {
      final wide = find.byKey(ValueKey('switch-$name'));
      await tester.tap(
        wide.evaluate().isNotEmpty ? wide : find.byKey(ValueKey('nav-$name')),
      );
      await tester.pumpAndSettle();
    }

    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    }

    Future<void> shortcut(LogicalKeyboardKey key) async {
      final modifier =
          defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.iOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await tester.sendKeyDownEvent(modifier);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(modifier);
    }

    // 1. Type into the document: a new party shows up as extracted.
    final parties =
        (editorOf('agreement').snapshot().nodeById('sa_parties')!
                as ParagraphNode)
            .text
            .text;
    await tester.ensureVisible(superEditorOf('agreement'));
    await tester.placeCaretInParagraph(
      'sa_parties',
      parties.length,
      superEditorFinder: superEditorOf('agreement'),
    );
    await tester.typeImeText(' Witness: @initech.');
    await settle();
    var results = form.FormResults.getResults(
      controller: home.controller,
      checkForErrors: false,
    );
    expect(results.extracted('agreement')['parties'], contains('initech'));

    // 2. Insert a Select through the slash menu at the end of the document.
    await tester.placeCaretInParagraph(
      'sa_end',
      0,
      superEditorFinder: superEditorOf('agreement'),
    );
    await tester.typeImeText('/select');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('slash-item-select')));
    await settle();
    final selectNode = editorOf('agreement')
        .snapshot()
        .nodes
        .whereType<EmbeddedFieldNode>()
        .firstWhere((n) => n.fieldType == 'select');
    final selectId = selectNode.controllerIdFor('agreement');
    expect(home.controller.hasFieldDefinition(selectId), isTrue);

    // 3. Pick "Option 2" in it.
    final dropdown = find.descendant(
      of: find.byKey(ValueKey('embedded-${selectNode.id}')),
      matching: find.byType(DropdownButtonFormField<String>),
    );
    await tester.ensureVisible(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Option 2').last);
    await settle();
    expect(
      home.controller
          .getFieldValue<List<form.FieldOption>>(selectId)!
          .map((o) => o.value),
      ['option_2'],
    );

    // 4. Select the block and copy it to the real system clipboard.
    final agreement = editorOf('agreement');
    agreement.focusNode.requestFocus();
    await tester.pump();
    agreement.editor.execute([
      se.ChangeSelectionRequest(
        SuperEditorAdapter.toEditorSelection(
          agreement.document,
          DocSelection(
            startNodeId: selectNode.id,
            startOffset: 0,
            endNodeId: selectNode.id,
            endOffset: 1,
          ),
        ),
        se.SelectionChangeType.expandSelection,
        se.SelectionReason.userInteraction,
      ),
    ]);
    await tester.pump();
    await shortcut(LogicalKeyboardKey.keyC);
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    final formats = await tester.runAsync(SystemClipboard.availableFormats);
    expect(formats, contains(docClipboardFormat));
    expect(formats, contains(ClipboardFormat.html));
    final read = await tester.runAsync(
      () => SystemClipboard.read(formats: [docClipboardFormat]),
    );
    final payload = utf8.decode(read!.bytes(docClipboardFormat)!);
    expect(payload, contains('option_2'));

    // 5. Paste into the scratch document: same field type, same value.
    await showTab('scratch');
    final scratchFirst = editorOf('scratch').snapshot().nodes.first.id;
    await tester.placeCaretInParagraph(
      scratchFirst,
      0,
      superEditorFinder: superEditorOf('scratch'),
    );
    await shortcut(LogicalKeyboardKey.keyV);
    // The paste reads the clipboard asynchronously.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
      if (editorOf('scratch').snapshot().embeddedFields.isNotEmpty) break;
    }
    await settle();
    final pasted = editorOf('scratch').snapshot().embeddedFields.single;
    expect(pasted.id, isNot(selectNode.id));
    expect(pasted.fieldType, 'select');
    final pastedId = pasted.controllerIdFor('scratch');
    final pastedField = home.scratchController.registeredFields.firstWhere(
      (f) => f.id == pastedId,
    );
    expect(pastedField, isA<form.OptionSelect>());
    expect(
      home.scratchController
          .getFieldValue<List<form.FieldOption>>(pastedId)!
          .map((o) => o.value),
      ['option_2'],
    );

    // 6. Back to the agreement: fix what the rules object to and submit.
    await showTab('agreement');
    home.controller.updateFieldValue('title', 'Portal build');
    final doc = editorOf('agreement').snapshot();
    home.controller.updateFieldValue(
      'agreement',
      DocSnapshot([
        for (final n in doc.nodes)
          if (n.id == 'sa_terms')
            const ParagraphNode(
              id: 'sa_terms',
              text: DocText('Work starts on 2026-10-01.'),
            )
          else
            n,
      ]),
    );
    await settle();
    await tester.ensureVisible(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('submit-dialog')), findsOneWidget);
    results = form.FormResults.getResults(
      controller: home.controller,
      checkForErrors: false,
    );
    expect(results.grab(selectId).asMultiselectList().map((o) => o.value), [
      'option_2',
    ]);

    // Unmount now: super_editor schedules a frame callback while its
    // keyboard opener is disposed, which must run before the test ends.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
