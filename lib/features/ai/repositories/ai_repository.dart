import 'package:dio/dio.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/models/api_response.dart';
import '../../../core/services/base_api_service.dart';
import '../models/plan_item.dart';

part 'ai_repository.g.dart';

@Riverpod(keepAlive: true)
AiRepository aiRepository(Ref ref) => AiRepository(ref);

class AiRepository extends BaseApiService {
  AiRepository(super.ref);

  /// POST /ai/plan: plans 7 days starting at [start] (local date).
  /// Autopilot only: the AI makes and posts every slot.
  Future<ApiResponse<void>> generatePlan(DateTime start) async {
    try {
      final date = start.toIso8601String().substring(0, 10);
      // The autopilot schedules each slot in this zone.
      final timezone = await FlutterTimezone.getLocalTimezone()
          .then((tz) => tz.identifier)
          .catchError((Object _) => '');
      await post(
        ApiEndpoints.aiPlan,
        data: {
          'startDate': date,
          'autopilot': true,
          if (timezone.isNotEmpty) 'timezone': timezone,
        },
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

  /// PATCH /plan/{id}: new local time (HH:MM) and/or caption, or retry a
  /// failed autopilot slot.
  Future<ApiResponse<void>> updatePlanItem(
    String id, {
    String? time,
    String? caption,
    bool retry = false,
  }) async {
    try {
      await patch(
        ApiEndpoints.planItem(id),
        data: {'time': ?time, 'caption': ?caption, if (retry) 'retry': true},
      );
      return ApiResponse.success(null);
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
