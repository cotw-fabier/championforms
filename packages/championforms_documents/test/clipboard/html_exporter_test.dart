import 'dart:convert';

import 'package:championforms/championforms.dart' as form;
import 'package:championforms_documents/championforms_documents.dart';
import 'package:flutter_test/flutter_test.dart';

DocMark m(DocMarkType t, int s, int e, [String? href]) =>
    DocMark(type: t, start: s, end: e, href: href);

void main() {
  group('block snapshots', () {
    test('paragraph, empty paragraph, headings', () {
      expect(
        exportHtmlBody([
          const ParagraphNode(id: 'a', text: DocText('Hi')),
          const ParagraphNode(id: 'b'),
          for (var l = 1; l <= 6; l++)
            HeadingNode(id: 'h$l', level: l, text: DocText('H$l')),
        ]),
        '<p>Hi</p><p><br></p><h1>H1</h1><h2>H2</h2><h3>H3</h3>'
        '<h4>H4</h4><h5>H5</h5><h6>H6</h6>',
      );
    });

    test('divider and quotes (consecutive quotes share a blockquote)', () {
      expect(
        exportHtmlBody([
          const QuoteNode(id: 'q1', text: DocText('One')),
          const QuoteNode(id: 'q2', text: DocText('Two')),
          const DividerNode(id: 'd'),
          const QuoteNode(id: 'q3', text: DocText('Three')),
        ]),
        '<blockquote><p>One</p><p>Two</p></blockquote><hr>'
        '<blockquote><p>Three</p></blockquote>',
      );
    });

    test('lists group, nest by indent and switch kinds', () {
      expect(
        exportHtmlBody([
          const ListItemNode(id: '1', text: DocText('a')),
          const ListItemNode(id: '2', indent: 1, text: DocText('a.1')),
          const ListItemNode(
            id: '3',
            indent: 1,
            ordered: true,
            text: DocText('a.i'),
          ),
          const ListItemNode(id: '4', text: DocText('b')),
          const ListItemNode(id: '5', ordered: true, text: DocText('one')),
          const ParagraphNode(id: 'p', text: DocText('break')),
          const ListItemNode(id: '6', ordered: true, text: DocText('again')),
        ]),
        '<ul><li>a<ul><li>a.1</li></ul><ol><li>a.i</li></ol></li>'
        '<li>b</li></ul><ol><li>one</li></ol><p>break</p>'
        '<ol><li>again</li></ol>',
      );
    });

    test('an indent jump bridges with an unstyled item', () {
      expect(
        exportHtmlBody([
          const ListItemNode(id: '1', indent: 2, text: DocText('deep')),
        ]),
        '<ul><li style="list-style-type:none"><ul>'
        '<li style="list-style-type:none"><ul><li>deep</li></ul></li></ul>'
        '</li></ul>',
      );
    });

    test('tasks form one checkbox list', () {
      expect(
        exportHtmlBody([
          const TaskNode(id: '1', checked: true, text: DocText('done')),
          const TaskNode(id: '2', text: DocText('todo')),
          const ListItemNode(id: '3', text: DocText('bullet')),
        ]),
        '<ul style="list-style-type:none">'
        '<li><input type="checkbox" disabled checked> done</li>'
        '<li><input type="checkbox" disabled> todo</li></ul>'
        '<ul><li>bullet</li></ul>',
      );
    });

    test('embedded fields use the fragment html, escaped text, or nothing', () {
      const withHtml = form.ClipboardFragment(
        plainText: 'x',
        html: '<span>Ada</span>',
        data: {'type': 'textField', 'value': 'Ada'},
      );
      const plainOnly = form.ClipboardFragment(
        plainText: 'a < b\nc',
        data: {'type': 'textField', 'value': 'a < b'},
      );
      expect(
        exportHtmlBody(
          [
            const EmbeddedFieldNode(id: 'e1', fieldJson: {}),
            const EmbeddedFieldNode(id: 'e2', fieldJson: {}),
            const EmbeddedFieldNode(id: 'e3', fieldJson: {}),
          ],
          fragments: {'e1': withHtml, 'e2': plainOnly},
        ),
        '<div><span>Ada</span></div><div>a &lt; b<br>c</div>',
      );
    });
  });

  group('mark snapshots', () {
    String inline(String text, List<DocMark> marks) =>
        htmlInline(DocText(text, marks));

    test('every mark kind', () {
      expect(inline('b', [m(DocMarkType.bold, 0, 1)]), '<strong>b</strong>');
      expect(inline('i', [m(DocMarkType.italic, 0, 1)]), '<em>i</em>');
      expect(inline('u', [m(DocMarkType.underline, 0, 1)]), '<u>u</u>');
      expect(inline('s', [m(DocMarkType.strikethrough, 0, 1)]), '<s>s</s>');
      expect(
        inline('c', [m(DocMarkType.code, 0, 1)]),
        '<code style="font-family:monospace">c</code>',
      );
      expect(
        inline('l', [m(DocMarkType.link, 0, 1, 'https://x.io/?a=1&b="2"')]),
        '<a href="https://x.io/?a=1&amp;b=&quot;2&quot;">l</a>',
      );
    });

    test('overlapping marks are properly nested', () {
      // bold [0,6) italic [3,9) over "abcdefghi"
      expect(
        inline('abcdefghi', [
          m(DocMarkType.bold, 0, 6),
          m(DocMarkType.italic, 3, 9),
        ]),
        '<strong>abc<em>def</em></strong><em>ghi</em>',
      );
      // A link wraps emphasis; code is innermost.
      expect(
        inline('link code', [
          m(DocMarkType.code, 5, 9),
          m(DocMarkType.link, 0, 9, 'https://a.b'),
          m(DocMarkType.bold, 0, 4),
        ]),
        '<a href="https://a.b"><strong>link</strong> '
        '<code style="font-family:monospace">code</code></a>',
      );
    });

    test('text is escaped and line breaks become <br>', () {
      expect(
        inline('<script>&"\'\nx', const []),
        '&lt;script&gt;&amp;&quot;&#39;<br>x',
      );
    });

    test('unsafe links and out-of-range marks are dropped', () {
      expect(
        inline('click', [m(DocMarkType.link, 0, 5, 'javascript:alert(1)')]),
        'click',
      );
      expect(inline('ab', [m(DocMarkType.bold, 1, 40)]), 'a<strong>b</strong>');
    });
  });

  group('payload embedding', () {
    test('wraps the body with attribute and comment copies', () {
      const json = '{"schemaVersion":1,"nodes":[]}';
      final html = embedPayloadInHtml('<p>x</p>', json);
      final b64 = base64Url.encode(utf8.encode(json));
      expect(
        html,
        '<meta charset="utf-8"><!--championforms:$b64-->'
        '<div data-championforms="$b64"><p>x</p></div>',
      );
      expect(extractPayloadJsonFromHtml(html), [json]);
    });

    test('extraction survives a stripped attribute and ignores garbage', () {
      const json = '{"a":"ü"}';
      final b64 = base64Url.encode(utf8.encode(json));
      expect(
        extractPayloadJsonFromHtml('<div><!--championforms:$b64--><p>x</p>'),
        [json],
      );
      expect(
        extractPayloadJsonFromHtml(
          '<div data-championforms="%%%">'
          '<!--championforms:AAAA_-->',
        ),
        isEmpty,
      );
    });
  });
}
