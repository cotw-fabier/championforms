import 'package:championforms_clipboard/championforms_clipboard.dart';

import 'clipboard_events.dart';

const bool browserClipboardEventsSupported = false;

class PlatformBrowserClipboardListener implements BrowserClipboardListener {
  PlatformBrowserClipboardListener({
    required bool Function() isActive,
    required void Function(BrowserClipboardAction action, Object event)
    onEvent,
  });

  @override
  void dispose() {}
}

ClipboardReadResult? readFromPasteEvent(Object event) => null;

bool writeToCopyEvent(Object event, ClipboardItem item) => false;
