/// Multi-format system clipboard for Flutter.
///
/// Reads and writes several representations of one clipboard item at once
/// (plain text, HTML and custom application types) on macOS, iOS, Windows,
/// Linux, Android and the web. Desktop and iOS backends are Rust native
/// assets; Android uses `package:jni`; the web uses the async Clipboard API.
///
/// This package has no dependency on `championforms` and can be used on its
/// own. The API lands in a later development release.
library;
