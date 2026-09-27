import 'package:flutter/widgets.dart';
import 'package:super_editor/super_editor.dart' as se;

/// The deepest list indentation a `ListItemNode` can hold.
const maxListIndent = 8;

/// super_editor formatting that a `DocSnapshot` has no place for: task
/// indentation, paragraph indentation and paragraph alignment (and list
/// indentation past [maxListIndent]).
///
/// If the editor showed any of it, the effect would silently vanish on the
/// next save and reload. So it is refused at the source, whatever asks for
/// it (a keyboard shortcut, the IME, code): this request handler runs
/// first and turns those requests into no-ops. The Tab shortcuts that
/// would ask are also left out of the editor's keyboard actions
/// ([isUnsupportedFormattingShortcut]), so Tab on a task or paragraph moves
/// focus instead of being swallowed.
se.EditCommand? refuseUnsupportedFormatting(
  se.Editor editor,
  se.EditRequest request,
) {
  final refuse = switch (request) {
    se.IndentTaskRequest() => true,
    se.SetTaskIndentRequest(:final indent) => indent > 0,
    se.IndentParagraphRequest() => true,
    se.SetParagraphIndentRequest(:final level) => level > 0,
    se.ChangeParagraphAlignmentRequest(:final alignment) =>
      alignment != TextAlign.left && alignment != TextAlign.start,
    se.IndentListItemRequest(:final nodeId) => switch (editor.document
        .getNodeById(nodeId)) {
      final se.ListItemNode node => node.indent >= maxListIndent,
      _ => false,
    },
    _ => false,
  };
  return refuse ? const _RefusedFormatting() : null;
}

/// Whether [action] is one of super_editor's Tab / Shift+Tab shortcuts for
/// task or paragraph indentation (see [refuseUnsupportedFormatting]).
bool isUnsupportedFormattingShortcut(se.SuperEditorKeyboardAction action) =>
    identical(action, se.tabToIndentTask) ||
    identical(action, se.shiftTabToUnIndentTask) ||
    identical(action, se.tabToIndentParagraph) ||
    identical(action, se.shiftTabToUnIndentParagraph);

class _RefusedFormatting extends se.EditCommand {
  const _RefusedFormatting();

  @override
  se.HistoryBehavior get historyBehavior => se.HistoryBehavior.nonHistorical;

  @override
  void execute(se.EditContext context, se.CommandExecutor executor) {}
}
