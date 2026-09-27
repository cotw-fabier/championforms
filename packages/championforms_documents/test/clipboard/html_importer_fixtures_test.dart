@TestOn('vm')
library;

// Fixture files are read with dart:io, so these run on the VM only; the
// importer rules in html_importer_test.dart also run in browsers.
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
}
