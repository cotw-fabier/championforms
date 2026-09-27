/// Web-only additions to `championforms_clipboard`.
///
/// Import this library only from web code (it depends on `package:web` and
/// `dart:js_interop`). It exposes [WebClipboardBackend] and its DOM event
/// helpers, [WebClipboardBackend.readFromPasteEvent] and
/// [WebClipboardBackend.writeToCopyEvent], which let an editor handle the
/// browser's own `paste`/`copy`/`cut` events without the permission prompt
/// that `navigator.clipboard.read()` triggers.
library;

import 'src/web/web_clipboard_backend.dart';

export 'championforms_clipboard.dart';
export 'src/web/web_clipboard_backend.dart';
export 'src/web/web_formats.dart' show webMimeTypeFor, webFormatForMimeType;
