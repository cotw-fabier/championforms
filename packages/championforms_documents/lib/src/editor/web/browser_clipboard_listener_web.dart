import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'clipboard_events.dart';

const bool browserClipboardEventsSupported = true;

/// Capture-phase `copy` / `cut` / `paste` listeners on the window. While
/// the editor is active they cancel the browser's default action (which
/// would otherwise insert plain text through Flutter's hidden input) and
/// hand the event to the editor.
class PlatformBrowserClipboardListener implements BrowserClipboardListener {
  PlatformBrowserClipboardListener({
    required this.isActive,
    required this.onEvent,
  }) {
    for (final action in BrowserClipboardAction.values) {
      final listener = ((web.Event event) {
        if (!isActive()) return;
        event.preventDefault();
        event.stopPropagation();
        onEvent(action, event);
      }).toJS;
      _listeners[action] = listener;
      web.window.addEventListener(action.name, listener, true.toJS);
    }
  }

  final bool Function() isActive;
  final void Function(BrowserClipboardAction action, Object event) onEvent;
  final Map<BrowserClipboardAction, JSFunction> _listeners = {};

  @override
  void dispose() {
    for (final e in _listeners.entries) {
      web.window.removeEventListener(e.key.name, e.value, true.toJS);
    }
    _listeners.clear();
  }
}
