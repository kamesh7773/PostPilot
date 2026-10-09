// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compose_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(composeRepository)
final composeRepositoryProvider = ComposeRepositoryProvider._();

final class ComposeRepositoryProvider
    extends
        $FunctionalProvider<
          ComposeRepository,
          ComposeRepository,
          ComposeRepository
        >
    with $Provider<ComposeRepository> {
  ComposeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'composeRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$composeRepositoryHash();

  @$internal
  @override
  $ProviderElement<ComposeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComposeRepository create(Ref ref) {
    return composeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComposeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComposeRepository>(value),
    );
  }
}

String _$composeRepositoryHash() => r'e6b5865fdcd7f7d384d2c7329c0b73a10489460c';
