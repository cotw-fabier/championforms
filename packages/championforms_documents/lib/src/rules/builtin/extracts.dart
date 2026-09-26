import '../../model/doc_node.dart';
import '../../model/doc_snapshot.dart';
import '../../model/doc_text_ops.dart';
import '../rule.dart';
import 'json_read.dart';
import 'sections.dart';

// Built-in extract rules. Each serializes as
// `{"rule": <name>, "key": ..., "required": ..., <config>}`.
//
// Not built in: a `fieldValue` extract (the value of an embedded field).
// Rules are pure functions of the snapshot, and an embedded field's value
// lives in the FormController, not the document, so it cannot be read here.
// Embedded field values are already individually grabbable as
// `{docId}.field.{nodeId}`; the S3 editor layer can add a controller-aware
// extract if a derived alias is needed.

Map<String, dynamic> _base(ExtractRule r) => {
  'key': r.key,
  if (r.required) 'required': true,
};

String _key(Map<String, dynamic> json) => readRequired<String>(json, 'key');
bool _required(Map<String, dynamic> json) =>
    readOptional(json, 'required', false);

/// All text of [doc], one line per text node.
String _docText(DocSnapshot doc) =>
    doc.textNodes.map((n) => n.text.text).join('\n');

/// `@name` mentions → a unique list of names (without the `@`), in order of
/// first appearance.
///
/// A name is letters, digits and `_`, optionally with inner `.` or `-`
/// (`@ada.lovelace`, `@jean-luc`); a trailing `.` or `-` is punctuation. An
/// `@` preceded by a letter or digit (an email address) is not a mention.
/// Letters include non-ASCII letters (`@zoë`).
final class MentionsExtract extends ExtractRule {
  const MentionsExtract({required super.key, super.required});

  static const name = 'mentions';

  static final _pattern = RegExp(
    r'(?<![\p{L}\p{N}_@])@([\p{L}\p{N}_](?:[\p{L}\p{N}_.\-]*[\p{L}\p{N}_])?)',
    unicode: true,
  );

  @override
  String get ruleName => name;

  @override
  List<String> extract(DocSnapshot doc) {
    final seen = <String>{};
    for (final n in doc.textNodes) {
      for (final m in _pattern.allMatches(n.text.text)) {
        seen.add(m.group(1)!);
      }
    }
    return seen.toList();
  }

  @override
  Map<String, dynamic> toJson() => _base(this);

  factory MentionsExtract.fromJson(Map<String, dynamic> json) =>
      MentionsExtract(key: _key(json), required: _required(json));
}

/// Dates written as ISO `yyyy-mm-dd` or US `m/d/yyyy`, normalized to ISO
/// `yyyy-mm-dd` strings. Impossible dates (`2024-02-30`) are ignored.
///
/// With [all] false (default) the value is the first date in document order
/// or null; with [all] true it is a list of unique dates in order.
final class DatesExtract extends ExtractRule {
  const DatesExtract({required super.key, super.required, this.all = false});

  static const name = 'dates';

  static final _pattern = RegExp(
    r'(?<!\d)(?:(\d{4})-(\d{2})-(\d{2})|(\d{1,2})/(\d{1,2})/(\d{4}))(?!\d)',
  );

  final bool all;

  @override
  String get ruleName => name;

  static String? _iso(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime.utc(y, m, d);
    if (date.year != y || date.month != m || date.day != d) return null;
    return '${y.toString().padLeft(4, '0')}-'
        '${m.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
  }

  /// Every valid date in [text], in order (with repeats).
  static Iterable<String> datesIn(String text) sync* {
    for (final m in _pattern.allMatches(text)) {
      final iso = m.group(1) != null
          ? _iso(
              int.parse(m.group(1)!),
              int.parse(m.group(2)!),
              int.parse(m.group(3)!),
            )
          : _iso(
              int.parse(m.group(6)!),
              int.parse(m.group(4)!),
              int.parse(m.group(5)!),
            );
      if (iso != null) yield iso;
    }
  }

  @override
  Object? extract(DocSnapshot doc) {
    final dates = [for (final n in doc.textNodes) ...datesIn(n.text.text)];
    if (!all) return dates.isEmpty ? null : dates.first;
    return dates.toSet().toList();
  }

  @override
  Map<String, dynamic> toJson() => {..._base(this), 'all': all};

  factory DatesExtract.fromJson(Map<String, dynamic> json) => DatesExtract(
    key: _key(json),
    required: _required(json),
    all: readOptional(json, 'all', false),
  );
}

/// The text under the heading titled [title] (trimmed, case-insensitive),
/// up to the next heading of the same or a higher level. Lines are joined
/// with `\n` and the result trimmed; null when the section does not exist.
final class SectionTextExtract extends ExtractRule {
  const SectionTextExtract({
    required super.key,
    super.required,
    required this.title,
  });

  static const name = 'sectionText';

  final String title;

  @override
  String get ruleName => name;

  @override
  String? extract(DocSnapshot doc) => findSection(doc, title)?.text;

  @override
  Map<String, dynamic> toJson() => {..._base(this), 'title': title};

  factory SectionTextExtract.fromJson(Map<String, dynamic> json) =>
      SectionTextExtract(
        key: _key(json),
        required: _required(json),
        title: readRequired<String>(json, 'title'),
      );
}

/// Matches of [pattern] against the document text (text nodes joined with
/// `\n`, matched in multi-line mode so `^`/`$` work per block).
///
/// The value is capture [group] (0 = whole match) of the first match, or
/// null; with [all], the list of every match's group (non-participating
/// groups skipped). An invalid pattern or group fails at evaluation time
/// and is reported as a rule-failure issue.
final class RegexExtract extends ExtractRule {
  const RegexExtract({
    required super.key,
    super.required,
    required this.pattern,
    this.group = 0,
    this.all = false,
    this.caseSensitive = true,
  });

  static const name = 'regex';

  final String pattern;
  final int group;
  final bool all;
  final bool caseSensitive;

  @override
  String get ruleName => name;

  @override
  Object? extract(DocSnapshot doc) {
    final re = RegExp(
      pattern,
      multiLine: true,
      caseSensitive: caseSensitive,
      unicode: true,
    );
    final matches = re.allMatches(_docText(doc));
    if (!all) {
      final first = matches.firstOrNull;
      return first?.group(group);
    }
    return [
      for (final m in matches)
        if (m.group(group) case final String g) g,
    ];
  }

  @override
  Map<String, dynamic> toJson() => {
    ..._base(this),
    'pattern': pattern,
    'group': group,
    'all': all,
    'caseSensitive': caseSensitive,
  };

  factory RegexExtract.fromJson(Map<String, dynamic> json) => RegexExtract(
    key: _key(json),
    required: _required(json),
    pattern: readRequired<String>(json, 'pattern'),
    group: readOptional(json, 'group', 0),
    all: readOptional(json, 'all', false),
    caseSensitive: readOptional(json, 'caseSensitive', true),
  );
}

/// Task progress: `{"total": <tasks>, "done": <checked tasks>}`.
final class TaskStatusExtract extends ExtractRule {
  const TaskStatusExtract({required super.key, super.required});

  static const name = 'taskStatus';

  @override
  String get ruleName => name;

  @override
  Map<String, int> extract(DocSnapshot doc) {
    final tasks = doc.nodes.whereType<TaskNode>();
    return {
      'total': tasks.length,
      'done': tasks.where((t) => t.checked).length,
    };
  }

  @override
  Map<String, dynamic> toJson() => _base(this);

  factory TaskStatusExtract.fromJson(Map<String, dynamic> json) =>
      TaskStatusExtract(key: _key(json), required: _required(json));
}

/// Whether a heading titled [title] exists (trimmed, case-insensitive).
///
/// A bool is never "empty", so `required` has no effect here; use a
/// `requiredSection` constraint to insist on a section.
final class HasSectionExtract extends ExtractRule {
  const HasSectionExtract({
    required super.key,
    super.required,
    required this.title,
  });

  static const name = 'hasSection';

  final String title;

  @override
  String get ruleName => name;

  @override
  bool extract(DocSnapshot doc) => findSection(doc, title) != null;

  @override
  Map<String, dynamic> toJson() => {..._base(this), 'title': title};

  factory HasSectionExtract.fromJson(Map<String, dynamic> json) =>
      HasSectionExtract(
        key: _key(json),
        required: _required(json),
        title: readRequired<String>(json, 'title'),
      );
}
