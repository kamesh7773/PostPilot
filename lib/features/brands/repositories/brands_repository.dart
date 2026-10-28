import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/brand.dart';
import '../models/brand_post.dart';

part 'brands_repository.g.dart';

@Riverpod(keepAlive: true)
BrandsRepository brandsRepository(Ref ref) => BrandsRepository(ref);

/// Live QR posts (dev only): the brand, its posts, change requests and approval.
class BrandsRepository extends BaseApiService {
  BrandsRepository(super.ref);

  Future<ApiResponse<List<Brand>>> fetchBrands() => _run(() async {
    final response = await get(ApiEndpoints.brands);
    return [
      for (final b in (response.data as Map<String, dynamic>)['brands'] as List)
        Brand.fromJson(b as Map<String, dynamic>),
    ];
  });

  /// The Instagram account the brand posts to (null clears it).
  Future<ApiResponse<Brand>> setAccount(String id, String? socialAccountId) =>
      _run(() async {
        final response = await patch(
          ApiEndpoints.brand(id),
          data: {'socialAccountId': socialAccountId},
        );
        return _brand(response);
      });

  Future<ApiResponse<List<BrandPost>>> fetchPosts(String brandId) =>
      _run(() async {
        final response = await get(ApiEndpoints.brandPosts(brandId));
        return [
          for (final p
              in (response.data as Map<String, dynamic>)['posts'] as List)
            BrandPost.fromJson(p as Map<String, dynamic>),
        ];
      });

  /// The AI makes it in the background; it then waits for review.
  Future<ApiResponse<BrandPost>> createPost(
    String brandId, {
    required String format,
    String idea = '',
  }) => _run(() async {
    final response = await post(
      ApiEndpoints.brandPosts(brandId),
      data: {'format': format, if (idea.isNotEmpty) 'idea': idea},
    );
    return _post(response);
  });

  /// A post from the owner's own files; the backend converts them, then it waits for review.
  Future<ApiResponse<BrandPost>> createOwnPost(
    String brandId, {
    required String format,
    required String caption,
    required List<({String name, Uint8List bytes})> files,
  }) => _run(() async {
    final form = FormData.fromMap({
      'format': format,
      'caption': caption,
      'files': [
        for (final f in files)
          MultipartFile.fromBytes(
            f.bytes,
            filename: f.name,
            contentType: DioMediaType.parse(mimeTypeOf(f.name)),
          ),
      ],
    });
    return _post(await post(ApiEndpoints.brandOwnPosts(brandId), data: form));
  });

  /// Edits the caption of a post waiting for approval.
  Future<ApiResponse<BrandPost>> updateCaption(String id, String caption) =>
      _run(() async {
        final response = await patch(
          ApiEndpoints.brandPost(id),
          data: {'caption': caption},
        );
        return _post(response);
      });

  Future<ApiResponse<BrandPost>> fetchPost(String id) =>
      _run(() async => _post(await get(ApiEndpoints.brandPost(id))));

  /// A change request; for a failed post, "try again" with an optional note.
  Future<ApiResponse<BrandPost>> requestChange(String id, String request) =>
      _run(() async {
        final response = await post(
          ApiEndpoints.brandPostChanges(id),
          data: {if (request.isNotEmpty) 'request': request},
        );
        return _post(response);
      });

  /// Publishes to Instagram and the Facebook Page; again retries what failed.
  Future<ApiResponse<BrandPost>> approve(String id) =>
      _run(() async => _post(await post(ApiEndpoints.brandPostApprove(id))));

  Future<ApiResponse<void>> deletePost(String id) =>
      _run(() => delete(ApiEndpoints.brandPost(id)));

  Brand _brand(Response response) => Brand.fromJson(
    (response.data as Map<String, dynamic>)['brand'] as Map<String, dynamic>,
  );

  BrandPost _post(Response response) => BrandPost.fromJson(
    (response.data as Map<String, dynamic>)['post'] as Map<String, dynamic>,
  );

  Future<ApiResponse<T>> _run<T>(Future<T> Function() call) async {
    try {
      return ApiResponse.success(await call());
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }
}

const _types = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
};

/// The file types you can upload; the backend converts them for each format.
final uploadExtensions = _types.keys.toList();

String mimeTypeOf(String name) =>
    _types[name.split('.').last.toLowerCase()] ?? 'application/octet-stream';

bool isVideoFile(String name) => mimeTypeOf(name).startsWith('video/');

/// The format that fits [names] best: a video is a Reel, several images a
/// carousel, and one image stays a Post or Story.
String formatFor(List<String> names, String current) {
  if (names.isEmpty) return current;
  if (names.any(isVideoFile)) return 'reel';
  if (names.length > 1) return 'carousel';
  return current == 'story' ? 'story' : 'image';
}
