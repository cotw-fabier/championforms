// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fieldactiveprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fieldActiveNotifierHash() =>
    r'ba9924ea395675ea6013483aa41cd2591e5dc75f';

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

abstract class _$FieldActiveNotifier
    extends BuildlessAutoDisposeNotifier<String> {
  late final String formId;

  String build(
    String formId,
  );
}

/// See also [FieldActiveNotifier].
@ProviderFor(FieldActiveNotifier)
const fieldActiveNotifierProvider = FieldActiveNotifierFamily();

/// See also [FieldActiveNotifier].
class FieldActiveNotifierFamily extends Family<String> {
  /// See also [FieldActiveNotifier].
  const FieldActiveNotifierFamily();

  /// See also [FieldActiveNotifier].
  FieldActiveNotifierProvider call(
    String formId,
  ) {
    return FieldActiveNotifierProvider(
      formId,
    );
  }

  @override
  FieldActiveNotifierProvider getProviderOverride(
    covariant FieldActiveNotifierProvider provider,
  ) {
    return call(
      provider.formId,
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
  String? get name => r'fieldActiveNotifierProvider';
}

/// See also [FieldActiveNotifier].
class FieldActiveNotifierProvider
    extends AutoDisposeNotifierProviderImpl<FieldActiveNotifier, String> {
  /// See also [FieldActiveNotifier].
  FieldActiveNotifierProvider(
    String formId,
  ) : this._internal(
          () => FieldActiveNotifier()..formId = formId,
          from: fieldActiveNotifierProvider,
          name: r'fieldActiveNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldActiveNotifierHash,
          dependencies: FieldActiveNotifierFamily._dependencies,
          allTransitiveDependencies:
              FieldActiveNotifierFamily._allTransitiveDependencies,
          formId: formId,
        );

  FieldActiveNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.formId,
  }) : super.internal();

  final String formId;

  @override
  String runNotifierBuild(
    covariant FieldActiveNotifier notifier,
  ) {
    return notifier.build(
      formId,
    );
  }

  @override
  Override overrideWith(FieldActiveNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FieldActiveNotifierProvider._internal(
        () => create()..formId = formId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        formId: formId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<FieldActiveNotifier, String>
      createElement() {
    return _FieldActiveNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldActiveNotifierProvider && other.formId == formId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, formId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FieldActiveNotifierRef on AutoDisposeNotifierProviderRef<String> {
  /// The parameter `formId` of this provider.
  String get formId;
}

class _FieldActiveNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FieldActiveNotifier, String>
    with FieldActiveNotifierRef {
  _FieldActiveNotifierProviderElement(super.provider);

  @override
  String get formId => (origin as FieldActiveNotifierProvider).formId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
