// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_accounts_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(socialAccountsRepository)
final socialAccountsRepositoryProvider = SocialAccountsRepositoryProvider._();

final class SocialAccountsRepositoryProvider
    extends
        $FunctionalProvider<
          SocialAccountsRepository,
          SocialAccountsRepository,
          SocialAccountsRepository
        >
    with $Provider<SocialAccountsRepository> {
  SocialAccountsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialAccountsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialAccountsRepositoryHash();

  @$internal
  @override
  $ProviderElement<SocialAccountsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SocialAccountsRepository create(Ref ref) {
    return socialAccountsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialAccountsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialAccountsRepository>(value),
    );
  }
}

String _$socialAccountsRepositoryHash() =>
    r'5e8c3b98fcb04d480164bdf8de0261cb9990379c';
