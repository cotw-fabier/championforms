// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiselect_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$multiSelectOptionNotifierHash() =>
    r'96f6b94a704d2a6bd762ea96a764eebe83025632';

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

abstract class _$MultiSelectOptionNotifier
    extends BuildlessAutoDisposeNotifier<List<MultiselectOption>> {
  late final String id;

  List<MultiselectOption> build(
    String id,
  );
}

/// See also [MultiSelectOptionNotifier].
@ProviderFor(MultiSelectOptionNotifier)
const multiSelectOptionNotifierProvider = MultiSelectOptionNotifierFamily();

/// See also [MultiSelectOptionNotifier].
class MultiSelectOptionNotifierFamily extends Family<List<MultiselectOption>> {
  /// See also [MultiSelectOptionNotifier].
  const MultiSelectOptionNotifierFamily();

  /// See also [MultiSelectOptionNotifier].
  MultiSelectOptionNotifierProvider call(
    String id,
  ) {
    return MultiSelectOptionNotifierProvider(
      id,
    );
  }

  @override
  MultiSelectOptionNotifierProvider getProviderOverride(
    covariant MultiSelectOptionNotifierProvider provider,
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
  String? get name => r'multiSelectOptionNotifierProvider';
}

/// See also [MultiSelectOptionNotifier].
class MultiSelectOptionNotifierProvider extends AutoDisposeNotifierProviderImpl<
    MultiSelectOptionNotifier, List<MultiselectOption>> {
  /// See also [MultiSelectOptionNotifier].
  MultiSelectOptionNotifierProvider(
    String id,
  ) : this._internal(
          () => MultiSelectOptionNotifier()..id = id,
          from: multiSelectOptionNotifierProvider,
          name: r'multiSelectOptionNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$multiSelectOptionNotifierHash,
          dependencies: MultiSelectOptionNotifierFamily._dependencies,
          allTransitiveDependencies:
              MultiSelectOptionNotifierFamily._allTransitiveDependencies,
          id: id,
        );

  MultiSelectOptionNotifierProvider._internal(
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
  List<MultiselectOption> runNotifierBuild(
    covariant MultiSelectOptionNotifier notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(MultiSelectOptionNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MultiSelectOptionNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<MultiSelectOptionNotifier,
      List<MultiselectOption>> createElement() {
    return _MultiSelectOptionNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MultiSelectOptionNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin MultiSelectOptionNotifierRef
    on AutoDisposeNotifierProviderRef<List<MultiselectOption>> {
  /// The parameter `id` of this provider.
  String get id;
}

class _MultiSelectOptionNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<MultiSelectOptionNotifier,
        List<MultiselectOption>> with MultiSelectOptionNotifierRef {
  _MultiSelectOptionNotifierProviderElement(super.provider);

  @override
  String get id => (origin as MultiSelectOptionNotifierProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
