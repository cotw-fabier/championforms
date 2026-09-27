import 'package:super_editor/super_editor.dart' as se;

import '../rules/rule.dart';
import 'super_editor_adapter.dart';

/// Asks the editor to apply a [DocEdit] (a list of snapshot-level ops plus an
/// optional caret) to its `MutableDocument` as one undoable step.
///
/// Every structural change the package makes — transform rules, slash-menu
/// insertions, pastes — goes through this request, so they all share one
/// well-tested path from the pure snapshot world into super_editor.
class ApplyDocEditRequest implements se.EditRequest {
  const ApplyDocEditRequest(this.edit);

  final DocEdit edit;
}

/// Request handler for [ApplyDocEditRequest]. Add it to the editor's
/// `requestHandlers`.
se.EditCommand? applyDocEditRequestHandler(
  se.Editor editor,
  se.EditRequest request,
) => request is ApplyDocEditRequest ? ApplyDocEditCommand(request.edit) : null;

/// Applies [edit] to the document in the edit context.
///
/// Ops are applied in order. An op that names a node that is not there is
/// skipped (the edit was computed against a snapshot of this document, so
/// that only happens if something else changed it in between).
class ApplyDocEditCommand extends se.EditCommand {
  const ApplyDocEditCommand(this.edit);

  final DocEdit edit;

  @override
  se.HistoryBehavior get historyBehavior => se.HistoryBehavior.undoable;

  @override
  void execute(se.EditContext context, se.CommandExecutor executor) {
    final document = context.document;
    final composer = context.find<se.MutableDocumentComposer>(
      se.Editor.composerKey,
    );
    final changes = <se.EditEvent>[];
    // Index of the last removed node, to re-home a caret that pointed at it.
    int? removedIndex;

    for (final op in edit.ops) {
      switch (op) {
        case ReplaceNodeOp(:final nodeId, :final replacement):
          final old = document.getNodeById(nodeId);
          if (old == null) continue;
          final node = SuperEditorAdapter.toEditorNode(replacement);
          document.replaceNodeById(nodeId, node);
          changes
            ..add(se.DocumentEdit(se.NodeRemovedEvent(nodeId, old)))
            ..add(
              se.DocumentEdit(
                se.NodeInsertedEvent(
                  node.id,
                  document.getNodeIndexById(node.id),
                ),
              ),
            );
        case InsertAfterOp(:final afterNodeId, :final node):
          if (document.getNodeById(node.id) != null) continue;
          final editorNode = SuperEditorAdapter.toEditorNode(node);
          if (afterNodeId == null) {
            document.insertNodeAt(0, editorNode);
          } else {
            if (document.getNodeById(afterNodeId) == null) continue;
            document.insertNodeAfter(
              existingNodeId: afterNodeId,
              newNode: editorNode,
            );
          }
          changes.add(
            se.DocumentEdit(
              se.NodeInsertedEvent(
                editorNode.id,
                document.getNodeIndexById(editorNode.id),
              ),
            ),
          );
        case RemoveNodeOp(:final nodeId):
          final old = document.getNodeById(nodeId);
          if (old == null) continue;
          removedIndex = document.getNodeIndexById(nodeId);
          document.deleteNode(nodeId);
          changes.add(se.DocumentEdit(se.NodeRemovedEvent(nodeId, old)));
      }
    }

    if (document.isEmpty) {
      // super_editor needs somewhere to put the caret.
      final paragraph = se.ParagraphNode(
        id: se.Editor.createNodeId(),
        text: se.AttributedText(),
      );
      document.add(paragraph);
      changes.add(se.DocumentEdit(se.NodeInsertedEvent(paragraph.id, 0)));
    }

    executor.logChanges(changes);

    se.DocumentSelection? selection;
    final caret = edit.caret;
    if (caret != null && document.getNodeById(caret.nodeId) != null) {
      selection = se.DocumentSelection.collapsed(
        position: SuperEditorAdapter.toEditorPosition(
          document,
          caret.nodeId,
          caret.offset,
        ),
      );
    } else {
      final current = composer.selection;
      final dangling =
          current != null &&
          (document.getNodeById(current.base.nodeId) == null ||
              document.getNodeById(current.extent.nodeId) == null);
      if (dangling) {
        // The caret's node is gone: put it where that node used to be.
        final index = (removedIndex ?? 0).clamp(0, document.nodeCount - 1);
        final node = document.getNodeAt(index)!;
        selection = se.DocumentSelection.collapsed(
          position: se.DocumentPosition(
            nodeId: node.id,
            nodePosition: node.beginningPosition,
          ),
        );
      }
    }

    if (selection != null) {
      executor.executeCommand(
        se.ChangeSelectionCommand(
          selection,
          se.SelectionChangeType.placeCaret,
          se.SelectionReason.contentChange,
        ),
      );
    }
  }
}
