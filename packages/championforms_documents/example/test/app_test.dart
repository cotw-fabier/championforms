import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:championforms_documents_example/src/draft_storage.dart';
import 'package:championforms_documents_example/src/rating_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:super_editor/super_editor_test.dart';

import 'helpers.dart';

void main() {
  setUpAll(loadTemplates);

  group('templates', () {
    testWidgets('the service agreement renders its blocks and registers its '
        'embedded fields', (tester) async {
      final app = await pumpApp(tester);
      final doc = app.snapshot('agreement');
      expect(doc.nodeById('sa_parties_h'), isA<HeadingNode>());
      expect(doc.nodeById('sa_deliv_1'), isA<TaskNode>());
      for (final id in [
        'sa_payment_terms',
        'sa_onboarding',
        'sa_signed_copy',
      ]) {
        expect(doc.nodeById(id), isA<EmbeddedFieldNode>(), reason: id);
        expect(find.byKey(ValueKey('embedded-$id')), findsOneWidget);
        expect(
          app.controller.hasFieldDefinition('agreement.field.$id'),
          isTrue,
          reason: id,
        );
      }
      final fields = {for (final f in app.controller.registeredFields) f.id: f};
      expect(
        fields['agreement.field.sa_payment_terms'],
        isA<form.OptionSelect>(),
      );
      expect(
        fields['agreement.field.sa_onboarding'],
        isA<form.CheckboxSelect>(),
      );
      expect(fields['agreement.field.sa_signed_copy'], isA<form.FileUpload>());
      // Everything comes from the template JSON: the Rating block and its
      // icon, and the app-wide clipboard delegate.
      final agreement = fields['agreement']! as DocumentField;
      final rating = agreement.blockTemplates.firstWhere(
        (b) => b.key == 'rating',
      );
      expect(rating.icon, DocumentBlockIcons.named['star']);
      expect(
        tester
            .widget<DocumentEditor>(
              find.descendant(
                of: find.byKey(const ValueKey('agreement')),
                matching: find.byType(DocumentEditor),
              ),
            )
            .clipboardDelegate,
        isA<ChampionDocClipboard>(),
      );
      // The template's rules are live: derived values are in the side panel.
      expect(app.extractedText('parties'), contains('acme, globex'));
      expect(app.extractedText('startDate'), contains('2026-10-01'));
      expect(find.text('Payment amount'), findsNothing);
    });

    testWidgets('switching to meeting notes loads its rules, document and the '
        'custom rating block', (tester) async {
      final app = await pumpApp(tester);
      await tester.tap(find.byKey(const ValueKey('template-meeting_notes')));
      await tester.pumpAndSettle();
      await app.settle();

      expect(app.home.template.id, 'meeting_notes');
      final doc = app.snapshot('agreement');
      expect(doc.nodeById('mn_action_1'), isA<TaskNode>());
      expect(find.byType(RatingFieldWidget), findsOneWidget);
      expect(
        app.controller.hasFieldDefinition('agreement.field.sa_payment_terms'),
        isFalse,
        reason: 'the new template runs on a fresh controller',
      );
      expect(app.extractedText('attendees'), contains('dana, lee'));
      expect(app.extractedText('actionItems'), contains('done: 1'));
    });

    testWidgets('the blank template starts empty', (tester) async {
      final app = await pumpApp(tester, template: 'blank');
      final doc = app.snapshot('agreement');
      expect(doc.nodes, hasLength(1));
      expect((doc.nodes.single as ParagraphNode).text.text, isEmpty);
    });
  });

  testWidgets('typing a mention updates the side panel', (tester) async {
    final app = await pumpApp(tester);
    expect(app.extractedText('parties'), isNot(contains('initech')));
    final text =
        (app.snapshot('agreement').nodeById('sa_parties')! as ParagraphNode)
            .text
            .text;
    await tester.placeCaretInParagraph(
      'sa_parties',
      text.length,
      superEditorFinder: app.superEditorOf('agreement'),
    );
    await tester.typeImeText(' Witness: @initech.');
    await app.settle();

    expect(app.extractedText('parties'), contains('acme, globex, initech'));
    final results = form.FormResults.getResults(
      controller: app.controller,
      checkForErrors: false,
    );
    expect(results.grab('agreement.parties').asStringList(), [
      'acme',
      'globex',
      'initech',
    ]);
  });

  testWidgets('a "Pricing" heading makes the payment fields appear', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    expect(find.text('Payment amount'), findsNothing);
    expect(find.text('Currency'), findsNothing);

    await tester.placeCaretInParagraph(
      'sa_end',
      0,
      superEditorFinder: app.superEditorOf('agreement'),
    );
    await tester.typeImeText('## Pricing');
    await app.settle();

    final node = app.snapshot('agreement').nodeById('sa_end');
    expect(node, isA<HeadingNode>(), reason: '"## " converts the block');
    expect(app.extractedText('hasPricing'), contains('true'));
    expect(find.text('Payment amount'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);

    // Payment fields validate only while they are shown.
    final results = form.FormResults.getResults(controller: app.controller);
    expect(
      results.formErrors.map((e) => e.fieldId),
      containsAll(['paymentAmount', 'paymentCurrency']),
    );
  });

  testWidgets('submitting without the required "Parties" section shows the '
      'errors', (tester) async {
    final app = await pumpApp(tester);
    app.controller.updateFieldValue('title', 'Portal build');
    // Drop the Parties heading and its paragraph, and the "TBD".
    final doc = app.snapshot('agreement');
    final edited = DocSnapshot([
      for (final n in doc.nodes)
        if (n.id == 'sa_terms')
          const ParagraphNode(
            id: 'sa_terms',
            text: DocText('Work starts on 2026-10-01.'),
          )
        else if (n.id != 'sa_parties_h' && n.id != 'sa_parties')
          n,
    ]);
    app.controller.updateFieldValue('agreement', edited);
    await app.settle();
    expect(app.snapshot('agreement').nodeById('sa_parties_h'), isNull);

    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pump();

    final errors = app.controller.findErrors('agreement');
    expect(errors, isNotEmpty);
    final reasons = errors.map((e) => e.reason).join('\n');
    expect(reasons, contains('Add a "Parties" section naming who signs'));
    expect(reasons, contains('parties'), reason: 'the required mentions');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Parties'), findsWidgets);
    await tester.pumpAndSettle();
    // The side panel lists the error.
    expect(
      find.byKey(const ValueKey('error-agreement-0'), skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('submit-dialog')), findsNothing);
  });

  testWidgets('a valid agreement submits and shows the results JSON', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    app.controller.updateFieldValue('title', 'Portal build');
    final doc = app.snapshot('agreement');
    app.controller.updateFieldValue(
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
    await app.settle();
    await tester.tap(find.byKey(const ValueKey('submit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('submit-dialog')), findsOneWidget);
    expect(find.textContaining('"agreement.parties"'), findsOneWidget);
  });

  testWidgets('save → reset → load round-trips every value', (tester) async {
    final storage = MemoryDraftStorage();
    final app = await pumpApp(tester, storage: storage);
    final c = app.controller;
    c.updateFieldValue('title', 'Portal build');
    await tester.placeCaretInParagraph(
      'sa_scope',
      0,
      superEditorFinder: app.superEditorOf('agreement'),
    );
    await tester.typeImeText('Phase one: ');
    c.toggleMultiSelectValue(
      'agreement.field.sa_payment_terms',
      toggleOn: ['net30'],
    );
    c.toggleMultiSelectValue(
      'agreement.field.sa_onboarding',
      toggleOn: ['training', 'support'],
    );
    await app.settle();
    // A block the template does not have: its id is unknown to a fresh
    // form until the loaded document registers it.
    c.updateFieldValue(
      'agreement',
      DocSnapshot([
        ...app.snapshot('agreement').nodes,
        const EmbeddedFieldNode(
          id: 'extra_note',
          fieldJson: {'type': 'text', 'title': 'Extra'},
        ),
      ]),
    );
    await app.settle();
    c.updateFieldValue('agreement.field.extra_note', 'kept');
    await app.settle();
    final before = form.FormResults.getResults(
      controller: c,
      checkForErrors: false,
    );
    final beforeDoc = before.grab('agreement').asDocumentJson();
    expect(
      (app.snapshot('agreement').nodeById('sa_scope')! as ParagraphNode)
          .text
          .text,
      startsWith('Phase one: '),
    );

    await tester.tap(find.byKey(const ValueKey('save')));
    await tester.pumpAndSettle();
    final saved = await storage.read();
    expect(saved, contains('Phase one: '));
    expect(saved, contains('"agreement.field.extra_note":"kept"'));
    expect(saved, isNot(contains('"agreement.parties"')), reason: 'derived');

    await tester.tap(find.byKey(const ValueKey('reset')));
    await tester.pumpAndSettle();
    await app.settle();
    expect(app.controller, isNot(same(c)), reason: 'reset starts over');
    expect(
      app.controller.getFieldValueOrNull<Object>('title'),
      anyOf(isNull, ''),
    );
    expect(
      (app.snapshot('agreement').nodeById('sa_scope')! as ParagraphNode)
          .text
          .text,
      isNot(startsWith('Phase one')),
    );

    await tester.tap(find.byKey(const ValueKey('load')));
    await tester.pumpAndSettle();
    await app.settle();

    final loaded = app.controller;
    expect(find.textContaining('Loaded and verified'), findsOneWidget);
    expect(loaded.getFieldValue<String>('title'), 'Portal build');
    final after = form.FormResults.getResults(
      controller: loaded,
      checkForErrors: false,
    );
    expect(after.grab('agreement').asDocumentJson(), beforeDoc);
    expect(
      after
          .grab('agreement.field.sa_payment_terms')
          .asMultiselectList()
          .map((o) => o.value),
      ['net30'],
    );
    expect(
      after
          .grab('agreement.field.sa_onboarding')
          .asMultiselectList()
          .map((o) => o.value),
      unorderedEquals(['training', 'support']),
    );
    expect(
      (app.snapshot('agreement').nodeById('sa_scope')! as ParagraphNode)
          .text
          .text,
      startsWith('Phase one: '),
      reason: 'the editor shows the loaded document',
    );
    expect(after.extracted('agreement'), before.extracted('agreement'));
    expect(after.grab('agreement.field.extra_note').asString(), 'kept');
    expect(after.toJson(), before.toJson());
  });

  testWidgets('copying a filled Select block and pasting it in the scratch tab '
      'recreates the field with its value', (tester) async {
    final app = await pumpApp(tester);
    app.controller.toggleMultiSelectValue(
      'agreement.field.sa_payment_terms',
      toggleOn: ['net60'],
    );
    await app.settle();

    // Select just the Select block and copy it.
    final agreement = app.editor('agreement');
    expect(agreement.selectNode('sa_payment_terms'), isTrue);
    await tester.pump();
    await pressShortcut(tester, LogicalKeyboardKey.keyC);
    await tester.pumpAndSettle();
    expect(app.clipboard.writes, hasLength(1));
    expect(app.clipboard.contents.keys.map((f) => f.id), contains('text/html'));
    expect(app.clipboard.contents.values, contains(contains('Net 60')));

    // Paste into the scratch document.
    await tester.tap(find.byKey(const ValueKey('switch-scratch')));
    await tester.pumpAndSettle();
    final scratchNode = app.snapshot('scratch').nodes.first.id;
    await tester.placeCaretInParagraph(
      scratchNode,
      0,
      superEditorFinder: app.superEditorOf('scratch'),
    );
    await pressShortcut(tester, LogicalKeyboardKey.keyV);
    await tester.pumpAndSettle();
    await app.settle();

    final pasted = app
        .snapshot('scratch')
        .nodes
        .whereType<EmbeddedFieldNode>()
        .single;
    expect(pasted.id, isNot('sa_payment_terms'), reason: 'a fresh id');
    expect(pasted.sourceId, 'sa_payment_terms');
    expect(pasted.fieldJson['title'], 'Payment terms');
    final id = pasted.controllerIdFor('scratch');
    final field = app.scratchController.registeredFields.firstWhere(
      (f) => f.id == id,
    );
    expect(field, isA<form.OptionSelect>());
    final value = app.scratchController.getFieldValue<List<form.FieldOption>>(
      id,
    )!;
    expect(value.map((o) => o.value), ['net60']);
    expect(
      find.byKey(const ValueKey('scratch-value-Payment terms')),
      findsOneWidget,
    );
  }, variant: const TargetPlatformVariant({TargetPlatform.macOS}));

  testWidgets('the clipboard inspector lists formats and previews', (
    tester,
  ) async {
    final app = await pumpApp(tester);
    await tester.tap(find.text('Clipboard inspector'));
    await tester.pumpAndSettle();
    app.clipboard.setExternal({
      ClipboardFormat.plainText: 'hello',
      ClipboardFormat.html: '<b>hello</b>',
      ClipboardFormat.custom('com.example.bin'): Uint8List.fromList([0xff, 1]),
    });
    await tester.tap(find.byKey(const ValueKey('clipboard-refresh')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('clipboard-format-text/plain')),
      findsOneWidget,
    );
    expect(find.text('<b>hello</b>'), findsOneWidget);
    expect(find.text('2 bytes'), findsOneWidget);
  });

  testWidgets('narrow screens use a bottom navigation bar and the theme '
      'toggle switches to dark', (tester) async {
    await pumpApp(tester, size: const Size(420, 900));
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('side-panel')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('nav-panel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('side-panel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-toggle')));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
    );
  });
}
