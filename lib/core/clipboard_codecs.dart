import 'package:championforms/controllers/form_controller.dart';
import 'package:championforms/core/field_builder_registry.dart';
import 'package:championforms/models/field_clipboard.dart';
import 'package:championforms/models/field_types/compound_field.dart';
import 'package:championforms/models/field_types/convienence_classes/checkboxselect.dart';
import 'package:championforms/models/field_types/convienence_classes/chipselect.dart';
import 'package:championforms/models/field_types/fileupload.dart';
import 'package:championforms/models/field_types/formfieldclass.dart';
import 'package:championforms/models/field_types/optionselect.dart';
import 'package:championforms/models/field_types/textfield.dart';
import 'package:championforms/models/file_model.dart';
import 'package:championforms/models/multiselect_option.dart';

// ===========================================================================
// SHARED HELPERS
// ===========================================================================

/// Escapes [text] for safe inclusion in HTML element content or a
/// double-quoted attribute.
///
/// Field values are user input and the HTML flavor of a copy is pasted into
/// other applications, so every value goes through this before it is wrapped
/// in markup.
String clipboardHtmlEscape(String text) {
  final buffer = StringBuffer();
  for (final unit in text.runes) {
    switch (unit) {
      case 0x26: // &
        buffer.write('&amp;');
      case 0x3C: // <
        buffer.write('&lt;');
      case 0x3E: // >
        buffer.write('&gt;');
      case 0x22: // "
        buffer.write('&quot;');
      case 0x27: // '
        buffer.write('&#39;');
      default:
        buffer.writeCharCode(unit);
    }
  }
  return buffer.toString();
}

/// Escapes [text] and turns its line breaks into `<br>`.
String _escapeMultiline(String text) => clipboardHtmlEscape(
  text.replaceAll('\r\n', '\n').replaceAll('\r', '\n'),
).replaceAll('\n', '<br>');

/// Runs a paste body, turning any exception from hostile input into null.
Object? _guard(Object? Function() body) {
  try {
    return body();
  } catch (_) {
    return null;
  }
}

/// The registry name for [field]'s type, or [fallback] for a type that was
/// never registered (a subclass using a per-field codec, say).
String _typeName(Field field, String fallback) =>
    FormFieldRegistry.nameForType(field.runtimeType) ?? fallback;

/// The `value` of a `{"type": String, "value": …}` data map, or null when the
/// map does not have that shape. Never throws.
Object? _valueOf(Map<String, dynamic> data) {
  try {
    if (data['type'] is! String) return null;
    return data['value'];
  } catch (_) {
    return null;
  }
}

// ===========================================================================
// TEXT FIELD
// ===========================================================================

/// Clipboard codec for [TextField].
///
/// - **plainText:** the value, verbatim.
/// - **html:** the HTML-escaped value in a `<span>`, line breaks as `<br>`.
/// - **data:** `{"type": "textField", "value": <String>}`.
///
/// Password fields ([TextField.password] is true) are never copied: [copy]
/// returns null for them. An empty field still produces a fragment (with an
/// empty value) so a copied document keeps the field.
///
/// [paste] returns the `String`, ready for `FormController.updateFieldValue`.
class TextFieldClipboardCodec extends FieldClipboardCodec {
  const TextFieldClipboardCodec();

  @override
  ClipboardFragment? copy(Field field, dynamic value) {
    if (field is TextField && field.password) return null;
    final text = value == null
        ? (field.defaultValue is String ? field.defaultValue as String : '')
        : value.toString();
    return ClipboardFragment(
      plainText: text,
      html: '<span>${_escapeMultiline(text)}</span>',
      data: {'type': _typeName(field, 'textField'), 'value': text},
    );
  }

  @override
  dynamic paste(Map<String, dynamic> data) => _guard(() {
    final value = _valueOf(data);
    return value is String ? value : null;
  });
}

// ===========================================================================
// OPTION SELECT FAMILY
// ===========================================================================

/// Clipboard codec for [OptionSelect] and its convenience subclasses
/// ([CheckboxSelect], [ChipSelect], `RadioSelect`).
///
/// - **plainText:** for checkbox-style fields ([CheckboxSelect],
///   [ChipSelect]) one `☑ Label` / `☐ Label` line per option, listing every
///   option. For dropdowns and radio groups, just the selected label(s), one
///   per line.
/// - **html:** a `<ul>` checklist with the same glyphs, or the selected
///   label(s) in a `<span>`.
/// - **data:** `{"type": <registry name>, "value": [<selected option values>]}`.
///
/// ## Restoring a pasted value
///
/// [paste] only receives the data map, not the field, so it cannot build the
/// [FieldOption]s the controller stores. It returns the selected option
/// values as a `List<String>`. Turn them back into options with
/// [optionsFor], given the field the value is being restored into, then
/// write them with `updateMultiselectValues(..., overwrite: true)`, which
/// also enforces single-select:
///
/// ```dart
/// final values = codec.paste(fragment.data) as List<String>?;
/// if (values != null) {
///   controller.updateMultiselectValues(
///     field.id,
///     OptionSelectClipboardCodec.optionsFor(field, values),
///     overwrite: true,
///   );
/// }
/// ```
///
/// Values that do not match one of the field's options are dropped rather
/// than invented, the same rule `FieldJson.defaultSelection` applies.
class OptionSelectClipboardCodec extends FieldClipboardCodec {
  const OptionSelectClipboardCodec();

  /// The options of [field] whose value is in [values], in the order of
  /// [values], without duplicates. Unknown values are dropped. A single-select
  /// field gets at most one option.
  static List<FieldOption> optionsFor(OptionSelect field, List<String> values) {
    final byValue = <String, FieldOption>{
      for (final option in field.options ?? const <FieldOption>[])
        option.value: option,
    };
    final seen = <String>{};
    final result = <FieldOption>[];
    for (final value in values) {
      final option = byValue[value];
      if (option == null || !seen.add(value)) continue;
      result.add(option);
      if (!field.multiselect) break;
    }
    return result;
  }

  /// Whether [field] renders as a checklist (every option visible with its
  /// own tick box) rather than as a picker showing only the selection.
  static bool _isChecklist(OptionSelect field) =>
      field is CheckboxSelect || field is ChipSelect;

  @override
  ClipboardFragment? copy(Field field, dynamic value) {
    if (field is! OptionSelect) return null;
    final selected = value is List
        ? value.whereType<FieldOption>().toList()
        : (value == null ? field.defaultValue : null);
    if (selected == null) return null;

    final selectedValues = selected.map((o) => o.value).toList();
    final String plain;
    final String html;

    if (_isChecklist(field)) {
      final selectedSet = selectedValues.toSet();
      final options = [...?field.options];
      final known = options.map((o) => o.value).toSet();
      // A selection the field no longer lists still gets a ticked line, so a
      // copy never silently drops part of the answer.
      options.addAll(selected.where((o) => !known.contains(o.value)));
      final lines = [
        for (final option in options)
          (selectedSet.contains(option.value) ? '☑' : '☐', option.label),
      ];
      plain = lines.map((l) => '${l.$1} ${l.$2}').join('\n');
      html =
          '<ul>'
          '${lines.map((l) => '<li>${l.$1} ${clipboardHtmlEscape(l.$2)}</li>').join()}'
          '</ul>';
    } else {
      final labels = selected.map((o) => o.label).toList();
      plain = labels.join('\n');
      html = '<span>${labels.map(clipboardHtmlEscape).join('<br>')}</span>';
    }

    return ClipboardFragment(
      plainText: plain,
      html: html,
      data: {'type': _typeName(field, 'optionSelect'), 'value': selectedValues},
    );
  }

  @override
  dynamic paste(Map<String, dynamic> data) => _guard(() {
    final value = _valueOf(data);
    if (value is! List) return null;
    if (value.any((v) => v is! String)) return null;
    return List<String>.from(value);
  });
}

// ===========================================================================
// FILE UPLOAD
// ===========================================================================

/// Clipboard codec for [FileUpload].
///
/// - **plainText:** the file names, one per line.
/// - **html:** a `<ul>` of the file names.
/// - **data:** `{"type": "fileUpload", "value": [{"name", "mimeType",
///   "size"}, …]}` — metadata only. File bytes never reach the system
///   clipboard.
///
/// [paste] returns that metadata list (`List<Map<String, dynamic>>`), not
/// files: bytes cannot be restored from the system clipboard. A consumer
/// that needs the live files back (the documents package's session cache,
/// for instance) keeps them itself and uses this metadata to match them up.
class FileUploadClipboardCodec extends FieldClipboardCodec {
  const FileUploadClipboardCodec();

  @override
  ClipboardFragment? copy(Field field, dynamic value) {
    if (field is! FileUpload) return null;
    final selected = value is List
        ? value.whereType<FieldOption>().toList()
        : (value == null ? field.defaultValue : null);
    if (selected == null) return null;

    final files = <Map<String, dynamic>>[
      for (final option in selected)
        if (option.additionalData is FileModel)
          _metadata(option.additionalData as FileModel)
        else
          {'name': option.label, 'mimeType': null, 'size': null},
    ];
    final names = files.map((f) => f['name'] as String).toList();

    return ClipboardFragment(
      plainText: names.join('\n'),
      html:
          '<ul>'
          '${names.map((n) => '<li>${clipboardHtmlEscape(n)}</li>').join()}'
          '</ul>',
      data: {'type': _typeName(field, 'fileUpload'), 'value': files},
    );
  }

  static Map<String, dynamic> _metadata(FileModel file) => {
    'name': file.fileName,
    'mimeType': file.mimeData?.mime,
    'size': file.fileBytes?.length,
  };

  @override
  dynamic paste(Map<String, dynamic> data) => _guard(() => _paste(data));

  List<Map<String, dynamic>>? _paste(Map<String, dynamic> data) {
    final value = _valueOf(data);
    if (value is! List) return null;
    final result = <Map<String, dynamic>>[];
    for (final entry in value) {
      if (entry is! Map) return null;
      final name = entry['name'];
      final mimeType = entry['mimeType'];
      final size = entry['size'];
      if (name is! String) return null;
      if (mimeType != null && mimeType is! String) return null;
      if (size != null && (size is! int || size < 0)) return null;
      result.add({'name': name, 'mimeType': mimeType, 'size': size});
    }
    return result;
  }
}

// ===========================================================================
// COMPOUND FIELDS
// ===========================================================================

/// Clipboard codec for [CompoundField]s such as `NameField` and
/// `AddressField`.
///
/// A compound field holds no value of its own; its sub-fields do. The value
/// this codec copies is therefore a `Map<String, String>` from each
/// sub-field's id **suffix** (`firstname`, `city`, …) to its text. Build it
/// with [valueFrom], and write a pasted map back with [writeTo].
///
/// - **plainText:** the non-empty sub-field values joined with `", "` in
///   sub-field order — what `FieldResultAccessor.asCompound()` produces.
/// - **html:** the same, escaped, in a `<span>`.
/// - **data:** `{"type": <registry name>, "value": {suffix: text, …}}`.
///
/// [paste] returns that `Map<String, String>`.
class CompoundClipboardCodec extends FieldClipboardCodec {
  const CompoundClipboardCodec();

  /// The controller id of [field]'s sub-field [suffix]:
  /// `{compoundId}_{suffix}`.
  static String subFieldId(CompoundField field, String suffix) =>
      suffix.startsWith('${field.id}_') ? suffix : '${field.id}_$suffix';

  /// The sub-field id suffixes of [field], in declaration order.
  static List<String> _suffixes(CompoundField field) {
    final prefix = '${field.id}_';
    return field
        .buildSubFields()
        .map(
          (f) => f.id.startsWith(prefix) ? f.id.substring(prefix.length) : f.id,
        )
        .toList();
  }

  /// Reads [field]'s sub-field values out of [controller] as the map this
  /// codec copies. Sub-fields without a value are included as `""`.
  static Map<String, String> valueFrom(
    FormController controller,
    CompoundField field,
  ) {
    return {
      for (final suffix in _suffixes(field))
        suffix:
            controller
                .getFieldValueOrNull<Object>(subFieldId(field, suffix))
                ?.toString() ??
            '',
    };
  }

  /// Writes a pasted sub-field map into [controller]. Suffixes [field] does
  /// not declare, or whose sub-field is not registered, are skipped.
  static void writeTo(
    FormController controller,
    CompoundField field,
    Map<String, String> value, {
    bool noNotify = false,
  }) {
    final known = _suffixes(field).toSet();
    for (final entry in value.entries) {
      if (!known.contains(entry.key)) continue;
      final id = subFieldId(field, entry.key);
      if (!controller.hasFieldDefinition(id)) continue;
      controller.updateFieldValue<String>(id, entry.value, noNotify: noNotify);
    }
  }

  @override
  ClipboardFragment? copy(Field field, dynamic value) {
    if (field is! CompoundField) return null;
    if (value != null && value is! Map) return null;
    final prefix = '${field.id}_';
    final raw = <String, String>{};
    (value as Map?)?.forEach((key, v) {
      if (key is! String) return;
      final suffix = key.startsWith(prefix)
          ? key.substring(prefix.length)
          : key;
      raw[suffix] = v?.toString() ?? '';
    });

    // Sub-field order first, then anything else the caller supplied.
    final ordered = <String, String>{
      for (final suffix in _suffixes(field))
        if (raw.containsKey(suffix)) suffix: raw[suffix]!,
      ...raw,
    };
    final joined = ordered.values.where((v) => v.isNotEmpty).join(', ');

    return ClipboardFragment(
      plainText: joined,
      html: '<span>${_escapeMultiline(joined)}</span>',
      data: {'type': _typeName(field, 'compound'), 'value': ordered},
    );
  }

  @override
  dynamic paste(Map<String, dynamic> data) => _guard(() => _paste(data));

  Map<String, String>? _paste(Map<String, dynamic> data) {
    final value = _valueOf(data);
    if (value is! Map) return null;
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! String) return null;
      result[entry.key as String] = entry.value as String;
    }
    return result;
  }
}
