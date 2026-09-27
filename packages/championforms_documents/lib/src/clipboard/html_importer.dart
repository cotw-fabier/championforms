import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../model/doc_ids.dart';
import '../model/doc_node.dart';
import '../model/doc_text.dart';
import 'clipboard_sanitize.dart';

/// Foreign clipboard HTML longer than this is not parsed (the paste falls
/// back to plain text). Parsing cost grows with input and the input is
/// untrusted.
const maxImportHtmlLength = 5 * 1024 * 1024;

/// Elements nested deeper than this are dropped with their content, so a
/// hostile document cannot exhaust the stack.
const _maxDepth = 256;

/// Converts HTML from another application (Google Docs, Word, Notion,
/// Pages, a browser selection…) into document nodes, each with a fresh id.
///
/// Blocks:
/// - `h1`–`h6` → [HeadingNode];
/// - `p`, and `div`/`section`/… that hold text → [ParagraphNode];
/// - `ul`/`ol` > `li` → [ListItemNode] (nesting depth → indent, at most 8;
///   Google Docs' `aria-level` wins when present). A `li` holding a checkbox
///   (`<input type=checkbox>`, `role="checkbox"` + `aria-checked`, Notion's
///   `checkbox-on`/`checkbox-off`), or whose text starts with `[ ]`, `[x]`,
///   `☐`, `☑` or `☒`, becomes a [TaskNode];
/// - Word's list paragraphs (`style="mso-list:l0 level2 lfo1"`) become list
///   items, their bullet/number marker (`<![if !supportLists]>…<![endif]>`
///   or `mso-list:Ignore` spans) removed and used to tell ordered lists;
/// - `blockquote` → [QuoteNode] (one per contained block);
/// - `hr` → [DividerNode];
/// - `pre` → one paragraph per line, code-marked;
/// - `br` splits a paragraph, heading or quote into two blocks; inside a
///   list item or task it becomes a line break in the text;
/// - table rows become paragraphs, cells separated by a tab.
///
/// Inline: `strong`/`b`, `em`/`i`, `u`/`ins`, `s`/`strike`/`del`,
/// `code`/`kbd`/`samp`/`tt` and `a href` (unsafe targets dropped, see
/// [safeHref]), plus inline styles: `font-weight` (≥ 600/bold on, normal or
/// < 600 off, so Google Docs' `<b style="font-weight:normal"
/// id="docs-internal-guid-…">` wrapper is *not* bold), `font-style`,
/// `text-decoration` (underline ignored inside links, which apps underline
/// anyway) and monospace `font-family` (→ code).
///
/// Whitespace collapses as in a browser (not inside `pre`), `&nbsp;` is a
/// plain space, entities are decoded, blocks with no visible text are
/// dropped. `script`, `style`, `head`, `svg` and similar are dropped with
/// their text; unknown tags (`o:p`, `font`, custom elements) keep their
/// text. A Windows CF_HTML header (`Version:0.9 StartHTML:…`) is skipped.
///
/// Returns an empty list for HTML of [maxImportHtmlLength] or more, or with
/// no text. Never throws for any input string.
List<DocNode> importHtml(String html) {
  if (html.length >= maxImportHtmlLength) return const [];
  try {
    final document = html_parser.parse(_stripCfHtmlHeader(html));
    final body = document.body;
    if (body == null) return const [];
    final importer = _Importer();
    importer.walkChildren(body, const _Ctx(), 0);
    importer.flush();
    return importer.nodes;
  } catch (_) {
    // package:html is lenient; this is belt and braces for untrusted input.
    return const [];
  }
}

final _cfHtmlHeader = RegExp(r'^\s*Version:\d');

String _stripCfHtmlHeader(String html) {
  if (!_cfHtmlHeader.hasMatch(html)) return html;
  final lt = html.indexOf('<');
  return lt < 0 ? '' : html.substring(lt);
}

// ---------------------------------------------------------------------------
// Context
// ---------------------------------------------------------------------------

enum _KindType { paragraph, heading, listItem, task, quote, wordList }

final class _Kind {
  const _Kind(
    this.type, {
    this.level = 1,
    this.ordered = false,
    this.indent = 0,
    this.checked = false,
  });

  static const paragraph = _Kind(_KindType.paragraph);
  static const quote = _Kind(_KindType.quote);

  final _KindType type;
  final int level;
  final bool ordered;
  final int indent;
  final bool checked;

  bool get isListLike =>
      type == _KindType.listItem ||
      type == _KindType.task ||
      type == _KindType.wordList;

  DocNode build(String id, DocText text) => switch (type) {
    _KindType.paragraph => ParagraphNode(id: id, text: text),
    _KindType.heading => HeadingNode(id: id, level: level, text: text),
    _KindType.listItem || _KindType.wordList => ListItemNode(
      id: id,
      ordered: ordered,
      indent: indent,
      text: text,
    ),
    _KindType.task => TaskNode(id: id, checked: checked, text: text),
    _KindType.quote => QuoteNode(id: id, text: text),
  };
}

final class _Fmt {
  const _Fmt({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.href,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;
  final String? href;

  _Fmt copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strike,
    bool? code,
    String? href,
  }) => _Fmt(
    bold: bold ?? this.bold,
    italic: italic ?? this.italic,
    underline: underline ?? this.underline,
    strike: strike ?? this.strike,
    code: code ?? this.code,
    href: href ?? this.href,
  );

  bool has(DocMarkType type) => switch (type) {
    DocMarkType.bold => bold,
    DocMarkType.italic => italic,
    DocMarkType.underline => underline,
    DocMarkType.strikethrough => strike,
    DocMarkType.code => code,
    DocMarkType.link => href != null,
  };
}

final class _Ctx {
  const _Ctx({
    this.fmt = const _Fmt(),
    this.kind = _Kind.paragraph,
    this.listDepth = 0,
    this.ordered = false,
    this.inQuote = false,
    this.inLi = false,
    this.pre = false,
  });

  final _Fmt fmt;
  final _Kind kind;
  final int listDepth;
  final bool ordered;
  final bool inQuote;
  final bool inLi;
  final bool pre;

  _Ctx copyWith({
    _Fmt? fmt,
    _Kind? kind,
    int? listDepth,
    bool? ordered,
    bool? inQuote,
    bool? inLi,
    bool? pre,
  }) => _Ctx(
    fmt: fmt ?? this.fmt,
    kind: kind ?? this.kind,
    listDepth: listDepth ?? this.listDepth,
    ordered: ordered ?? this.ordered,
    inQuote: inQuote ?? this.inQuote,
    inLi: inLi ?? this.inLi,
    pre: pre ?? this.pre,
  );

  /// The kind a plain block (`p`, `div`…) inside this context gets.
  _Kind get blockKind =>
      inLi ? kind : (inQuote ? _Kind.quote : _Kind.paragraph);
}

// ---------------------------------------------------------------------------
// Tag tables
// ---------------------------------------------------------------------------

const _dropTags = {
  'script',
  'style',
  'head',
  'title',
  'template',
  'noscript',
  'iframe',
  'object',
  'embed',
  'svg',
  'math',
  'canvas',
  'video',
  'audio',
  'meta',
  'link',
  'xml',
  'select',
  'textarea',
  'img',
  'picture',
};

const _blockTags = {
  'p',
  'div',
  'section',
  'article',
  'header',
  'footer',
  'main',
  'nav',
  'aside',
  'figure',
  'figcaption',
  'address',
  'dl',
  'dt',
  'dd',
  'center',
  'form',
  'fieldset',
  'details',
  'summary',
  'caption',
  'table',
  'thead',
  'tbody',
  'tfoot',
  'tr',
};

const _headings = {'h1': 1, 'h2': 2, 'h3': 3, 'h4': 4, 'h5': 5, 'h6': 6};

const _monospaceFonts = [
  'monospace',
  'courier',
  'consolas',
  'menlo',
  'monaco',
  'source code',
  'roboto mono',
  'sf mono',
];

// ---------------------------------------------------------------------------
// Importer
// ---------------------------------------------------------------------------

final class _Run {
  const _Run(this.start, this.end, this.fmt);
  final int start;
  final int end;
  final _Fmt fmt;
}

final class _Block {
  _Block(this.kind);
  final _Kind kind;
  final StringBuffer text = StringBuffer();
  final List<_Run> runs = [];
  bool endsWithSpace = true; // at block start, leading space collapses
}

final _collapsible = RegExp(r'[ \t\n\r\f]+');
final _wordListLevel = RegExp(r'level(\d+)');
final _orderedMarker = RegExp(r'^\s*(\d+|[a-zA-Z]|[ivxlcdmIVXLCDM]+)[.)]');
final _taskPrefix = RegExp(r'^(\[( |x|X)?\]|☐|☑|☒)\s*');

final class _Importer {
  final List<DocNode> nodes = [];
  _Block? _block;

  bool _inWordMarker = false;
  final StringBuffer _wordMarker = StringBuffer();

  void walkChildren(dom.Node parent, _Ctx ctx, int depth) {
    for (final child in parent.nodes) {
      walk(child, ctx, depth + 1);
    }
  }

  void walk(dom.Node node, _Ctx ctx, int depth) {
    if (depth > _maxDepth) return;
    switch (node) {
      case dom.Text(:final data):
        if (_inWordMarker) {
          _wordMarker.write(data);
        } else {
          _append(data, ctx);
        }
      case dom.Comment(:final data):
        final d = (data ?? '').trim();
        if (d.startsWith('[if !supportLists]')) {
          _inWordMarker = true;
        } else if (d.startsWith('[endif]')) {
          _inWordMarker = false;
        }
      case dom.Element():
        _element(node, ctx, depth);
      default:
        break;
    }
  }

  void _element(dom.Element el, _Ctx ctx, int depth) {
    final tag = (el.localName ?? '').toLowerCase();
    if (_dropTags.contains(tag)) return;
    final style = {..._parseStyle(el.attributes['style'])};
    if (tag == 'li' && el.attributes['role'] == 'checkbox') {
      // Google Docs strikes through ticked checklist items as presentation,
      // not as content formatting.
      style
        ..remove('text-decoration')
        ..remove('text-decoration-line');
    }

    // Word's list marker span: capture, don't import.
    if ((style['mso-list'] ?? '') == 'ignore') {
      final was = _inWordMarker;
      _inWordMarker = true;
      walkChildren(el, ctx, depth);
      _inWordMarker = was;
      return;
    }

    final inner = ctx.copyWith(
      fmt: _applyStyle(_applyTag(ctx.fmt, el, tag), style, ctx),
    );

    if (tag == 'br') {
      if (ctx.pre || (_block?.kind.isListLike ?? ctx.kind.isListLike)) {
        _append('\n', ctx, raw: true);
      } else {
        flush();
      }
      return;
    }
    if (tag == 'hr') {
      flush();
      nodes.add(DividerNode(id: newNodeId()));
      return;
    }
    if (tag == 'input') return; // checkboxes are read by the enclosing li
    if (tag == 'td' || tag == 'th') {
      if (_block != null && _block!.text.isNotEmpty) {
        _append('\t', ctx, raw: true);
      }
      walkChildren(el, inner, depth);
      return;
    }

    final level = _headings[tag];
    if (level != null) {
      _asBlock(
        el,
        inner.copyWith(kind: _Kind(_KindType.heading, level: level)),
        depth,
      );
      return;
    }
    switch (tag) {
      case 'ul' || 'ol':
        _asBlock(
          el,
          inner.copyWith(listDepth: ctx.listDepth + 1, ordered: tag == 'ol'),
          depth,
        );
      case 'li':
        _asBlock(el, inner.copyWith(kind: _liKind(el, ctx), inLi: true), depth);
      case 'blockquote':
        _asBlock(
          el,
          inner.copyWith(inQuote: true, kind: ctx.inLi ? null : _Kind.quote),
          depth,
        );
      case 'pre':
        _asBlock(
          el,
          inner.copyWith(pre: true, fmt: inner.fmt.copyWith(code: true)),
          depth,
        );
      default:
        final wordList = _wordListKind(style);
        if (wordList != null) {
          _wordMarker.clear();
          _inWordMarker = false;
          _asBlock(el, inner.copyWith(kind: wordList), depth);
        } else if (_blockTags.contains(tag)) {
          _asBlock(el, inner.copyWith(kind: inner.blockKind), depth);
        } else {
          walkChildren(el, inner, depth); // inline or unknown: keep text
        }
    }
  }

  void _asBlock(dom.Element el, _Ctx ctx, int depth) {
    flush();
    walkChildren(el, ctx, depth);
    flush();
  }

  // ---- kinds --------------------------------------------------------------

  _Kind _liKind(dom.Element li, _Ctx ctx) {
    final ariaLevel = int.tryParse(li.attributes['aria-level'] ?? '');
    final indent = ((ariaLevel ?? ctx.listDepth) - 1).clamp(0, 8);
    final checked = _checkboxState(li);
    if (checked != null) {
      return _Kind(_KindType.task, checked: checked);
    }
    return _Kind(_KindType.listItem, ordered: ctx.ordered, indent: indent);
  }

  /// The checked state of a checkbox belonging to [li] (not to a nested
  /// list), or null when it has none.
  static bool? _checkboxState(dom.Element li) {
    bool? fromRole(dom.Element e) => e.attributes['role'] == 'checkbox'
        ? e.attributes['aria-checked'] == 'true'
        : null;
    final own = fromRole(li);
    if (own != null) return own;

    bool? search(dom.Element e, int depth) {
      if (depth > 16) return null;
      for (final child in e.children) {
        final tag = child.localName;
        if (tag == 'ul' || tag == 'ol') continue;
        if (tag == 'input' &&
            (child.attributes['type'] ?? '').toLowerCase() == 'checkbox') {
          return child.attributes.containsKey('checked');
        }
        final role = fromRole(child);
        if (role != null) return role;
        final cls = child.attributes['class'] ?? '';
        if (cls.contains('checkbox-on')) return true;
        if (cls.contains('checkbox-off')) return false;
        final nested = search(child, depth + 1);
        if (nested != null) return nested;
      }
      return null;
    }

    return search(li, 0);
  }

  static _Kind? _wordListKind(Map<String, String> style) {
    final msoList = style['mso-list'];
    if (msoList == null) return null;
    final m = _wordListLevel.firstMatch(msoList);
    if (m == null) return null;
    final level = int.parse(m[1]!);
    return _Kind(_KindType.wordList, indent: (level - 1).clamp(0, 8));
  }

  // ---- formatting ---------------------------------------------------------

  static Map<String, String> _parseStyle(String? style) {
    if (style == null || style.isEmpty) return const {};
    final result = <String, String>{};
    for (final decl in style.split(';')) {
      final colon = decl.indexOf(':');
      if (colon <= 0) continue;
      final key = decl.substring(0, colon).trim().toLowerCase();
      final value = decl.substring(colon + 1).trim().toLowerCase();
      if (key.isNotEmpty) result[key] = value;
    }
    return result;
  }

  static _Fmt _applyTag(_Fmt fmt, dom.Element el, String tag) {
    switch (tag) {
      case 'b' || 'strong':
        // Google Docs wraps every copy in a non-bold <b id="docs-internal-guid-…">.
        final id = el.attributes['id'] ?? '';
        return id.startsWith('docs-internal-guid')
            ? fmt
            : fmt.copyWith(bold: true);
      case 'em' || 'i' || 'cite' || 'dfn' || 'var':
        return fmt.copyWith(italic: true);
      case 'u' || 'ins':
        return fmt.copyWith(underline: true);
      case 's' || 'strike' || 'del':
        return fmt.copyWith(strike: true);
      case 'code' || 'kbd' || 'samp' || 'tt':
        return fmt.copyWith(code: true);
      case 'a':
        final href = safeHref(el.attributes['href']);
        return href == null ? fmt : fmt.copyWith(href: href);
      default:
        return fmt;
    }
  }

  static _Fmt _applyStyle(_Fmt fmt, Map<String, String> style, _Ctx ctx) {
    if (style.isEmpty) return fmt;
    var f = fmt;
    final weight = style['font-weight'];
    if (weight != null) {
      final n = int.tryParse(weight);
      if (weight == 'bold' || weight == 'bolder' || (n != null && n >= 600)) {
        f = f.copyWith(bold: true);
      } else if (weight == 'normal' ||
          weight == 'lighter' ||
          (n != null && n < 600)) {
        f = f.copyWith(bold: false);
      }
    }
    final fontStyle = style['font-style'];
    if (fontStyle == 'italic' || fontStyle == 'oblique') {
      f = f.copyWith(italic: true);
    } else if (fontStyle == 'normal') {
      f = f.copyWith(italic: false);
    }
    final decoration =
        '${style['text-decoration'] ?? ''} ${style['text-decoration-line'] ?? ''}';
    if (decoration.contains('underline') && f.href == null) {
      f = f.copyWith(underline: true);
    }
    if (decoration.contains('line-through')) f = f.copyWith(strike: true);
    final family = style['font-family'];
    if (family != null && _monospaceFonts.any(family.contains)) {
      f = f.copyWith(code: true);
    }
    return f;
  }

  // ---- text ---------------------------------------------------------------

  void _append(String input, _Ctx ctx, {bool raw = false}) {
    if (ctx.pre && !raw) {
      final lines = input.replaceAll('\r\n', '\n').split('\n');
      for (var i = 0; i < lines.length; i++) {
        if (i > 0) flush();
        _write(lines[i].replaceAll(' ', ' '), ctx);
      }
      return;
    }
    var s = input;
    if (!raw) {
      s = s.replaceAll(_collapsible, ' ');
      if (s.startsWith(' ') && (_block?.endsWithSpace ?? true)) {
        s = s.substring(1);
      }
      s = s.replaceAll(' ', ' ');
    }
    _write(s, ctx);
  }

  void _write(String s, _Ctx ctx) {
    if (s.isEmpty) return;
    final block = _block ??= _Block(_resolveKind(ctx.kind));
    final start = block.text.length;
    block.text.write(s);
    block.runs.add(_Run(start, block.text.length, ctx.fmt));
    block.endsWithSpace = s.endsWith(' ') || s.endsWith('\n');
  }

  _Kind _resolveKind(_Kind kind) {
    if (kind.type != _KindType.wordList) return kind;
    final ordered = _orderedMarker.hasMatch(_wordMarker.toString());
    return _Kind(_KindType.listItem, ordered: ordered, indent: kind.indent);
  }

  void flush() {
    final block = _block;
    _block = null;
    if (block == null) return;
    final raw = block.text.toString();
    final start = raw.length - raw.trimLeft().length;
    final end = raw.trimRight().length;
    if (end <= start) return;
    var text = DocText(raw, _marks(block.runs)).slice(start, end);
    var kind = block.kind;
    if (kind.type == _KindType.listItem || kind.type == _KindType.paragraph) {
      final m = _taskPrefix.firstMatch(text.text);
      if (m != null && (kind.type == _KindType.listItem || m[1]!.length == 1)) {
        final token = m[1]!;
        final checked = token.contains(RegExp('[xX☑☒]'));
        text = text.slice(m.end);
        kind = _Kind(_KindType.task, checked: checked);
        if (text.isEmpty) return;
      }
    }
    nodes.add(kind.build(newNodeId(), text));
  }

  static List<DocMark> _marks(List<_Run> runs) {
    final marks = <DocMark>[];
    for (final type in DocMarkType.values) {
      int? start;
      int end = 0;
      String? href;
      void close() {
        if (start != null && end > start!) {
          marks.add(DocMark(type: type, start: start!, end: end, href: href));
        }
        start = null;
      }

      for (final run in runs) {
        final active = run.fmt.has(type);
        final runHref = type == DocMarkType.link ? run.fmt.href : null;
        if (active && start != null && runHref == href && run.start == end) {
          end = run.end;
        } else {
          close();
          if (active) {
            start = run.start;
            end = run.end;
            href = runHref;
          }
        }
      }
      close();
    }
    marks.sort((a, b) => a.start.compareTo(b.start));
    return marks;
  }
}
