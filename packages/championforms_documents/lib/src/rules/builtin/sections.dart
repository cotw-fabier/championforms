import '../../model/doc_node.dart';
import '../../model/doc_snapshot.dart';

/// A heading and the nodes under it.
final class DocSection {
  const DocSection(this.heading, this.body);

  final HeadingNode heading;

  /// Nodes after [heading] up to (not including) the next heading of the
  /// same or a higher level (a smaller or equal `level` number). Deeper
  /// sub-headings are part of the body.
  final List<DocNode> body;

  /// The text nodes of [body], sub-headings included.
  Iterable<TextDocNode> get textNodes => body.whereType<TextDocNode>();

  /// The body's text, one line per text node, trimmed.
  String get text => textNodes.map((n) => n.text.text).join('\n').trim();
}

/// The first section whose heading text equals [title], compared trimmed
/// and case-insensitively; null when there is none.
DocSection? findSection(DocSnapshot doc, String title) {
  final wanted = title.trim().toLowerCase();
  final nodes = doc.nodes;
  for (var i = 0; i < nodes.length; i++) {
    final n = nodes[i];
    if (n is! HeadingNode || n.text.text.trim().toLowerCase() != wanted) {
      continue;
    }
    final body = <DocNode>[];
    for (var j = i + 1; j < nodes.length; j++) {
      final b = nodes[j];
      if (b is HeadingNode && b.level <= n.level) break;
      body.add(b);
    }
    return DocSection(n, body);
  }
  return null;
}
