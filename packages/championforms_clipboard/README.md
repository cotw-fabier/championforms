# championforms_clipboard

Multi-format system clipboard for Flutter. One clipboard item can carry several
representations at once (plain text, HTML and custom application types), so
rich content can round-trip between your app and other apps.

> **Status:** early development (`0.1.0-dev`). The API is not available yet.

## Platforms

| Platform | Backend |
|---|---|
| macOS, iOS, Windows, Linux | Rust native assets (build hook) |
| Android | `package:jni` (`ClipboardManager`) |
| Web | async Clipboard API (`package:web`) |

Building for desktop or iOS requires a Rust toolchain (`rustup`).

This package has no dependency on `championforms` and can be used on its own.
It lives in the [championforms repository](https://github.com/cotw-fabier/championforms)
as a pub workspace member.

## License

MIT. Portions are ported from
[super_native_extensions](https://github.com/superlistapp/super_native_extensions)
(MIT, Copyright (c) 2022 Superlist, Matej Knopp and the contributors). See
[LICENSE](LICENSE).
