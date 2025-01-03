// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fleathercustomembedprovider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$fleatherCustomEmbedNotifierHash() =>
    r'5fb49ee75f2244a59f57ef8a6d5697db7b09cec1';

/// See also [fleatherCustomEmbedNotifier].
@ProviderFor(fleatherCustomEmbedNotifier)
final fleatherCustomEmbedNotifierProvider =
    AutoDisposeProvider<Widget Function(BuildContext, EmbedNode)>.internal(
  fleatherCustomEmbedNotifier,
  name: r'fleatherCustomEmbedNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$fleatherCustomEmbedNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef FleatherCustomEmbedNotifierRef
    = AutoDisposeProviderRef<Widget Function(BuildContext, EmbedNode)>;
String _$embedRegistryNotifierHash() =>
    r'8be4045241ecaabb9de516972f2c19a6c6640a40';

/// See also [EmbedRegistryNotifier].
@ProviderFor(EmbedRegistryNotifier)
final embedRegistryNotifierProvider = AutoDisposeNotifierProvider<
    EmbedRegistryNotifier, Map<String, Embed>>.internal(
  EmbedRegistryNotifier.new,
  name: r'embedRegistryNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$embedRegistryNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$EmbedRegistryNotifier = AutoDisposeNotifier<Map<String, Embed>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
