import '../model/doc_text.dart';

final _scheme = RegExp(r'^([A-Za-z][A-Za-z0-9+.\-]*):');
const _safeSchemes = {'http', 'https', 'mailto', 'tel'};

// Control characters and whitespace browsers ignore inside a URL scheme
// (`java\tscript:` still runs), removed before the scheme check.
final _schemeNoise = RegExp(r'[\u0000- \u007f-\u009f]');

/// [href] if it is safe to keep as a link target, else null.
///
/// Allows `http`, `https`, `mailto` and `tel` URLs and scheme-less
/// (relative or fragment) references. Everything else, notably
/// `javascript:`, `data:`, `vbscript:` and `file:`, is rejected: pasted
/// links come from untrusted HTML and payloads and may later be opened.
String? safeHref(String? href) {
  if (href == null) return null;
  final trimmed = href.trim();
  if (trimmed.isEmpty) return null;
  final probe = trimmed.replaceAll(_schemeNoise, '');
  final match = _scheme.firstMatch(probe);
  if (match == null) return trimmed; // relative or fragment reference
  return _safeSchemes.contains(match[1]!.toLowerCase()) ? trimmed : null;
}

/// [text] with every mark clipped to the text, empty marks dropped, and
/// link marks with an unsafe [safeHref] dropped.
///
/// Pasted payloads are untrusted: a mark may point past the end of its text
/// or carry a `javascript:` link.
DocText sanitizeDocText(DocText text) {
  final length = text.text.length;
  final marks = <DocMark>[];
  for (final m in text.marks) {
    final start = m.start.clamp(0, length);
    final end = m.end.clamp(0, length);
    if (end <= start) continue;
    String? href;
    if (m.type == DocMarkType.link) {
      href = safeHref(m.href);
      if (href == null) continue;
    }
    marks.add(DocMark(type: m.type, start: start, end: end, href: href));
  }
  return DocText(text.text, marks);
}
