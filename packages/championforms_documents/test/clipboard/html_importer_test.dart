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
  group('fixtures', () {
    test(
      'Google Docs (non-bold wrapper, span styles, aria-level, checklists)',
      () {
        expect(importFixture('google_docs'), [
          'h1 "Project Brief"',
          'p "This is bold and italic text with a link." bold:bold '
              'italic:italic link(https://example.com/spec):link',
          'ul0 "First point"',
          'ul1 "Nested point"',
          'ul0 "Second point"',
          'ol0 "Step one"',
          'task[x] "Done task"',
          'task[ ] "Open task"',
          'p "code_snippet()" code:code_snippet()',
          'hr',
          'p "Underlined and struck" underline:Underlined strikethrough:struck',
        ]);
      },
    );

    test('the Google Docs wrapper alone never makes text bold', () {
      final nodes = importHtml(
        '<b style="font-weight:normal;" id="docs-internal-guid-1234">'
        '<p><span>plain</span></p></b>',
      );
      expect((nodes.single as ParagraphNode).text.marks, isEmpty);
      // Even without the style attribute, the docs id is recognized.
      final bare = importHtml('<b id="docs-internal-guid-9">plain</b>');
      expect((bare.single as ParagraphNode).text.marks, isEmpty);
    });

    test('Word (o:p, mso styles, conditional comments, list paragraphs)', () {
      expect(importFixture('word'), [
        'h1 "Meeting Notes"',
        'p "This paragraph has bold, italic, underlined and more bold text, '
            'wrapped across lines by Word." bold:bold italic:italic '
            'underline:underlined bold:more bold',
        'ul0 "Bullet one"',
        'ul1 "Bullet nested"',
        'ul0 "Bullet two"',
        'ol0 "Numbered one"',
        'ol0 "Numbered two"',
        'p "Removed and a Word link" strikethrough:Removed '
            'link(https://example.com/word):a Word link',
      ]);
    });

    test('Notion (to-do list, code, blockquote, script dropped)', () {
      expect(importFixture('notion'), [
        'h2 "Launch checklist"',
        'p "Owner: Dana, see the plan and deploy.sh." bold:Dana '
            'link(https://www.notion.so/Launch-plan-0123456789abcdef):the plan '
            'code:deploy.sh',
        'task[x] "Write release notes"',
        'task[ ] "Tag the release"',
        'ul0 "Plain bullet"',
        'ul1 "Child bullet"',
        'ol0 "First"',
        'ol0 "Second"',
        'quote "Ship it when it is ready." italic:ready',
        'hr',
        'p "Old idea highlighted" strikethrough:Old idea',
      ]);
    });

    test('Pages / Cocoa HTML Writer (head styles dropped, br splits)', () {
      expect(importFixture('pages'), [
        'p "Quarterly Report" bold:Quarterly Report',
        'p "Revenue grew in every region  this quarter." italic:every',
        'ul0 "North & South"',
        'ul0 "East"',
        'ol0 "Hire"',
        'ol0 "Expand"',
        'p "Line one"',
        'p "Line two"',
      ]);
    });

    test('Chrome selection (entities, unsafe link, table, style dropped)', () {
      expect(importFixture('chrome_selection'), [
        'h2 "Getting started"',
        'p "Install the package with flutter pub add, then read the guide. '
            'Avoid this link." code:flutter pub add '
            'link(https://docs.example.com/guide?a=1&b=2):guide',
        'ul0 "Fast: <1 ms & tiny" bold:Fast',
        'ul0 "Safe   and sound"',
        'quote "Quoted wisdom."',
        'p "Cell A\tCell B"',
      ]);
    });

    test('every imported node has a fresh, unique id', () {
      final a = importHtml('<p>x</p><p>y</p>');
      final b = importHtml('<p>x</p><p>y</p>');
      final ids = [...a, ...b].map((n) => n.id).toSet();
      expect(ids, hasLength(4));
    });
  });

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
