import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

import '../api/clipboard_backend.dart';
import '../api/clipboard_format.dart';
import '../api/clipboard_item.dart';
import 'android_formats.dart';

/// Android clipboard through `ClipboardManager`, called with `package:jni`
/// dynamic method lookups (no jnigen bindings, no plugin class of our own;
/// `package:jni_flutter` supplies the application context).
///
/// Supports [ClipboardFormat.plainText] and [ClipboardFormat.html] only.
/// Writes always carry plain text: when an item has HTML but no plain text,
/// the text is derived with [htmlToPlainText]. RTF, PNG and custom formats
/// are skipped by [write] and [supports] returns false for them.
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
  static const _charSeq = 'Ljava/lang/CharSequence;';
  static const _string = 'Ljava/lang/String;';

  @override
  bool supports(ClipboardFormat format) =>
      androidSupportedFormats.contains(format);

  @override
  Future<void> write(ClipboardItem item) async {
    final html = item.values[ClipboardFormat.html] as String?;
    final plain =
        item.values[ClipboardFormat.plainText] as String? ??
        (html == null ? null : htmlToPlainText(html));
    if (plain == null) {
      throw const ClipboardException(
        'No writable format in item (Android supports plain text and HTML)',
      );
    }
    _guard('write', () {
      using((arena) {
        final manager = _clipboardManager(arena);
        final clipDataClass = JClass.forName('android/content/ClipData')
          ..releasedBy(arena);
        final JObject clip;
        if (html != null) {
          clip = clipDataClass
              .staticMethodId(
                'newHtmlText',
                '($_charSeq$_charSeq$_string)$_clipDataSig',
              )
              .call(clipDataClass, JObject.type, [
                _jstr(label, arena),
                _jstr(plain, arena),
                _jstr(html, arena),
              ]);
        } else {
          clip = clipDataClass
              .staticMethodId(
                'newPlainText',
                '($_charSeq$_charSeq)$_clipDataSig',
              )
              .call(clipDataClass, JObject.type, [
                _jstr(label, arena),
                _jstr(plain, arena),
              ]);
        }
        clip.releasedBy(arena);
        final managerClass = JClass.forName('android/content/ClipboardManager')
          ..releasedBy(arena);
        managerClass
            .instanceMethodId('setPrimaryClip', '($_clipDataSig)V')
            .call(manager, jvoid.type, [clip]);
      });
    });
  }

  @override
  Future<ClipboardReadResult> read({List<ClipboardFormat>? formats}) async {
    final wanted = formats?.toSet() ?? androidSupportedFormats;
    if (!wanted.any(supports)) return ClipboardReadResult.empty;
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

        final item =
            clipClass
                .instanceMethodId(
                  'getItemAt',
                  '(I)Landroid/content/ClipData\$Item;',
                )
                .call(clip, JObject.type, [JValueInt(0)])
              ..releasedBy(arena);
        final itemClass = JClass.forName('android/content/ClipData\$Item')
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

        return ClipboardReadResult({
          if (plain != null && wanted.contains(ClipboardFormat.plainText))
            ClipboardFormat.plainText: plain,
          if (html != null && wanted.contains(ClipboardFormat.html))
            ClipboardFormat.html: html,
        });
      });
    });
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
