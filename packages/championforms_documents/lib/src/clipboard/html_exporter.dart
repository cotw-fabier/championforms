import 'package:championforms/championforms.dart' as form;

import '../model/doc_node.dart';
import '../model/doc_text.dart';
import 'clipboard_sanitize.dart';
import 'html_payload.dart';

/// Renders copied document nodes as semantic HTML for other applications.
///
/// Shapes (chosen so Google Docs, Word, Pages, Notion and browsers keep the
/// structure without a stylesheet):
///
/// | Node | HTML |
/// |---|---|
/// | paragraph | `<p>…</p>` (`<p><br></p>` when empty) |
/// | heading | `<h1>`…`<h6>` |
/// | list items | consecutive items grouped into `<ul>`/`<ol>`; a deeper indent nests a list inside the previous `<li>` (a jump of several levels bridges with `<li style="list-style-type:none">`) |
/// | tasks | consecutive tasks in one `<ul style="list-style-type:none">`, each `<li><input type="checkbox" disabled[ checked]> …</li>` |
/// | quote | consecutive quotes in one `<blockquote>`, one `<p>` each |
/// | divider | `<hr>` |
/// | embedded field | its fragment's html (or escaped plainText) in `<div>`; skipped without a fragment |
///
/// Marks: `<a href>` outermost, then `<strong>`, `<em>`, `<s>`, `<u>`,
/// `<code style="font-family:monospace">` innermost. Overlapping marks are
/// closed and reopened so the markup is always properly nested. All text
/// and attribute values are escaped; line breaks inside a block become
/// `<br>`; unsafe link targets ([safeHref]) are dropped.
///
/// [fragments] maps embedded node ids to their clipboard fragments.
String exportHtmlBody(
  List<DocNode> nodes, {
  Map<String, form.ClipboardFragment> fragments = const {},
}) {
  final out = StringBuffer();
  final lists = _ListWriter(out);
  var inTasks = false;
  var inQuote = false;

  void closeGroups({bool keepLists = false, bool keepTasks = false}) {
    if (!keepLists) lists.closeAll();
    if (!keepTasks && inTasks) {
      out.write('</ul>');
      inTasks = false;
    }
  }

  for (final node in nodes) {
    if (node is! QuoteNode && inQuote) {
      out.write('</blockquote>');
      inQuote = false;
    }
    closeGroups(keepLists: node is ListItemNode, keepTasks: node is TaskNode);
    switch (node) {
      case ParagraphNode(:final text):
        out.write(text.isEmpty ? '<p><br></p>' : '<p>${htmlInline(text)}</p>');
      case HeadingNode(:final text, :final level):
        out.write('<h$level>${htmlInline(text)}</h$level>');
      case ListItemNode(:final text, :final indent, :final ordered):
        lists.item(indent, ordered, htmlInline(text));
      case TaskNode(:final text, :final checked):
        if (!inTasks) {
          out.write('<ul style="list-style-type:none">');
          inTasks = true;
        }
        out.write(
          '<li><input type="checkbox" disabled${checked ? ' checked' : ''}> '
          '${htmlInline(text)}</li>',
        );
      case QuoteNode(:final text):
        if (!inQuote) {
          out.write('<blockquote>');
          inQuote = true;
        }
        out.write('<p>${htmlInline(text)}</p>');
      case DividerNode():
        out.write('<hr>');
      case EmbeddedFieldNode():
        final fragment = fragments[node.id];
        if (fragment != null) out.write('<div>${fragmentHtml(fragment)}</div>');
    }
  }
  if (inQuote) out.write('</blockquote>');
  closeGroups();
  return out.toString();
}

/// The full clipboard HTML: [body] wrapped with the ChampionForms payload
/// (see `embedPayloadInHtml`), or just [body] with a charset declaration when
/// [payloadJson] is null.
String exportHtml(
  List<DocNode> nodes, {
  Map<String, form.ClipboardFragment> fragments = const {},
  String? payloadJson,
}) {
  final body = exportHtmlBody(nodes, fragments: fragments);
  return payloadJson == null
      ? '<meta charset="utf-8">$body'
      : embedPayloadInHtml(body, payloadJson);
}

/// A fragment's own html, or its escaped plainText with `<br>` line breaks.
String fragmentHtml(form.ClipboardFragment fragment) =>
    fragment.html ?? _escapeText(fragment.plainText);

/// Writes nested `<ul>`/`<ol>` for a run of list items.
final class _ListWriter {
  _ListWriter(this.out);

  final StringBuffer out;
  final List<({bool ordered, bool liOpen})> _stack = [];

  void _open(bool ordered) {
    out.write(ordered ? '<ol>' : '<ul>');
    _stack.add((ordered: ordered, liOpen: false));
  }

  void _closeLevel() {
    final top = _stack.removeLast();
    if (top.liOpen) out.write('</li>');
    out.write(top.ordered ? '</ol>' : '</ul>');
  }

  void _setLiOpen(bool open) {
    final top = _stack.removeLast();
    _stack.add((ordered: top.ordered, liOpen: open));
  }

  void item(int indent, bool ordered, String content) {
    final depth = indent + 1;
    while (_stack.length > depth) {
      _closeLevel();
    }
    if (_stack.length == depth && _stack.last.ordered != ordered) {
      _closeLevel();
    }
    while (_stack.length < depth) {
      if (_stack.isNotEmpty && !_stack.last.liOpen) {
        out.write('<li style="list-style-type:none">');
        _setLiOpen(true);
      }
      // Bridging levels (a jump of several indents) are plain bullets.
      _open(_stack.length == depth - 1 ? ordered : false);
    }
    if (_stack.last.liOpen) out.write('</li>');
    out.write('<li>$content');
    _setLiOpen(true);
  }

  void closeAll() {
    while (_stack.isNotEmpty) {
      _closeLevel();
    }
  }
}

// Outermost first, as in the Markdown serializer.
const _markOrder = [
  DocMarkType.link,
  DocMarkType.bold,
  DocMarkType.italic,
  DocMarkType.strikethrough,
  DocMarkType.underline,
  DocMarkType.code,
];

String _openTag(DocMark m) => switch (m.type) {
  DocMarkType.bold => '<strong>',
  DocMarkType.italic => '<em>',
  DocMarkType.underline => '<u>',
  DocMarkType.strikethrough => '<s>',
  DocMarkType.code => '<code style="font-family:monospace">',
  DocMarkType.link => '<a href="${form.clipboardHtmlEscape(m.href!)}">',
};

String _closeTag(DocMark m) => switch (m.type) {
  DocMarkType.bold => '</strong>',
  DocMarkType.italic => '</em>',
  DocMarkType.underline => '</u>',
  DocMarkType.strikethrough => '</s>',
  DocMarkType.code => '</code>',
  DocMarkType.link => '</a>',
};

String _escapeText(String text) => form
    .clipboardHtmlEscape(text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'))
    .replaceAll('\n', '<br>');

/// [text] as inline HTML with its marks as properly nested tags.
String htmlInline(DocText text) {
  final clean = sanitizeDocText(text);
  final s = clean.text;
  final marks = clean.marks.toSet().toList()
    ..sort((a, b) {
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
    final active = [
      for (final m in marks)
        if (m.start <= a && m.end >= b) m,
    ];
    // Keep the common outer part of the open stack, close the rest from the
    // innermost out, then open what is missing.
    var keep = 0;
    while (keep < open.length &&
        keep < active.length &&
        open[keep] == active[keep]) {
      keep++;
    }
    for (var j = open.length - 1; j >= keep; j--) {
      out.write(_closeTag(open[j]));
    }
    open.removeRange(keep, open.length);
    for (final m in active.skip(keep)) {
      out.write(_openTag(m));
      open.add(m);
    }
    out.write(_escapeText(s.substring(a, b)));
  }
  for (var j = open.length - 1; j >= 0; j--) {
    out.write(_closeTag(open[j]));
  }
  return out.toString();
}
