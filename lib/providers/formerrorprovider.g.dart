// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'formerrorprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$formBuilderErrorNotifierHash() =>
    r'83bf3a410f8f74fc789d2b3bb40fc06f027e7dff';

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

abstract class _$FormBuilderErrorNotifier
    extends BuildlessAutoDisposeNotifier<FormBuilderError?> {
  late final String formId;
  late final String fieldId;
  late final int validatorPosition;

  FormBuilderError? build(
    String formId,
    String fieldId,
    int validatorPosition,
  );
}

/// See also [FormBuilderErrorNotifier].
@ProviderFor(FormBuilderErrorNotifier)
const formBuilderErrorNotifierProvider = FormBuilderErrorNotifierFamily();

/// See also [FormBuilderErrorNotifier].
class FormBuilderErrorNotifierFamily extends Family<FormBuilderError?> {
  /// See also [FormBuilderErrorNotifier].
  const FormBuilderErrorNotifierFamily();

  /// See also [FormBuilderErrorNotifier].
  FormBuilderErrorNotifierProvider call(
    String formId,
    String fieldId,
    int validatorPosition,
  ) {
    return FormBuilderErrorNotifierProvider(
      formId,
      fieldId,
      validatorPosition,
    );
  }

  @override
  FormBuilderErrorNotifierProvider getProviderOverride(
    covariant FormBuilderErrorNotifierProvider provider,
  ) {
    return call(
      provider.formId,
      provider.fieldId,
      provider.validatorPosition,
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
  String? get name => r'formBuilderErrorNotifierProvider';
}

/// See also [FormBuilderErrorNotifier].
class FormBuilderErrorNotifierProvider extends AutoDisposeNotifierProviderImpl<
    FormBuilderErrorNotifier, FormBuilderError?> {
  /// See also [FormBuilderErrorNotifier].
  FormBuilderErrorNotifierProvider(
    String formId,
    String fieldId,
    int validatorPosition,
  ) : this._internal(
          () => FormBuilderErrorNotifier()
            ..formId = formId
            ..fieldId = fieldId
            ..validatorPosition = validatorPosition,
          from: formBuilderErrorNotifierProvider,
          name: r'formBuilderErrorNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$formBuilderErrorNotifierHash,
          dependencies: FormBuilderErrorNotifierFamily._dependencies,
          allTransitiveDependencies:
              FormBuilderErrorNotifierFamily._allTransitiveDependencies,
          formId: formId,
          fieldId: fieldId,
          validatorPosition: validatorPosition,
        );

  FormBuilderErrorNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.formId,
    required this.fieldId,
    required this.validatorPosition,
  }) : super.internal();

  final String formId;
  final String fieldId;
  final int validatorPosition;

  @override
  FormBuilderError? runNotifierBuild(
    covariant FormBuilderErrorNotifier notifier,
  ) {
    return notifier.build(
      formId,
      fieldId,
      validatorPosition,
    );
  }

  @override
  Override overrideWith(FormBuilderErrorNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: FormBuilderErrorNotifierProvider._internal(
        () => create()
          ..formId = formId
          ..fieldId = fieldId
          ..validatorPosition = validatorPosition,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        formId: formId,
        fieldId: fieldId,
        validatorPosition: validatorPosition,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<FormBuilderErrorNotifier,
      FormBuilderError?> createElement() {
    return _FormBuilderErrorNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is FormBuilderErrorNotifierProvider &&
        other.formId == formId &&
        other.fieldId == fieldId &&
        other.validatorPosition == validatorPosition;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, formId.hashCode);
    hash = _SystemHash.combine(hash, fieldId.hashCode);
    hash = _SystemHash.combine(hash, validatorPosition.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin FormBuilderErrorNotifierRef
    on AutoDisposeNotifierProviderRef<FormBuilderError?> {
  /// The parameter `formId` of this provider.
  String get formId;

  /// The parameter `fieldId` of this provider.
  String get fieldId;

  /// The parameter `validatorPosition` of this provider.
  int get validatorPosition;
}

class _FormBuilderErrorNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<FormBuilderErrorNotifier,
        FormBuilderError?> with FormBuilderErrorNotifierRef {
  _FormBuilderErrorNotifierProviderElement(super.provider);

  @override
  String get formId => (origin as FormBuilderErrorNotifierProvider).formId;
  @override
  String get fieldId => (origin as FormBuilderErrorNotifierProvider).fieldId;
  @override
  int get validatorPosition =>
      (origin as FormBuilderErrorNotifierProvider).validatorPosition;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
