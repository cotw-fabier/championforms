import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

import '../api/clipboard_backend.dart';
import '../api/clipboard_format.dart';
import '../api/clipboard_item.dart';
import 'android_formats.dart';

/// Android clipboard through `ClipboardManager`, called with `package:jni`
/// dynamic method lookups (no jnigen bindings; `package:jni_flutter`
/// supplies the application context).
///
/// Supports [ClipboardFormat.plainText], [ClipboardFormat.html],
/// [ClipboardFormat.png], [ClipboardFormat.gif] and [ClipboardFormat.files].
/// Text and HTML go on the clip's first item. Images and files are copied
/// into `<cacheDir>/championforms_clipboard/` and put on the clip as
/// `content://<applicationId>.championforms_clipboard/...` URIs, served by
/// the package's `ClipboardContentProvider` (merged into the app's manifest
/// by the plugin module); the first URI shares the first item with the
/// text, each further one gets its own item. Every write first deletes what
/// the previous write left in that folder.
///
/// When an item has HTML but no plain text, the text is derived with
/// [htmlToPlainText]. RTF and custom formats are skipped by [write] and
/// [supports] returns false for them. [ClipboardFormat.files] is write only:
/// a pasted `content://` URI is not a local path, so [read] and
/// [availableFormats] never report it.
///
/// Threading assumption: `ClipboardManager` is called directly from the
/// calling isolate. With Flutter's merged platform/UI threads (the default
/// since 3.29) the root isolate runs on the Android main thread, which is
/// what `ClipboardManager` expects; the S0 spike confirmed this works.
/// Calling from a background isolate is not supported.
class AndroidClipboardBackend implements ClipboardBackend {
  /// Label attached to written `ClipData` (shown by some clipboard UIs).
  AndroidClipboardBackend({this.label = 'championforms'});

  final String label;

  static const _clipDataSig = 'Landroid/content/ClipData;';
  static const _itemSig = 'Landroid/content/ClipData\$Item;';
  static const _charSeq = 'Ljava/lang/CharSequence;';
  static const _string = 'Ljava/lang/String;';
  static const _uriSig = 'Landroid/net/Uri;';
  static const _resolverSig = 'Landroid/content/ContentResolver;';

  /// Writes run one at a time: each clears the folder the previous one
  /// staged into, which must not happen under a write still in flight.
  Future<void> _writeChain = Future.value();

  @override
  bool supports(ClipboardFormat format) =>
      androidSupportedFormats.contains(format);

  @override
  Future<void> write(ClipboardItem item) {
    final next = _writeChain.then((_) => _write(item));
    _writeChain = next.then((_) {}, onError: (_) {});
    return next;
  }

  Future<void> _write(ClipboardItem item) async {
    final html = item.values[ClipboardFormat.html] as String?;
    final plain =
        item.values[ClipboardFormat.plainText] as String? ??
        (html == null ? null : htmlToPlainText(html));
    final png = item.values[ClipboardFormat.png] as Uint8List?;
    final gif = item.values[ClipboardFormat.gif] as Uint8List?;
    final files = item.values[ClipboardFormat.files] as List<String>?;
    if (plain == null && png == null && gif == null && files == null) {
      throw const ClipboardException(
        'No writable format in item (Android supports plain text, HTML, '
        'PNG, GIF and files)',
      );
    }

    final (cacheDir, packageName) = _guard(
      'write',
      () => using((arena) => (_cacheDir(arena), _packageName(arena))),
    );
    final staged = await _stage(cacheDir, png: png, gif: gif, files: files);

    _guard('write', () {
      using((arena) {
        final resolver = _contentResolver(arena);
        final resolverClass = JClass.forName('android/content/ContentResolver')
          ..releasedBy(arena);
        final getType = resolverClass.instanceMethodId(
          'getType',
          '($_uriSig)$_string',
        );
        final uriClass = JClass.forName('android/net/Uri')..releasedBy(arena);
        final parse = uriClass.staticMethodId('parse', '($_string)$_uriSig');

        final uris = <JObject>[];
        final mimeTypes = <String>[
          if (plain != null) 'text/plain',
          if (html != null) 'text/html',
        ];
        for (final path in staged) {
          final uri = parse.call(uriClass, JObject.type, [
            _jstr(androidContentUri(packageName, path), arena),
          ])..releasedBy(arena);
          uris.add(uri);
          final mime =
              getType
                  .callNullable(resolver, JString.type, [uri])
                  ?.toDartString(releaseOriginal: true) ??
              'application/octet-stream';
          if (!mimeTypes.contains(mime)) mimeTypes.add(mime);
        }

        final itemClass = JClass.forName('android/content/ClipData\$Item')
          ..releasedBy(arena);
        // Item(CharSequence text, String htmlText, Intent intent, Uri uri).
        final newItem = itemClass.constructorId(
          '(${_charSeq}Ljava/lang/String;Landroid/content/Intent;$_uriSig)V',
        );
        JObject makeItem(String? text, String? htmlText, JObject? uri) =>
            newItem.call<JObject>(itemClass, [
              text == null ? null : _jstr(text, arena),
              htmlText == null ? null : _jstr(htmlText, arena),
              null,
              uri,
            ])..releasedBy(arena);

        final clipDataClass = JClass.forName('android/content/ClipData')
          ..releasedBy(arena);
        final mimeArray = JArray.of<JString>(JString.type, [
          for (final m in mimeTypes) _jstr(m, arena),
        ])..releasedBy(arena);
        final clip =
            clipDataClass
                .constructorId('($_charSeq[$_string$_itemSig)V')
                .call<JObject>(clipDataClass, [
                  _jstr(label, arena),
                  mimeArray,
                  makeItem(plain, html, uris.firstOrNull),
                ])
              ..releasedBy(arena);
        final addItem = clipDataClass.instanceMethodId(
          'addItem',
          '($_itemSig)V',
        );
        for (final uri in uris.skip(1)) {
          addItem.call(clip, jvoid.type, [makeItem(null, null, uri)]);
        }

        final manager = _clipboardManager(arena);
        final managerClass = JClass.forName('android/content/ClipboardManager')
          ..releasedBy(arena);
        managerClass
            .instanceMethodId('setPrimaryClip', '($_clipDataSig)V')
            .call(manager, jvoid.type, [clip]);
      });
    });
  }

  /// Clears `<cacheDir>/championforms_clipboard/` and copies the images and
  /// files of this write into a fresh subfolder of it. Returns their paths
  /// relative to that folder, in clip order: PNG, GIF, then the files.
  static Future<List<String>> _stage(
    String cacheDir, {
    Uint8List? png,
    Uint8List? gif,
    List<String>? files,
  }) async {
    final root = Directory('$cacheDir/$androidClipboardDir');
    try {
      if (await root.exists()) {
        await for (final stale in root.list(followLinks: false)) {
          await stale.delete(recursive: true);
        }
      }
      if (png == null && gif == null && files == null) return const [];

      final batch = DateTime.now().microsecondsSinceEpoch.toString();
      final staged = <String>[];
      Future<void> put(
        String relative,
        Future<void> Function(File) fill,
      ) async {
        final file = File('${root.path}/$relative');
        await file.parent.create(recursive: true);
        await fill(file);
        staged.add(relative);
      }

      if (png != null) {
        await put('$batch/image.png', (f) => f.writeAsBytes(png, flush: true));
      }
      if (gif != null) {
        await put('$batch/image.gif', (f) => f.writeAsBytes(gif, flush: true));
      }
      // One folder per file keeps the original name even when two files
      // share it.
      for (final (i, path) in (files ?? const <String>[]).indexed) {
        await put(
          '$batch/$i/${androidBaseName(path)}',
          (f) => File(path).copy(f.path),
        );
      }
      return staged;
    } on FileSystemException catch (e) {
      throw ClipboardException('Android clipboard write failed: $e');
    }
  }

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) async {
    final wanted = formats?.toSet() ?? androidReadableFormats;
    if (!wanted.any(androidReadableFormats.contains)) {
      return ClipboardReadResult.empty;
    }
    return _guard('read', () {
      return using((arena) {
        final manager = _clipboardManager(arena);
        final managerClass = JClass.forName('android/content/ClipboardManager')
          ..releasedBy(arena);
        final clip =
            managerClass
                .instanceMethodId('getPrimaryClip', '()$_clipDataSig')
                .callNullable(manager, JObject.type, [])
              ?..releasedBy(arena);
        if (clip == null) return ClipboardReadResult.empty;

        final clipClass = JClass.forName('android/content/ClipData')
          ..releasedBy(arena);
        final count = clipClass
            .instanceMethodId('getItemCount', '()I')
            .call(clip, jint.type, []);
        if (count < 1) return ClipboardReadResult.empty;

        final getItemAt = clipClass.instanceMethodId(
          'getItemAt',
          '(I)$_itemSig',
        );
        final itemClass = JClass.forName('android/content/ClipData\$Item')
          ..releasedBy(arena);
        final item = getItemAt.call(clip, JObject.type, [JValueInt(0)])
          ..releasedBy(arena);

        String? html;
        if (wanted.contains(ClipboardFormat.html) ||
            wanted.contains(ClipboardFormat.plainText)) {
          html = itemClass
              .instanceMethodId('getHtmlText', '()$_string')
              .callNullable(item, JString.type, [])
              ?.toDartString(releaseOriginal: true);
        }
        String? plain;
        if (wanted.contains(ClipboardFormat.plainText)) {
          // getText() returns a CharSequence (possibly a styled Spanned);
          // JObject.toString() calls Java's toString(), giving the text.
          final text =
              itemClass
                  .instanceMethodId('getText', '()$_charSeq')
                  .callNullable(item, JObject.type, [])
                ?..releasedBy(arena);
          plain = text?.toString();
          if (plain == null && html != null) plain = htmlToPlainText(html);
        }

        // Images: the first item URI of each wanted image type.
        final images = <ClipboardFormat, Uint8List>{};
        final wantedImages = {
          ClipboardFormat.png,
          ClipboardFormat.gif,
        }.intersection(wanted);
        if (wantedImages.isNotEmpty) {
          final resolver = _contentResolver(arena);
          final resolverClass = JClass.forName(
            'android/content/ContentResolver',
          )..releasedBy(arena);
          final getType = resolverClass.instanceMethodId(
            'getType',
            '($_uriSig)$_string',
          );
          final getUri = itemClass.instanceMethodId('getUri', '()$_uriSig');
          for (
            var i = 0;
            i < count && images.length < wantedImages.length;
            i++
          ) {
            final it = i == 0
                ? item
                : (getItemAt.call(clip, JObject.type, [JValueInt(i)])
                    ..releasedBy(arena));
            final uri = getUri.callNullable(it, JObject.type, [])
              ?..releasedBy(arena);
            if (uri == null) continue;
            final mime = getType
                .callNullable(resolver, JString.type, [uri])
                ?.toDartString(releaseOriginal: true);
            final format = switch (mime?.toLowerCase()) {
              'image/png' => ClipboardFormat.png,
              'image/gif' => ClipboardFormat.gif,
              _ => null,
            };
            if (format == null ||
                !wantedImages.contains(format) ||
                images.containsKey(format)) {
              continue;
            }
            final bytes = _readUri(resolver, uri, arena);
            if (bytes != null) images[format] = bytes;
          }
        }

        return ClipboardReadResult({
          if (plain != null && wanted.contains(ClipboardFormat.plainText))
            ClipboardFormat.plainText: plain,
          if (html != null && wanted.contains(ClipboardFormat.html))
            ClipboardFormat.html: html,
          ...images,
        });
      });
    });
  }

  /// Reads a content URI through `ContentResolver.openInputStream`, in
  /// 64 KiB chunks. Null when the provider has no stream for it.
  static Uint8List? _readUri(JObject resolver, JObject uri, Arena arena) {
    final resolverClass = JClass.forName('android/content/ContentResolver')
      ..releasedBy(arena);
    final stream =
        resolverClass
            .instanceMethodId(
              'openInputStream',
              '($_uriSig)Ljava/io/InputStream;',
            )
            .callNullable(resolver, JObject.type, [uri])
          ?..releasedBy(arena);
    if (stream == null) return null;
    final streamClass = JClass.forName('java/io/InputStream')
      ..releasedBy(arena);
    final readInto = streamClass.instanceMethodId('read', '([B)I');
    final close = streamClass.instanceMethodId('close', '()V');
    final buffer = JByteArray(64 * 1024)..releasedBy(arena);
    final out = BytesBuilder(copy: false);
    try {
      while (true) {
        final n = readInto.call(stream, jint.type, [buffer]);
        if (n < 0) break;
        if (n > 0) out.add(Uint8List.fromList(buffer.getRange(0, n)));
      }
    } finally {
      close.call(stream, jvoid.type, []);
    }
    return out.takeBytes();
  }

  @override
  Future<Set<ClipboardFormat>> availableFormats() async {
    return _guard('availableFormats', () {
      return using((arena) {
        final manager = _clipboardManager(arena);
        final managerClass = JClass.forName('android/content/ClipboardManager')
          ..releasedBy(arena);
        // getPrimaryClipDescription() does not read the clip's data, so it
        // does not trigger Android 12+'s "pasted from clipboard" toast.
        final desc =
            managerClass
                .instanceMethodId(
                  'getPrimaryClipDescription',
                  '()Landroid/content/ClipDescription;',
                )
                .callNullable(manager, JObject.type, [])
              ?..releasedBy(arena);
        if (desc == null) return <ClipboardFormat>{};
        final descClass = JClass.forName('android/content/ClipDescription')
          ..releasedBy(arena);
        final count = descClass
            .instanceMethodId('getMimeTypeCount', '()I')
            .call(desc, jint.type, []);
        final getMimeType = descClass.instanceMethodId(
          'getMimeType',
          '(I)$_string',
        );
        final mimes = [
          for (var i = 0; i < count; i++)
            getMimeType
                .call(desc, JString.type, [JValueInt(i)])
                .toDartString(releaseOriginal: true),
        ];
        return androidFormatsFromMimeTypes(mimes);
      });
    });
  }

  /// `context.getSystemService("clipboard")`, released with [arena].
  JObject _clipboardManager(Arena arena) {
    final contextClass = JClass.forName('android/content/Context')
      ..releasedBy(arena);
    // androidApplicationContext is a long-lived global owned by jni_flutter;
    // it must not be released here.
    return contextClass
        .instanceMethodId('getSystemService', '($_string)Ljava/lang/Object;')
        .call(androidApplicationContext, JObject.type, [
          _jstr('clipboard', arena),
        ])
      ..releasedBy(arena);
  }

  static JObject _contentResolver(Arena arena) {
    final contextClass = JClass.forName('android/content/Context')
      ..releasedBy(arena);
    return contextClass
        .instanceMethodId('getContentResolver', '()$_resolverSig')
        .call(androidApplicationContext, JObject.type, [])
      ..releasedBy(arena);
  }

  /// `context.getCacheDir().getAbsolutePath()`.
  static String _cacheDir(Arena arena) {
    final contextClass = JClass.forName('android/content/Context')
      ..releasedBy(arena);
    final dir =
        contextClass
            .instanceMethodId('getCacheDir', '()Ljava/io/File;')
            .call(androidApplicationContext, JObject.type, [])
          ..releasedBy(arena);
    final fileClass = JClass.forName('java/io/File')..releasedBy(arena);
    return fileClass
        .instanceMethodId('getAbsolutePath', '()$_string')
        .call(dir, JString.type, [])
        .toDartString(releaseOriginal: true);
  }

  /// `context.getPackageName()`: the application id the provider authority
  /// is built from.
  static String _packageName(Arena arena) {
    final contextClass = JClass.forName('android/content/Context')
      ..releasedBy(arena);
    return contextClass
        .instanceMethodId('getPackageName', '()$_string')
        .call(androidApplicationContext, JString.type, [])
        .toDartString(releaseOriginal: true);
  }

  static JString _jstr(String s, Arena arena) =>
      s.toJString()..releasedBy(arena);

  static T _guard<T>(String op, T Function() body) {
    try {
      return body();
    } on ClipboardException {
      rethrow;
    } catch (e) {
      throw ClipboardException('Android clipboard $op failed: $e');
    }
  }
}
