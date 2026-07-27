import 'package:championforms/functions/defaultvalidators/defaultvalidators.dart';
import 'package:championforms/models/multiselect_option.dart';
import 'package:championforms/models/validatorclass.dart';
import 'package:flutter/foundation.dart' as flutter;

/// Builds a [Validator] from a parameter map.
///
/// The parameters come straight from a serialized document, so a factory must
/// treat every one of them as untrusted: read what it needs, coerce leniently
/// (a JSON round trip turns `2` into `2.0` and back), and fall back to a
/// sensible default rather than throwing on a key it does not recognise.
typedef NamedValidatorFactory = Validator Function(Map<String, dynamic> params);

/// The registry that turns a validator *name* into a [Validator].
///
/// A [Validator] is a closure, which is the right shape for a form written in
/// Dart and the wrong shape for a form that arrives as data. This registry is
/// the bridge: a document names `"maxLength"` and supplies `{"max": 254}`, and
/// what comes back out is an ordinary [Validator] that the existing form
/// machinery already knows how to run. Nothing downstream of [resolve] can tell
/// the difference between a validator that came from here and one written by
/// hand, which is the property that makes this addition non-breaking.
///
/// ```dart
/// ValidatorRegistry.ensureInitialized();       // the built-ins
///
/// ValidatorRegistry.register('evenNumber', (params) => Validator(
///   validator: (value) => (int.tryParse('$value') ?? 1).isEven,
///   reason: params['reason'] as String? ?? 'must be an even number',
/// ));
///
/// final rule = ValidatorRegistry.resolve('evenNumber');
/// ```
///
/// ## Every built-in takes a `reason`
///
/// [Validator.reason] is a fixed string chosen at construction, so a registry
/// entry cannot compute a message from the value it rejected. Every built-in
/// therefore accepts a `reason` parameter and falls back to a plain-English
/// default that names the constraint. A caller that needs a message assembled
/// from the value itself still needs a hand-written [Validator]; that is a
/// limitation of [Validator], not of this registry.
class ValidatorRegistry {
  ValidatorRegistry._internal();

  static final ValidatorRegistry _instance = ValidatorRegistry._internal();

  /// The singleton. Provided for symmetry with `FormFieldRegistry.instance`;
  /// prefer the static methods.
  static ValidatorRegistry get instance => _instance;

  final Map<String, NamedValidatorFactory> _factories = {};

  bool _builtInsRegistered = false;

  /// Whether the built-in validators have been registered.
  bool get isInitialized => _builtInsRegistered;

  /// Registers [factory] under [name], replacing any previous entry.
  ///
  /// Replacing is deliberate and warns rather than throws: overriding a
  /// built-in — a stricter `email`, a localised `required` message — is a
  /// legitimate reason to call this, and an exception would make it impossible.
  static void register(String name, NamedValidatorFactory factory) {
    if (_instance._factories.containsKey(name)) {
      flutter.debugPrint('Warning: Overwriting validator "$name"');
    }
    _instance._factories[name] = factory;
  }

  /// Whether anything is registered under [name].
  static bool hasValidator(String name) =>
      _instance._factories.containsKey(name);

  /// Every registered validator name.
  static Iterable<String> get registeredNames => _instance._factories.keys;

  /// Builds the validator registered under [name], or `null` if there is none.
  ///
  /// Returns `null` rather than throwing so a caller can decide what an unknown
  /// name means — a decoder may want to report every unresolvable rule in one
  /// pass instead of dying on the first. `NamedValidator.resolve` is the
  /// throwing wrapper for the common case.
  static Validator? resolve(
    String name, {
    Map<String, dynamic> params = const {},
  }) {
    final factory = _instance._factories[name];
    if (factory == null) return null;
    return factory(params);
  }

  /// Removes every registration, including the built-ins.
  ///
  /// For tests. After this, [ensureInitialized] will re-register the built-ins.
  static void reset() {
    _instance._factories.clear();
    _instance._builtInsRegistered = false;
  }

  /// Registers the built-in validators if they are not already registered.
  ///
  /// Idempotent and cheap. Unlike field builders — which the `Form` widget
  /// registers on its first build — nothing registers these implicitly,
  /// because resolving a validator usually happens while *parsing* a document,
  /// before any form is on screen.
  static void ensureInitialized() {
    if (_instance._builtInsRegistered) return;
    _instance._builtInsRegistered = true;
    _instance._registerBuiltIns();
  }

  void _registerBuiltIns() {
    // ── Presence ────────────────────────────────────────────────────────────
    register('required', (params) => Validator(
          validator: _isPresent,
          reason: _reason(params, 'is required'),
        ));

    register('notEmpty', (params) => Validator(
          validator: Validators.stringIsNotEmpty,
          reason: _reason(params, 'cannot be empty'),
        ));

    register('listNotEmpty', (params) => Validator(
          validator: Validators.listIsNotEmpty,
          reason: _reason(params, 'needs at least one selection'),
        ));

    // ── Format ──────────────────────────────────────────────────────────────
    register('email', (params) => Validator(
          validator: Validators.isEmailOrNull,
          reason: _reason(params, 'must be a valid email address'),
        ));

    register('url', (params) => Validator(
          validator: Validators.isUrlOrNull,
          reason: _reason(params, 'must be a valid URL'),
        ));

    register('tel', (params) => Validator(
          validator: Validators.isPhoneOrNull,
          reason: _reason(params, 'must be a valid phone number'),
        ));

    register('integer', (params) => Validator(
          validator: Validators.isIntegerOrNull,
          reason: _reason(params, 'must be a whole number'),
        ));

    register('number', (params) => Validator(
          validator: Validators.isDoubleOrNull,
          reason: _reason(params, 'must be a number'),
        ));

    register('regex', (params) {
      final pattern = params['pattern'] as String? ?? '';
      // Compiled once per resolve, never per keystroke: a validator runs on
      // every change, and RegExp compilation is not free.
      final expression = RegExp(pattern);
      return Validator(
        validator: (value) {
          if (_isBlank(value)) return true;
          return expression.hasMatch(value.toString());
        },
        reason: _reason(params, 'is not in the expected format'),
      );
    });

    // ── Length ──────────────────────────────────────────────────────────────
    register('minLength', (params) {
      final min = _asInt(params['min']) ?? 0;
      return Validator(
        validator: Validators(minLength: min).stringLengthInRange,
        reason: _reason(params, 'must be at least $min characters'),
      );
    });

    register('maxLength', (params) {
      final max = _asInt(params['max']);
      return Validator(
        validator: Validators(maxLength: max).stringLengthInRange,
        reason: _reason(params, 'must be at most $max characters'),
      );
    });

    register('lengthRange', (params) {
      final min = _asInt(params['min']);
      final max = _asInt(params['max']);
      return Validator(
        validator: Validators(minLength: min, maxLength: max)
            .stringLengthInRange,
        reason: _reason(params, 'must be between $min and $max characters'),
      );
    });

    // ── Magnitude ───────────────────────────────────────────────────────────
    register('min', (params) {
      final min = _asDouble(params['min']);
      return Validator(
        validator: (value) {
          if (_isBlank(value)) return true;
          final number = _asDouble(value);
          if (number == null || min == null) return false;
          return number >= min;
        },
        reason: _reason(params, 'must be at least ${_trim(min)}'),
      );
    });

    register('max', (params) {
      final max = _asDouble(params['max']);
      return Validator(
        validator: (value) {
          if (_isBlank(value)) return true;
          final number = _asDouble(value);
          if (number == null || max == null) return false;
          return number <= max;
        },
        reason: _reason(params, 'must be at most ${_trim(max)}'),
      );
    });

    // ── Membership ──────────────────────────────────────────────────────────
    register('oneOf', (params) {
      final allowed = (params['values'] as List?)
              ?.map((v) => v.toString())
              .toSet() ??
          const <String>{};
      return Validator(
        validator: (value) {
          if (_isBlank(value)) return true;
          // A multi-select answers with a list; every member has to be allowed,
          // not merely the first, or an injected extra option slips through.
          if (value is List) {
            return value.every((v) => allowed.contains(_optionValue(v)));
          }
          return allowed.contains(_optionValue(value));
        },
        reason: _reason(params, 'is not one of the available choices'),
      );
    });
  }

  // ── Shared coercion ───────────────────────────────────────────────────────
  //
  // Every one of these tolerates the round trip a value takes through JSON and
  // through a text field: an int arrives as `2.0`, a number arrives as the
  // string `"2"`, and an untouched field arrives as `''` rather than null.

  static String _reason(Map<String, dynamic> params, String fallback) =>
      params['reason'] as String? ?? fallback;

  static bool _isBlank(dynamic value) =>
      value == null || (value is String && value.trim().isEmpty);

  static bool _isPresent(dynamic value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable) return value.isNotEmpty;
    if (value is Map) return value.isNotEmpty;
    if (value is bool) return value;
    return true;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is double && value == value.roundToDouble()) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }

  static String _trim(double? value) {
    if (value == null) return '?';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  /// The comparable string behind a selection.
  ///
  /// A select field's value is a `FieldOption`, not a `String`, so `oneOf` has
  /// to reach through it — comparing the object's `toString()` would fail for
  /// every option ever selected through the UI while passing for the same value
  /// typed into a JSON document, which is the worst possible split.
  static String _optionValue(dynamic value) =>
      value is FieldOption ? value.value : value.toString();
}
