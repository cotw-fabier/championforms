import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_robots/flutter_test_robots.dart';
import 'package:super_editor/super_editor_test.dart';

// Enter and Backspace the way the running platform delivers them.
//
// On native platforms a hardware Enter / Backspace is a key event that
// super_editor handles itself. In a browser, super_editor deliberately
// ignores those key events (`doNothingWithEnterOnWeb`,
// `doNothingWithBackspaceOnWeb`) and lets them reach the browser, which then
// reports them through the IME connection: Enter as a `"\n"` delta plus a
// `TextInputAction.newline` action, Backspace as a deletion delta.
// flutter_test only sends the key event, so on web these helpers also send
// what the browser would. super_editor's own web tests do the same.
//
// A key event our editor *does* handle (the rules' Backspace at the start of
// a node, for instance) is `preventDefault`ed by the Flutter web engine, so
// the browser sends nothing further; the helpers mirror that too.

/// Presses Enter: the key event, then on web (when nothing handled it) the
/// `"\n"` delta and newline action the browser would send.
Future<void> pressEnterOnPlatform(WidgetTester tester) async {
  final handled = await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  if (!handled && kIsWeb) {
    await tester.ime.typeText('\n', getter: imeClientGetter);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.newline);
  }
  await tester.pumpAndSettle();
}

/// Presses Backspace: the key event, then on web (when nothing handled it)
/// the deletion delta the browser would send.
Future<void> pressBackspaceOnPlatform(WidgetTester tester) async {
  final handled = await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
  if (!handled && kIsWeb) {
    await tester.ime.backspace(getter: imeClientGetter);
  }
  await tester.pumpAndSettle();
}
