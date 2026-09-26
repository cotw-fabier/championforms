import 'package:championforms/models/field_types/formfieldclass.dart';

/// What one field contributes to the clipboard when it is copied.
///
/// A copy carries two audiences at once:
///
/// - **Other apps** read [plainText] and [html]: formatted, human-readable,
///   ready to paste into a word processor, an email or a chat.
/// - **ChampionForms itself** reads [data]: a JSON-safe description of the
///   value precise enough to restore it into a field of the same type. It is
///   what makes a pasted checkbox come back as a checkbox with the same boxes
///   ticked rather than as the text "☑ Option A".
///
/// [data] always has the shape `{"type": <registry type name>, "value": …}`.
/// It deliberately carries the value, not the field definition: fields are
/// built *from* JSON but have no general way back to it, so whoever owns the
/// definition (a document block stores the JSON it was built from) adds it
/// alongside.
class ClipboardFragment {
  const ClipboardFragment({
    required this.plainText,
    this.html,
    required this.data,
  });

  /// Plain-text rendering. Always present — it is the format every
  /// clipboard, on every platform, is guaranteed to keep.
  final String plainText;

  /// HTML rendering for rich-text targets, or null to let the consumer fall
  /// back to an escaped [plainText].
  final String? html;

  /// The restorable value: `{"type": …, "value": …}`, JSON-encodable.
  final Map<String, dynamic> data;

  /// The registry type name recorded in [data].
  String? get type => data['type'] as String?;

  Map<String, dynamic> toJson() => {
        'plainText': plainText,
        if (html != null) 'html': html,
        'data': data,
      };

  /// Decodes [toJson] output. Throws [FormatException] on a wrong shape —
  /// pasted data comes from outside the app and is never trusted.
  factory ClipboardFragment.fromJson(Map<String, dynamic> json) {
    final plainText = json['plainText'];
    final html = json['html'];
    final data = json['data'];
    if (plainText is! String) {
      throw const FormatException('Clipboard fragment needs "plainText".');
    }
    if (html != null && html is! String) {
      throw const FormatException('Clipboard fragment "html" must be a string.');
    }
    if (data is! Map<String, dynamic> || data['type'] is! String) {
      throw const FormatException(
          'Clipboard fragment needs "data" with a string "type".');
    }
    return ClipboardFragment(plainText: plainText, html: html, data: data);
  }
}

/// Converts one field type's value to and from the clipboard.
///
/// Resolution follows the package's sensible-default pattern:
/// `field.clipboard ?? FormFieldRegistry.clipboardFor(field.runtimeType)`,
/// and nothing is copied when `FormFieldDefaults.instance.clipboardEnabled`
/// is false.
///
/// Implementations must be pure — no controller access, no platform calls —
/// so they can be unit-tested and run on any isolate.
abstract class FieldClipboardCodec {
  const FieldClipboardCodec();

  /// The fragment for [field] holding [value], or null when this field must
  /// never reach the clipboard (a password, for instance) or has nothing to
  /// copy.
  ClipboardFragment? copy(Field field, dynamic value);

  /// Restores a value from a fragment's `data` map, or returns null when the
  /// map is not something this codec wrote. Must not throw on hostile input;
  /// return null instead.
  ///
  /// The returned value is JSON-shaped, because [data] carries no field
  /// definition to resolve against. It is a `String` for a text field, the
  /// selected option *values* (`List<String>`) for an option select (turn them
  /// into `FieldOption`s with `OptionSelectClipboardCodec.optionsFor`), and so
  /// on. Each built-in codec documents its shape and the controller call that
  /// restores it.
  dynamic paste(Map<String, dynamic> data);
}
