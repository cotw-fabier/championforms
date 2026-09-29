/// One representation a clipboard item can carry.
///
/// Formats are identified by a platform-neutral [id]. Backends map it to the
/// platform's own name: a UTI on Apple platforms, a registered clipboard
/// format on Windows, a MIME target on Linux and the web.
///
/// | Format        | [id]            | Value type                |
/// |---------------|-----------------|---------------------------|
/// | [plainText]   | `text/plain`    | `String`                  |
/// | [html]        | `text/html`     | `String`                  |
/// | [rtf]         | `text/rtf`      | `String`                  |
/// | [png]         | `image/png`     | `Uint8List`               |
/// | [gif]         | `image/gif`     | `Uint8List`               |
/// | [files]       | `files`         | `List<String>` (paths)    |
/// | [custom]      | `custom:<name>` | `Uint8List`               |
final class ClipboardFormat {
  const ClipboardFormat._(this.id, this.kind);

  /// A custom application format, e.g. `ClipboardFormat.custom('com.championforms.data')`.
  ///
  /// [name] should be reverse-DNS. Backends derive the platform identifier
  /// from it: the UTI on Apple, a registered format name on Windows,
  /// `application/x-<name>` targets on Linux, and a `web ` prefixed MIME type
  /// on the web where the browser supports custom formats at all.
  factory ClipboardFormat.custom(String name) {
    if (name.isEmpty || name.contains(RegExp(r'\s'))) {
      throw ArgumentError.value(name, 'name', 'must be non-empty, no spaces');
    }
    return ClipboardFormat._('custom:$name', ClipboardFormatKind.custom);
  }

  /// Parses an [id] produced by this class.
  factory ClipboardFormat.fromId(String id) => switch (id) {
    'text/plain' => plainText,
    'text/html' => html,
    'text/rtf' => rtf,
    'image/png' => png,
    'image/gif' => gif,
    'files' => files,
    _ when id.startsWith('custom:') => ClipboardFormat.custom(
      id.substring('custom:'.length),
    ),
    _ => throw ArgumentError.value(id, 'id', 'unknown clipboard format'),
  };

  static const plainText = ClipboardFormat._(
    'text/plain',
    ClipboardFormatKind.plainText,
  );
  static const html = ClipboardFormat._('text/html', ClipboardFormatKind.html);
  static const rtf = ClipboardFormat._('text/rtf', ClipboardFormatKind.rtf);
  static const png = ClipboardFormat._('image/png', ClipboardFormatKind.png);

  /// A GIF image, animation included. Written as the platform's GIF type
  /// (`com.compuserve.gif`, a registered `GIF` format, `image/gif`); apps
  /// that only paste still images usually look for [png] instead, so pair
  /// it with a [png] of the first frame when you have one.
  static const gif = ClipboardFormat._('image/gif', ClipboardFormatKind.gif);

  /// Local files, as absolute paths. The value is a non-empty
  /// `List<String>`.
  ///
  /// Written as file references other apps paste as files (Finder,
  /// Explorer, file managers, chat apps): file URLs on macOS, `CF_HDROP` on
  /// Windows, `text/uri-list` on Linux and `content://` URIs on Android.
  /// Not available on iOS or the web. Reading back is platform dependent:
  /// see the package README.
  static const files = ClipboardFormat._('files', ClipboardFormatKind.files);

  /// Platform-neutral identifier; also what crosses the FFI boundary.
  final String id;

  final ClipboardFormatKind kind;

  /// The custom name for a [ClipboardFormatKind.custom] format, else null.
  String? get customName => kind == ClipboardFormatKind.custom
      ? id.substring('custom:'.length)
      : null;

  /// Whether values of this format are a `List<String>` of file paths.
  bool get isFiles => kind == ClipboardFormatKind.files;

  /// Whether values of this format are `String` (as opposed to bytes).
  bool get isText =>
      kind == ClipboardFormatKind.plainText ||
      kind == ClipboardFormatKind.html ||
      kind == ClipboardFormatKind.rtf;

  @override
  bool operator ==(Object other) => other is ClipboardFormat && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ClipboardFormat($id)';
}

enum ClipboardFormatKind { plainText, html, rtf, png, gif, files, custom }
