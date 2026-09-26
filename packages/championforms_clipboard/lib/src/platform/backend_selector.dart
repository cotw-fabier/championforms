import '../api/clipboard_backend.dart';
import 'backend_selector_io.dart'
    if (dart.library.js_interop) 'backend_selector_web.dart' as impl;

/// The backend for the current platform: web → Clipboard API, Android →
/// JNI, macOS/iOS/Windows/Linux → Rust FFI.
ClipboardBackend createDefaultBackend() => impl.createPlatformBackend();
