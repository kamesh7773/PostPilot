import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/post.dart';

part 'posts_repository.g.dart';

@Riverpod(keepAlive: true)
PostsRepository postsRepository(Ref ref) => PostsRepository(ref);

/// The autopilot's posts: list, publish now / retry, cancel.
class PostsRepository extends BaseApiService {
  PostsRepository(super.ref);

  /// GET /posts — newest first.
  Future<ApiResponse<List<Post>>> fetchPosts() async {
    try {
      final response = await get(ApiEndpoints.posts);
      final items = (response.data as Map<String, dynamic>)['posts'] as List;
      return ApiResponse.success(
        items
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// POST /posts/{id}/publish — publish a scheduled post now, or retry a
  /// failed one. Runs in the background.
  Future<ApiResponse<Post>> publishExisting(String id) async {
    try {
      final response = await post(ApiEndpoints.publishPost(id));
      return ApiResponse.success(
        Post.fromJson(
          (response.data as Map<String, dynamic>)['post']
              as Map<String, dynamic>,
        ),
      );
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// DELETE /posts/{id} — cancels a scheduled post or removes a failed one.
  Future<ApiResponse<bool>> deletePost(String id) async {
    try {
      await delete(ApiEndpoints.post(id));
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  ApiResponse<T> _failure<T>(DioException e) => ApiResponse.failure(
    e.message ?? getDioErrorType(e).message,
    statusCode: e.response?.statusCode,
  );
}
