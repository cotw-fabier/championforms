import 'package:championforms/models/field_condition.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/named_validator.dart';
import 'package:championforms/models/validatorclass.dart';

/// Readers for the properties every field has.
///
/// Without this, each `fromJson` would re-parse `id`, `title`, `description`,
/// `disabled`, `hideField`, `validators` and `conditional` — seven chances per
/// field type for the same key to be spelled or coerced slightly differently,
/// which is exactly the class of bug that makes a document behave differently
/// depending on which field it is attached to.
///
/// Every reader is **tolerant of an absent key and strict about a wrong type**.
/// A missing `validators` is `[]`; `"validators": 3` throws [FormatException]
/// naming the field and the key, because a rule that silently disappears is a
/// rule that stops protecting the data it was written for.
abstract final class FieldJson {
  /// The field's `id`. Required, and required to be non-empty — an id is what
  /// every value, error and condition is keyed by.
  static String id(Map<String, dynamic> json) {
    final value = json['id'];
    if (value is! String || value.isEmpty) {
      throw FormatException('A field needs a non-empty "id"; got $value.');
    }
    return value;
  }

  /// The field's `type`, or null when the document does not name one.
  static String? type(Map<String, dynamic> json) => string(json, 'type');

  /// An optional string at [key].
  static String? string(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is! String) {
      throw FormatException(
        'Field "${json['id']}": "$key" must be a string; got '
        '${value.runtimeType}.',
      );
    }
    return value;
  }

  /// A boolean at [key], defaulting to [fallback].
  static bool boolean(
    Map<String, dynamic> json,
    String key, {
    bool fallback = false,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is! bool) {
      throw FormatException(
        'Field "${json['id']}": "$key" must be a boolean; got '
        '${value.runtimeType}.',
      );
    }
    return value;
  }

  /// An optional integer at [key].
  ///
  /// A JSON number that arrived as `3.0` is an integer that survived a
  /// JavaScript round trip. Accepting it costs nothing; rejecting it makes a
  /// document fail to parse on one platform that parsed fine on another.
  static int? integer(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double && value == value.roundToDouble() && value.isFinite) {
      return value.toInt();
    }
    throw FormatException(
      'Field "${json['id']}": "$key" must be a whole number; got $value.',
    );
  }

  /// The field's `defaultValue` as text, or null.
  ///
  /// Coerced rather than type-checked: a number field's default is written as
  /// a number in a document and held as a `String` by the widget, and refusing
  /// `{"defaultValue": 1}` on a number field would be pedantry that helps
  /// nobody.
  static String? defaultText(Map<String, dynamic> json) {
    final value = json['defaultValue'];
    if (value == null) return null;
    if (value is String) return value;
    return '$value';
  }

  /// The `options` list.
  ///
  /// Each entry is `{"value": ..., "label"?: ..., "hintText"?: ...}`, or a bare
  /// string, which is both the value and the label. The bare form exists
  /// because an options list written by hand usually means the two to be the
  /// same, and a document full of `{"value": "a", "label": "a"}` is noise.
  static List<FieldOption> options(Map<String, dynamic> json) {
    final raw = json['options'];
    if (raw == null) return const [];
    if (raw is! List) {
      throw FormatException(
        'Field "${json['id']}": "options" must be a list; got '
        '${raw.runtimeType}.',
      );
    }
    return [
      for (final entry in raw) _option(entry, json['id']),
    ];
  }

  static FieldOption _option(dynamic entry, dynamic fieldId) {
    if (entry is String) return FieldOption(value: entry);
    if (entry is Map) {
      final value = entry['value'];
      if (value is! String || value.isEmpty) {
        throw FormatException(
          'Field "$fieldId": every option needs a non-empty "value"; got '
          '$value.',
        );
      }
      return FieldOption(
        value: value,
        label: entry['label'] as String?,
        hintText: entry['hintText'] as String?,
      );
    }
    throw FormatException(
      'Field "$fieldId": an option must be a string or an object; got '
      '${entry.runtimeType}.',
    );
  }

  /// The `defaultValue` of a selection field, resolved against [options].
  ///
  /// Accepts a scalar (single-select) or a list (multi-select). **Values with
  /// no matching option are dropped rather than invented**: an option removed
  /// from the document since the value was stored must not reappear as a
  /// selectable choice just because something once selected it.
  static List<FieldOption> defaultSelection(
    Map<String, dynamic> json,
    List<FieldOption> options,
  ) {
    final raw = json['defaultValue'];
    if (raw == null) return const [];
    final wanted = raw is List
        ? raw.map((entry) => '$entry').toSet()
        : {'$raw'};
    return [
      for (final option in options)
        if (wanted.contains(option.value)) option,
    ];
  }

  /// The `validators` list, resolved through [ValidatorRegistry].
  ///
  /// Returns null rather than an empty list when the key is absent, because
  /// `Field.validators` is nullable and `[]` is a *different* statement from
  /// "not specified" to code that inspects it.
  ///
  /// Throws [UnknownValidatorException] when a name is not registered. It
  /// throws rather than skipping, because a validator that silently vanishes
  /// is a rule that stops protecting the data it was written for, and the
  /// failure shows up as bad rows rather than as an error.
  static List<Validator>? validators(Map<String, dynamic> json) {
    final raw = json['validators'];
    if (raw == null) return null;
    if (raw is! List) {
      throw FormatException(
        'Field "${json['id']}": "validators" must be a list; got '
        '${raw.runtimeType}.',
      );
    }
    return [
      for (final entry in raw)
        NamedValidator.fromJson(
          entry is String
              // A bare string is a validator that takes no parameters. Most
              // of them do not.
              ? {'name': entry}
              : Map<String, dynamic>.from(entry as Map),
        ).resolve(),
    ];
  }

  /// The `conditional` block, or null.
  static FieldCondition? conditional(Map<String, dynamic> json) {
    final raw = json['conditional'];
    if (raw == null) return null;
    if (raw is! Map) {
      throw FormatException(
        'Field "${json['id']}": "conditional" must be an object; got '
        '${raw.runtimeType}.',
      );
    }
    return FieldCondition.fromJson(Map<String, dynamic>.from(raw));
  }
}
