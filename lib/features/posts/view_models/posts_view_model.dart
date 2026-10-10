import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/dialog_service.dart';
import '../models/post.dart';
import '../repositories/posts_repository.dart';

part 'posts_view_model.g.dart';

/// The user's posts (newest first) with scheduled/failed actions.
@riverpod
class PostsViewModel extends _$PostsViewModel {
  PostsRepository get _repo => ref.read(postsRepositoryProvider);
  DialogService get _dialog => ref.read(dialogServiceProvider.notifier);

  @override
  Future<List<Post>> build() async {
    final response = await _repo.fetchPosts();
    if (!response.isSuccess) throw Exception(response.error);
    return response.data!;
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Publishes a scheduled post now, or retries a failed one.
  Future<void> publishNow(Post post) async {
    final response = await _repo.publishExisting(post.id);
    if (!ref.mounted) return;
    if (response.isSuccess) {
      _dialog.showInfo('Publishing now. Pull to refresh for the result.');
    } else {
      _dialog.showError(response.error!);
    }
    await refresh();
  }

  /// Cancels a scheduled post, or removes a failed one.
  Future<void> delete(Post post) async {
    final response = await _repo.deletePost(post.id);
    if (!ref.mounted) return;
    if (!response.isSuccess) _dialog.showError(response.error!);
    await refresh();
  }
}
