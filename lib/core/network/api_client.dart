import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient._({Dio? dio}) : _dio = dio ?? _createDio();

  static final instance = ApiClient._();

  final Dio _dio;

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> data,
  }) async {
    try {
      _log('POST ${ApiEndpoints.baseUrl}$path');
      _log('REQUEST BODY: $data');

      final response = await _dio.post<Object?>(path, data: data);
      final responseData = response.data;

      _log('STATUS: ${response.statusCode}');
      _log('RESPONSE BODY: $responseData');

      if (responseData is Map<String, dynamic>) {
        return responseData;
      }

      if (responseData is Map) {
        return Map<String, dynamic>.from(responseData);
      }

      throw const ApiException(message: 'Unexpected API response.');
    } on DioException catch (error) {
      _log('ERROR TYPE: ${error.type}');
      _log('ERROR STATUS: ${error.response?.statusCode}');
      _log('ERROR BODY: ${error.response?.data}');
      _log('ERROR MESSAGE: ${error.message}');

      throw ApiException(
        message: _messageFromDio(error),
        statusCode: error.response?.statusCode,
        cause: error,
      );
    }
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 20),
        responseType: ResponseType.json,
        headers: const {
          Headers.acceptHeader: Headers.jsonContentType,
          Headers.contentTypeHeader: Headers.jsonContentType,
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (ApiEndpoints.baseUrl.isEmpty &&
              !options.path.startsWith('http')) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: const ApiException(
                  message:
                      'API base URL is missing. Pass --dart-define=SLAMORA_API_BASE_URL=...',
                ),
              ),
            );
            return;
          }

          handler.next(options);
        },
      ),
    );

    if (!kReleaseMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (object) => _log(object),
        ),
      );
    }

    return dio;
  }

  static void _log(Object? message) {
    if (kReleaseMode) {
      return;
    }

    debugPrintSynchronously('[Slamora API] $message');
  }

  static String _messageFromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map) {
      final message = responseData['message'] ?? responseData['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    final cause = error.error;
    if (cause is ApiException) {
      return cause.message;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Request timed out. Please try again.',
      DioExceptionType.badResponse => 'Something went wrong. Please try again.',
      DioExceptionType.cancel => 'Request cancelled.',
      DioExceptionType.connectionError =>
        'No internet connection. Please try again.',
      _ => 'Could not complete the request. Please try again.',
    };
  }
}
