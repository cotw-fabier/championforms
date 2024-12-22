// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field_focus.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fieldFocusNotifierHash() =>
    r'5eabaa8b05af7a557a77d7eb92850d019a8f85e9';

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

abstract class _$FieldFocusNotifier extends BuildlessAutoDisposeNotifier<bool> {
  late final String fieldId;

  bool build(
    String fieldId,
  );
}

/// See also [FieldFocusNotifier].
@ProviderFor(FieldFocusNotifier)
const fieldFocusNotifierProvider = FieldFocusNotifierFamily();

/// See also [FieldFocusNotifier].
class FieldFocusNotifierFamily extends Family<bool> {
  /// See also [FieldFocusNotifier].
  const FieldFocusNotifierFamily();

  /// See also [FieldFocusNotifier].
  FieldFocusNotifierProvider call(
    String fieldId,
  ) {
    return FieldFocusNotifierProvider(
      fieldId,
    );
  }

  @override
  FieldFocusNotifierProvider getProviderOverride(
    covariant FieldFocusNotifierProvider provider,
  ) {
    return call(
      provider.fieldId,
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
    extends AutoDisposeNotifierProviderImpl<FieldFocusNotifier, bool> {
  /// See also [FieldFocusNotifier].
  FieldFocusNotifierProvider(
    String fieldId,
  ) : this._internal(
          () => FieldFocusNotifier()..fieldId = fieldId,
          from: fieldFocusNotifierProvider,
          name: r'fieldFocusNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$fieldFocusNotifierHash,
          dependencies: FieldFocusNotifierFamily._dependencies,
          allTransitiveDependencies:
              FieldFocusNotifierFamily._allTransitiveDependencies,
          fieldId: fieldId,
        );

  FieldFocusNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.fieldId,
  }) : super.internal();

  final String fieldId;

  @override
  bool runNotifierBuild(
    covariant FieldFocusNotifier notifier,
  ) {
    return notifier.build(
      fieldId,
    );
  }

  @override
  Override overrideWith(FieldFocusNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FieldFocusNotifierProvider._internal(
        () => create()..fieldId = fieldId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        fieldId: fieldId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<FieldFocusNotifier, bool> createElement() {
    return _FieldFocusNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FieldFocusNotifierProvider && other.fieldId == fieldId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, fieldId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FieldFocusNotifierRef on AutoDisposeNotifierProviderRef<bool> {
  /// The parameter `fieldId` of this provider.
  String get fieldId;
}

class _FieldFocusNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FieldFocusNotifier, bool>
    with FieldFocusNotifierRef {
  _FieldFocusNotifierProviderElement(super.provider);

  @override
  String get fieldId => (origin as FieldFocusNotifierProvider).fieldId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
