import 'dart:io';

import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

/// A compact, id-free description of a node for structural assertions.
String describe(DocNode n) {
  String marks(DocText t) => t.marks.isEmpty
      ? ''
      : ' ${[for (final m in t.marks) '${m.type.name}${m.href == null ? '' : '(${m.href})'}:${t.text.substring(m.start, m.end)}'].join(' ')}';
  return switch (n) {
    ParagraphNode(:final text) => 'p "${text.text}"${marks(text)}',
    HeadingNode(:final text, :final level) =>
      'h$level "${text.text}"${marks(text)}',
    ListItemNode(:final text, :final ordered, :final indent) =>
      '${ordered ? 'ol' : 'ul'}$indent "${text.text}"${marks(text)}',
    TaskNode(:final text, :final checked) =>
      'task${checked ? '[x]' : '[ ]'} "${text.text}"${marks(text)}',
    QuoteNode(:final text) => 'quote "${text.text}"${marks(text)}',
    DividerNode() => 'hr',
    EmbeddedFieldNode() => 'field',
  };
}

List<String> importFixture(String name) => importHtml(
  File('test/fixtures/clipboard/$name.html').readAsStringSync(),
).map(describe).toList();

List<String> imp(String html) => importHtml(html).map(describe).toList();

void main() {
  group('rules', () {
    test('whitespace collapses like a browser', () {
      expect(imp('<p>  a \n\t b  <b> c </b> d </p>'), ['p "a b c d" bold:c ']);
    });

    test('br splits paragraphs; inside list items it is a line break', () {
      expect(imp('<p>one<br>two<br></p>'), ['p "one"', 'p "two"']);
      expect(imp('<ul><li>one<br>two</li></ul>'), ['ul0 "one\ntwo"']);
    });

    test('div holding text is a paragraph; wrapper divs add nothing', () {
      expect(imp('<div><div>a</div><div><p>b</p></div></div>'), [
        'p "a"',
        'p "b"',
      ]);
    });

    test('checkbox inputs and text prefixes become tasks', () {
      expect(
        imp(
          '<ul><li><input type="checkbox" checked> a</li>'
          '<li><input type="checkbox"> b</li><li>[x] c</li><li>☐ d</li></ul>',
        ),
        ['task[x] "a"', 'task[ ] "b"', 'task[x] "c"', 'task[ ] "d"'],
      );
    });

    test('ol nesting and indent clamp at 8', () {
      final deep = '${'<ul><li>x' * 12}${'</li></ul>' * 12}';
      final nodes = importHtml(deep).cast<ListItemNode>();
      expect(nodes.last.indent, 8);
      expect(imp('<ol><li>a<ol><li>b</li></ol></li></ol>'), [
        'ol0 "a"',
        'ol1 "b"',
      ]);
    });

    test('inline styles: weight, style, decoration, monospace', () {
      expect(
        imp(
          '<p><span style="font-weight:bold">b</span>'
          '<span style="font-weight: 600">B</span>'
          '<strong><span style="font-weight:400">n</span></strong>'
          '<span style="font-style:italic">i</span>'
          '<span style="text-decoration: underline line-through">x</span>'
          '<span style="font-family: Menlo">c</span></p>',
        ),
        ['p "bBnixc" bold:bB italic:i underline:x strikethrough:x code:c'],
      );
    });

    test('pre keeps whitespace and becomes code paragraphs', () {
      expect(imp('<pre>a  b\nc</pre>'), ['p "a  b" code:a  b', 'p "c" code:c']);
    });

    test('script, style and unsafe links never leak', () {
      expect(
        imp(
          '<p>ok<script>bad()</script><style>p{}</style>'
          '<a href="  JaVaScRiPt:alert(1)">x</a>'
          '<a href="data:text/html,hi">y</a></p>',
        ),
        ['p "okxy"'],
      );
    });

    test('a CF_HTML header is skipped', () {
      expect(
        imp(
          'Version:0.9\r\nStartHTML:0000000105\r\nEndHTML:0000000200\r\n'
          '<html><body><!--StartFragment--><p>hi</p><!--EndFragment--></body></html>',
        ),
        ['p "hi"'],
      );
    });

    test(
      'empty, oversize and pathological input yields nothing, not errors',
      () {
        expect(imp(''), isEmpty);
        expect(imp('<p> &nbsp; </p><br><br>'), isEmpty);
        expect(importHtml('<p>${'x' * maxImportHtmlLength}</p>'), isEmpty);
        // Nesting far beyond the depth limit is cut off, not a stack overflow.
        final nested = '${'<span>' * 5000}deep${'</span>' * 5000}';
        expect(() => importHtml(nested), returnsNormally);
      },
    );
  });
}
