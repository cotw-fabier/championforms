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
import 'package:super_editor/super_editor.dart' as se;

/// The templates, loaded once from the real assets.
late TemplateLibrary templates;

Future<void> loadTemplates() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  ensureFieldTypes();
  templates = await TemplateLibrary.load(rootBundle);
}

/// The running app.
class AppHarness {
  AppHarness(this.tester, this.clipboard);

  final WidgetTester tester;
  final FakeClipboardBackend clipboard;

  HomePageState get home => tester.state<HomePageState>(find.byType(HomePage));

  form.FormController get controller => home.controller;

  form.FormController get scratchController => home.scratchController;

  DocumentFieldWidgetState docState(String docId) =>
      tester.state<DocumentFieldWidgetState>(
        find.byKey(ValueKey(docId), skipOffstage: false),
      );

  DocumentEditorState editor(String docId) => docState(docId).editorState!;

  /// The editor's current document (not the throttled controller value).
  DocSnapshot snapshot(String docId) => editor(docId).snapshot();

  /// The SuperEditor of document [docId], for the super_editor test robot.
  Finder superEditorOf(String docId) => find.descendant(
    of: find.byKey(ValueKey(docId)),
    matching: find.byType(se.SuperEditor),
  );

  /// Lets the 150 ms document throttle and the side panel refresh run.
  Future<void> settle() async {
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  /// The side panel text shown for extracted key [key].
  String extractedText(String key) {
    final row = find.byKey(ValueKey('extracted-$key'));
    expect(row, findsOneWidget);
    final texts = tester.widgetList<Text>(
      find.descendant(of: row, matching: find.byType(Text)),
    );
    final selectable = tester.widgetList<SelectableText>(
      find.descendant(of: row, matching: find.byType(SelectableText)),
    );
    return [
      ...texts.map((t) => t.data ?? ''),
      ...selectable.map((t) => t.data ?? ''),
    ].join(' ');
  }
}

/// Pumps the Agreement Builder with in-memory storage and a fake clipboard.
Future<AppHarness> pumpApp(
  WidgetTester tester, {
  DraftStorage? storage,
  String template = 'service_agreement',
  Size size = const Size(1400, 2600),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  final clipboard = FakeClipboardBackend();
  SystemClipboard.backend = clipboard;
  _silencePlatformClipboard(tester);
  await tester.pumpWidget(
    AgreementBuilderApp(
      library: templates,
      storage: storage ?? MemoryDraftStorage(),
      initialTemplateId: template,
    ),
  );
  await tester.pumpAndSettle();
  return AppHarness(tester, clipboard);
}

/// Flutter's own clipboard channel, which text fields may touch.
void _silencePlatformClipboard(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async => switch (call.method) {
      'Clipboard.getData' => {'text': null},
      'Clipboard.hasStrings' => {'value': false},
      _ => null,
    },
  );
}

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
