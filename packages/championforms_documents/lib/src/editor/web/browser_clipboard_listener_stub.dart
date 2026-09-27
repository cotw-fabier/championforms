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
