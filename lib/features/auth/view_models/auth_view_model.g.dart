// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Sign in / sign up / sign out.
///
/// Navigation is not done here: `PostPilotApp` listens to Supabase auth
/// events and routes to Home on sign-in and to Login on sign-out.

@ProviderFor(AuthViewModel)
final authViewModelProvider = AuthViewModelProvider._();

/// Sign in / sign up / sign out.
///
/// Navigation is not done here: `PostPilotApp` listens to Supabase auth
/// events and routes to Home on sign-in and to Login on sign-out.
final class AuthViewModelProvider
    extends $NotifierProvider<AuthViewModel, AuthViewState> {
  /// Sign in / sign up / sign out.
  ///
  /// Navigation is not done here: `PostPilotApp` listens to Supabase auth
  /// events and routes to Home on sign-in and to Login on sign-out.
  AuthViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authViewModelHash();

  @$internal
  @override
  AuthViewModel create() => AuthViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthViewState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthViewState>(value),
    );
  }
}

String _$authViewModelHash() => r'560d7ee03bf5c0ea2a221dded071332bd5cb9766';

/// Sign in / sign up / sign out.
///
/// Navigation is not done here: `PostPilotApp` listens to Supabase auth
/// events and routes to Home on sign-in and to Login on sign-out.

abstract class _$AuthViewModel extends $Notifier<AuthViewState> {
  AuthViewState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AuthViewState, AuthViewState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthViewState, AuthViewState>,
              AuthViewState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
