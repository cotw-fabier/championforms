import 'dart:io' show Platform;

import '../android/android_clipboard_backend.dart';
import '../api/clipboard_backend.dart';
import '../ffi/ffi_clipboard_backend.dart';

ClipboardBackend createPlatformBackend() => Platform.isAndroid
    ? AndroidClipboardBackend()
    : FfiClipboardBackend();
