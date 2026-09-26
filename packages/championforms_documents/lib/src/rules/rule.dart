import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';

/// Base of every document rule. Rules are pure: no controller, no widgets,
/// no platform calls. That is what lets them run in unit tests, on any
/// isolate, and be shipped as data (`toJson` / `RuleRegistry`).
abstract class DocRule {
  const DocRule();

  /// Registry name used as `"rule"` in JSON (e.g. `"markdownPrefix"`).
  String get ruleName;

  /// Rule configuration, without the `"rule"` key (the registry adds it).
  Map<String, dynamic> toJson();
}

// ---------------------------------------------------------------------------
// Transform rules: run while typing.
// ---------------------------------------------------------------------------

/// Something the person just did in the editor, expressed on the snapshot.
sealed class DocInputEvent {
  const DocInputEvent(this.nodeId);

  /// The text node the event happened in.
  final String nodeId;
}

/// [text] was inserted so that it now ends at [caretOffset] in [nodeId].
final class TextInserted extends DocInputEvent {
  const TextInserted(
    super.nodeId, {
    required this.text,
    required this.caretOffset,
  });

  final String text;
  final int caretOffset;
}

/// Enter at [caretOffset] in [nodeId].
final class EnterPressed extends DocInputEvent {
  const EnterPressed(super.nodeId, {required this.caretOffset});

  final int caretOffset;
}

/// Backspace with the caret at offset 0 of [nodeId].
final class BackspaceAtStart extends DocInputEvent {
  const BackspaceAtStart(super.nodeId);
}

/// One change to apply to a document. Applied in order by the engine.
sealed class DocEditOp {
  const DocEditOp();
}

final class ReplaceNodeOp extends DocEditOp {
  const ReplaceNodeOp(this.nodeId, this.replacement);
  final String nodeId;
  final DocNode replacement;
}

final class InsertAfterOp extends DocEditOp {
  /// [afterNodeId] null inserts at the start of the document.
  const InsertAfterOp(this.afterNodeId, this.node);
  final String? afterNodeId;
  final DocNode node;
}

final class RemoveNodeOp extends DocEditOp {
  const RemoveNodeOp(this.nodeId);
  final String nodeId;
}

/// The caret position the editor should show after the edit.
final class DocCaret {
  const DocCaret(this.nodeId, this.offset);
  final String nodeId;
  final int offset;
}

/// What a [TransformRule] wants done. [caret] null keeps the editor's own.
final class DocEdit {
  const DocEdit(this.ops, {this.caret});
  final List<DocEditOp> ops;
  final DocCaret? caret;
}

/// Reacts to an input event by returning an edit, or null to decline.
///
/// The engine offers each event to transform rules in order and applies the
/// first non-null edit (so earlier rules win).
abstract class TransformRule extends DocRule {
  const TransformRule();

  DocEdit? apply(DocSnapshot doc, DocInputEvent event);
}

// ---------------------------------------------------------------------------
// Extract rules: derive named values from the document.
// ---------------------------------------------------------------------------

/// Derives one named value from the document.
///
/// Each extract rule becomes a registered derived field `{docId}.{key}`, so
/// its value appears in `FormResults` and can drive `FieldCondition`s.
abstract class ExtractRule extends DocRule {
  const ExtractRule({required this.key, this.required = false});

  /// Result key. Must be a valid field-id segment: `[A-Za-z0-9_]+`.
  final String key;

  /// When true and [extract] yields null or an empty value, the document
  /// fails validation with [requiredMessage].
  final bool required;

  String get requiredMessage => '"$key" is required';

  /// The value: JSON-safe (String, num, bool, null, List, Map of those).
  Object? extract(DocSnapshot doc);
}

// ---------------------------------------------------------------------------
// Constraint rules: validate the document.
// ---------------------------------------------------------------------------

/// A validation problem, optionally anchored to a node or a text range so
/// the editor can underline and wiggle the right block.
final class DocIssue {
  const DocIssue(this.message, {this.nodeId, this.start, this.end});

  final String message;
  final String? nodeId;
  final int? start;
  final int? end;

  @override
  String toString() => 'DocIssue($message${nodeId == null ? '' : ' @$nodeId'})';
}

/// Checks the document. [extracted] holds every extract rule's value by key.
abstract class ConstraintRule extends DocRule {
  const ConstraintRule();

  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted);
}
