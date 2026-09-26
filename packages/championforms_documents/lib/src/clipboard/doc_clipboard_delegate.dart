import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';

/// A selection expressed on a [DocSnapshot] (not on super_editor types).
///
/// `start` is always before or equal to `end` in document order. Offsets are
/// text offsets for text nodes; for block nodes (divider, embedded field)
/// offset 0 is "before" the block and 1 is "after" it, matching the upstream
/// and downstream positions in super_editor.
final class DocSelection {
  const DocSelection({
    required this.startNodeId,
    required this.startOffset,
    required this.endNodeId,
    required this.endOffset,
  });

  final String startNodeId;
  final int startOffset;
  final String endNodeId;
  final int endOffset;

  bool get isCollapsed => startNodeId == endNodeId && startOffset == endOffset;
}

/// Where and what to insert after a paste.
///
/// [nodes] are inserted at the caret. When the caret is inside a text node
/// the editor splits it: the first pasted node's text merges into the text
/// before the caret when both are text nodes of a compatible kind, and the
/// last one merges with the text after it. All other nodes are inserted
/// between the two halves. Every pasted node already has a fresh id.
///
/// [fieldValues] maps an inserted `EmbeddedFieldNode.id` to the value to
/// restore into its controller field once it is registered (the value shape
/// is whatever that field type's `FieldClipboardCodec.paste` returns; the
/// editor restores it with the codec-documented controller call).
final class DocPasteResult {
  const DocPasteResult({required this.nodes, this.fieldValues = const {}});

  final List<DocNode> nodes;
  final Map<String, Object?> fieldValues;
}

/// Everything the editor needs from the clipboard layer (stage S3b).
///
/// The editor (stage S3a) owns *when* these run: its cmd/ctrl+C/X/V keyboard
/// actions, the iOS/Android toolbar buttons, a desktop context menu and, on
/// the web, browser paste events. The delegate owns *what* goes on and
/// comes off the clipboard. A delegate never mutates the document itself:
/// cut = [copy] followed by the editor deleting the selection.
abstract interface class DocClipboardDelegate {
  /// Copies [selection] of [doc] to the system clipboard. `docId` is the
  /// DocumentField id, used to read embedded field values from the
  /// controller (`EmbeddedFieldNode.controllerIdFor(docId)`).
  Future<void> copy({
    required String docId,
    required DocSnapshot doc,
    required DocSelection selection,
  });

  /// Reads the system clipboard and returns what to insert, or null when
  /// there is nothing pasteable.
  Future<DocPasteResult?> paste({
    required String docId,
    required DocSnapshot doc,
  });
}
