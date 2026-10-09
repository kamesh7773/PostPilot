import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/creator_profile.dart';

part 'profile_repository.g.dart';

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) => ProfileRepository(ref);

class ProfileRepository extends BaseApiService {
  ProfileRepository(super.ref);

  /// GET /profile — `data` is null when the creator hasn't set one up yet.
  Future<ApiResponse<CreatorProfile?>> fetch() async {
    try {
      final response = await get(ApiEndpoints.profile);
      return ApiResponse.success(_profile(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return ApiResponse.success(null);
      return _failure(e);
    }
  }

  /// PUT /profile
  Future<ApiResponse<CreatorProfile>> save(CreatorProfile profile) async {
    try {
      final response = await put(ApiEndpoints.profile, data: profile.toJson());
      return ApiResponse.success(_profile(response.data));
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  CreatorProfile _profile(dynamic data) => CreatorProfile.fromJson(
    (data as Map<String, dynamic>)['profile'] as Map<String, dynamic>,
  );

  ApiResponse<T> _failure<T>(DioException e) => ApiResponse.failure(
    e.message ?? getDioErrorType(e).message,
    statusCode: e.response?.statusCode,
  );
}
