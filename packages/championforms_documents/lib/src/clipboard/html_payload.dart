import 'dart:convert';

import '../model/doc_clipboard_payload.dart';

/// The attribute that carries the payload on the wrapping `<div>`.
const payloadHtmlAttribute = 'data-championforms';

/// The prefix of the HTML comment that carries a second copy of the payload
/// (`<!--championforms:<base64url>-->`), for apps that strip attributes.
const payloadHtmlCommentPrefix = 'championforms:';

/// The largest base64url string worth decoding: the base64 of a payload at
/// [DocClipboardPayload.maxEncodedLength], plus padding.
const maxEncodedPayloadBase64Length =
    (DocClipboardPayload.maxEncodedLength ~/ 3 + 1) * 4 + 4;

/// Clipboard HTML at or above this length is not scanned for a payload at
/// all (two base64 copies of a maximum payload, plus generous markup).
const maxHtmlScanLength = 2 * maxEncodedPayloadBase64Length + 4 * 1024 * 1024;

/// [body] wrapped for the clipboard with the payload JSON [payloadJson]
/// embedded twice, as base64url of its UTF-8 bytes:
///
/// ```html
/// <meta charset="utf-8"><!--championforms:B64--><div data-championforms="B64">body</div>
/// ```
///
/// The attribute is the primary carrier; the comment survives apps that
/// strip unknown attributes. base64url needs no HTML escaping.
String embedPayloadInHtml(String body, String payloadJson) {
  final b64 = base64Url.encode(utf8.encode(payloadJson));
  return '<meta charset="utf-8"><!--$payloadHtmlCommentPrefix$b64-->'
      '<div $payloadHtmlAttribute="$b64">$body</div>';
}

final _attributePattern = RegExp(
  '$payloadHtmlAttribute\\s*=\\s*["\']?([A-Za-z0-9_=-]+)',
);
final _commentPattern = RegExp(
  '<!--\\s*$payloadHtmlCommentPrefix([A-Za-z0-9_=-]+)\\s*-->',
);

/// The payload JSON strings embedded in [html], attribute copy first, then
/// comment copy, without duplicates. Each is decoded from base64url and
/// UTF-8; a copy that fails to decode, or is larger than
/// [maxEncodedPayloadBase64Length], is skipped. Never throws. HTML of
/// [maxHtmlScanLength] or more yields nothing.
List<String> extractPayloadJsonFromHtml(String html) {
  if (html.length >= maxHtmlScanLength) return const [];
  final candidates = <String>[
    for (final m in _attributePattern.allMatches(html)) m[1]!,
    for (final m in _commentPattern.allMatches(html)) m[1]!,
  ];
  final seen = <String>{};
  final result = <String>[];
  for (final b64 in candidates) {
    if (b64.length > maxEncodedPayloadBase64Length || !seen.add(b64)) continue;
    try {
      result.add(utf8.decode(base64Url.decode(base64Url.normalize(b64))));
    } on FormatException {
      continue;
    }
  }
  return result;
}
