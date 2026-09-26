import 'doc_node.dart';
import 'doc_plain_text.dart';
import 'doc_snapshot.dart';
import 'doc_text.dart';

/// The document as Markdown (CommonMark plus `~~strike~~` and `<u>`).
///
/// Blocks: `#`…`######` headings, `- ` / `N. ` list items (two spaces of
/// indent per level), `- [ ] ` / `- [x] ` tasks, `> ` quotes, `---`
/// dividers. Consecutive list items and tasks are separated by a single
/// line break, other blocks by a blank line; empty paragraphs are skipped.
/// Embedded fields go through [embeddedField] (default
/// `[field: <type>]`).
///
/// Marks: bold `**`, italic `_`, code `` ` ``, link `[text](href)`, strike
/// `~~`, underline `<u>…</u>`. Overlapping marks are closed and reopened so
/// the output is always properly nested. Markdown punctuation in the text
/// is backslash-escaped (except inside code spans), as is a block-level
/// marker at the start of a paragraph.
String toMarkdown(DocSnapshot doc, {EmbeddedFieldRenderer? embeddedField}) {
  final numbering = ListNumbering();
  final out = StringBuffer();
  DocNode? previous;
  for (final node in doc.nodes) {
    if (node is! ListItemNode) numbering.reset();
    if (node is ParagraphNode && node.text.text.trim().isEmpty) {
      previous = node;
      continue;
    }
    final block = switch (node) {
      ParagraphNode(:final text) => markdownInline(text, escapeBlock: true),
      HeadingNode(:final text, :final level) =>
        '${'#' * level} ${markdownInline(text)}',
      ListItemNode(:final text, :final indent) =>
        '${'  ' * indent}${numbering.markerFor(node)}${markdownInline(text)}',
      TaskNode(:final text, :final checked) =>
        '- [${checked ? 'x' : ' '}] ${markdownInline(text)}',
      QuoteNode(:final text) => markdownInline(
        text,
      ).split('\n').map((l) => '> $l').join('\n'),
      DividerNode() => '---',
      EmbeddedFieldNode() => (embeddedField ?? defaultEmbeddedFieldText)(node),
    };
    if (out.isNotEmpty) {
      out.write(_isListLike(node) && _isListLike(previous) ? '\n' : '\n\n');
    }
    out.write(block);
    previous = node;
  }
  return out.toString();
}

bool _isListLike(DocNode? n) => n is ListItemNode || n is TaskNode;

// Outermost first: a link wraps emphasis, code is innermost (Markdown does
// not parse inside code spans).
const _markOrder = [
  DocMarkType.link,
  DocMarkType.bold,
  DocMarkType.italic,
  DocMarkType.strikethrough,
  DocMarkType.underline,
  DocMarkType.code,
];

String _open(DocMark m) => switch (m.type) {
  DocMarkType.bold => '**',
  DocMarkType.italic => '_',
  DocMarkType.code => '`',
  DocMarkType.link => '[',
  DocMarkType.strikethrough => '~~',
  DocMarkType.underline => '<u>',
};

String _close(DocMark m) => switch (m.type) {
  DocMarkType.bold => '**',
  DocMarkType.italic => '_',
  DocMarkType.code => '`',
  DocMarkType.link => '](${m.href ?? ''})',
  DocMarkType.strikethrough => '~~',
  DocMarkType.underline => '</u>',
};

final _inlineSpecial = RegExp(r'[\\*_`\[\]~<]');
final _blockMarker = RegExp(r'^(#|>|[-+] |---)');
final _orderedMarker = RegExp(r'^(\d+)\. ');

/// [text] rendered as inline Markdown (see [toMarkdown] for the marks).
///
/// With [escapeBlock], a leading block marker (`#`, `>`, `- `, `+ `, `---`,
/// `N. `) is escaped so a paragraph stays a paragraph.
String markdownInline(DocText text, {bool escapeBlock = false}) {
  final s = text.text;
  final marks =
      <DocMark>{
        for (final m in text.marks)
          if (m.start < s.length && m.end > m.start)
            DocMark(
              type: m.type,
              start: m.start,
              end: m.end > s.length ? s.length : m.end,
              href: m.href,
            ),
      }.toList()..sort((a, b) {
        final byType = _markOrder
            .indexOf(a.type)
            .compareTo(_markOrder.indexOf(b.type));
        return byType != 0 ? byType : a.start.compareTo(b.start);
      });

  final points = <int>{
    0,
    s.length,
    for (final m in marks) ...[m.start, m.end],
  }.toList()..sort();
  final out = StringBuffer();
  final open = <DocMark>[];
  for (var i = 0; i + 1 < points.length; i++) {
    final a = points[i], b = points[i + 1];
    // The wanted nesting, outermost first (marks are sorted that way).
    final active = [
      for (final m in marks)
        if (m.start <= a && m.end >= b) m,
    ];
    // Keep the common outer part of the open stack; close the rest from the
    // innermost out, then open what is missing.
    var keep = 0;
    while (keep < open.length &&
        keep < active.length &&
        open[keep] == active[keep]) {
      keep++;
    }
    for (var j = open.length - 1; j >= keep; j--) {
      out.write(_close(open[j]));
    }
    open.removeRange(keep, open.length);
    for (final m in active.skip(keep)) {
      out.write(_open(m));
      open.add(m);
    }
    final segment = s.substring(a, b);
    out.write(
      open.any((m) => m.type == DocMarkType.code)
          ? segment
          : segment.replaceAllMapped(_inlineSpecial, (m) => '\\${m[0]}'),
    );
  }
  for (var j = open.length - 1; j >= 0; j--) {
    out.write(_close(open[j]));
  }

  var result = out.toString();
  if (escapeBlock) {
    if (_blockMarker.hasMatch(result)) {
      result = '\\$result';
    } else {
      result = result.replaceFirstMapped(_orderedMarker, (m) => '${m[1]}\\. ');
    }
  }
  return result;
}
