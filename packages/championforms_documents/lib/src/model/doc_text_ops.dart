import 'doc_node.dart';
import 'doc_snapshot.dart';
import 'doc_text.dart';

/// Helpers for combining [DocText] values.
///
/// Offsets everywhere are UTF-16 code units, matching Dart `String` indices
/// and super_editor's text positions.
extension DocTextOps on DocText {
  /// Marks moved by [delta] code units (clamped at 0).
  List<DocMark> shiftedMarks(int delta) => [
    for (final m in marks)
      DocMark(
        type: m.type,
        start: m.start + delta < 0 ? 0 : m.start + delta,
        end: m.end + delta < 0 ? 0 : m.end + delta,
        href: m.href,
      ),
  ];

  /// This text followed by [other], with [other]'s marks re-based.
  DocText concat(DocText other) => DocText(text + other.text, [
    ...marks,
    ...other.shiftedMarks(text.length),
  ]);
}

/// Read helpers over a snapshot's content.
extension DocSnapshotText on DocSnapshot {
  /// Every text-bearing node, in document order.
  Iterable<TextDocNode> get textNodes => nodes.whereType<TextDocNode>();

  /// The node before [id], or null for the first node (or an unknown id).
  DocNode? nodeBefore(String id) {
    final i = indexOf(id);
    return i > 0 ? nodes[i - 1] : null;
  }
}
