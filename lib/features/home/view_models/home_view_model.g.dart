// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The backend profile for the signed-in user. Refresh with
/// `ref.invalidate(currentUserProvider)`.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// The backend profile for the signed-in user. Refresh with
/// `ref.invalidate(currentUserProvider)`.

final class CurrentUserProvider
    extends
        $FunctionalProvider<
          AsyncValue<ApiResponse<AppUser>>,
          ApiResponse<AppUser>,
          FutureOr<ApiResponse<AppUser>>
        >
    with
        $FutureModifier<ApiResponse<AppUser>>,
        $FutureProvider<ApiResponse<AppUser>> {
  /// The backend profile for the signed-in user. Refresh with
  /// `ref.invalidate(currentUserProvider)`.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $FutureProviderElement<ApiResponse<AppUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ApiResponse<AppUser>> create(Ref ref) {
    return currentUser(ref);
  }
}

String _$currentUserHash() => r'bf86c61c591c2a09477d2200cfef6f3ecb5dbdd9';
