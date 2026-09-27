import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import 'doc_clipboard_delegate.dart';

/// The nodes of [doc] covered by [selection], trimmed to it.
///
/// - Nodes strictly between the start and end nodes are included whole.
/// - A text node at an edge contributes only its selected text
///   (`DocText.slice`, marks clipped). Offsets are clamped to the text.
/// - A block node (divider, embedded field) at an edge is included only when
///   the selection covers it: offset 0 is before the block, 1 after it, so a
///   start edge needs offset 0 and an end edge needs offset 1.
/// - A text edge that contributes nothing because the selection only touches
///   it (starts at its very end, or ends at its very start) is dropped when
///   the selection spans several nodes, so "end of A → start of C" copies
///   just B.
///
/// Sliced nodes keep their ids (the paste side always assigns fresh ones). A
/// collapsed selection, unknown node ids or a start after the end give an
/// empty list.
List<DocNode> sliceSelection(DocSnapshot doc, DocSelection selection) {
  if (selection.isCollapsed) return const [];
  final startIndex = doc.indexOf(selection.startNodeId);
  final endIndex = doc.indexOf(selection.endNodeId);
  if (startIndex < 0 || endIndex < 0 || startIndex > endIndex) {
    return const [];
  }

  final single = startIndex == endIndex;
  final result = <DocNode>[];
  for (var i = startIndex; i <= endIndex; i++) {
    final node = doc.nodes[i];
    final isStart = i == startIndex;
    final isEnd = i == endIndex;
    if (!isStart && !isEnd) {
      result.add(node);
      continue;
    }
    switch (node) {
      case TextDocNode(:final text):
        final length = text.text.length;
        final from = isStart ? selection.startOffset.clamp(0, length) : 0;
        final to = isEnd ? selection.endOffset.clamp(0, length) : length;
        if (from > to) continue;
        if (!single && from == to && (isStart ? from == length : to == 0)) {
          // Only touched at its boundary.
          continue;
        }
        result.add(
          from == 0 && to == length
              ? node
              : node.withText(text.slice(from, to)),
        );
      case DividerNode() || EmbeddedFieldNode():
        final coveredFromStart = !isStart || selection.startOffset <= 0;
        final coveredToEnd = !isEnd || selection.endOffset >= 1;
        if (coveredFromStart && coveredToEnd) result.add(node);
    }
  }
  return result;
}
