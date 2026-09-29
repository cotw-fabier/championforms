# Changelog

## 0.1.0-dev.2

- `ClipboardFormat.gif` (`image/gif`, `Uint8List`): `com.compuserve.gif` on
  macOS and iOS, a registered `GIF` format on Windows, `image/gif` on Linux,
  a `content://` URI on Android. Not supported on the web.
- `ClipboardFormat.files`: local file paths as a non-empty `List<String>`
  (`ClipboardItem` validates and copies it; `ClipboardReadResult.files`
  reads it; `ClipboardFormat.isFiles`). macOS writes one `public.file-url`
  pasteboard item per file and reads them back; Windows writes and reads
  `CF_HDROP`; Linux writes `text/uri-list` and
  `x-special/gnome-copied-files` and reads `text/uri-list`; Android writes
  `content://` URIs (write only). Not supported on iOS or the web. On the
  FFI boundary the value is the UTF-8 paths joined by NUL.
- Android: PNG, GIF and files. The package is now a Flutter plugin on
  Android only: its module merges a read-only `ClipboardContentProvider`
  (authority `<applicationId>.championforms_clipboard`) into the app's
  manifest. Writes copy images and files into
  `<cacheDir>/championforms_clipboard/`, clearing the previous write's files,
  and are serialised. PNG and GIF are read back from any app's image URI.
- `FakeClipboardBackend(writeOnly: ...)` imitates a write-only format.
- **Breaking:** `ClipboardFormatKind` gains `gif` and `files`; exhaustive
  switches over it need the new cases.
- Rust: `ClipError::Unavailable` no longer trips `dead_code` on Apple
  targets (clippy `-D warnings` was failing there).

## 0.1.0-dev.1

- Initial package skeleton inside the championforms monorepo.
- Web backend (`WebClipboardBackend`): async Clipboard API for plain text,
  HTML, PNG and `web application/x-<name>` custom formats, with a
  `readText()` fallback. Adds `readFromPasteEvent`/`writeToCopyEvent` helpers
  for DOM clipboard events, exported from `championforms_clipboard_web.dart`.
- Android backend (`AndroidClipboardBackend`): `ClipboardManager` via
  `package:jni` for plain text and HTML. Plain text is derived from HTML
  when missing and inferred in `availableFormats()`.
- Native backend (`FfiClipboardBackend`) for macOS, iOS, Windows and Linux:
  a Rust crate built as a native asset by `hook/build.dart` (requires
  `rustup`), called through a small C ABI (`lib/src/ffi/ABI.md`). Every call
  is asynchronous and works from any isolate.
  - Apple: `NSPasteboard` / `UIPasteboard`, run on the main thread. macOS
    reads a TIFF-only pasteboard as PNG.
  - Windows: Win32 clipboard on a dedicated thread with a message-only
    window; HTML as CF_HTML. No `CF_DIB` fallback is written for PNG.
  - Linux: GTK 3 on the GLib main context, with a 2 s read timeout.
  - Custom formats map to a `<name>` UTI (Apple), a registered format
    `<name>` (Windows) and `application/x-<name>` (Linux).
- Clipboard inspector example app; FFI round-trip, stress and Android
  integration tests. Verified on macOS 26, the iOS 26.4 simulator, an
  Android API 36 emulator and Chrome; Windows and Linux are compile-checked
  and verified by CI integration jobs.
