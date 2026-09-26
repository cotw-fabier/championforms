/// Handwritten `@Native` bindings for the Rust clipboard backend.
///
/// The C ABI is specified in `ABI.md` next to this file. The asset id must
/// match the Cargo package name and the hook's `assetName`.
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';

const _asset = 'package:championforms_clipboard/championforms_clipboard_native';

/// `CfClipEntry`: one format and its bytes.
final class CfClipEntry extends Struct {
  /// NUL-terminated UTF-8 format id (`text/plain`, `custom:<name>`, ...).
  external Pointer<Utf8> format;

  /// May be null when [len] is 0.
  external Pointer<Uint8> data;

  @Size()
  external int len;
}

/// `CfClipCallback`: invoked exactly once per request, on any thread.
typedef CfClipCallback = Void Function(
  Int64 reqId,
  Int32 status,
  Pointer<CfClipEntry> entries,
  Size count,
);

typedef CfClipCallbackPointer = Pointer<NativeFunction<CfClipCallback>>;

@Native<Int32 Function(Int64, Pointer<CfClipEntry>, Size, CfClipCallbackPointer)>(
  symbol: 'cfclip_write',
  assetId: _asset,
)
external int cfclipWrite(
  int reqId,
  Pointer<CfClipEntry> entries,
  int count,
  CfClipCallbackPointer cb,
);

@Native<Int32 Function(Int64, Pointer<Pointer<Utf8>>, Size, CfClipCallbackPointer)>(
  symbol: 'cfclip_read',
  assetId: _asset,
)
external int cfclipRead(
  int reqId,
  Pointer<Pointer<Utf8>> formats,
  int count,
  CfClipCallbackPointer cb,
);

@Native<Int32 Function(Int64, CfClipCallbackPointer)>(
  symbol: 'cfclip_available_formats',
  assetId: _asset,
)
external int cfclipAvailableFormats(int reqId, CfClipCallbackPointer cb);

@Native<Void Function(Pointer<CfClipEntry>, Size)>(
  symbol: 'cfclip_free_entries',
  assetId: _asset,
)
external void cfclipFreeEntries(Pointer<CfClipEntry> entries, int count);

@Native<Pointer<Utf8> Function()>(symbol: 'cfclip_last_error', assetId: _asset)
external Pointer<Utf8> cfclipLastError();

@Native<Void Function(Pointer<Utf8>)>(
  symbol: 'cfclip_free_string',
  assetId: _asset,
)
external void cfclipFreeString(Pointer<Utf8> s);
