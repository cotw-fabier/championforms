// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formbuilderprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fieldControllerNotifierHash() =>
    r'f06e4a3a1f9f4cb4796a6f6f42c37ab4579cb70d';

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

abstract class _$FieldControllerNotifier
    extends BuildlessAutoDisposeNotifier<TextEditingController> {
  late final String id;

  TextEditingController build(
    String id,
  );
}

/// See also [FieldControllerNotifier].
@ProviderFor(FieldControllerNotifier)
const fieldControllerNotifierProvider = FieldControllerNotifierFamily();

/// See also [FieldControllerNotifier].
class FieldControllerNotifierFamily extends Family<TextEditingController> {
  /// See also [FieldControllerNotifier].
  const FieldControllerNotifierFamily();

  /// See also [FieldControllerNotifier].
  FieldControllerNotifierProvider call(
    String id,
  ) {
    return FieldControllerNotifierProvider(
      id,
    );
  }

  @override
  FieldControllerNotifierProvider getProviderOverride(
    covariant FieldControllerNotifierProvider provider,
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
  String? get name => r'fieldControllerNotifierProvider';
}

/// See also [FieldControllerNotifier].
class FieldControllerNotifierProvider extends AutoDisposeNotifierProviderImpl<
    FieldControllerNotifier, TextEditingController> {
  /// See also [FieldControllerNotifier].
  FieldControllerNotifierProvider(
    String id,
  ) : this._internal(
          () => FieldControllerNotifier()..id = id,
          from: fieldControllerNotifierProvider,
          name: r'fieldControllerNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldControllerNotifierHash,
          dependencies: FieldControllerNotifierFamily._dependencies,
          allTransitiveDependencies:
              FieldControllerNotifierFamily._allTransitiveDependencies,
          id: id,
        );

  FieldControllerNotifierProvider._internal(
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
  TextEditingController runNotifierBuild(
    covariant FieldControllerNotifier notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(FieldControllerNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FieldControllerNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<FieldControllerNotifier,
      TextEditingController> createElement() {
    return _FieldControllerNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldControllerNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FieldControllerNotifierRef
    on AutoDisposeNotifierProviderRef<TextEditingController> {
  /// The parameter `id` of this provider.
  String get id;
}

class _FieldControllerNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FieldControllerNotifier,
        TextEditingController> with FieldControllerNotifierRef {
  _FieldControllerNotifierProviderElement(super.provider);

  @override
  String get id => (origin as FieldControllerNotifierProvider).id;
}

String _$fieldFocusNotifierHash() =>
    r'f4108a90a79e5d2d5a64e41d5303239ef43a35d0';

abstract class _$FieldFocusNotifier
    extends BuildlessAutoDisposeNotifier<FocusNode> {
  late final String id;

  FocusNode build(
    String id,
  );
}

/// See also [FieldFocusNotifier].
@ProviderFor(FieldFocusNotifier)
const fieldFocusNotifierProvider = FieldFocusNotifierFamily();

/// See also [FieldFocusNotifier].
class FieldFocusNotifierFamily extends Family<FocusNode> {
  /// See also [FieldFocusNotifier].
  const FieldFocusNotifierFamily();

  /// See also [FieldFocusNotifier].
  FieldFocusNotifierProvider call(
    String id,
  ) {
    return FieldFocusNotifierProvider(
      id,
    );
  }

  @override
  FieldFocusNotifierProvider getProviderOverride(
    covariant FieldFocusNotifierProvider provider,
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
  String? get name => r'fieldFocusNotifierProvider';
}

/// See also [FieldFocusNotifier].
class FieldFocusNotifierProvider
    extends AutoDisposeNotifierProviderImpl<FieldFocusNotifier, FocusNode> {
  /// See also [FieldFocusNotifier].
  FieldFocusNotifierProvider(
    String id,
  ) : this._internal(
          () => FieldFocusNotifier()..id = id,
          from: fieldFocusNotifierProvider,
          name: r'fieldFocusNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldFocusNotifierHash,
          dependencies: FieldFocusNotifierFamily._dependencies,
          allTransitiveDependencies:
              FieldFocusNotifierFamily._allTransitiveDependencies,
          id: id,
        );

  FieldFocusNotifierProvider._internal(
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
  FocusNode runNotifierBuild(
    covariant FieldFocusNotifier notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(FieldFocusNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FieldFocusNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<FieldFocusNotifier, FocusNode>
      createElement() {
    return _FieldFocusNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldFocusNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FieldFocusNotifierRef on AutoDisposeNotifierProviderRef<FocusNode> {
  /// The parameter `id` of this provider.
  String get id;
}

class _FieldFocusNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FieldFocusNotifier, FocusNode>
    with FieldFocusNotifierRef {
  _FieldFocusNotifierProviderElement(super.provider);

  @override
  String get id => (origin as FieldFocusNotifierProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
