// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formliststringsprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$formListStringsNotifierHash() =>
    r'c95db9ae4be2c8230d51a3a303b60735810dab00';

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

abstract class _$FormListStringsNotifier
    extends BuildlessAutoDisposeNotifier<List<String>> {
  late final String id;

  List<String> build(
    String id,
  );
}

/// See also [FormListStringsNotifier].
@ProviderFor(FormListStringsNotifier)
const formListStringsNotifierProvider = FormListStringsNotifierFamily();

/// See also [FormListStringsNotifier].
class FormListStringsNotifierFamily extends Family<List<String>> {
  /// See also [FormListStringsNotifier].
  const FormListStringsNotifierFamily();

  /// See also [FormListStringsNotifier].
  FormListStringsNotifierProvider call(
    String id,
  ) {
    return FormListStringsNotifierProvider(
      id,
    );
  }

  @override
  FormListStringsNotifierProvider getProviderOverride(
    covariant FormListStringsNotifierProvider provider,
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
  String? get name => r'formListStringsNotifierProvider';
}

/// See also [FormListStringsNotifier].
class FormListStringsNotifierProvider extends AutoDisposeNotifierProviderImpl<
    FormListStringsNotifier, List<String>> {
  /// See also [FormListStringsNotifier].
  FormListStringsNotifierProvider(
    String id,
  ) : this._internal(
          () => FormListStringsNotifier()..id = id,
          from: formListStringsNotifierProvider,
          name: r'formListStringsNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formListStringsNotifierHash,
          dependencies: FormListStringsNotifierFamily._dependencies,
          allTransitiveDependencies:
              FormListStringsNotifierFamily._allTransitiveDependencies,
          id: id,
        );

  FormListStringsNotifierProvider._internal(
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
  List<String> runNotifierBuild(
    covariant FormListStringsNotifier notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(FormListStringsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FormListStringsNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<FormListStringsNotifier, List<String>>
      createElement() {
    return _FormListStringsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormListStringsNotifierProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FormListStringsNotifierRef
    on AutoDisposeNotifierProviderRef<List<String>> {
  /// The parameter `id` of this provider.
  String get id;
}

class _FormListStringsNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FormListStringsNotifier,
        List<String>> with FormListStringsNotifierRef {
  _FormListStringsNotifierProviderElement(super.provider);

  @override
  String get id => (origin as FormListStringsNotifierProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
