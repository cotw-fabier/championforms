// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'choicechipprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$choiceChipNotifierHash() =>
    r'34bb5db76e6e58338fc0fefc2a865beb35d58504';

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

abstract class _$ChoiceChipNotifier
    extends BuildlessAutoDisposeNotifier<List<ChoiceChipValue>> {
  late final String id;

  List<ChoiceChipValue> build(
    String id,
  );
}

/// See also [ChoiceChipNotifier].
@ProviderFor(ChoiceChipNotifier)
const choiceChipNotifierProvider = ChoiceChipNotifierFamily();

/// See also [ChoiceChipNotifier].
class ChoiceChipNotifierFamily extends Family<List<ChoiceChipValue>> {
  /// See also [ChoiceChipNotifier].
  const ChoiceChipNotifierFamily();

  /// See also [ChoiceChipNotifier].
  ChoiceChipNotifierProvider call(
    String id,
  ) {
    return ChoiceChipNotifierProvider(
      id,
    );
  }

  @override
  ChoiceChipNotifierProvider getProviderOverride(
    covariant ChoiceChipNotifierProvider provider,
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
  String? get name => r'choiceChipNotifierProvider';
}

/// See also [ChoiceChipNotifier].
class ChoiceChipNotifierProvider extends AutoDisposeNotifierProviderImpl<
    ChoiceChipNotifier, List<ChoiceChipValue>> {
  /// See also [ChoiceChipNotifier].
  ChoiceChipNotifierProvider(
    String id,
  ) : this._internal(
          () => ChoiceChipNotifier()..id = id,
          from: choiceChipNotifierProvider,
          name: r'choiceChipNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$choiceChipNotifierHash,
          dependencies: ChoiceChipNotifierFamily._dependencies,
          allTransitiveDependencies:
              ChoiceChipNotifierFamily._allTransitiveDependencies,
          id: id,
        );

  ChoiceChipNotifierProvider._internal(
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
  List<ChoiceChipValue> runNotifierBuild(
    covariant ChoiceChipNotifier notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(ChoiceChipNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: ChoiceChipNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<ChoiceChipNotifier, List<ChoiceChipValue>>
      createElement() {
    return _ChoiceChipNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ChoiceChipNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin ChoiceChipNotifierRef
    on AutoDisposeNotifierProviderRef<List<ChoiceChipValue>> {
  /// The parameter `id` of this provider.
  String get id;
}

class _ChoiceChipNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<ChoiceChipNotifier,
        List<ChoiceChipValue>> with ChoiceChipNotifierRef {
  _ChoiceChipNotifierProviderElement(super.provider);

  @override
  String get id => (origin as ChoiceChipNotifierProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
