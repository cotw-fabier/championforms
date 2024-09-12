// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formfieldsstorage.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$formFieldsStorageNotifierHash() =>
    r'76c7715d1ef57c25db009a2ca36003cd82e0940f';

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

abstract class _$FormFieldsStorageNotifier
    extends BuildlessAutoDisposeNotifier<List<FormFieldDef>> {
  late final String formId;

  List<FormFieldDef> build(
    String formId,
  );
}

/// See also [FormFieldsStorageNotifier].
@ProviderFor(FormFieldsStorageNotifier)
const formFieldsStorageNotifierProvider = FormFieldsStorageNotifierFamily();

/// See also [FormFieldsStorageNotifier].
class FormFieldsStorageNotifierFamily extends Family<List<FormFieldDef>> {
  /// See also [FormFieldsStorageNotifier].
  const FormFieldsStorageNotifierFamily();

  /// See also [FormFieldsStorageNotifier].
  FormFieldsStorageNotifierProvider call(
    String formId,
  ) {
    return FormFieldsStorageNotifierProvider(
      formId,
    );
  }

  @override
  FormFieldsStorageNotifierProvider getProviderOverride(
    covariant FormFieldsStorageNotifierProvider provider,
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
  String? get name => r'formFieldsStorageNotifierProvider';
}

/// See also [FormFieldsStorageNotifier].
class FormFieldsStorageNotifierProvider extends AutoDisposeNotifierProviderImpl<
    FormFieldsStorageNotifier, List<FormFieldDef>> {
  /// See also [FormFieldsStorageNotifier].
  FormFieldsStorageNotifierProvider(
    String formId,
  ) : this._internal(
          () => FormFieldsStorageNotifier()..formId = formId,
          from: formFieldsStorageNotifierProvider,
          name: r'formFieldsStorageNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formFieldsStorageNotifierHash,
          dependencies: FormFieldsStorageNotifierFamily._dependencies,
          allTransitiveDependencies:
              FormFieldsStorageNotifierFamily._allTransitiveDependencies,
          formId: formId,
        );

  FormFieldsStorageNotifierProvider._internal(
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
  List<FormFieldDef> runNotifierBuild(
    covariant FormFieldsStorageNotifier notifier,
  ) {
    return notifier.build(
      formId,
    );
  }

  @override
  Override overrideWith(FormFieldsStorageNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FormFieldsStorageNotifierProvider._internal(
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
  AutoDisposeNotifierProviderElement<FormFieldsStorageNotifier,
      List<FormFieldDef>> createElement() {
    return _FormFieldsStorageNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormFieldsStorageNotifierProvider && other.formId == formId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, formId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FormFieldsStorageNotifierRef
    on AutoDisposeNotifierProviderRef<List<FormFieldDef>> {
  /// The parameter `formId` of this provider.
  String get formId;
}

class _FormFieldsStorageNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FormFieldsStorageNotifier,
        List<FormFieldDef>> with FormFieldsStorageNotifierRef {
  _FormFieldsStorageNotifierProviderElement(super.provider);

  @override
  String get formId => (origin as FormFieldsStorageNotifierProvider).formId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
