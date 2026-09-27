import '../clipboard/doc_clipboard_delegate.dart';
import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import '../model/doc_text.dart';
import '../model/doc_text_ops.dart';
import '../rules/rule.dart';

/// [result] with every node id that already exists in [doc] (or repeats
/// within the paste) replaced by a fresh one, and `fieldValues` re-keyed to
/// match.
///
/// A delegate is required to hand over fresh ids already; this is the
/// editor's own guard, because a duplicate id would make the document
/// invalid.
DocPasteResult rekeyPaste(DocSnapshot doc, DocPasteResult result) {
  final taken = {for (final n in doc.nodes) n.id};
  final renamed = <String, String>{};
  final nodes = <DocNode>[];
  for (final node in result.nodes) {
    if (taken.add(node.id)) {
      nodes.add(node);
      continue;
    }
    final id = newNodeId();
    taken.add(id);
    renamed[node.id] = id;
    nodes.add(_withId(node, id));
  }
  if (renamed.isEmpty) return result;
  return DocPasteResult(
    nodes: nodes,
    fieldValues: {
      for (final e in result.fieldValues.entries)
        renamed[e.key] ?? e.key: e.value,
    },
  );
}

DocNode _withId(DocNode node, String id) => switch (node) {
  ParagraphNode(:final text) => ParagraphNode(id: id, text: text),
  HeadingNode(:final level, :final text) => HeadingNode(
    id: id,
    level: level,
    text: text,
  ),
  ListItemNode(:final ordered, :final indent, :final text) => ListItemNode(
    id: id,
    ordered: ordered,
    indent: indent,
    text: text,
  ),
  TaskNode(:final checked, :final text) => TaskNode(
    id: id,
    checked: checked,
    text: text,
  ),
  QuoteNode(:final text) => QuoteNode(id: id, text: text),
  DividerNode() => DividerNode(id: id),
  EmbeddedFieldNode(:final fieldJson, :final sourceId) => EmbeddedFieldNode(
    id: id,
    fieldJson: fieldJson,
    sourceId: sourceId,
  ),
};

/// Whether a pasted [pasted] node's text may merge into the text node
/// [target] it lands in: a plain paragraph merges into anything (it is just
/// inline text), otherwise only the same kind merges.
bool _mergesInto(DocNode pasted, TextDocNode target) =>
    pasted is ParagraphNode ||
    (pasted is TextDocNode && pasted.runtimeType == target.runtimeType);

TextDocNode _sameKind(TextDocNode node, DocText text) => switch (node) {
  ParagraphNode() => ParagraphNode(id: newNodeId(), text: text),
  HeadingNode(:final level) => HeadingNode(
    id: newNodeId(),
    level: level,
    text: text,
  ),
  ListItemNode(:final ordered, :final indent) => ListItemNode(
    id: newNodeId(),
    ordered: ordered,
    indent: indent,
    text: text,
  ),
  TaskNode() => TaskNode(id: newNodeId(), text: text),
  QuoteNode() => QuoteNode(id: newNodeId(), text: text),
};

/// The edit that inserts [pasted] at a collapsed caret ([nodeId], [offset])
/// of [doc], implementing `DocPasteResult`'s documented semantics:
///
/// **Caret inside a text node N** (split at the caret into *before* and
/// *after*):
/// 1. If the first pasted node is a text node that merges into N (a
///    paragraph, or the same kind as N), its text is appended to *before*
///    and N keeps its kind and id. Otherwise N keeps just *before* — and
///    when *before* is empty N is dropped, so pasting blocks at the start of
///    an empty line does not leave a stray blank line.
/// 2. The remaining pasted nodes are inserted after it, in order.
/// 3. If the last pasted node is a text node, *after* is appended to it
///    (it keeps its own kind). If it is a block, *after* (when non-empty)
///    becomes a new node of N's kind after it.
/// 4. The caret lands at the end of the pasted content: after the last
///    pasted character, or at the start of the text that follows a pasted
///    block (an empty paragraph is added when nothing text-like follows).
///
/// A single mergeable node therefore behaves like inline text:
/// `ab|cd` + "XY" → `abXY|cd`.
///
/// **Caret on a block** (divider / embedded field): the nodes go before it
/// (offset 0, upstream) or after it (offset 1, downstream), unchanged.
///
/// Returns null when [pasted] is empty or the caret node is unknown.
DocEdit? pasteEdit(
  DocSnapshot doc,
  String nodeId,
  int offset,
  List<DocNode> pasted,
) {
  if (pasted.isEmpty) return null;
  final target = doc.nodeById(nodeId);
  if (target == null) return null;
  final ops = <DocEditOp>[];

  DocCaret caretAfterBlock(String anchorId, DocNode? next) {
    if (next is TextDocNode) return DocCaret(next.id, 0);
    final paragraph = ParagraphNode(id: newNodeId());
    ops.add(InsertAfterOp(anchorId, paragraph));
    return DocCaret(paragraph.id, 0);
  }

  final index = doc.indexOf(target.id);
  final following = index + 1 < doc.nodes.length ? doc.nodes[index + 1] : null;

  if (target is! TextDocNode) {
    var anchor = offset == 0 ? doc.nodeBefore(target.id)?.id : target.id;
    for (final node in pasted) {
      ops.add(InsertAfterOp(anchor, node));
      anchor = node.id;
    }
    final last = pasted.last;
    final caret = last is TextDocNode
        ? DocCaret(last.id, last.text.text.length)
        : DocCaret(last.id, 1);
    return DocEdit(ops, caret: caret);
  }

  final text = target.text;
  final at = offset.clamp(0, text.text.length);
  final before = text.slice(0, at);
  final after = text.slice(at);
  final first = pasted.first;

  // Single node that merges: plain inline insertion.
  if (pasted.length == 1 && first is TextDocNode && _mergesInto(first, target)) {
    final merged = before.concat(first.text);
    return DocEdit([
      ReplaceNodeOp(target.id, target.withText(merged.concat(after))),
    ], caret: DocCaret(target.id, merged.text.length));
  }

  // 1. The head.
  final List<DocNode> rest;
  String? anchor;
  var keepTarget = true;
  if (first is TextDocNode && _mergesInto(first, target)) {
    ops.add(
      ReplaceNodeOp(target.id, target.withText(before.concat(first.text))),
    );
    rest = pasted.sublist(1);
    anchor = target.id;
  } else if (before.isEmpty) {
    keepTarget = false;
    rest = pasted;
    anchor = doc.nodeBefore(target.id)?.id;
  } else {
    ops.add(ReplaceNodeOp(target.id, target.withText(before)));
    rest = pasted;
    anchor = target.id;
  }

  // 2. + 3. The middle and the tail.
  DocCaret caret;
  final last = rest.last;
  for (final node in rest) {
    if (identical(node, last) && node is TextDocNode) {
      final merged = node.withText(node.text.concat(after));
      ops.add(InsertAfterOp(anchor, merged));
      anchor = merged.id;
    } else {
      ops.add(InsertAfterOp(anchor, node));
      anchor = node.id;
    }
  }
  if (last is TextDocNode) {
    caret = DocCaret(last.id, last.text.text.length);
  } else if (!after.isEmpty) {
    final tail = _sameKind(target, after);
    ops.add(InsertAfterOp(anchor, tail));
    caret = DocCaret(tail.id, 0);
  } else {
    caret = caretAfterBlock(anchor!, following);
  }

  if (!keepTarget) ops.add(RemoveNodeOp(target.id));
  return DocEdit(ops, caret: caret);
}
