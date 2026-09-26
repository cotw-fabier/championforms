import '../../model/doc_ids.dart';
import '../../model/doc_node.dart';
import '../../model/doc_snapshot.dart';
import '../../model/doc_text.dart';
import '../../model/doc_text_ops.dart';
import '../rule.dart';
import 'json_read.dart';

/// The node kind a markdown prefix turns a paragraph into.
enum PrefixKind { listItem, heading, task, quote, divider }

/// What [MarkdownPrefixRule] converts a paragraph into for one prefix.
final class PrefixTarget {
  const PrefixTarget.listItem({this.ordered = false})
    : kind = PrefixKind.listItem,
      level = 1,
      checked = false;
  const PrefixTarget.heading(this.level)
    : assert(level >= 1 && level <= 6),
      kind = PrefixKind.heading,
      ordered = false,
      checked = false;
  const PrefixTarget.task({this.checked = false})
    : kind = PrefixKind.task,
      level = 1,
      ordered = false;
  const PrefixTarget.quote()
    : kind = PrefixKind.quote,
      level = 1,
      ordered = false,
      checked = false;

  /// A divider fires on **Enter** when the paragraph's whole text is the
  /// prefix (e.g. `---`), not while typing.
  const PrefixTarget.divider()
    : kind = PrefixKind.divider,
      level = 1,
      ordered = false,
      checked = false;

  final PrefixKind kind;
  final int level;
  final bool ordered;
  final bool checked;

  /// The converted node, keeping [id].
  DocNode build(String id, DocText text) => switch (kind) {
    PrefixKind.listItem => ListItemNode(id: id, ordered: ordered, text: text),
    PrefixKind.heading => HeadingNode(id: id, level: level, text: text),
    PrefixKind.task => TaskNode(id: id, checked: checked, text: text),
    PrefixKind.quote => QuoteNode(id: id, text: text),
    PrefixKind.divider => DividerNode(id: id),
  };

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (kind == PrefixKind.heading) 'level': level,
    if (kind == PrefixKind.listItem) 'ordered': ordered,
    if (kind == PrefixKind.task) 'checked': checked,
  };

  factory PrefixTarget.fromJson(Map<String, dynamic> json) {
    final kind = PrefixKind.values.asNameMap()[json['kind']];
    return switch (kind) {
      PrefixKind.listItem => PrefixTarget.listItem(
        ordered: readOptional(json, 'ordered', false),
      ),
      PrefixKind.heading => switch (readOptional<int>(json, 'level', 1)) {
        final l when l >= 1 && l <= 6 => PrefixTarget.heading(l),
        final l => throw FormatException('Heading level out of range: $l'),
      },
      PrefixKind.task => PrefixTarget.task(
        checked: readOptional(json, 'checked', false),
      ),
      PrefixKind.quote => const PrefixTarget.quote(),
      PrefixKind.divider => const PrefixTarget.divider(),
      null => throw FormatException('Unknown prefix kind: $json'),
    };
  }

  @override
  bool operator ==(Object other) =>
      other is PrefixTarget &&
      other.kind == kind &&
      other.level == level &&
      other.ordered == ordered &&
      other.checked == checked;

  @override
  int get hashCode => Object.hash(kind, level, ordered, checked);
}

/// Markdown-style shortcuts: typing `- ` at the start of a paragraph makes
/// it a list item, `# ` a heading, `[] ` a task, and so on.
///
/// Fires on [TextInserted] when the paragraph's text starts with a prefix
/// and the caret sits right after it. The paragraph is replaced by the
/// target kind **with the same id**, the prefix is stripped (marks shift
/// left with the text) and the caret goes to offset 0.
///
/// Divider targets (default `---`) fire on [EnterPressed] instead, when the
/// paragraph's whole text is the prefix: the paragraph becomes a divider and
/// a new empty paragraph follows it, holding the caret.
///
/// When several prefixes match, the longest wins. With [numberedLists],
/// any `N. ` prefix (not just `1. `) starts an ordered list item.
final class MarkdownPrefixRule extends TransformRule {
  const MarkdownPrefixRule({
    this.prefixes = defaultPrefixes,
    this.numberedLists = true,
  });

  static const name = 'markdownPrefix';

  static const defaultPrefixes = <String, PrefixTarget>{
    '- ': PrefixTarget.listItem(),
    '* ': PrefixTarget.listItem(),
    '1. ': PrefixTarget.listItem(ordered: true),
    '# ': PrefixTarget.heading(1),
    '## ': PrefixTarget.heading(2),
    '### ': PrefixTarget.heading(3),
    '#### ': PrefixTarget.heading(4),
    '##### ': PrefixTarget.heading(5),
    '###### ': PrefixTarget.heading(6),
    '[] ': PrefixTarget.task(),
    '[ ] ': PrefixTarget.task(),
    '[x] ': PrefixTarget.task(checked: true),
    '[X] ': PrefixTarget.task(checked: true),
    '> ': PrefixTarget.quote(),
    '---': PrefixTarget.divider(),
  };

  static final _numbered = RegExp(r'^\d{1,9}\. ');

  final Map<String, PrefixTarget> prefixes;
  final bool numberedLists;

  @override
  String get ruleName => name;

  /// The longest non-divider prefix [text] starts with, or null.
  ({int length, PrefixTarget target})? matchPrefix(String text) {
    ({int length, PrefixTarget target})? best;
    for (final e in prefixes.entries) {
      if (e.value.kind == PrefixKind.divider || e.key.isEmpty) continue;
      if (text.startsWith(e.key) &&
          (best == null || e.key.length > best.length)) {
        best = (length: e.key.length, target: e.value);
      }
    }
    if (numberedLists) {
      final m = _numbered.firstMatch(text);
      if (m != null && (best == null || m.end > best.length)) {
        best = (
          length: m.end,
          target: const PrefixTarget.listItem(ordered: true),
        );
      }
    }
    return best;
  }

  /// Whether [text] is exactly a divider prefix.
  bool isDividerText(String text) => prefixes.entries.any(
    (e) => e.value.kind == PrefixKind.divider && e.key == text,
  );

  /// Converts a whole line of pasted text: a divider line becomes a
  /// [DividerNode], a prefixed line its target kind (prefix stripped), and
  /// anything else stays [paragraph]. Used by `fromPlainText`.
  DocNode convertLine(ParagraphNode paragraph) {
    final text = paragraph.text.text;
    if (isDividerText(text)) return DividerNode(id: paragraph.id);
    final match = matchPrefix(text);
    if (match == null) return paragraph;
    return match.target.build(paragraph.id, paragraph.text.slice(match.length));
  }

  @override
  DocEdit? apply(DocSnapshot doc, DocInputEvent event) {
    final node = doc.nodeById(event.nodeId);
    if (node is! ParagraphNode) return null;
    final text = node.text.text;
    switch (event) {
      case TextInserted(:final caretOffset):
        final match = matchPrefix(text);
        if (match == null || caretOffset != match.length) return null;
        return DocEdit([
          ReplaceNodeOp(
            node.id,
            match.target.build(node.id, node.text.slice(match.length)),
          ),
        ], caret: DocCaret(node.id, 0));
      case EnterPressed(:final caretOffset):
        if (!isDividerText(text) || caretOffset != text.length) return null;
        final next = ParagraphNode(id: newNodeId());
        return DocEdit([
          ReplaceNodeOp(node.id, DividerNode(id: node.id)),
          InsertAfterOp(node.id, next),
        ], caret: DocCaret(next.id, 0));
      case BackspaceAtStart():
        return null;
    }
  }

  @override
  Map<String, dynamic> toJson() => {
    'prefixes': {for (final e in prefixes.entries) e.key: e.value.toJson()},
    'numberedLists': numberedLists,
  };

  factory MarkdownPrefixRule.fromJson(Map<String, dynamic> json) {
    final raw = readNullable<Map<String, dynamic>>(json, 'prefixes');
    return MarkdownPrefixRule(
      prefixes: raw == null
          ? defaultPrefixes
          : {
              for (final e in raw.entries)
                e.key: PrefixTarget.fromJson(switch (e.value) {
                  final Map m => m.cast<String, dynamic>(),
                  _ => throw FormatException(
                    'Bad prefix target for "${e.key}"',
                  ),
                }),
            },
      numberedLists: readOptional(json, 'numberedLists', true),
    );
  }
}

/// Enter splits the text node at the caret.
///
/// - The text after the caret moves to a new node inserted after. That node
///   is a [ParagraphNode], except that a non-empty list item continues as a
///   list item (same `ordered` / `indent`) and a task continues as an
///   **unchecked** task. A heading or quote split gives a paragraph, so
///   Enter at the end of a heading starts body text.
/// - Enter at offset 0 of a non-empty node inserts an empty node of that
///   continuation kind **before** it and leaves the caret where it was, so a
///   heading keeps its formatting instead of moving its text into a
///   paragraph.
/// - Enter on an **empty** list item or task converts it to a paragraph
///   (Notion's "leave the list" behavior).
///
/// The new node's caret is offset 0. Non-text nodes and out-of-range caret
/// offsets are declined.
final class EnterSplitsRule extends TransformRule {
  const EnterSplitsRule();

  static const name = 'enterSplits';

  @override
  String get ruleName => name;

  @override
  DocEdit? apply(DocSnapshot doc, DocInputEvent event) {
    if (event is! EnterPressed) return null;
    final node = doc.nodeById(event.nodeId);
    if (node is! TextDocNode) return null;
    final caret = event.caretOffset;
    final length = node.text.text.length;
    if (caret < 0 || caret > length) return null;

    final isListLike = node is ListItemNode || node is TaskNode;
    if (isListLike && node.text.isEmpty) {
      return DocEdit([
        ReplaceNodeOp(node.id, ParagraphNode(id: node.id)),
      ], caret: DocCaret(node.id, 0));
    }

    DocNode continuation(DocText text) => switch (node) {
      ListItemNode(:final ordered, :final indent) => ListItemNode(
        id: newNodeId(),
        ordered: ordered,
        indent: indent,
        text: text,
      ),
      TaskNode() => TaskNode(id: newNodeId(), text: text),
      _ => ParagraphNode(id: newNodeId(), text: text),
    };

    if (caret == 0 && length > 0) {
      final before = doc.nodeBefore(node.id);
      return DocEdit([
        InsertAfterOp(before?.id, continuation(DocText.empty)),
      ], caret: DocCaret(node.id, 0));
    }

    final next = continuation(node.text.slice(caret));
    return DocEdit([
      ReplaceNodeOp(node.id, node.withText(node.text.slice(0, caret))),
      InsertAfterOp(node.id, next),
    ], caret: DocCaret(next.id, 0));
  }

  @override
  Map<String, dynamic> toJson() => const {};

  factory EnterSplitsRule.fromJson(Map<String, dynamic> json) =>
      const EnterSplitsRule();
}

/// Backspace with the caret at the start of a text node.
///
/// - On a non-paragraph text node (heading, list item, task, quote) it
///   converts the node to a paragraph, keeping its text and id.
/// - On a paragraph it merges the paragraph into the previous text node;
///   the caret lands at the join.
/// - **Choice:** when the previous node is a block without text (a divider
///   or an embedded field) that block is **removed** and the paragraph is
///   kept. This matches Notion for dividers. For embedded fields it deletes
///   the field (the editor's undo restores it); an editor that prefers
///   "select the block first" can put its own rule ahead of this one.
/// - On the first node of the document it declines.
final class BackspaceMergesRule extends TransformRule {
  const BackspaceMergesRule();

  static const name = 'backspaceMerges';

  @override
  String get ruleName => name;

  @override
  DocEdit? apply(DocSnapshot doc, DocInputEvent event) {
    if (event is! BackspaceAtStart) return null;
    final node = doc.nodeById(event.nodeId);
    if (node is! TextDocNode) return null;

    if (node is! ParagraphNode) {
      return DocEdit([
        ReplaceNodeOp(node.id, ParagraphNode(id: node.id, text: node.text)),
      ], caret: DocCaret(node.id, 0));
    }

    final previous = doc.nodeBefore(node.id);
    switch (previous) {
      case null:
        return null;
      case DividerNode() || EmbeddedFieldNode():
        return DocEdit([
          RemoveNodeOp(previous.id),
        ], caret: DocCaret(node.id, 0));
      case TextDocNode():
        return DocEdit([
          ReplaceNodeOp(
            previous.id,
            previous.withText(previous.text.concat(node.text)),
          ),
          RemoveNodeOp(node.id),
        ], caret: DocCaret(previous.id, previous.text.text.length));
    }
  }

  @override
  Map<String, dynamic> toJson() => const {};

  factory BackspaceMergesRule.fromJson(Map<String, dynamic> json) =>
      const BackspaceMergesRule();
}
