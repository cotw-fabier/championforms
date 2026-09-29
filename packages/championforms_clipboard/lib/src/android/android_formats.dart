// Pure (JNI-free) helpers for the Android backend, kept separate so they can
// be unit-tested on the Dart VM.

import '../api/clipboard_format.dart';

/// Formats the Android backend can write.
///
/// Android's `ClipData` carries plain text and HTML on its first item and
/// images and files as `content://` URIs served by the package's
/// `ClipboardContentProvider`. RTF and custom formats are not supported.
/// [ClipboardFormat.files] is write only (see [androidReadableFormats]).
final androidSupportedFormats = {
  ClipboardFormat.plainText,
  ClipboardFormat.html,
  ClipboardFormat.png,
  ClipboardFormat.gif,
  ClipboardFormat.files,
};

/// Formats the Android backend can read back. A pasted `content://` URI is
/// not a local path, so [ClipboardFormat.files] is not read.
final androidReadableFormats = {
  ClipboardFormat.plainText,
  ClipboardFormat.html,
  ClipboardFormat.png,
  ClipboardFormat.gif,
};

/// Subfolder of the app's cache dir that the provider serves. Must match
/// `ClipboardContentProvider.DIR`.
const androidClipboardDir = 'championforms_clipboard';

/// Suffix of the provider authority, after the application id. Must match
/// the package's `AndroidManifest.xml`.
const androidAuthoritySuffix = '.championforms_clipboard';

/// The `content://` URI string for [relativePath] (slash separated, under
/// [androidClipboardDir]), each segment percent-encoded.
String androidContentUri(String packageName, String relativePath) {
  final segments = relativePath
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(Uri.encodeComponent)
      .join('/');
  return 'content://$packageName$androidAuthoritySuffix/$segments';
}

/// The last segment of a local [path] (`/` separated), used as the display
/// name of a copied file. Never empty.
String androidBaseName(String path) {
  final parts = path.split('/').where((s) => s.isNotEmpty);
  return parts.isEmpty ? 'file' : parts.last;
}

/// Maps the MIME types of a `ClipDescription` to [ClipboardFormat]s.
///
/// `ClipData.newHtmlText` lists only `text/html`, yet every HTML item also
/// carries plain text (`ClipData.Item.getText()`), so HTML implies
/// [ClipboardFormat.plainText]. Any other `text/*` type (`text/plain`,
/// `text/uri-list`, ...) is readable as plain text through `getText()`.
/// `image/png` and `image/gif` URIs are readable as bytes; other URI types
/// (files) are not reported, since [ClipboardFormat.files] is write only.
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
    } else if (mime == 'image/png') {
      result.add(ClipboardFormat.png);
    } else if (mime == 'image/gif') {
      result.add(ClipboardFormat.gif);
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
