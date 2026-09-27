import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:follow_the_leader/follow_the_leader.dart';
import 'package:super_editor/super_editor.dart' as se;

import 'package:championforms_clipboard/championforms_clipboard.dart'
    show ClipboardFormat, ClipboardItem;

import '../clipboard/champion_doc_clipboard.dart';
import '../clipboard/doc_clipboard_delegate.dart';
import 'doc_edit_command.dart';
import 'paste_insertion.dart';
import 'super_editor_adapter.dart';
import 'web/clipboard_events.dart';

/// Routes every copy / cut / paste entry point of the editor to a
/// [DocClipboardDelegate]:
///
/// - cmd/ctrl+C/X/V: [patch] swaps super_editor's `copyWhenCmdCIsPressed`,
///   `cutWhenCmdXIsPressed` and `pasteWhenCmdVIsPressed` in the IME keyboard
///   action list for ours;
/// - the iOS and Android selection toolbars ([iosToolbar],
///   [androidToolbar], installed through `SuperEditorIosControlsScope` /
///   `SuperEditorAndroidControlsScope` controllers);
/// - the desktop right-click menu (built by the editor, calling [copy],
///   [cut] and [paste]);
/// - on the web, browser `copy` / `cut` / `paste` events
///   ([handleBrowserEvent]); the keyboard shortcuts deliberately fall
///   through there so the browser raises them.
///
/// The delegate owns what goes on and comes off the clipboard; this class
/// owns the document side: which [DocSelection] is copied, deleting the
/// selection for a cut, and inserting a [DocPasteResult].
class DocumentClipboardActions {
  DocumentClipboardActions({
    required this.delegate,
    required this.docId,
    required this.editorOf,
    required this.restoreFieldValues,
  });

  final DocClipboardDelegate delegate;
  final String docId;

  /// The current editor (the editor is recreated when the document is
  /// replaced from outside).
  final se.Editor Function() editorOf;

  /// Restores `DocPasteResult.fieldValues` once the pasted blocks are
  /// registered.
  final void Function(Map<String, Object?> fieldValues) restoreFieldValues;

  se.Editor get _editor => editorOf();

  /// The current selection as a [DocSelection], or null when there is none
  /// or it is collapsed.
  DocSelection? expandedSelection() {
    final selection = _editor.composer.selection;
    if (selection == null || selection.isCollapsed) return null;
    return SuperEditorAdapter.toDocSelection(_editor.document, selection);
  }

  /// Copies the selection. Does nothing for a collapsed selection.
  Future<void> copy() async {
    final selection = expandedSelection();
    if (selection == null) return;
    await delegate.copy(
      docId: docId,
      doc: SuperEditorAdapter.toSnapshot(_editor.document),
      selection: selection,
    );
  }

  /// Copies the selection, then deletes it. The delegate receives the
  /// document as it was before the delete (snapshots are immutable), and
  /// the delete happens immediately so the editor never shows stale
  /// content. Deleted embedded blocks are unregistered by the field's
  /// document listener.
  Future<void> cut() async {
    final editor = _editor;
    final range = editor.composer.selection;
    final selection = expandedSelection();
    if (range == null || selection == null) return;
    final copied = delegate.copy(
      docId: docId,
      doc: SuperEditorAdapter.toSnapshot(editor.document),
      selection: selection,
    );
    editor.execute([
      se.DeleteContentRequest(documentRange: range),
      se.ChangeSelectionRequest(
        se.DocumentSelection.collapsed(position: range.normalize(editor.document).start),
        se.SelectionChangeType.deleteContent,
        se.SelectionReason.userInteraction,
      ),
    ]);
    await copied;
  }

  /// Asks the delegate for content and inserts it at the caret (replacing
  /// an expanded selection), then restores the pasted field values.
  Future<void> paste() async {
    final DocPasteResult? result;
    try {
      result = await delegate.paste(
        docId: docId,
        doc: SuperEditorAdapter.toSnapshot(_editor.document),
      );
    } catch (e) {
      debugPrint('Document paste failed: $e');
      return;
    }
    if (result == null || result.nodes.isEmpty) return;
    insertPasteResult(result);
  }

  /// Inserts [result] at the caret (see [pasteEdit] for the semantics) and
  /// restores its field values.
  void insertPasteResult(DocPasteResult result) {
    final editor = _editor;
    final selection = editor.composer.selection;
    if (selection != null && !selection.isCollapsed) {
      final start = selection.normalize(editor.document).start;
      editor.execute([
        se.DeleteContentRequest(documentRange: selection),
        se.ChangeSelectionRequest(
          se.DocumentSelection.collapsed(position: start),
          se.SelectionChangeType.deleteContent,
          se.SelectionReason.userInteraction,
        ),
      ]);
    }

    final doc = SuperEditorAdapter.toSnapshot(editor.document);
    final rekeyed = rekeyPaste(doc, result);
    final caret = editor.composer.selection?.extent;
    final String nodeId;
    final int offset;
    if (caret != null && doc.nodeById(caret.nodeId) != null) {
      nodeId = caret.nodeId;
      offset = SuperEditorAdapter.offsetOf(caret.nodePosition);
    } else {
      // No caret: paste at the end of the document.
      final last = editor.document.last;
      nodeId = last.id;
      offset = SuperEditorAdapter.offsetOf(last.endPosition);
    }
    final edit = pasteEdit(doc, nodeId, offset, rekeyed.nodes);
    if (edit == null) return;
    editor.execute([ApplyDocEditRequest(edit)]);
    if (rekeyed.fieldValues.isNotEmpty) {
      restoreFieldValues(rekeyed.fieldValues);
    }
  }

  /// Handles a browser clipboard event on the web.
  ///
  /// With [ChampionDocClipboard] the event's own `clipboardData` is used:
  /// a copy/cut writes `encodeSelection`'s HTML (payload embedded) and plain
  /// text into the event, and a paste reads the event's formats through
  /// `pasteFromRead` — no permission prompt, no async clipboard API. Any
  /// other delegate is called synchronously inside [DocClipboardEvents.run]
  /// so it can use the event itself.
  void handleBrowserEvent(BrowserClipboardAction action, Object event) {
    final d = delegate;
    if (d is ChampionDocClipboard) {
      _handleBrowserEventWith(d, action, event);
      return;
    }
    DocClipboardEvents.run(event, () {
      switch (action) {
        case BrowserClipboardAction.copy:
          copy();
        case BrowserClipboardAction.cut:
          cut();
        case BrowserClipboardAction.paste:
          paste();
      }
    });
  }

  void _handleBrowserEventWith(
    ChampionDocClipboard d,
    BrowserClipboardAction action,
    Object event,
  ) {
    final editor = _editor;
    if (action == BrowserClipboardAction.paste) {
      final read = readBrowserPasteEvent(event);
      if (read == null) return;
      final result = d.pasteFromRead(read, docId: docId);
      if (result != null && result.nodes.isNotEmpty) insertPasteResult(result);
      return;
    }
    final range = editor.composer.selection;
    final selection = expandedSelection();
    if (range == null || selection == null) return;
    final data = d.encodeSelection(
      docId: docId,
      doc: SuperEditorAdapter.toSnapshot(editor.document),
      selection: selection,
    );
    if (data != null) {
      writeBrowserCopyEvent(
        event,
        ClipboardItem({
          ClipboardFormat.html: data.html,
          ClipboardFormat.plainText: data.plainText,
        }),
      );
    }
    if (action == BrowserClipboardAction.cut) {
      editor.execute([
        se.DeleteContentRequest(documentRange: range),
        se.ChangeSelectionRequest(
          se.DocumentSelection.collapsed(
            position: range.normalize(editor.document).start,
          ),
          se.SelectionChangeType.deleteContent,
          se.SelectionReason.userInteraction,
        ),
      ]);
    }
  }

  // -------------------------------------------------------------------------
  // Keyboard
  // -------------------------------------------------------------------------

  se.ExecutionInstruction _shortcut(
    KeyEvent event,
    LogicalKeyboardKey key,
    VoidCallback run,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return se.ExecutionInstruction.continueExecution;
    }
    if (!event.isPrimaryShortcutKeyPressed || event.logicalKey != key) {
      return se.ExecutionInstruction.continueExecution;
    }
    if (_editor.composer.selection == null) {
      return se.ExecutionInstruction.continueExecution;
    }
    if (kIsWeb) {
      // Let the browser raise its clipboard event; the editor's browser
      // listener handles it (see handleBrowserEvent).
      return se.ExecutionInstruction.continueExecution;
    }
    run();
    return se.ExecutionInstruction.haltExecution;
  }

  se.ExecutionInstruction copyAction({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) => _shortcut(keyEvent, LogicalKeyboardKey.keyC, copy);

  se.ExecutionInstruction cutAction({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) => _shortcut(keyEvent, LogicalKeyboardKey.keyX, cut);

  se.ExecutionInstruction pasteAction({
    required se.SuperEditorContext editContext,
    required KeyEvent keyEvent,
  }) => _shortcut(keyEvent, LogicalKeyboardKey.keyV, paste);

  /// [defaults] with super_editor's clipboard shortcuts replaced by ours.
  List<se.SuperEditorKeyboardAction> patch(
    List<se.SuperEditorKeyboardAction> defaults,
  ) => [
    for (final action in defaults)
      if (action == se.copyWhenCmdCIsPressed)
        copyAction
      else if (action == se.cutWhenCmdXIsPressed)
        cutAction
      else if (action == se.pasteWhenCmdVIsPressed)
        pasteAction
      else
        action,
  ];

  // -------------------------------------------------------------------------
  // Mobile toolbars
  // -------------------------------------------------------------------------

  Widget iosToolbar(
    BuildContext context,
    Key toolbarKey,
    LeaderLink focalPoint,
  ) => se.IOSTextEditingFloatingToolbar(
    floatingToolbarKey: toolbarKey,
    focalPoint: focalPoint,
    onCopyPressed: copy,
    onCutPressed: cut,
    onPastePressed: paste,
  );

  Widget androidToolbar(
    BuildContext context,
    Key toolbarKey,
    LeaderLink focalPoint,
  ) => se.AndroidTextEditingFloatingToolbar(
    floatingToolbarKey: toolbarKey,
    focalPoint: focalPoint,
    onCopyPressed: copy,
    onCutPressed: cut,
    onPastePressed: paste,
  );
}
