# championforms_clipboard native ABI (contract)

Rust crate `championforms_clipboard_native` (in `rust/`), built by
`hook/build.dart` with `native_toolchain_rust`. Dart binds with `@Native`,
`assetId: 'package:championforms_clipboard/championforms_clipboard_native'`.
Targets: macOS, iOS, Windows, Linux. The hook returns early on every other OS.

All symbols are `#[unsafe(no_mangle)] pub extern "C"` and wrap their body in
`std::panic::catch_unwind`.

## Types

```c
typedef struct {
  const char*    format;  // NUL-terminated UTF-8 format id (see below)
  const uint8_t* data;    // may be NULL when len == 0
  size_t         len;
} CfClipEntry;

// Invoked exactly once per request, on an arbitrary thread (Dart binds it
// with NativeCallable.listener). `entries` is owned by Rust; the Dart side
// copies what it needs and then MUST call cfclip_free_entries(entries, count).
typedef void (*CfClipCallback)(int64_t req_id, int32_t status,
                               CfClipEntry* entries, size_t count);
```

## Functions

```c
// Replace clipboard contents with one item holding `count` formats.
// `entries` (and the strings/bytes they point to) are only borrowed for the
// duration of this call; Rust copies them before returning.
int32_t cfclip_write(int64_t req_id, const CfClipEntry* entries, size_t count,
                     CfClipCallback cb);

// Read the listed formats. Callback entries: one per format present
// (absent formats are simply omitted).
int32_t cfclip_read(int64_t req_id, const char* const* formats, size_t count,
                    CfClipCallback cb);

// Formats currently on the clipboard. Callback entries have data = NULL, len = 0.
int32_t cfclip_available_formats(int64_t req_id, CfClipCallback cb);

void cfclip_free_entries(CfClipEntry* entries, size_t count);

// Synchronous failures only (a non-zero return from the three calls above,
// in which case the callback is NOT invoked). Thread-local; caller frees.
char* cfclip_last_error(void);
void  cfclip_free_string(char* s);
```

## Status codes

| Code | Meaning |
|------|---------|
| 0    | success |
| -1   | invalid argument (null pointer, bad UTF-8, unknown format id) |
| -2   | platform clipboard unavailable / could not be opened |
| -3   | platform error during write or read |
| -999 | panic caught |

For an asynchronous failure the callback gets `status < 0` and exactly one
entry whose `format` is `"error"` and whose `data` is the UTF-8 message.

## Format ids and platform mapping (implemented in Rust, `cargo test`ed)

| Id | macOS / iOS | Windows | Linux (GTK target) |
|----|-------------|---------|--------------------|
| `text/plain` | `public.utf8-plain-text` | `CF_UNICODETEXT` (UTF-16, NUL-terminated) | `text/plain;charset=utf-8`, `UTF8_STRING` |
| `text/html`  | `public.html` | registered `HTML Format` (CF_HTML header with byte offsets) | `text/html` |
| `text/rtf`   | `public.rtf` | registered `Rich Text Format` | `text/rtf` |
| `image/png`  | `public.png` | registered `PNG` | `image/png` |
| `custom:<n>` | `<n>` as UTI | registered format `<n>` | `application/x-<n>` |

## Threading

- Apple: run inline when already on the main thread (`pthread_main_np()`),
  otherwise `dispatch_async` to the main queue.
- Windows: a dedicated clipboard thread owning a message-only HWND
  (`OpenClipboard(NULL)` would make `SetClipboardData` fail). No OLE.
- Linux: marshal to the default GLib main context with `g_main_context_invoke`;
  GTK3 is declared with hand-written `extern "C"` (no gtk-rs crates).
