import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/social_account.dart';

part 'social_accounts_repository.g.dart';

@Riverpod(keepAlive: true)
SocialAccountsRepository socialAccountsRepository(Ref ref) =>
    SocialAccountsRepository(ref);

class SocialAccountsRepository extends BaseApiService {
  SocialAccountsRepository(super.ref);

  /// GET /social-accounts
  Future<ApiResponse<List<SocialAccount>>> fetchAccounts() async {
    try {
      final response = await get(ApiEndpoints.socialAccounts);
      final items = (response.data as Map<String, dynamic>)['accounts'] as List;
      return ApiResponse.success(
        items
            .map((e) => SocialAccount.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// POST /auth/instagram/start — returns the Facebook Login URL to open.
  Future<ApiResponse<String>> startInstagramConnect() async {
    try {
      final response = await post(
        ApiEndpoints.instagramConnectStart,
        // Web: the backend sends the result to web/auth.html on this origin.
        data: kIsWeb ? {'returnUrl': '${Uri.base.origin}/auth.html'} : null,
      );
      return ApiResponse.success(
        (response.data as Map<String, dynamic>)['authUrl'] as String,
      );
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// DELETE /social-accounts/{id}
  Future<ApiResponse<bool>> disconnect(String id) async {
    try {
      await delete(ApiEndpoints.socialAccount(id));
      return ApiResponse.success(true);
    } on DioException catch (e) {
      return ApiResponse.failure(
        e.message ?? getDioErrorType(e).message,
        statusCode: e.response?.statusCode,
      );
    }
  }
}
