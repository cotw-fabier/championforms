import 'package:championforms_clipboard/championforms_clipboard.dart';

import 'browser_clipboard_listener_stub.dart'
    if (dart.library.js_interop) 'browser_clipboard_listener_web.dart'
    as impl;

/// The browser clipboard events the editor handles on the web.
enum BrowserClipboardAction { copy, cut, paste }

/// Access to the browser `ClipboardEvent` being handled, for a
/// `DocClipboardDelegate` running on the web.
///
/// On the web the browser owns the clipboard: its data can only be read in
/// a `paste` event and written in a `copy`/`cut` event, synchronously. So on
/// the web the editor does not handle Cmd/Ctrl+C/X/V itself; it lets the
/// browser raise the event, cancels the browser's default handling and
/// calls the delegate **while the event is being dispatched**. During that
/// synchronous call [current] is the event (a `package:web`
/// `ClipboardEvent`, typed as [Object] so this library stays
/// platform-neutral). A delegate reads it before its first `await`:
///
/// ```dart
/// final event = DocClipboardEvents.current; // null off the web
/// if (event is web.ClipboardEvent) {
///   final read = WebClipboardBackend.readFromPasteEvent(event);
///   ...
/// }
/// ```
///
/// Everywhere else [current] is always null.
abstract final class DocClipboardEvents {
  static Object? _current;

  /// The event being dispatched, or null.
  static Object? get current => _current;

  /// Runs [body] with [current] set to [event].
  static T run<T>(Object event, T Function() body) {
    final previous = _current;
    _current = event;
    try {
      return body();
    } finally {
      _current = previous;
    }
  }
}

/// Listens for browser copy/cut/paste events while `isActive` says the
/// editor owns the keyboard. A no-op off the web.
abstract class BrowserClipboardListener {
  factory BrowserClipboardListener({
    required bool Function() isActive,
    required void Function(BrowserClipboardAction action, Object event) onEvent,
  }) = impl.PlatformBrowserClipboardListener;

  /// Whether this platform delivers browser clipboard events (the web).
  static bool get supported => impl.browserClipboardEventsSupported;

  void dispose();
}

/// The text formats of a browser `paste` event (null off the web).
ClipboardReadResult? readBrowserPasteEvent(Object event) =>
    impl.readFromPasteEvent(event);

/// Writes [item]'s text formats into a browser `copy` / `cut` event
/// (false off the web).
bool writeBrowserCopyEvent(Object event, ClipboardItem item) =>
    impl.writeToCopyEvent(event, item);
