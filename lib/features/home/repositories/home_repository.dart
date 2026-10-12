import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/app_user.dart';

part 'home_repository.g.dart';

@Riverpod(keepAlive: true)
HomeRepository homeRepository(Ref ref) => HomeRepository(ref);

class HomeRepository extends BaseApiService {
  HomeRepository(super.ref);

  /// GET /me — returns (and on first call creates) the backend profile.
  Future<ApiResponse<AppUser>> fetchMe() async {
    try {
      final response = await get(ApiEndpoints.me);
      return ApiResponse.success(
        AppUser.fromJson(response.data as Map<String, dynamic>),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /me/reset — deletes connected accounts, posts, plan, creator
  /// profile and media. The login stays.
  Future<ApiResponse<void>> resetAccount() async {
    try {
      await post(ApiEndpoints.resetAccount);
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }
}
