// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formfield_value_by_id.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$textFormFieldValueByIdHash() =>
    r'a76ef4dcbbb0772d861a90e5236f601901161015';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$TextFormFieldValueById
    extends BuildlessAutoDisposeNotifier<String> {
  late final String id;

  String build(
    String id,
  );
}

/// See also [TextFormFieldValueById].
@ProviderFor(TextFormFieldValueById)
const textFormFieldValueByIdProvider = TextFormFieldValueByIdFamily();

/// See also [TextFormFieldValueById].
class TextFormFieldValueByIdFamily extends Family<String> {
  /// See also [TextFormFieldValueById].
  const TextFormFieldValueByIdFamily();

  /// See also [TextFormFieldValueById].
  TextFormFieldValueByIdProvider call(
    String id,
  ) {
    return TextFormFieldValueByIdProvider(
      id,
    );
  }

  @override
  TextFormFieldValueByIdProvider getProviderOverride(
    covariant TextFormFieldValueByIdProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'textFormFieldValueByIdProvider';
}

/// See also [TextFormFieldValueById].
class TextFormFieldValueByIdProvider
    extends AutoDisposeNotifierProviderImpl<TextFormFieldValueById, String> {
  /// See also [TextFormFieldValueById].
  TextFormFieldValueByIdProvider(
    String id,
  ) : this._internal(
          () => TextFormFieldValueById()..id = id,
          from: textFormFieldValueByIdProvider,
          name: r'textFormFieldValueByIdProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$textFormFieldValueByIdHash,
          dependencies: TextFormFieldValueByIdFamily._dependencies,
          allTransitiveDependencies:
              TextFormFieldValueByIdFamily._allTransitiveDependencies,
          id: id,
        );

  TextFormFieldValueByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  String runNotifierBuild(
    covariant TextFormFieldValueById notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(TextFormFieldValueById Function() create) {
    return ProviderOverride(
      origin: this,
      override: TextFormFieldValueByIdProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<TextFormFieldValueById, String>
      createElement() {
    return _TextFormFieldValueByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TextFormFieldValueByIdProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin TextFormFieldValueByIdRef on AutoDisposeNotifierProviderRef<String> {
  /// The parameter `id` of this provider.
  String get id;
}

class _TextFormFieldValueByIdProviderElement
    extends AutoDisposeNotifierProviderElement<TextFormFieldValueById, String>
    with TextFormFieldValueByIdRef {
  _TextFormFieldValueByIdProviderElement(super.provider);

  @override
  String get id => (origin as TextFormFieldValueByIdProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
