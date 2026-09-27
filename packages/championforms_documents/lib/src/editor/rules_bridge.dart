import 'package:flutter/services.dart';
import 'package:super_editor/super_editor.dart' as se;

import '../model/doc_snapshot.dart';
import '../rules/builtin/registration.dart';
import '../rules/engine.dart';
import '../rules/rule.dart';
import '../rules/rule_set.dart';
import 'doc_edit_command.dart';
import 'super_editor_adapter.dart';

/// Connects a document's transform rules to super_editor.
///
/// The rules replace super_editor's built-in markdown reactions, so the
/// editing behavior is whatever the [RuleSet] says. Three kinds of input
/// become [DocInputEvent]s:
///
/// - **Typing** — a reaction ([reaction]) turns each `TextInsertionEvent`
///   into [TextInserted].
/// - **Enter** — a request handler ([requestHandler]) intercepts
///   `InsertNewlineAtCaretRequest` (hardware Enter, the macOS
///   `insertNewline:` selector and the IME newline all end there) and offers
///   [EnterPressed] to the rules.
/// - **Backspace at the start of a text node** — a keyboard action
///   ([backspaceAction], hardware keyboards), the same request handler for
///   the IME's `DeleteUpstreamAtBeginningOfNodeRequest`, and a `deleteBackward:`
///   selector override ([selectorHandlers]) offer [BackspaceAtStart].
///
/// When no rule reacts, the input falls through to super_editor's native
/// behavior, so a rule set without an Enter rule still gets ordinary
/// paragraph splitting.
class DocumentRulesBridge {
  DocumentRulesBridge(RuleSet ruleSet) : _engine = _engineFor(ruleSet);

  TransformEngine _engine;

  /// Whether the bridge reacts at all (false while the document is being
  /// replaced wholesale, for instance).
  bool enabled = true;

  /// Swaps in a new rule set.
  set ruleSet(RuleSet ruleSet) => _engine = _engineFor(ruleSet);

  /// A rule set with no transforms gets [DocumentRules.defaultTransforms].
  static TransformEngine _engineFor(RuleSet ruleSet) => TransformEngine(
    ruleSet.transforms.isEmpty
        ? DocumentRules.defaultTransforms
        : ruleSet.transforms,
  );

  /// The edit the rules want for [event] on [document], validated against
  /// the snapshot, or null when no rule reacts (or a rule proposes an edit
  /// that does not apply).
  DocEdit? editFor(se.Document document, DocInputEvent event) {
    if (!enabled) return null;
    final DocSnapshot snapshot;
    try {
      snapshot = SuperEditorAdapter.toSnapshot(document);
    } catch (_) {
      return null;
    }
    final edit = _engine.handle(snapshot, event);
    if (edit == null) return null;
    try {
      DocEditApplier.apply(snapshot, edit);
    } on StateError {
      return null;
    }
    return edit;
  }

  // -------------------------------------------------------------------------
  // Typing
  // -------------------------------------------------------------------------

  /// Offers every text insertion to the rules.
  late final se.EditReaction reaction = _TextInsertedReaction(this);

  // -------------------------------------------------------------------------
  // Enter and IME backspace
  // -------------------------------------------------------------------------

  /// Put this first in the editor's request handlers.
  se.EditCommand? requestHandler(se.Editor editor, se.EditRequest request) {
    if (request is se.InsertNewlineAtCaretRequest) {
      final caret = _collapsedTextCaret(editor);
      if (caret == null) return null;
      final edit = editFor(
        editor.document,
        EnterPressed(caret.nodeId, caretOffset: caret.offset),
      );
      return edit == null ? null : ApplyDocEditCommand(edit);
    }
    if (request is se.DeleteUpstreamAtBeginningOfNodeRequest &&
        request.node is se.TextNode) {
      final edit = _backspaceEdit(editor);
      return edit == null ? null : ApplyDocEditCommand(edit);
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Hardware backspace
  // -------------------------------------------------------------------------

  /// Keyboard action for Backspace at offset 0 of a text node. Put it at the
  /// front of the editor's keyboard actions.
  se.ExecutionInstruction backspaceAction({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) {
    if (keyEvent is! KeyDownEvent && keyEvent is! KeyRepeatEvent) {
      return se.ExecutionInstruction.continueExecution;
    }
    if (keyEvent.logicalKey != LogicalKeyboardKey.backspace) {
      return se.ExecutionInstruction.continueExecution;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed) {
      return se.ExecutionInstruction.continueExecution;
    }
    final edit = _backspaceEdit(editContext.editor);
    if (edit == null) return se.ExecutionInstruction.continueExecution;
    editContext.editor.execute([ApplyDocEditRequest(edit)]);
    return se.ExecutionInstruction.haltExecution;
  }

  /// super_editor's selector handlers with `deleteBackward:` routed through
  /// the rules first.
  late final Map<String, se.SuperEditorSelectorHandler> selectorHandlers = {
    ...se.defaultEditorSelectorHandlers,
    se.MacOsSelectors.deleteBackward: (se.SuperEditorContext context) {
      final edit = _backspaceEdit(context.editor);
      if (edit != null) {
        context.editor.execute([ApplyDocEditRequest(edit)]);
        return;
      }
      se.defaultEditorSelectorHandlers[se.MacOsSelectors.deleteBackward]?.call(
        context,
      );
    },
  };

  DocEdit? _backspaceEdit(se.Editor editor) {
    final caret = _collapsedTextCaret(editor);
    if (caret == null || caret.offset != 0) return null;
    return editFor(editor.document, BackspaceAtStart(caret.nodeId));
  }

  /// The collapsed caret in a text node, or null.
  static ({String nodeId, int offset})? _collapsedTextCaret(se.Editor editor) {
    final selection = editor.composer.selection;
    if (selection == null || !selection.isCollapsed) return null;
    final position = selection.extent.nodePosition;
    if (position is! se.TextNodePosition) return null;
    if (editor.document.getNodeById(selection.extent.nodeId) is! se.TextNode) {
      return null;
    }
    return (nodeId: selection.extent.nodeId, offset: position.offset);
  }
}

/// Turns `TextInsertionEvent`s into [TextInserted] events for the rules.
class _TextInsertedReaction extends se.EditReaction {
  _TextInsertedReaction(this.bridge);

  final DocumentRulesBridge bridge;

  @override
  void react(
    se.EditContext editorContext,
    se.RequestDispatcher requestDispatcher,
    List<se.EditEvent> changeList,
  ) {
    if (!bridge.enabled) return;
    se.TextInsertionEvent? inserted;
    for (final event in changeList.reversed) {
      if (event is se.DocumentEdit && event.change is se.TextInsertionEvent) {
        inserted = event.change as se.TextInsertionEvent;
        break;
      }
    }
    if (inserted == null) return;
    final text = inserted.text.toPlainText();
    final edit = bridge.editFor(
      editorContext.document,
      TextInserted(
        inserted.nodeId,
        text: text,
        caretOffset: inserted.offset + text.length,
      ),
    );
    if (edit != null) requestDispatcher.execute([ApplyDocEditRequest(edit)]);
  }
}
