import 'package:championforms_clipboard/championforms_clipboard.dart';
import 'package:championforms_clipboard/src/android/android_formats.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('htmlToPlainText', () {
    test('strips inline tags', () {
      expect(htmlToPlainText('<b>Hello</b> <i>world</i>'), 'Hello world');
    });

    test('block tags and <br> become line breaks', () {
      expect(
        htmlToPlainText(
          '<p>One</p><p>Two<br>Three</p><ul><li>a</li>'
          '<li>b</li></ul><h1>T</h1>',
        ),
        'One\nTwo\nThree\na\nb\nT',
      );
    });

    test('decodes entities', () {
      expect(
        htmlToPlainText(
          'a &amp; b &lt;c&gt; &quot;d&quot; &#39;e&#39; '
          '&#x263A; &nbsp;f &unknown;',
        ),
        'a & b <c> "d" \'e\' ☺ f &unknown;',
      );
    });

    test('drops comments, script, style and head', () {
      expect(
        htmlToPlainText(
          '<html><head><title>t</title></head><body>'
          '<!-- c --><style>p{}</style><script>x()</script>Body</body>'
          '</html>',
        ),
        'Body',
      );
    });

    test('collapses whitespace and source newlines', () {
      expect(htmlToPlainText('  a\n   b\t\tc  '), 'a b c');
      expect(htmlToPlainText('<p>a</p>\n\n\n<p>b</p>'), 'a\nb');
      expect(htmlToPlainText('<div>a</div><br><br><br><br>b'), 'a\n\nb');
    });

    test('plain text passes through', () {
      expect(htmlToPlainText('just text'), 'just text');
      expect(htmlToPlainText(''), '');
    });
  });

  group('androidFormatsFromMimeTypes', () {
    test('text/html implies plain text', () {
      expect(androidFormatsFromMimeTypes(['text/html']), {
        ClipboardFormat.html,
        ClipboardFormat.plainText,
      });
    });

    test('other text types read as plain text', () {
      expect(androidFormatsFromMimeTypes(['text/plain']), {
        ClipboardFormat.plainText,
      });
      expect(androidFormatsFromMimeTypes(['text/uri-list']), {
        ClipboardFormat.plainText,
      });
      expect(androidFormatsFromMimeTypes(['TEXT/HTML']), {
        ClipboardFormat.html,
        ClipboardFormat.plainText,
      });
    });

    test('non-text types are ignored', () {
      expect(androidFormatsFromMimeTypes(['image/png']), isEmpty);
      expect(androidFormatsFromMimeTypes(['image/png', 'text/plain']), {
        ClipboardFormat.plainText,
      });
      expect(androidFormatsFromMimeTypes([]), isEmpty);
    });

    test('supported set is plain text and HTML only', () {
      expect(androidSupportedFormats, {
        ClipboardFormat.plainText,
        ClipboardFormat.html,
      });
    });
  });
}
