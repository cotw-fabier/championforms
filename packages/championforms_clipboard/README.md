# championforms_clipboard

Multi-format system clipboard for Flutter. One clipboard item can carry several
representations at once (plain text, HTML and custom application types), so
rich content can round-trip between your app and other apps.

> **Status:** prerelease (`0.1.0-dev`). Every backend is implemented: Rust
> native assets on macOS, iOS, Windows and Linux, `package:jni` on Android
> and the async Clipboard API on the web. macOS, iOS, Android and Chrome are
> verified at runtime; Windows and Linux are compile-checked and wait on
> their first CI integration run (see [Verified on](#verified-on)).

## Using from git (before the pub.dev release)

Until the package is on pub.dev, depend on the repository:

```yaml
dependencies:
  championforms_clipboard:
    git:
      url: https://github.com/cotw-fabier/championforms
      ref: feature/documents-monorepo
      path: packages/championforms_clipboard
```

`ref` is the branch until it merges into `main`; pin a commit SHA for
reproducible builds. No overrides are needed: this package does not depend on
`championforms`. Building for macOS, iOS, Windows or Linux needs a Rust
toolchain (`rustup`).

## Usage

```dart
import 'package:championforms_clipboard/championforms_clipboard.dart';

await SystemClipboard.write(ClipboardItem({
  ClipboardFormat.plainText: 'Hello',
  ClipboardFormat.html: '<b>Hello</b>',
}));

final read = await SystemClipboard.read();
print(read.html ?? read.plainText);

final formats = await SystemClipboard.availableFormats();
```

Formats a platform cannot carry are skipped on write
(`SystemClipboard.supports(format)` tells you up front); a write throws a
`ClipboardException` only when nothing in the item is writable. Always include
plain text as a fallback.

In tests, swap in the in-memory backend:

```dart
SystemClipboard.backend = FakeClipboardBackend();
```

## Platforms

| Platform | Backend |
|---|---|
| macOS, iOS, Windows, Linux | Rust native assets (build hook) |
| Android | `package:jni` (`ClipboardManager`) |
| Web | async Clipboard API (`package:web`) |

Building for desktop or iOS requires a Rust toolchain (`rustup`).

### Supported formats

Each `ClipboardFormat` maps to these platform identifiers. "no" means the
format is skipped on write (`SystemClipboard.supports(format)` is false) and
never reported by `availableFormats()`.

| Format | macOS / iOS | Windows | Linux (GTK 3) | Android | Web |
|---|---|---|---|---|---|
| `plainText` | `public.utf8-plain-text` | `CF_UNICODETEXT` | `text/plain;charset=utf-8`, `UTF8_STRING` | `ClipData` text | `text/plain` |
| `html` | `public.html` | registered `HTML Format` (CF_HTML) | `text/html` | `ClipData.newHtmlText` | `text/html` |
| `rtf` | `public.rtf` | registered `Rich Text Format` | `text/rtf` | no | `text/rtf`, where supported¹ |
| `png` | `public.png`³ | registered `PNG`⁴ | `image/png` | no | `image/png` |
| `custom(name)` | `<name>` as a UTI | registered format `<name>` | `application/x-<name>` | no | `web application/x-<name>`² |

1. Written only where `ClipboardItem.supports('text/rtf')` is true, which no
   mainstream browser reports today.
2. Chromium's "web custom format" syntax. Probed with
   `ClipboardItem.supports()`. On browsers without it, the custom format is
   attempted; if the browser rejects the write, it is retried without custom
   formats and `supports()` reports false from then on. Reads accept the
   unprefixed `application/x-<name>` too.
3. On macOS a pasteboard that holds only `public.tiff` (screenshots,
   Preview) is read as PNG.
4. No `CF_DIB` fallback is written, so pasting an image into older Windows
   apps that only read bitmaps may not work.

The native mapping is specified in `lib/src/ffi/ABI.md`.

### Verified on

| Platform | Result |
|---|---|
| macOS 26 | FFI round trip 7/7, stress 4/4 (`example/integration_test`; the Windows-only CF_HTML cases are skipped) |
| iOS 26.4 simulator | FFI round trip 7/7, stress 4/4 |
| Android API 36 emulator | 4/4 (`android_clipboard_test.dart`) |
| Chrome | browser tests 9/9 (`test/web_backend_browser_test.dart`), including the paste/copy event path |
| Windows | compile-checked; runtime verified by the CI integration job (pending first CI run) |
| Linux | compile-checked; runtime verified by the CI integration job (pending first CI run) |

Manual paste checks into other apps (**not yet done**):

- [ ] Google Docs (Chrome): HTML keeps headings, lists and bold; plain text
  fallback in the plain-paste shortcut.
- [ ] Microsoft Word (macOS and Windows): HTML keeps structure; RTF where
  written.
- [ ] Notion: HTML keeps headings, lists and checkboxes.

### Android

- Plain text and HTML only. Every write carries plain text: if an item has
  HTML but no plain text, a plain-text version is derived by stripping the
  tags.
- `ClipData.newHtmlText` lists only `text/html` in its description, so
  `availableFormats()` infers plain text from HTML.
- Android 10+ only lets the focused app read the clipboard, and Android 12+
  shows a "pasted from your clipboard" toast on reads.
  `availableFormats()` reads only the clip description and does not trigger
  the toast.
- Calls run on the calling isolate, which with Flutter's merged
  platform/UI thread is the Android main thread. Background isolates are not
  supported.

### Web

- The Clipboard API exists only in secure contexts (https or `localhost`).
- **Writes** need a user gesture and a focused document; otherwise they fail
  with a `ClipboardException` (`NotAllowedError`).
- **Reads** through `SystemClipboard.read()` / `availableFormats()` call
  `navigator.clipboard.read()` (falling back to `readText()`), which shows a
  permission prompt (Chromium) or a "Paste" bubble (Safari, Firefox).
- For Ctrl/Cmd+V and Ctrl/Cmd+C in an editor, handle the browser's own
  clipboard events instead. No prompt is involved, and super_editor receives
  pastes on the web this way:

  ```dart
  import 'dart:js_interop';

  import 'package:championforms_clipboard/championforms_clipboard_web.dart';
  import 'package:web/web.dart' as web;

  web.document.addEventListener('paste', (web.ClipboardEvent e) {
    final result = WebClipboardBackend.readFromPasteEvent(e);
    // result.plainText, result.html (and rtf where the source provided it)
  }.toJS);

  web.document.addEventListener('copy', (web.ClipboardEvent e) {
    WebClipboardBackend.writeToCopyEvent(e, item); // text formats only
  }.toJS);
  ```

  Event helpers carry text formats only (plain text, HTML, RTF).

This package has no dependency on `championforms` and can be used on its own.
It lives in the [championforms repository](https://github.com/cotw-fabier/championforms)
as a pub workspace member.

## Example

`example/` is a clipboard inspector: it writes each format, lists what is on
the clipboard now, and shows the last error.

## License

MIT. Portions are ported from
[super_native_extensions](https://github.com/superlistapp/super_native_extensions)
(MIT, Copyright (c) 2022 Superlist, Matej Knopp and the contributors). See
[LICENSE](LICENSE).
