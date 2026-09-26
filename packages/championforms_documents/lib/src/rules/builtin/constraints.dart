import '../../model/doc_node.dart';
import '../../model/doc_snapshot.dart';
import '../../model/doc_text_ops.dart';
import '../rule.dart';
import 'json_read.dart';
import 'sections.dart';

// Built-in constraint rules. Each accepts an optional "message" overriding
// its default wording, and anchors its issues (node id, and a UTF-16 text
// range where one is meaningful) so the editor can underline the block.

/// A heading titled [title] must exist (trimmed, case-insensitive). With
/// [nonEmpty], the section must also contain some text.
///
/// A missing section yields an unanchored issue (there is no node to point
/// at); an empty section is anchored to its heading.
final class RequiredSectionRule extends ConstraintRule {
  const RequiredSectionRule({
    required this.title,
    this.nonEmpty = false,
    this.message,
  });

  static const name = 'requiredSection';

  final String title;
  final bool nonEmpty;
  final String? message;

  @override
  String get ruleName => name;

  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) {
    final section = findSection(doc, title);
    if (section == null) {
      return [DocIssue(message ?? 'Section "$title" is required')];
    }
    if (nonEmpty && section.text.isEmpty) {
      final h = section.heading;
      return [
        DocIssue(
          message ?? 'Section "$title" must not be empty',
          nodeId: h.id,
          start: 0,
          end: h.text.text.length,
        ),
      ];
    }
    return const [];
  }

  @override
  Map<String, dynamic> toJson() => {
    'title': title,
    if (nonEmpty) 'nonEmpty': true,
    if (message != null) 'message': message,
  };

  factory RequiredSectionRule.fromJson(Map<String, dynamic> json) =>
      RequiredSectionRule(
        title: readRequired<String>(json, 'title'),
        nonEmpty: readOptional(json, 'nonEmpty', false),
        message: readNullable<String>(json, 'message'),
      );
}

/// Text-node scope shared by the length rules: the whole document, or the
/// body of the section titled `section`.
({List<TextDocNode> nodes, HeadingNode? heading, bool found}) _scope(
  DocSnapshot doc,
  String? section,
) {
  if (section == null) {
    return (nodes: doc.textNodes.toList(), heading: null, found: true);
  }
  final s = findSection(doc, section);
  return (
    nodes: s?.textNodes.toList() ?? const [],
    heading: s?.heading,
    found: s != null,
  );
}

/// Length in characters (Unicode code points) of [text].
int _chars(String text) => text.runes.length;

/// The document (or the section titled [section]) must have at least [min]
/// characters of text. Characters are Unicode code points summed over text
/// nodes (headings count in the whole-document scope; line breaks between
/// blocks do not).
///
/// Anchored to the section heading when [section] is set, otherwise
/// unanchored. A missing section counts as length 0.
final class MinLengthRule extends ConstraintRule {
  const MinLengthRule({required this.min, this.section, this.message});

  static const name = 'minLength';

  final int min;
  final String? section;
  final String? message;

  @override
  String get ruleName => name;

  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) {
    final scope = _scope(doc, section);
    final length = scope.nodes.fold(0, (sum, n) => sum + _chars(n.text.text));
    if (length >= min) return const [];
    final where = section == null ? 'The document' : 'Section "$section"';
    final h = scope.heading;
    return [
      DocIssue(
        message ?? '$where needs at least $min characters',
        nodeId: h?.id,
        start: h == null ? null : 0,
        end: h?.text.text.length,
      ),
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
    'min': min,
    if (section != null) 'section': section,
    if (message != null) 'message': message,
  };

  factory MinLengthRule.fromJson(Map<String, dynamic> json) => MinLengthRule(
    min: readRequired<int>(json, 'min'),
    section: readNullable<String>(json, 'section'),
    message: readNullable<String>(json, 'message'),
  );
}

/// The document (or the section titled [section]) must have at most [max]
/// characters of text (counted as for [MinLengthRule]).
///
/// The issue is anchored to the node where the limit is crossed, with a
/// range from the first character over the limit to the end of that node.
/// A missing section passes.
final class MaxLengthRule extends ConstraintRule {
  const MaxLengthRule({required this.max, this.section, this.message});

  static const name = 'maxLength';

  final int max;
  final String? section;
  final String? message;

  @override
  String get ruleName => name;

  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) {
    final scope = _scope(doc, section);
    var used = 0;
    for (final n in scope.nodes) {
      final text = n.text.text;
      final chars = _chars(text);
      if (used + chars > max) {
        // UTF-16 offset just past the last code point that still fits.
        final fits = max - used;
        var offset = 0;
        var count = 0;
        final it = text.runes.iterator;
        while (count < fits && it.moveNext()) {
          offset += it.current > 0xFFFF ? 2 : 1;
          count++;
        }
        final where = section == null ? 'The document' : 'Section "$section"';
        return [
          DocIssue(
            message ?? '$where must be at most $max characters',
            nodeId: n.id,
            start: offset,
            end: text.length,
          ),
        ];
      }
      used += chars;
    }
    return const [];
  }

  @override
  Map<String, dynamic> toJson() => {
    'max': max,
    if (section != null) 'section': section,
    if (message != null) 'message': message,
  };

  factory MaxLengthRule.fromJson(Map<String, dynamic> json) => MaxLengthRule(
    max: readRequired<int>(json, 'max'),
    section: readNullable<String>(json, 'section'),
    message: readNullable<String>(json, 'message'),
  );
}

/// No text node may contain a match of [pattern]. Each (non-empty) match is
/// one issue anchored to its node and range. An invalid pattern fails at
/// evaluation time and is reported as a rule-failure issue.
final class ForbiddenPatternRule extends ConstraintRule {
  const ForbiddenPatternRule({
    required this.pattern,
    this.caseSensitive = true,
    this.message,
  });

  static const name = 'forbiddenPattern';

  final String pattern;
  final bool caseSensitive;
  final String? message;

  @override
  String get ruleName => name;

  @override
  List<DocIssue> check(DocSnapshot doc, Map<String, Object?> extracted) {
    final re = RegExp(pattern, caseSensitive: caseSensitive, unicode: true);
    return [
      for (final n in doc.textNodes)
        for (final m in re.allMatches(n.text.text))
          if (m.end > m.start)
            DocIssue(
              message ?? '"${m.group(0)}" is not allowed',
              nodeId: n.id,
              start: m.start,
              end: m.end,
            ),
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
    'pattern': pattern,
    if (!caseSensitive) 'caseSensitive': false,
    if (message != null) 'message': message,
  };

  factory ForbiddenPatternRule.fromJson(Map<String, dynamic> json) =>
      ForbiddenPatternRule(
        pattern: readRequired<String>(json, 'pattern'),
        caseSensitive: readOptional(json, 'caseSensitive', true),
        message: readNullable<String>(json, 'message'),
      );
}
