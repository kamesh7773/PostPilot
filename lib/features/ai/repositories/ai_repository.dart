import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/generated_caption.dart';
import '../models/plan_item.dart';

part 'ai_repository.g.dart';

@Riverpod(keepAlive: true)
AiRepository aiRepository(Ref ref) => AiRepository(ref);

class AiRepository extends BaseApiService {
  AiRepository(super.ref);

  // Local models can take a while; don't give up at the default timeout.
  static final _slow = Options(receiveTimeout: const Duration(minutes: 3));

  /// POST /ai/caption
  Future<ApiResponse<GeneratedCaption>> caption({
    required String type,
    required String topic,
  }) async {
    try {
      final response = await post(
        ApiEndpoints.aiCaption,
        data: {'type': type, 'topic': topic},
        options: _slow,
      );
      return ApiResponse.success(
        GeneratedCaption.fromJson(response.data as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// POST /ai/plan: plans 7 days starting at [start] (local date).
  Future<ApiResponse<void>> generatePlan(DateTime start) async {
    try {
      final date = start.toIso8601String().substring(0, 10);
      await post(
        ApiEndpoints.aiPlan,
        data: {'startDate': date},
        // A whole week with captions is the slowest AI call.
        options: Options(receiveTimeout: const Duration(minutes: 5)),
      );
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// GET /plan
  Future<ApiResponse<List<PlanItem>>> fetchPlan() async {
    try {
      final response = await get(ApiEndpoints.plan);
      final items = (response.data as Map<String, dynamic>)['items'] as List;
      return ApiResponse.success(
        items
            .map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  /// DELETE /plan/{id}
  Future<ApiResponse<void>> deletePlanItem(String id) async {
    try {
      await delete(ApiEndpoints.planItem(id));
      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _failure(e);
    }
  }

  ApiResponse<T> _failure<T>(DioException e) => ApiResponse.failure(
    e.message ?? getDioErrorType(e).message,
    statusCode: e.response?.statusCode,
  );
}
