import '../rules/builtin/transforms.dart';
import 'doc_ids.dart';
import 'doc_node.dart';
import 'doc_snapshot.dart';
import 'doc_text.dart';

/// Renders an embedded field as one line of text (plain or markdown).
typedef EmbeddedFieldRenderer = String Function(EmbeddedFieldNode node);

/// The default [EmbeddedFieldRenderer]: `[field: <type>]`.
String defaultEmbeddedFieldText(EmbeddedFieldNode node) =>
    '[field: ${node.fieldType ?? 'unknown'}]';

/// Numbers ordered list items the way a reader expects: a run of ordered
/// items at one indent counts 1, 2, 3…; a deeper item starts its own count;
/// any non-list block ends every run.
final class ListNumbering {
  final Map<int, int> _counters = {};

  /// The marker for [node] (`- `, or `N. ` for an ordered item), updating
  /// the running counts.
  String markerFor(ListItemNode node) {
    _counters.removeWhere((indent, _) => indent > node.indent);
    if (!node.ordered) {
      _counters.remove(node.indent);
      return '- ';
    }
    final n = (_counters[node.indent] ?? 0) + 1;
    _counters[node.indent] = n;
    return '$n. ';
  }

  /// Ends every run (call for any block that is not a list item).
  void reset() => _counters.clear();
}

/// The document as plain text, one line per block, ready for the
/// `text/plain` clipboard format or a plain-text export.
///
/// Headings and paragraphs are their text. List items use `- ` / `N. `
/// markers (indented two spaces per level), tasks `[ ] ` / `[x] `, quotes
/// `> `, dividers `---`, and embedded fields go through [embeddedField]
/// (default [defaultEmbeddedFieldText]). Marks are dropped.
///
/// The list, task, quote and divider markers are the ones
/// [MarkdownPrefixRule] recognizes, so [fromPlainText] restores those
/// blocks; headings come back as paragraphs.
String toPlainText(DocSnapshot doc, {EmbeddedFieldRenderer? embeddedField}) {
  final numbering = ListNumbering();
  final lines = <String>[];
  for (final node in doc.nodes) {
    if (node is! ListItemNode) numbering.reset();
    lines.add(switch (node) {
      ParagraphNode(:final text) || HeadingNode(:final text) => text.text,
      ListItemNode(:final text, :final indent) =>
        '${'  ' * indent}${numbering.markerFor(node)}${text.text}',
      TaskNode(:final text, :final checked) =>
        '${checked ? '[x]' : '[ ]'} ${text.text}',
      QuoteNode(:final text) => '> ${text.text}',
      DividerNode() => '---',
      EmbeddedFieldNode() => (embeddedField ?? defaultEmbeddedFieldText)(node),
    });
  }
  return lines.join('\n');
}

/// Builds a document from plain text, one block per line, running each
/// line through [rule] (default: the built-in [MarkdownPrefixRule]) so
/// `- item`, `# Title`, `[ ] todo`, `> quote` and `---` become structured.
/// This is the last-resort path for a plain-text paste.
///
/// Leading whitespace before a list marker sets the list indent (two
/// spaces or one tab per level, at most 8); on an unconverted line it is
/// kept. `\r\n` and `\r` line endings are accepted, a single trailing line
/// break is ignored, and empty lines become empty paragraphs. An empty
/// string gives an empty document. Every node gets a fresh id.
DocSnapshot fromPlainText(
  String text, {
  MarkdownPrefixRule rule = const MarkdownPrefixRule(),
}) {
  if (text.isEmpty) return DocSnapshot(const []);
  final lines = text.split(RegExp(r'\r\n|\r|\n'));
  if (lines.length > 1 && lines.last.isEmpty) lines.removeLast();

  return DocSnapshot([for (final line in lines) _convert(line, rule)]);
}

DocNode _convert(String line, MarkdownPrefixRule rule) {
  final stripped = line.trimLeft();
  final leading = line.substring(0, line.length - stripped.length);
  final id = newNodeId();
  final converted = rule.convertLine(
    ParagraphNode(id: id, text: DocText(stripped)),
  );
  return switch (converted) {
    ListItemNode(:final ordered, :final text) => ListItemNode(
      id: id,
      ordered: ordered,
      text: text,
      indent: _indent(leading),
    ),
    ParagraphNode() => ParagraphNode(id: id, text: DocText(line)),
    _ => converted,
  };
}

int _indent(String whitespace) {
  var columns = 0;
  for (final c in whitespace.runes) {
    columns += c == 0x09 ? 2 : 1;
  }
  final level = columns ~/ 2;
  return level > 8 ? 8 : level;
}
