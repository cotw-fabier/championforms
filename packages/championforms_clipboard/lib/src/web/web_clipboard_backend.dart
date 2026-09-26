// Web clipboard backend (async Clipboard API via package:web).
//
// Portions ported from super_native_extensions
// (super_native_extensions/lib/src/web/clipboard_writer.dart,
// clipboard_reader.dart, reader.dart and js_interop.dart),
// MIT License, Copyright (c) 2022 Superlist, Matej Knopp and the
// contributors. See the package LICENSE.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../api/clipboard_backend.dart';
import '../api/clipboard_format.dart';
import '../api/clipboard_item.dart';
import 'web_formats.dart';

/// Web clipboard through the async Clipboard API (`navigator.clipboard`).
///
/// **Writing** puts one `ClipboardItem` on the clipboard with a `Blob` per
/// format: `text/plain`, `text/html`, `image/png` and custom formats as
/// `web application/x-<name>` (Chromium's "web custom formats"). Support is
/// probed with `ClipboardItem.supports()` where the browser has it. Where it
/// does not, custom formats are attempted and, if the browser rejects the
/// write, it is retried without them and [supports] reports false for custom
/// formats from then on. Without `ClipboardItem` at all, only plain text is
/// written (`writeText`). RTF is written only where `supports('text/rtf')`
/// is true, which no mainstream browser reports today.
///
/// Browsers only allow writes during (or shortly after) a user gesture and
/// while the document has focus; otherwise the write fails with a
/// [ClipboardException].
///
/// **Reading** with [read] or [availableFormats] uses
/// `navigator.clipboard.read()` and falls back to `readText()` for plain
/// text. Browsers guard both behind a permission prompt (Chromium) or a
/// "Paste" confirmation bubble (Safari, Firefox). An editor that reacts to
/// Ctrl/Cmd+V should instead listen for the DOM `paste` event and use
/// [readFromPasteEvent], which reads the event's `clipboardData` without any
/// prompt. That is how super_editor receives pastes on the web. Likewise,
/// [writeToCopyEvent] fills a `copy`/`cut` event's `clipboardData`.
///
/// The Clipboard API exists only in secure contexts (https or localhost).
class WebClipboardBackend implements ClipboardBackend {
  /// Set when a write with custom formats failed but succeeded without them,
  /// on browsers that lack `ClipboardItem.supports()`.
  bool _customRejected = false;

  static bool get _hasClipboard => web.window.navigator.has('clipboard');

  static bool get _hasClipboardItem => globalContext.has('ClipboardItem');

  static bool get _hasSupportsFn =>
      _hasClipboardItem &&
      (globalContext['ClipboardItem'] as JSObject).has('supports');

  static web.Clipboard get _clipboard {
    if (!_hasClipboard) {
      throw const ClipboardException(
        'navigator.clipboard is unavailable (requires a secure context: '
        'https or localhost)',
      );
    }
    return web.window.navigator.clipboard;
  }

  @override
  bool supports(ClipboardFormat format) {
    if (!_hasClipboard) return false;
    if (format == ClipboardFormat.plainText) return true; // writeText at worst
    if (!_hasClipboardItem) return false;
    if (_hasSupportsFn) {
      return web.ClipboardItem.supports(webMimeTypeFor(format));
    }
    return switch (format.kind) {
      // The spec mandates text/plain, text/html and image/png.
      ClipboardFormatKind.html || ClipboardFormatKind.png => true,
      ClipboardFormatKind.custom => !_customRejected,
      _ => false,
    };
  }

  @override
  Future<void> write(ClipboardItem item) async {
    final clipboard = _clipboard;
    final values = {
      for (final e in item.values.entries)
        if (supports(e.key)) e.key: e.value,
    };
    if (values.isEmpty) {
      throw const ClipboardException('No writable format in item');
    }

    if (!_hasClipboardItem) {
      await _run('writeText', () async {
        await clipboard
            .writeText(values[ClipboardFormat.plainText]! as String)
            .toDart;
      });
      return;
    }

    // Build the ClipboardItem synchronously, before the first await: Safari
    // only accepts clipboard writes created within the user gesture.
    final attempt = clipboard.write([_toClipboardItem(values)].toJS).toDart;
    try {
      await attempt;
    } catch (error) {
      // Without ClipboardItem.supports() we could not tell up front whether
      // custom formats are allowed; retry without them.
      final hasCustom = values.keys.any(
        (f) => f.kind == ClipboardFormatKind.custom,
      );
      if (hasCustom && !_hasSupportsFn) {
        final rest = {
          for (final e in values.entries)
            if (e.key.kind != ClipboardFormatKind.custom) e.key: e.value,
        };
        if (rest.isNotEmpty) {
          try {
            await clipboard.write([_toClipboardItem(rest)].toJS).toDart;
            _customRejected = true;
            return;
          } catch (_) {
            // Fall through and report the original error.
          }
        }
      }
      throw ClipboardException('Clipboard write failed: ${_describe(error)}');
    }
  }

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) async {
    final clipboard = _clipboard;
    Object? readError;
    if (_hasClipboardItem && clipboard.has('read')) {
      try {
        final items = (await clipboard.read().toDart).toDart;
        if (items.isEmpty) return ClipboardReadResult.empty;
        final item = items.first;
        final values = <ClipboardFormat, Object>{};
        for (final jsType in item.types.toDart) {
          final type = jsType.toDart;
          final format = webFormatForMimeType(type);
          if (format == null || values.containsKey(format)) continue;
          if (formats != null && !formats.contains(format)) continue;
          final blob = await item.getType(type).toDart;
          values[format] = format.isText
              ? (await blob.text().toDart).toDart
              : (await blob.arrayBuffer().toDart).toDart.asUint8List();
        }
        return ClipboardReadResult(values);
      } catch (error) {
        readError = error;
      }
    }
    if (formats == null || formats.contains(ClipboardFormat.plainText)) {
      final text = await _run('readText', () async {
        return (await clipboard.readText().toDart).toDart;
      });
      return text.isEmpty
          ? ClipboardReadResult.empty
          : ClipboardReadResult({ClipboardFormat.plainText: text});
    }
    if (readError != null) {
      throw ClipboardException(
        'Clipboard read failed: ${_describe(readError)}',
      );
    }
    return ClipboardReadResult.empty;
  }

  @override
  Future<Set<ClipboardFormat>> availableFormats() async {
    final clipboard = _clipboard;
    if (_hasClipboardItem && clipboard.has('read')) {
      try {
        final items = (await clipboard.read().toDart).toDart;
        if (items.isEmpty) return {};
        return {
          for (final t in items.first.types.toDart)
            ?webFormatForMimeType(t.toDart),
        };
      } catch (_) {
        // Fall back to readText below.
      }
    }
    final text = await _run('readText', () async {
      return (await clipboard.readText().toDart).toDart;
    });
    return text.isEmpty ? {} : {ClipboardFormat.plainText};
  }

  /// Reads the text formats (plain text, HTML and RTF) from a DOM `paste`
  /// event's `clipboardData`, synchronously and without a permission prompt.
  ///
  /// Call it from the `paste` listener itself: the data is only available
  /// while the event is being dispatched. Call `event.preventDefault()` if
  /// you handle the paste yourself. Custom and PNG formats are not read
  /// (images arrive as `clipboardData.files`).
  static ClipboardReadResult readFromPasteEvent(web.ClipboardEvent event) {
    final data = event.clipboardData;
    if (data == null) return ClipboardReadResult.empty;
    final values = <ClipboardFormat, Object>{};
    for (final jsType in data.types.toDart) {
      final type = jsType.toDart;
      final format = webFormatForMimeType(type);
      if (format == null || !format.isText || values.containsKey(format)) {
        continue;
      }
      values[format] = data.getData(type);
    }
    return ClipboardReadResult(values);
  }

  /// Writes the text formats of [item] (plain text, HTML and RTF) into a DOM
  /// `copy` or `cut` event's `clipboardData` and calls `preventDefault()`
  /// so the browser keeps them.
  ///
  /// Call it synchronously from the event listener. Returns false (and
  /// leaves the event alone) when [item] has no text format or the event has
  /// no `clipboardData`.
  static bool writeToCopyEvent(web.ClipboardEvent event, ClipboardItem item) {
    final data = event.clipboardData;
    final text = {
      for (final e in item.values.entries)
        if (e.key.isText) e.key: e.value as String,
    };
    if (data == null || text.isEmpty) return false;
    event.preventDefault();
    for (final MapEntry(:key, :value) in text.entries) {
      data.setData(webMimeTypeFor(key), value);
    }
    return true;
  }

  static web.ClipboardItem _toClipboardItem(
    Map<ClipboardFormat, Object> values,
  ) {
    final representations = JSObject();
    for (final MapEntry(key: format, :value) in values.entries) {
      final type = webMimeTypeFor(format);
      final JSAny part = switch (value) {
        String s => s.toJS,
        Uint8List b => b.toJS,
        _ => throw ArgumentError('Unsupported clipboard value: $value'),
      };
      representations[type] = web.Blob(
        <JSAny>[part].toJS,
        web.BlobPropertyBag(type: type),
      );
    }
    return web.ClipboardItem(representations);
  }

  static Future<T> _run<T>(String op, Future<T> Function() body) async {
    try {
      return await body();
    } on ClipboardException {
      rethrow;
    } catch (error) {
      throw ClipboardException('Clipboard $op failed: ${_describe(error)}');
    }
  }

  // DOMExceptions stringify as "NotAllowedError: <message>".
  static String _describe(Object error) => error.toString();
}
