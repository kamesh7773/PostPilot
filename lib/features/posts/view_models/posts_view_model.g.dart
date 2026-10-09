// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'posts_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The user's posts (newest first) with scheduled/failed actions.

@ProviderFor(PostsViewModel)
final postsViewModelProvider = PostsViewModelProvider._();

/// The user's posts (newest first) with scheduled/failed actions.
final class PostsViewModelProvider
    extends $AsyncNotifierProvider<PostsViewModel, List<Post>> {
  /// The user's posts (newest first) with scheduled/failed actions.
  PostsViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postsViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postsViewModelHash();

  @$internal
  @override
  PostsViewModel create() => PostsViewModel();
}

String _$postsViewModelHash() => r'e03d9d5f89e864c1f58a213f0cb1fe0f9d694b26';

/// The user's posts (newest first) with scheduled/failed actions.

abstract class _$PostsViewModel extends $AsyncNotifier<List<Post>> {
  FutureOr<List<Post>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Post>>, List<Post>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Post>>, List<Post>>,
              AsyncValue<List<Post>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
