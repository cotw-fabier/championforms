import 'package:championforms/core/validator_registry.dart';
import 'package:championforms/models/validatorclass.dart';

/// A validator referenced **by name**, with its parameters, instead of by
/// closure.
///
/// [Validator] wraps a `bool Function(dynamic)`. That is the right shape for a
/// form written in Dart, and the wrong shape for a form that arrives as data —
/// a closure cannot be stored in a database row, diffed between two versions of
/// a form, rendered in a visual builder, or sent to a server so the same rule
/// runs on both sides of the wire.
///
/// A [NamedValidator] is the serializable half of the same idea. It carries a
/// registry key and a parameter map, and [resolve] turns it back into the
/// ordinary [Validator] the rest of the package already understands:
///
/// ```dart
/// ValidatorRegistry.ensureInitialized();
///
/// const rule = NamedValidator('maxLength', params: {'max': 254});
/// final field = TextField(id: 'email', validators: [rule.resolve()]);
/// ```
///
/// Nothing about the existing closure API changes. A hand-built form that
/// passes `Validator(validator: ..., reason: ...)` is unaffected, and a form
/// may mix the two freely.
class NamedValidator {
  /// Creates a reference to the validator registered under [name].
  const NamedValidator(this.name, {this.params = const {}});

  /// The registry key, e.g. `'maxLength'`.
  ///
  /// Resolved against [ValidatorRegistry] at [resolve] time rather than at
  /// construction, so a document may be parsed before the registry has been
  /// populated — which is the normal order when custom validators are
  /// registered during app start-up.
  final String name;

  /// The validator's parameters, e.g. `{'max': 254}`.
  ///
  /// Left untyped because a registry is open by definition: the package cannot
  /// know what a caller's `'creditCard'` validator needs. Each factory is
  /// responsible for reading what it needs and tolerating what it does not
  /// recognise.
  final Map<String, dynamic> params;

  /// Decodes `{"name": ..., "params": {...}}`.
  ///
  /// Throws [FormatException] when `name` is missing or is not a non-empty
  /// string. A missing `params` is an empty map — most validators take none,
  /// and requiring the key would make every hand-written document noisier for
  /// no gain.
  factory NamedValidator.fromJson(Map<String, dynamic> json) {
    final name = json['name'];
    if (name is! String || name.isEmpty) {
      return throw FormatException(
        'A named validator needs a non-empty "name"; got ${json['name']}.',
      );
    }
    final params = json['params'];
    if (params != null && params is! Map) {
      throw FormatException(
        'Validator "$name" has a "params" that is not an object: $params.',
      );
    }
    return NamedValidator(
      name,
      params: params == null
          ? const {}
          : Map<String, dynamic>.from(params as Map),
    );
  }

  /// The JSON form. `params` is omitted when empty so a round trip through
  /// this pair does not grow the document.
  Map<String, dynamic> toJson() => {
        'name': name,
        if (params.isNotEmpty) 'params': params,
      };

  /// Builds the [Validator] this reference names.
  ///
  /// Throws [UnknownValidatorException] when nothing is registered under
  /// [name]. It throws rather than returning a validator that always passes,
  /// because a silently-passing rule is a rule that stops protecting the data
  /// it was written for, and nobody finds out until the bad row is already
  /// stored.
  Validator resolve() {
    final validator = ValidatorRegistry.resolve(name, params: params);
    if (validator == null) {
      throw UnknownValidatorException(name);
    }
    return validator;
  }

  /// Resolves a whole list, in order.
  ///
  /// Order is preserved because [Validator]s run in order and the first failure
  /// is the message a person reads.
  static List<Validator> resolveAll(Iterable<NamedValidator> validators) =>
      validators.map((v) => v.resolve()).toList();

  @override
  bool operator ==(Object other) =>
      other is NamedValidator &&
      other.name == name &&
      _mapsEqual(other.params, params);

  @override
  int get hashCode => Object.hash(name, params.length);

  @override
  String toString() =>
      params.isEmpty ? 'NamedValidator($name)' : 'NamedValidator($name, $params)';

  static bool _mapsEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key)) return false;
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}

/// Thrown when a [NamedValidator] names a validator nothing has registered.
///
/// The message lists what *is* registered, because the overwhelmingly common
/// cause is a typo or a missing `ValidatorRegistry.register` call at start-up,
/// and both are obvious the moment the available names are in front of you.
class UnknownValidatorException implements Exception {
  /// Creates the exception for [name].
  UnknownValidatorException(this.name);

  /// The unresolvable validator name.
  final String name;

  @override
  String toString() {
    final known = ValidatorRegistry.registeredNames.toList()..sort();
    return 'UnknownValidatorException: no validator is registered under '
        '"$name". Registered: ${known.isEmpty ? '<none>' : known.join(', ')}. '
        'Call ValidatorRegistry.ensureInitialized() for the built-ins, or '
        'ValidatorRegistry.register("$name", ...) for your own.';
  }
}
