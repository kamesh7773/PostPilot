import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/post.dart';

part 'compose_repository.g.dart';

@Riverpod(keepAlive: true)
ComposeRepository composeRepository(Ref ref) => ComposeRepository(ref);

/// A one-time direct-to-storage upload slot for a video.
@immutable
class VideoUploadSlot {
  final String path;
  final String signedUrl;

  const VideoUploadSlot({required this.path, required this.signedUrl});
}

/// The video is bigger than the server allows; [maxBytes] is the limit.
class VideoTooLarge implements Exception {
  final int maxBytes;

  const VideoTooLarge(this.maxBytes);
}

class ComposeRepository extends BaseApiService {
  ComposeRepository(super.ref);

  // Plain client for uploads to storage: the signed URL is the credential,
  // so our API base URL and auth header must not be applied.
  final Dio _uploadDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 15),
      receiveTimeout: const Duration(minutes: 2),
    ),
  );

  /// POST /media — uploads a JPEG; returns its storage path. Stories skip the
  /// feed aspect-ratio check.
  Future<ApiResponse<String>> uploadImage(
    String filePath, {
    bool story = false,
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'upload.jpg',
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });
      final response = await post(
        ApiEndpoints.media,
        data: form,
        queryParameters: story ? {'purpose': 'story'} : null,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse.success(
        (response.data as Map<String, dynamic>)['path'] as String,
      );
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// POST /media/video-upload-url. Throws [VideoTooLarge] on 413.
  Future<ApiResponse<VideoUploadSlot>> requestVideoUpload({
    required int sizeBytes,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.videoUploadUrl,
        data: {'contentType': 'video/mp4', 'size': sizeBytes},
      );
      final data = response.data as Map<String, dynamic>;
      return ApiResponse.success(
        VideoUploadSlot(
          path: data['path'] as String,
          signedUrl: data['signedUrl'] as String,
        ),
      );
    } on DioException catch (e) {
      final body = e.response?.data;
      if (e.response?.statusCode == 413 && body is Map<String, dynamic>) {
        throw VideoTooLarge((body['maxBytes'] as num?)?.toInt() ?? 0);
      }
      return _failure(e);
    }
  }

  /// PUTs the video straight to storage. [onProgress] receives 0.0–1.0.
  Future<ApiResponse<bool>> uploadVideo(
    VideoUploadSlot slot,
    String filePath, {
    ValueChanged<double>? onProgress,
  }) async {
    try {
      final file = File(filePath);
      final length = await file.length();
      await _uploadDio.put<void>(
        slot.signedUrl,
        data: file.openRead(),
        options: Options(
          headers: {
            Headers.contentLengthHeader: length,
            Headers.contentTypeHeader: 'video/mp4',
          },
        ),
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.type == DioExceptionType.badResponse
            ? 'Upload was rejected (${e.response?.statusCode}).'
            : 'Upload failed. Check your connection and try again.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /posts — creates the post and starts publishing in the background
  /// (202). Poll [fetchPost] for the outcome.
  Future<ApiResponse<Post>> createPost({
    required String socialAccountId,
    required PostType type,
    required List<String> mediaPaths,
    required String caption,
    bool shareToFeed = true,
    DateTime? scheduledAt,
    String? timezone,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.posts,
        data: {
          'socialAccountId': socialAccountId,
          'type': type.name,
          if (type == PostType.carousel)
            'mediaPaths': mediaPaths
          else
            'mediaPath': mediaPaths.single,
          'caption': caption,
          if (type == PostType.reel) 'shareToFeed': shareToFeed,
          'publishNow': true,
          if (scheduledAt != null)
            'scheduledAt': scheduledAt.toUtc().toIso8601String(),
          if (timezone != null && timezone.isNotEmpty) 'timezone': timezone,
        },
      );
      return ApiResponse.success(_post(response.data));
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// GET /posts/{id}
  Future<ApiResponse<Post>> fetchPost(String id) async {
    try {
      final response = await get(ApiEndpoints.post(id));
      return ApiResponse.success(_post(response.data));
    } on DioException catch (e) {
      return _failure(e);
    }
  }

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
      return ApiResponse.success(_post(response.data));
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

  Post _post(dynamic data) => Post.fromJson(
    (data as Map<String, dynamic>)['post'] as Map<String, dynamic>,
  );

  ApiResponse<T> _failure<T>(DioException e) => ApiResponse.failure(
    e.message ?? getDioErrorType(e).message,
    statusCode: e.response?.statusCode,
  );
}
