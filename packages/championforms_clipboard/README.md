# championforms_clipboard

Multi-format system clipboard for Flutter. One clipboard item can carry several
representations at once (plain text, HTML, images, local files and custom
application types), so rich content can round-trip between your app and other
apps.

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
toolchain (`rustup`). On Android the package is a Flutter plugin: its module
adds a `ContentProvider` to your app's manifest (see [Android](#android));
nothing needs to be added by hand.

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

// Images and files (check support first: see the table below).
if (SystemClipboard.supports(ClipboardFormat.files)) {
  await SystemClipboard.write(ClipboardItem({
    ClipboardFormat.files: ['/path/to/clip.mp4'],
    ClipboardFormat.plainText: 'clip.mp4',
  }));
}
await SystemClipboard.write(ClipboardItem({ClipboardFormat.gif: gifBytes}));
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
| Android | `package:jni` (`ClipboardManager`), plus a plugin module that ships a `ContentProvider` for images and files |
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
| `png` | `public.png`³ | registered `PNG`⁴ | `image/png` | `content://` URI⁵ | `image/png` |
| `gif` | `com.compuserve.gif` | registered `GIF` | `image/gif` | `content://` URI⁵ | no |
| `files` | macOS: `public.file-url`, one pasteboard item per file⁶; iOS: no | `CF_HDROP` | `text/uri-list`, `x-special/gnome-copied-files` | `content://` URIs⁵, write only⁷ | no |
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
5. The bytes or files are copied into the app's cache and put on the clip as
   URIs served by the package's own provider. See [Android](#android).
6. Paths read back on macOS are in the file system's decomposed (NFD) form,
   so a path with accented letters may not compare equal to the one written,
   though it names the same file.
7. `supports(ClipboardFormat.files)` is true on Android, but a read never
   returns files: a pasted `content://` URI is not a local path. Every other
   supported format reads back.

`files` values are absolute local paths (`List<String>`). What the other side
does with them is up to it: Finder, Explorer and GNOME file managers paste
copies of the files; chat and mail apps attach them.

The native mapping is specified in `lib/src/ffi/ABI.md`.

### Verified on

| Platform | Result |
|---|---|
| macOS 26 | FFI round trip 9/9 (including GIF and file lists), stress 4/4 (`example/integration_test`; the Windows-only CF_HTML cases are skipped) |
| iOS 26.4 simulator | FFI round trip 7/7, stress 4/4 (before GIF was added; GIF on iOS not yet run) |
| Android API 36 emulator | 9/9 (`android_clipboard_test.dart`, including PNG, GIF, text plus image, and files served through the provider) |
| Chrome | browser tests 10/10 (`test/web_backend_browser_test.dart`), including the paste/copy event path |
| Windows | compile-checked (`cargo clippy --target x86_64-pc-windows-msvc`), including GIF and `CF_HDROP`; runtime verified by the CI integration job (pending first CI run) |
| Linux | compile-checked (`cargo clippy --target x86_64-unknown-linux-gnu`), including GIF and file lists; runtime verified by the CI integration job (pending first CI run) |

Manual paste checks into other apps (**not yet done**):

- [ ] Google Docs (Chrome): HTML keeps headings, lists and bold; plain text
  fallback in the plain-paste shortcut.
- [ ] Microsoft Word (macOS and Windows): HTML keeps structure; RTF where
  written.
- [ ] Notion: HTML keeps headings, lists and checkboxes.
- [ ] Finder (macOS), Explorer (Windows), Nautilus (Linux): a copied file
  list pastes as copies of the files.
- [ ] Android: a copied PNG, GIF and video paste into another app (Messages,
  Gboard's clipboard, a chat app) through the provider's read grant.

### Android

- Plain text, HTML, PNG, GIF and files. When an item has HTML but no plain
  text, a plain-text version is derived by stripping the tags.
- Images and files go on the clip as `content://` URIs. A write copies them
  into `<cacheDir>/championforms_clipboard/` and the package's
  `ClipboardContentProvider` (authority
  `<applicationId>.championforms_clipboard`, not exported, read only,
  `grantUriPermissions`) serves them; the clipboard gives the pasting app a
  temporary read grant. The first URI shares the clip's first item with the
  text and HTML, each further one gets its own item, and the clip
  description lists every MIME type. Each write first deletes what the
  previous write left in that folder, so the cache holds at most one clip.
  Copying a large video takes as long as the copy does.
- The provider is merged into your app's manifest by this package's plugin
  module; you add nothing. It is its own class, so it cannot collide with an
  app's `androidx.core.content.FileProvider` or another plugin's.
- Files are write only (a pasted URI is not a local path); PNG and GIF read
  back from any app's `image/png` / `image/gif` URI.
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

`example/` is a clipboard inspector: it writes each format (including an
animated GIF and a one-file list), lists what is on the clipboard now, and
shows the last error.

## License

MIT. Portions are ported from
[super_native_extensions](https://github.com/superlistapp/super_native_extensions)
(MIT, Copyright (c) 2022 Superlist, Matej Knopp and the contributors). See
[LICENSE](LICENSE).
