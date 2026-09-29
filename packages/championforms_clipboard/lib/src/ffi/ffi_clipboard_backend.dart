import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../api/clipboard_backend.dart';
import '../api/clipboard_format.dart';
import '../api/clipboard_item.dart';
import 'bindings.dart';

/// [ClipboardBackend] for macOS, iOS, Windows and Linux, backed by the Rust
/// native asset (see `ABI.md`).
///
/// Every call is asynchronous: Rust hops to the platform's clipboard thread
/// and completes through one long-lived [NativeCallable.listener] per
/// isolate, which routes each completion to its request by `req_id`. It
/// works from any isolate, including background ones.
///
/// Every format is supported on all four platforms except
/// [ClipboardFormat.files] on iOS (`UIPasteboard` has no file references).
class FfiClipboardBackend implements ClipboardBackend {
  @override
  bool supports(ClipboardFormat format) =>
      _nativePlatform && !(format.isFiles && Platform.isIOS);

  static final bool _nativePlatform =
      Platform.isMacOS ||
      Platform.isIOS ||
      Platform.isWindows ||
      Platform.isLinux;

  @override
  Future<void> write(ClipboardItem item) async {
    final values = {
      for (final e in item.values.entries)
        if (supports(e.key)) e.key: _encode(e.key, e.value),
    };
    if (values.isEmpty) {
      throw const ClipboardException('No writable format in item');
    }
    await _call((reqId, cb) {
      final arena = Arena();
      try {
        final entries = arena<CfClipEntry>(values.length);
        var i = 0;
        for (final MapEntry(key: format, value: bytes) in values.entries) {
          final entry = (entries + i++).ref
            ..format = format.id.toNativeUtf8(allocator: arena)
            ..len = bytes.length
            ..data = nullptr;
          if (bytes.isNotEmpty) {
            final buf = arena<Uint8>(bytes.length);
            buf.asTypedList(bytes.length).setAll(0, bytes);
            entry.data = buf;
          }
        }
        return cfclipWrite(reqId, entries, values.length, cb);
      } finally {
        // Rust copies everything before cfclip_write returns.
        arena.releaseAll();
      }
    });
  }

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) async {
    final wanted = (formats ?? (await availableFormats()).toList())
        .where(supports)
        .toList();
    if (wanted.isEmpty) return ClipboardReadResult.empty;
    final entries = await _call((reqId, cb) {
      final arena = Arena();
      try {
        final ids = arena<Pointer<Utf8>>(wanted.length);
        for (var i = 0; i < wanted.length; i++) {
          ids[i] = wanted[i].id.toNativeUtf8(allocator: arena);
        }
        return cfclipRead(reqId, ids, wanted.length, cb);
      } finally {
        arena.releaseAll();
      }
    });
    final values = <ClipboardFormat, Object>{};
    for (final (id, bytes) in entries) {
      final format = _parseFormat(id);
      if (format == null) continue;
      if (format.isFiles) {
        final paths = decodePaths(bytes);
        if (paths.isNotEmpty) values[format] = paths;
      } else {
        values[format] = format.isText
            ? utf8.decode(bytes, allowMalformed: true)
            : bytes;
      }
    }
    return ClipboardReadResult(values);
  }

  @override
  Future<Set<ClipboardFormat>> availableFormats() async {
    final entries = await _call(cfclipAvailableFormats);
    return {for (final (id, _) in entries) ?_parseFormat(id)};
  }

  static Uint8List _encode(ClipboardFormat format, Object value) {
    if (format.isFiles) return encodePaths(value as List<String>);
    return format.isText ? utf8.encode(value as String) : value as Uint8List;
  }

  /// The ABI encoding of a file list: UTF-8 paths separated by NUL (no path
  /// can contain NUL on any platform).
  static Uint8List encodePaths(List<String> paths) =>
      utf8.encode(paths.join('\x00'));

  /// Inverse of [encodePaths]; empty segments are dropped.
  static List<String> decodePaths(Uint8List bytes) => List.unmodifiable(
    utf8
        .decode(bytes, allowMalformed: true)
        .split('\x00')
        .where((p) => p.isNotEmpty),
  );

  static ClipboardFormat? _parseFormat(String id) {
    try {
      return ClipboardFormat.fromId(id);
    } on ArgumentError {
      return null;
    }
  }

  // ---------------------------------------------------------------------
  // Request routing. Statics are per isolate, so each isolate gets its own
  // callable and pending table.

  static int _nextReqId = 1;
  static final _pending = <int, Completer<List<(String, Uint8List)>>>{};
  static NativeCallable<CfClipCallback>? _callable;

  static NativeCallable<CfClipCallback> get _listener =>
      _callable ??= NativeCallable<CfClipCallback>.listener(_onComplete)
        ..keepIsolateAlive = false;

  /// Registers a request, runs [start] (which makes the synchronous FFI
  /// call and returns its status) and waits for the callback.
  ///
  /// The callable keeps the isolate alive only while requests are pending,
  /// so an idle clipboard never blocks isolate shutdown.
  static Future<List<(String, Uint8List)>> _call(
    int Function(int reqId, CfClipCallbackPointer cb) start,
  ) {
    final reqId = _nextReqId++;
    final completer = Completer<List<(String, Uint8List)>>();
    final listener = _listener;
    _pending[reqId] = completer;
    listener.keepIsolateAlive = true;
    final int status;
    try {
      status = start(reqId, listener.nativeFunction);
    } catch (_) {
      _settle(reqId);
      rethrow;
    }
    if (status != 0) {
      // The callback is not invoked for a synchronous failure.
      _settle(reqId);
      throw ClipboardException(_takeLastError(), code: status);
    }
    return completer.future;
  }

  static Completer<List<(String, Uint8List)>>? _settle(int reqId) {
    final completer = _pending.remove(reqId);
    if (_pending.isEmpty) _callable?.keepIsolateAlive = false;
    return completer;
  }

  static void _onComplete(
    int reqId,
    int status,
    Pointer<CfClipEntry> entries,
    int count,
  ) {
    // Copy everything out, then always hand the buffers back to Rust.
    List<(String, Uint8List)> copied = const [];
    Object? copyError;
    try {
      copied = [for (var i = 0; i < count; i++) _copyEntry((entries + i).ref)];
    } catch (e) {
      copyError = e;
    } finally {
      cfclipFreeEntries(entries, count);
    }
    final completer = _settle(reqId);
    if (completer == null) return;
    if (copyError != null) {
      completer.completeError(
        ClipboardException('bad clipboard reply: $copyError', code: status),
      );
    } else if (status < 0) {
      final message =
          copied
              .where((e) => e.$1 == 'error')
              .map((e) => utf8.decode(e.$2, allowMalformed: true))
              .firstOrNull ??
          'clipboard operation failed';
      completer.completeError(ClipboardException(message, code: status));
    } else {
      completer.complete(copied);
    }
  }

  static (String, Uint8List) _copyEntry(CfClipEntry e) => (
    e.format == nullptr ? '' : e.format.toDartString(),
    e.data == nullptr || e.len == 0
        ? Uint8List(0)
        : Uint8List.fromList(e.data.asTypedList(e.len)),
  );

  static String _takeLastError() {
    final p = cfclipLastError();
    if (p == nullptr) return 'unknown clipboard error';
    try {
      return p.toDartString();
    } finally {
      cfclipFreeString(p);
    }
  }
}
