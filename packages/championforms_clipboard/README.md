# championforms_clipboard

Multi-format system clipboard for Flutter. One clipboard item can carry several
representations at once (plain text, HTML and custom application types), so
rich content can round-trip between your app and other apps.

> **Status:** early development (`0.1.0-dev`). The web and Android backends
> are implemented; the Rust desktop/iOS backends are in progress.

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

| Format | Android | Web (Chromium) | Web (Safari, Firefox) |
|---|---|---|---|
| `plainText` | yes | yes | yes |
| `html` | yes (`ClipData.newHtmlText`) | yes | yes |
| `rtf` | no | no¹ | no¹ |
| `png` | no | yes | yes |
| `custom(name)` | no | yes, as `web application/x-<name>` | where the browser accepts it² |

1. Written only where `ClipboardItem.supports('text/rtf')` is true, which no
   mainstream browser reports today.
2. Probed with `ClipboardItem.supports()`. On browsers without it, the custom
   format is attempted; if the browser rejects the write, it is retried
   without custom formats and `supports()` reports false from then on.

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
