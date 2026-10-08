// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_accounts_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocialAccountsViewModel)
final socialAccountsViewModelProvider = SocialAccountsViewModelProvider._();

final class SocialAccountsViewModelProvider
    extends $NotifierProvider<SocialAccountsViewModel, SocialAccountsState> {
  SocialAccountsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialAccountsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialAccountsViewModelHash();

  @$internal
  @override
  SocialAccountsViewModel create() => SocialAccountsViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SocialAccountsState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SocialAccountsState>(value),
    );
  }
}

String _$socialAccountsViewModelHash() =>
    r'4ea433c72d052948becf288a9d7076b82691eb8c';

abstract class _$SocialAccountsViewModel
    extends $Notifier<SocialAccountsState> {
  SocialAccountsState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SocialAccountsState, SocialAccountsState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SocialAccountsState, SocialAccountsState>,
              SocialAccountsState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
