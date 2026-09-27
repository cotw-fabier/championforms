// Pure (browser-free) format mapping for the web backend, kept separate so it
// can be unit-tested on the Dart VM.

import '../api/clipboard_format.dart';

/// Prefix the async Clipboard API requires for custom ("web custom") formats.
const webCustomPrefix = 'web ';

/// The MIME type [format] is written as with `navigator.clipboard.write`.
///
/// Built-in formats use their own MIME type. Custom formats become
/// `web application/x-<name>`, Chromium's "web custom format" syntax; the
/// browser keeps them out of the sanitized native clipboard and only other
/// web pages (or native apps that look for the prefixed type) can read them.
String webMimeTypeFor(ClipboardFormat format) => switch (format.kind) {
  ClipboardFormatKind.custom =>
    '${webCustomPrefix}application/x-${format.customName}',
  _ => format.id,
};

/// The [ClipboardFormat] for a MIME type reported by the browser, or null
/// when it is not one this package models.
///
/// Accepts both the `web `-prefixed custom type and the unprefixed
/// `application/x-<name>` form (some browsers report types without the
/// prefix, and `DataTransfer` in copy/paste events never has it).
ClipboardFormat? webFormatForMimeType(String mimeType) {
  var type = mimeType.trim();
  final isWebCustom = type.startsWith(webCustomPrefix);
  if (isWebCustom) type = type.substring(webCustomPrefix.length).trim();
  final lower = type.toLowerCase();
  // Strip parameters such as `text/plain;charset=utf-8`.
  final base = lower.split(';').first.trim();
  if (!isWebCustom) {
    switch (base) {
      case 'text/plain':
        return ClipboardFormat.plainText;
      case 'text/html':
        return ClipboardFormat.html;
      case 'text/rtf':
      case 'application/rtf':
        return ClipboardFormat.rtf;
      case 'image/png':
        return ClipboardFormat.png;
    }
  }
  if (base.startsWith('application/x-') && base.length > 14) {
    final name = type
        .split(';')
        .first
        .trim()
        .substring('application/x-'.length);
    if (name.contains(RegExp(r'\s'))) return null;
    return ClipboardFormat.custom(name);
  }
  return null;
}
