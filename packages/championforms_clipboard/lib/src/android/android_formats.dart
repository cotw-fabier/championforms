// Pure (JNI-free) helpers for the Android backend, kept separate so they can
// be unit-tested on the Dart VM.

import '../api/clipboard_format.dart';

/// Formats the Android backend can write and read.
///
/// Android's `ClipData` carries plain text and HTML on one item
/// (`ClipData.newHtmlText`). RTF, PNG (which needs a `ContentProvider` URI)
/// and custom formats are not supported.
final androidSupportedFormats = {
  ClipboardFormat.plainText,
  ClipboardFormat.html,
};

/// Maps the MIME types of a `ClipDescription` to [ClipboardFormat]s.
///
/// `ClipData.newHtmlText` lists only `text/html`, yet every HTML item also
/// carries plain text (`ClipData.Item.getText()`), so HTML implies
/// [ClipboardFormat.plainText]. Any other `text/*` type (`text/plain`,
/// `text/uri-list`, ...) is readable as plain text through `getText()`.
Set<ClipboardFormat> androidFormatsFromMimeTypes(Iterable<String> mimeTypes) {
  final result = <ClipboardFormat>{};
  for (final raw in mimeTypes) {
    final mime = raw.toLowerCase();
    if (mime == 'text/html') {
      result
        ..add(ClipboardFormat.html)
        ..add(ClipboardFormat.plainText);
    } else if (mime.startsWith('text/')) {
      result.add(ClipboardFormat.plainText);
    }
  }
  return result;
}

final _blockBreak = RegExp(
  r'<\s*(br|/p|/div|/li|/h[1-6]|/tr|/blockquote|/pre)\b[^>]*>',
  caseSensitive: false,
);
final _dropElements = RegExp(
  r'<\s*(script|style|head)\b[^>]*>.*?<\s*/\s*\1\s*>',
  caseSensitive: false,
  dotAll: true,
);
final _comment = RegExp(r'<!--.*?-->', dotAll: true);
final _tag = RegExp(r'<[^>]*>');
final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);');
final _spaces = RegExp(r'[ \t\f\r]+');
final _spaceAroundNewline = RegExp(r' *\n *');
final _manyNewlines = RegExp(r'\n{3,}');

const _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
};

/// Derives a plain-text fallback from [html].
///
/// Android requires plain text alongside HTML (`ClipData.newHtmlText`), so
/// when a [ClipboardItem] only has HTML we strip it: comments, `<script>`,
/// `<style>` and `<head>` are dropped, block-closing tags and `<br>` become
/// line breaks, other tags are removed, common entities are decoded and
/// whitespace is collapsed. This is a best-effort fallback, not an HTML
/// renderer.
String htmlToPlainText(String html) {
  var s = html.replaceAll(_comment, '').replaceAll(_dropElements, '');
  s = s.replaceAll('\r\n', '\n').replaceAll('\n', ' ');
  s = s.replaceAll(_blockBreak, '\n').replaceAll(_tag, '');
  s = s.replaceAllMapped(_entity, (m) {
    final body = m[1]!;
    int? code;
    if (body.startsWith('#x') || body.startsWith('#X')) {
      code = int.tryParse(body.substring(2), radix: 16);
    } else if (body.startsWith('#')) {
      code = int.tryParse(body.substring(1));
    } else {
      return _namedEntities[body.toLowerCase()] ?? m[0]!;
    }
    if (code == null || code > 0x10FFFF) return m[0]!;
    return String.fromCharCode(code);
  });
  return s
      .replaceAll(_spaces, ' ')
      .replaceAll(_spaceAroundNewline, '\n')
      .replaceAll(_manyNewlines, '\n\n')
      .trim();
}
