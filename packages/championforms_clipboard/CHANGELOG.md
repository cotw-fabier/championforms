# Changelog

## 0.1.0-dev.1

- Initial package skeleton inside the championforms monorepo.
- Web backend (`WebClipboardBackend`): async Clipboard API for plain text,
  HTML, PNG and `web application/x-<name>` custom formats, with a
  `readText()` fallback. Adds `readFromPasteEvent`/`writeToCopyEvent` helpers
  for DOM clipboard events, exported from `championforms_clipboard_web.dart`.
- Android backend (`AndroidClipboardBackend`): `ClipboardManager` via
  `package:jni` for plain text and HTML. Plain text is derived from HTML
  when missing and inferred in `availableFormats()`.
- Clipboard inspector example app and an Android integration test.
