// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The creator profile; `null` until onboarding is completed.

@ProviderFor(ProfileViewModel)
final profileViewModelProvider = ProfileViewModelProvider._();

/// The creator profile; `null` until onboarding is completed.
final class ProfileViewModelProvider
    extends $AsyncNotifierProvider<ProfileViewModel, CreatorProfile?> {
  /// The creator profile; `null` until onboarding is completed.
  ProfileViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'profileViewModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$profileViewModelHash();

  @$internal
  @override
  ProfileViewModel create() => ProfileViewModel();
}

String _$profileViewModelHash() => r'003b499cda021ea9bcc6e8e673d886a6b2e4e126';

/// The creator profile; `null` until onboarding is completed.

abstract class _$ProfileViewModel extends $AsyncNotifier<CreatorProfile?> {
  FutureOr<CreatorProfile?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CreatorProfile?>, CreatorProfile?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CreatorProfile?>, CreatorProfile?>,
              AsyncValue<CreatorProfile?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
