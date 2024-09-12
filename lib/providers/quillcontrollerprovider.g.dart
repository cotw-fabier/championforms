// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quillcontrollerprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$quillControllerNotifierHash() =>
    r'a21046951833c48422eff4c9d1b255fc29068050';

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

abstract class _$QuillControllerNotifier
    extends BuildlessAutoDisposeNotifier<FleatherController> {
  late final String formId;
  late final String fieldId;

  FleatherController build(
    String formId,
    String fieldId,
  );
}

/// See also [QuillControllerNotifier].
@ProviderFor(QuillControllerNotifier)
const quillControllerNotifierProvider = QuillControllerNotifierFamily();

/// See also [QuillControllerNotifier].
class QuillControllerNotifierFamily extends Family<FleatherController> {
  /// See also [QuillControllerNotifier].
  const QuillControllerNotifierFamily();

  /// See also [QuillControllerNotifier].
  QuillControllerNotifierProvider call(
    String formId,
    String fieldId,
  ) {
    return QuillControllerNotifierProvider(
      formId,
      fieldId,
    );
  }

  @override
  QuillControllerNotifierProvider getProviderOverride(
    covariant QuillControllerNotifierProvider provider,
  ) {
    return call(
      provider.formId,
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
  String? get name => r'quillControllerNotifierProvider';
}

/// See also [QuillControllerNotifier].
class QuillControllerNotifierProvider extends AutoDisposeNotifierProviderImpl<
    QuillControllerNotifier, FleatherController> {
  /// See also [QuillControllerNotifier].
  QuillControllerNotifierProvider(
    String formId,
    String fieldId,
  ) : this._internal(
          () => QuillControllerNotifier()
            ..formId = formId
            ..fieldId = fieldId,
          from: quillControllerNotifierProvider,
          name: r'quillControllerNotifierProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$quillControllerNotifierHash,
          dependencies: QuillControllerNotifierFamily._dependencies,
          allTransitiveDependencies:
              QuillControllerNotifierFamily._allTransitiveDependencies,
          formId: formId,
          fieldId: fieldId,
        );

  QuillControllerNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.formId,
    required this.fieldId,
  }) : super.internal();

  final String formId;
  final String fieldId;

  @override
  FleatherController runNotifierBuild(
    covariant QuillControllerNotifier notifier,
  ) {
    return notifier.build(
      formId,
      fieldId,
    );
  }

  @override
  Override overrideWith(QuillControllerNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: QuillControllerNotifierProvider._internal(
        () => create()
          ..formId = formId
          ..fieldId = fieldId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        formId: formId,
        fieldId: fieldId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<QuillControllerNotifier,
      FleatherController> createElement() {
    return _QuillControllerNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is QuillControllerNotifierProvider &&
        other.formId == formId &&
        other.fieldId == fieldId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, formId.hashCode);
    hash = _SystemHash.combine(hash, fieldId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin QuillControllerNotifierRef
    on AutoDisposeNotifierProviderRef<FleatherController> {
  /// The parameter `formId` of this provider.
  String get formId;

  /// The parameter `fieldId` of this provider.
  String get fieldId;
}

class _QuillControllerNotifierProviderElement
    extends AutoDisposeNotifierProviderElement<QuillControllerNotifier,
        FleatherController> with QuillControllerNotifierRef {
  _QuillControllerNotifierProviderElement(super.provider);

  @override
  String get formId => (origin as QuillControllerNotifierProvider).formId;
  @override
  String get fieldId => (origin as QuillControllerNotifierProvider).fieldId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
