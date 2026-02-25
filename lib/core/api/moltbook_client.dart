import 'dart:convert';

import 'package:dio/dio.dart';

import '../../config/env.dart';
import '../debug/api_debug.dart';
import 'api_exceptions.dart';

/// Dio-based HTTP client for Moltbook API with auth support.
class MoltbookClient {
  MoltbookClient({this.apiKey, ApiDebugNotifier? debugNotifier}) {
    _dio = Dio(BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (apiKey != null && apiKey!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $apiKey';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugNotifier?.record(_recordFromResponse(response));
        return handler.next(response);
      },
      onError: (error, handler) {
        if (error.response != null) {
          debugNotifier?.record(_recordFromError(error));
          final data = error.response?.data;
          String message = 'Request failed';
          String? code;
          String? hint;
          if (data is Map<String, dynamic>) {
            message = (data['message'] ?? data['error']) as String? ?? message;
            code = data['code'] as String?;
            hint = data['hint'] as String?;
          } else if (data is String) {
            try {
              final decoded = jsonDecode(data) as Map<String, dynamic>;
              message = (decoded['message'] ?? decoded['error']) as String? ?? message;
              code = decoded['code'] as String?;
              hint = decoded['hint'] as String?;
            } catch (_) {}
          }
          handler.reject(DioException(
            requestOptions: error.requestOptions,
            response: error.response,
            error: ApiException(
              statusCode: error.response?.statusCode ?? 0,
              message: message,
              code: code,
              hint: hint,
            ),
          ));
          return;
        }
        debugNotifier?.record(_recordFromError(error));
        handler.next(error);
      },
    ));
  }

  String? apiKey;
  late final Dio _dio;

  Dio get dio => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    return response.data as T;
  }

  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    return response.data as T;
  }

  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.patch<T>(path, data: data, queryParameters: queryParameters, options: options);
    return response.data as T;
  }

  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final response = await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    return response.data as T;
  }

  static ApiCallRecord _recordFromResponse(Response<dynamic> response) {
    return ApiCallRecord(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(response.requestOptions.headers),
      requestBody: response.requestOptions.data,
      responseStatus: response.statusCode,
      responseHeaders: response.headers.map,
      responseBody: response.data,
    );
  }

  static ApiCallRecord _recordFromError(DioException error) {
    return ApiCallRecord(
      method: error.requestOptions.method,
      url: error.requestOptions.uri.toString(),
      requestHeaders: Map<String, dynamic>.from(error.requestOptions.headers),
      requestBody: error.requestOptions.data,
      responseStatus: error.response?.statusCode,
      responseHeaders: error.response?.headers.map,
      responseBody: error.response?.data,
      error: error.error?.toString() ?? error.message ?? 'Unknown error',
    );
  }

  /// Parses rate limit headers from a response.
  static Map<String, int>? parseRateLimit(Response<dynamic> response) {
    final limit = response.headers.value('x-ratelimit-limit');
    final remaining = response.headers.value('x-ratelimit-remaining');
    final reset = response.headers.value('x-ratelimit-reset');
    if (limit == null && remaining == null && reset == null) return null;
    return {
      if (limit != null) 'limit': int.tryParse(limit) ?? 0,
      if (remaining != null) 'remaining': int.tryParse(remaining) ?? 0,
      if (reset != null) 'reset': int.tryParse(reset) ?? 0,
    };
  }
}
