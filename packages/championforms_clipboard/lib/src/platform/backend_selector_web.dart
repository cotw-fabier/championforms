import '../api/clipboard_backend.dart';
import '../web/web_clipboard_backend.dart';

ClipboardBackend createPlatformBackend() => WebClipboardBackend();
