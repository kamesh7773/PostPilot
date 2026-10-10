import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/env.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import 'supabase_client.dart';

part 'api_client.g.dart';

/// Function-style provider — returns a fully configured Dio instance.
/// Consumers read `ref.watch(apiClientProvider)` to get the Dio directly.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        // ngrok's free tunnel serves an HTML warning page to browsers otherwise.
        if (kIsWeb) 'ngrok-skip-browser-warning': 'true',
      },
    ),
  );

  dio.interceptors.add(_interceptor(ref));

  if (Env.enableLogs && kDebugMode) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: false,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  return dio;
}

Interceptor _interceptor(Ref ref) {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      final apiToken = Env.apiToken;
      if (apiToken != null && apiToken.isNotEmpty) {
        options.headers['Api-Token'] = apiToken;
      }

      // supabase_flutter refreshes the session automatically, so the
      // current access token is always the one to send to our backend.
      final accessToken = ref
          .read(supabaseClientProvider)
          .auth
          .currentSession
          ?.accessToken;
      if (accessToken != null) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }

      return handler.next(options);
    },
    onError: (error, handler) {
      // The mapped message below is user-facing; keep the real cause in logs.
      if (kDebugMode) {
        debugPrint(
          'ApiClient: ${error.requestOptions.method} '
          '${error.requestOptions.uri} failed: ${error.type} ${error.error}',
        );
      }

      String message = 'Something went wrong';
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        message = 'No internet connection, please check your connection';
      } else if (error.response?.data is Map<String, dynamic>) {
        final data = error.response!.data as Map<String, dynamic>;
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['error'] != null) {
          message = data['error'].toString();
        }
      }

      return handler.next(
        DioException(
          requestOptions: error.requestOptions,
          error: message,
          type: error.type,
          message: message,
          response: error.response,
        ),
      );
    },
  );
}
