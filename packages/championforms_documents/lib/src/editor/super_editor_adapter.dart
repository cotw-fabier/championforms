import 'package:flutter/services.dart' show TextAffinity;
import 'package:super_editor/super_editor.dart' as se;

import '../clipboard/doc_clipboard_delegate.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import '../model/doc_text.dart';
import 'embedded_block.dart';
import 'unsupported_formatting.dart' show refuseUnsupportedFormatting;

/// Converts between super_editor's mutable document model and the immutable
/// [DocSnapshot] the rest of the package works with.
///
/// The mapping is lossless for everything a [DocSnapshot] can hold:
///
/// | DocNode             | super_editor node                                   |
/// |---------------------|-----------------------------------------------------|
/// | [ParagraphNode]     | `ParagraphNode` (blockType `paragraph`)              |
/// | [HeadingNode]       | `ParagraphNode` (blockType `header1`…`header6`)      |
/// | [QuoteNode]         | `ParagraphNode` (blockType `blockquote`)             |
/// | [ListItemNode]      | `ListItemNode` (ordered/unordered, indent)           |
/// | [TaskNode]          | `TaskNode` (isComplete)                              |
/// | [DividerNode]       | `HorizontalRuleNode`                                 |
/// | [EmbeddedFieldNode] | [EmbeddedFieldBlock]                                 |
///
/// Node ids are preserved in both directions. Marks convert between
/// [DocMark]'s exclusive `end` and attributed_text's inclusive span end.
///
/// Things super_editor can hold that a snapshot cannot (task and paragraph
/// indentation, paragraph alignment, images, code blocks, composing/spelling
/// attributions) are dropped or degrade to a paragraph when converting
/// editor → snapshot. The `DocumentEditor` never lets a user create the
/// indentation or alignment ([refuseUnsupportedFormatting]), so nothing
/// visible is lost. Empty marks (`start == end`) cannot be represented in
/// attributed text and are dropped snapshot → editor; they cover no text,
/// so they have no visible effect.
///
/// A node that has not been edited converts back to the very [DocNode] it
/// was made from. Marks read from edited editor text come back in a
/// canonical order (start, end, type, href).
abstract final class SuperEditorAdapter {
  /// Editor → snapshot conversions are cached per (immutable) editor node,
  /// so converting a large document on every keystroke only converts the
  /// nodes that actually changed.
  static final Expando<DocNode> _cache = Expando('docNodeCache');

  // -------------------------------------------------------------------------
  // Documents
  // -------------------------------------------------------------------------

  /// A fresh [se.MutableDocument] holding [snapshot]'s nodes (ids preserved).
  static se.MutableDocument toMutableDocument(DocSnapshot snapshot) =>
      se.MutableDocument(
        nodes: [for (final n in snapshot.nodes) toEditorNode(n)],
      );

  /// The current content of [document] as a snapshot.
  ///
  /// Editor nodes with no snapshot equivalent (images, for instance) are
  /// skipped. A document that would convert to zero nodes still yields zero
  /// nodes; callers that need a caret target add a paragraph themselves.
  static DocSnapshot toSnapshot(se.Document document) {
    final nodes = <DocNode>[];
    for (final node in document) {
      final converted = toDocNode(node);
      if (converted != null) nodes.add(converted);
    }
    return DocSnapshot(nodes);
  }

  // -------------------------------------------------------------------------
  // Nodes
  // -------------------------------------------------------------------------

  /// The super_editor node for [node].
  static se.DocumentNode toEditorNode(DocNode node) {
    final se.DocumentNode result = switch (node) {
      ParagraphNode(:final id, :final text) => se.ParagraphNode(
        id: id,
        text: toAttributedText(text),
      ),
      HeadingNode(:final id, :final level, :final text) => se.ParagraphNode(
        id: id,
        text: toAttributedText(text),
        metadata: {se.NodeMetadata.blockType: _headerAttribution(level)},
      ),
      QuoteNode(:final id, :final text) => se.ParagraphNode(
        id: id,
        text: toAttributedText(text),
        metadata: {se.NodeMetadata.blockType: se.blockquoteAttribution},
      ),
      ListItemNode(:final id, :final ordered, :final indent, :final text) =>
        se.ListItemNode(
          id: id,
          itemType: ordered
              ? se.ListItemType.ordered
              : se.ListItemType.unordered,
          indent: indent,
          text: toAttributedText(text),
        ),
      TaskNode(:final id, :final checked, :final text) => se.TaskNode(
        id: id,
        text: toAttributedText(text),
        isComplete: checked,
      ),
      DividerNode(:final id) => se.HorizontalRuleNode(id: id),
      EmbeddedFieldNode() => EmbeddedFieldBlock.fromDocNode(node),
    };
    _cache[result] = node;
    return result;
  }

  /// The [DocNode] for an editor node, or null for a node kind a snapshot
  /// cannot hold.
  static DocNode? toDocNode(se.DocumentNode node) {
    final cached = _cache[node];
    if (cached != null) return cached;
    final converted = _convert(node);
    if (converted != null) _cache[node] = converted;
    return converted;
  }

  static DocNode? _convert(se.DocumentNode node) {
    switch (node) {
      case se.TaskNode():
        return TaskNode(
          id: node.id,
          checked: node.isComplete,
          text: toDocText(node.text),
        );
      case se.ListItemNode():
        return ListItemNode(
          id: node.id,
          ordered: node.type == se.ListItemType.ordered,
          indent: node.indent.clamp(0, 8),
          text: toDocText(node.text),
        );
      case se.ParagraphNode():
        final text = toDocText(node.text);
        final blockType = node.metadata[se.NodeMetadata.blockType];
        final id = blockType is se.NamedAttribution ? blockType.id : null;
        final heading = id == null ? null : _headerPattern.firstMatch(id);
        if (heading != null) {
          return HeadingNode(
            id: node.id,
            level: int.parse(heading.group(1)!),
            text: text,
          );
        }
        if (blockType == se.blockquoteAttribution) {
          return QuoteNode(id: node.id, text: text);
        }
        return ParagraphNode(id: node.id, text: text);
      case se.TextNode():
        return ParagraphNode(id: node.id, text: toDocText(node.text));
      case se.HorizontalRuleNode():
        return DividerNode(id: node.id);
      case EmbeddedFieldBlock():
        return node.toDocNode();
      default:
        return null;
    }
  }

  static final _headerPattern = RegExp(r'^header([1-6])$');

  static se.NamedAttribution _headerAttribution(int level) => switch (level) {
    1 => se.header1Attribution,
    2 => se.header2Attribution,
    3 => se.header3Attribution,
    4 => se.header4Attribution,
    5 => se.header5Attribution,
    _ => se.header6Attribution,
  };

  // -------------------------------------------------------------------------
  // Text and marks
  // -------------------------------------------------------------------------

  /// [text] as attributed text. Empty marks are dropped; marks are clamped
  /// to the text.
  static se.AttributedText toAttributedText(DocText text) {
    final result = se.AttributedText(text.text);
    final length = text.text.length;
    for (final mark in text.marks) {
      final start = mark.start.clamp(0, length);
      final end = mark.end.clamp(0, length);
      if (end <= start) continue;
      final attribution = _attributionFor(mark);
      if (attribution == null) continue;
      try {
        result.addAttribution(
          attribution,
          se.SpanRange(start, end - 1),
          overwriteConflictingSpans: true,
        );
      } catch (_) {
        // A mark attributed_text refuses (a conflicting overlap it cannot
        // resolve) is dropped rather than breaking the whole document.
      }
    }
    return result;
  }

  /// The [DocText] for attributed [text]: its plain text plus every mark
  /// attribution, in canonical order. Attributions that are not marks
  /// (composing tags, spelling errors) are ignored.
  static DocText toDocText(se.AttributedText text) {
    final plain = text.toPlainText();
    if (plain.isEmpty) return DocText(plain);
    final marks = <DocMark>[];
    final spans = text.getAttributionSpansInRange(
      attributionFilter: (_) => true,
      range: se.SpanRange(0, plain.length - 1),
    );
    for (final span in spans) {
      final a = span.attribution;
      final end = span.end + 1;
      if (a is se.LinkAttribution) {
        marks.add(
          DocMark(
            type: DocMarkType.link,
            start: span.start,
            end: end,
            href: a.plainTextUri,
          ),
        );
        continue;
      }
      final type = _markTypeFor(a);
      if (type != null) {
        marks.add(DocMark(type: type, start: span.start, end: end));
      }
    }
    marks.sort(compareMarks);
    return DocText(plain, marks);
  }

  /// The canonical mark order: start, end, type, href.
  static int compareMarks(DocMark a, DocMark b) {
    if (a.start != b.start) return a.start - b.start;
    if (a.end != b.end) return a.end - b.end;
    if (a.type != b.type) return a.type.index - b.type.index;
    return (a.href ?? '').compareTo(b.href ?? '');
  }

  static se.Attribution? _attributionFor(DocMark mark) => switch (mark.type) {
    DocMarkType.bold => se.boldAttribution,
    DocMarkType.italic => se.italicsAttribution,
    DocMarkType.underline => se.underlineAttribution,
    DocMarkType.strikethrough => se.strikethroughAttribution,
    DocMarkType.code => se.codeAttribution,
    DocMarkType.link =>
      mark.href == null ? null : se.LinkAttribution(mark.href!),
  };

  static DocMarkType? _markTypeFor(se.Attribution a) {
    if (a == se.boldAttribution) return DocMarkType.bold;
    if (a == se.italicsAttribution) return DocMarkType.italic;
    if (a == se.underlineAttribution) return DocMarkType.underline;
    if (a == se.strikethroughAttribution) return DocMarkType.strikethrough;
    if (a == se.codeAttribution) return DocMarkType.code;
    return null;
  }

  // -------------------------------------------------------------------------
  // Positions and selections
  // -------------------------------------------------------------------------

  /// A [DocSelection] for an editor [selection], normalized so start comes
  /// first. Block positions map to 0 (upstream) / 1 (downstream).
  static DocSelection toDocSelection(
    se.Document document,
    se.DocumentSelection selection,
  ) {
    final range = selection.normalize(document);
    return DocSelection(
      startNodeId: range.start.nodeId,
      startOffset: offsetOf(range.start.nodePosition),
      endNodeId: range.end.nodeId,
      endOffset: offsetOf(range.end.nodePosition),
    );
  }

  /// The editor selection for [selection]. [document] decides whether each
  /// end is a text or a block position.
  static se.DocumentSelection toEditorSelection(
    se.Document document,
    DocSelection selection,
  ) => se.DocumentSelection(
    base: toEditorPosition(
      document,
      selection.startNodeId,
      selection.startOffset,
    ),
    extent: toEditorPosition(
      document,
      selection.endNodeId,
      selection.endOffset,
    ),
  );

  /// The editor position at [offset] in node [nodeId]: a text offset for a
  /// text node, upstream (0) / downstream (anything else) for a block.
  static se.DocumentPosition toEditorPosition(
    se.Document document,
    String nodeId,
    int offset,
  ) {
    final node = document.getNodeById(nodeId);
    final se.NodePosition position = node is se.TextNode
        ? se.TextNodePosition(offset: offset.clamp(0, node.text.length))
        : (offset == 0
              ? const se.UpstreamDownstreamNodePosition.upstream()
              : const se.UpstreamDownstreamNodePosition.downstream());
    return se.DocumentPosition(nodeId: nodeId, nodePosition: position);
  }

  /// The snapshot offset of an editor node position.
  static int offsetOf(se.NodePosition position) => switch (position) {
    se.TextNodePosition(:final offset) => offset,
    se.UpstreamDownstreamNodePosition(:final affinity) =>
      affinity == TextAffinity.upstream ? 0 : 1,
    _ => 0,
  };
}
