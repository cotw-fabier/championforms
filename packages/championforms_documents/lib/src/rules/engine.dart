import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_snapshot.dart';
import 'rule.dart';
import 'rule_set.dart';

/// Applies a [DocEdit] to a [DocSnapshot], producing a new snapshot.
///
/// Ops run in order, each against the result of the previous one. Any op
/// that refers to a node that is not there, or that would create a
/// duplicate id, throws [StateError]: a transform rule that emits such an
/// edit is buggy, and silently skipping ops would corrupt the document.
abstract final class DocEditApplier {
  /// Applies [edit] to [doc]. Throws [StateError] on:
  /// - a [ReplaceNodeOp] / [RemoveNodeOp] / [InsertAfterOp] anchor naming an
  ///   unknown node id;
  /// - an insert (or a replacement) whose node id already exists;
  /// - a [DocEdit.caret] that names a node missing from the result, or an
  ///   offset outside `[0, text.length]` for a text node. Block nodes
  ///   (divider, embedded field) accept offset 0 (before) or 1 (after),
  ///   mirroring super_editor's upstream/downstream positions.
  static DocSnapshot apply(DocSnapshot doc, DocEdit edit) {
    final nodes = [...doc.nodes];
    int indexOf(String id, String opName) {
      final i = nodes.indexWhere((n) => n.id == id);
      if (i < 0) throw StateError('$opName: unknown node id "$id"');
      return i;
    }

    void checkFree(String id, String opName, {String? except}) {
      if (id != except && nodes.any((n) => n.id == id)) {
        throw StateError('$opName: node id "$id" already exists');
      }
    }

    for (final op in edit.ops) {
      switch (op) {
        case ReplaceNodeOp(:final nodeId, :final replacement):
          final i = indexOf(nodeId, 'ReplaceNodeOp');
          checkFree(replacement.id, 'ReplaceNodeOp', except: nodeId);
          nodes[i] = replacement;
        case InsertAfterOp(:final afterNodeId, :final node):
          final at = afterNodeId == null
              ? 0
              : indexOf(afterNodeId, 'InsertAfterOp') + 1;
          checkFree(node.id, 'InsertAfterOp');
          nodes.insert(at, node);
        case RemoveNodeOp(:final nodeId):
          nodes.removeAt(indexOf(nodeId, 'RemoveNodeOp'));
      }
    }

    final result = DocSnapshot(nodes, schemaVersion: doc.schemaVersion);
    final caret = edit.caret;
    if (caret != null) {
      final node = result.nodeById(caret.nodeId);
      if (node == null) {
        throw StateError('Caret refers to unknown node "${caret.nodeId}"');
      }
      final max = node is TextDocNode ? node.text.text.length : 1;
      if (caret.offset < 0 || caret.offset > max) {
        throw StateError(
          'Caret offset ${caret.offset} is outside [0, $max] in "${node.id}"',
        );
      }
    }
    return result;
  }
}

/// Offers input events to transform rules in order.
///
/// The first rule that returns a non-null [DocEdit] wins; later rules are
/// not consulted. A rule that throws is treated as declining (typing must
/// never crash the editor); the next rule gets the event.
final class TransformEngine {
  TransformEngine(List<TransformRule> rules) : rules = List.unmodifiable(rules);

  /// The rules of [ruleSet].
  factory TransformEngine.fromRuleSet(RuleSet ruleSet) =>
      TransformEngine(ruleSet.transforms);

  final List<TransformRule> rules;

  /// The first non-null edit any rule proposes for [event], or null.
  DocEdit? handle(DocSnapshot doc, DocInputEvent event) {
    for (final rule in rules) {
      final DocEdit? edit;
      try {
        edit = rule.apply(doc, event);
      } catch (_) {
        continue;
      }
      if (edit != null) return edit;
    }
    return null;
  }

  /// [handle] plus [DocEditApplier.apply]: the edited document and the caret
  /// the rule asked for, or null when no rule reacted.
  ({DocSnapshot doc, DocCaret? caret})? run(
    DocSnapshot doc,
    DocInputEvent event,
  ) {
    final edit = handle(doc, event);
    if (edit == null) return null;
    return (doc: DocEditApplier.apply(doc, edit), caret: edit.caret);
  }
}

/// What [evaluate] found: extracted values by key and validation issues.
final class ExtractionResult {
  const ExtractionResult({required this.values, required this.issues});

  /// Every extract rule's value by key. A rule that failed maps to null.
  final Map<String, Object?> values;

  /// Required-missing and rule-failure issues from extract rules (in rule
  /// order), then constraint issues (in rule order).
  final List<DocIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Whether [value] counts as "missing" for a required extract: null, a
/// blank string, or an empty list/map.
bool isEmptyExtractedValue(Object? value) => switch (value) {
  null => true,
  final String s => s.trim().isEmpty,
  final Iterable<Object?> l => l.isEmpty,
  final Map<Object?, Object?> m => m.isEmpty,
  _ => false,
};

/// Runs [ruleSet]'s extract and constraint rules against [doc].
///
/// Never throws for a misbehaving rule: a rule that throws becomes a
/// [DocIssue] `"Rule <name> failed: <error>"`, the same stance the core
/// library takes for a throwing validator (it is a failure, not a crash).
/// An extract rule whose key is not a valid id segment fails the same way.
/// When two extract rules share a key, the later one wins.
ExtractionResult evaluate(DocSnapshot doc, RuleSet ruleSet) {
  final values = <String, Object?>{};
  final issues = <DocIssue>[];

  for (final rule in ruleSet.extracts) {
    try {
      checkIdSegment(rule.key, 'key');
      final value = rule.extract(doc);
      values[rule.key] = value;
      if (rule.required && isEmptyExtractedValue(value)) {
        issues.add(DocIssue(rule.requiredMessage));
      }
    } catch (e) {
      if (isValidIdSegment(rule.key)) values[rule.key] = null;
      issues.add(DocIssue('Rule ${rule.ruleName} failed: $e'));
    }
  }

  final view = Map<String, Object?>.unmodifiable(values);
  for (final rule in ruleSet.constraints) {
    try {
      issues.addAll(rule.check(doc, view));
    } catch (e) {
      issues.add(DocIssue('Rule ${rule.ruleName} failed: $e'));
    }
  }
  return ExtractionResult(values: values, issues: issues);
}
