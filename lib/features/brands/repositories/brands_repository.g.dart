// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brands_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(brandsRepository)
final brandsRepositoryProvider = BrandsRepositoryProvider._();

final class BrandsRepositoryProvider
    extends
        $FunctionalProvider<
          BrandsRepository,
          BrandsRepository,
          BrandsRepository
        >
    with $Provider<BrandsRepository> {
  BrandsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'brandsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$brandsRepositoryHash();

  @$internal
  @override
  $ProviderElement<BrandsRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BrandsRepository create(Ref ref) {
    return brandsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BrandsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BrandsRepository>(value),
    );
  }
}

String _$brandsRepositoryHash() => r'5b2dc37658eeee90aee17efd788fe404c8cc4e78';
