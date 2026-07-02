import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../error/exceptions.dart';
import 'interceptors/logging_interceptor.dart';
import 'interceptors/error_interceptor.dart';

class ApiClient {
  static Dio create({
    required String baseUrl,
    Map<String, String>? defaultHeaders,
    int connectionTimeoutSeconds = AppConstants.connectionTimeoutSeconds,
    int receiveTimeoutSeconds = AppConstants.receiveTimeoutSeconds,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: connectionTimeoutSeconds),
      receiveTimeout: Duration(seconds: receiveTimeoutSeconds),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...?defaultHeaders,
      },
    ));
    if (kDebugMode) dio.interceptors.add(LoggingInterceptor());
    dio.interceptors.add(ErrorInterceptor());
    return dio;
  }

  /// Streams OpenAI-compatible SSE: `data: {...}\n\n`
  static Stream<String> streamSSE({
    required Dio dio,
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? additionalHeaders,
  }) async* {
    final controller = StreamController<String>();

    dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: additionalHeaders,
      ),
    ).then((response) async {
      final buffer = StringBuffer();
      await for (final chunk in response.data!.stream) {
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        final content = buffer.toString();
        final events = content.split('\n\n');

        for (int i = 0; i < events.length - 1; i++) {
          final event = events[i].trim();
          if (event.isEmpty) continue;
          for (final line in event.split('\n')) {
            if (line.startsWith('data: ')) {
              final data = line.substring(6).trim();
              if (data == '[DONE]') {
                if (!controller.isClosed) controller.close();
                return;
              }
              if (!controller.isClosed) controller.add(data);
            }
          }
        }
        buffer
          ..clear()
          ..write(events.last);
      }
      if (!controller.isClosed) controller.close();
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(_mapError(e));
        controller.close();
      }
    });

    yield* controller.stream;
  }

  /// Streams Anthropic's event/data SSE format
  static Stream<Map<String, dynamic>> streamAnthropicSSE({
    required Dio dio,
    required String path,
    required Map<String, dynamic> body,
    Map<String, String>? additionalHeaders,
  }) async* {
    final controller = StreamController<Map<String, dynamic>>();

    dio.post<ResponseBody>(
      path,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: additionalHeaders,
      ),
    ).then((response) async {
      final buffer = StringBuffer();
      String? currentEventType;

      await for (final chunk in response.data!.stream) {
        buffer.write(utf8.decode(chunk, allowMalformed: true));
        final content = buffer.toString();
        final events = content.split('\n\n');

        for (int i = 0; i < events.length - 1; i++) {
          final event = events[i].trim();
          if (event.isEmpty) continue;
          String? eventData;
          for (final line in event.split('\n')) {
            if (line.startsWith('event: ')) {
              currentEventType = line.substring(7).trim();
            } else if (line.startsWith('data: ')) {
              eventData = line.substring(6).trim();
            }
          }
          if (eventData != null && !controller.isClosed) {
            try {
              final parsed = jsonDecode(eventData) as Map<String, dynamic>;
              if (currentEventType != null) {
                parsed['_event_type'] = currentEventType;
              }
              controller.add(parsed);
            } catch (_) {}
          }
        }
        buffer
          ..clear()
          ..write(events.last);
      }
      if (!controller.isClosed) controller.close();
    }).catchError((e) {
      if (!controller.isClosed) {
        controller.addError(_mapError(e));
        controller.close();
      }
    });

    yield* controller.stream;
  }

  static Exception _mapError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return NetworkException.timeout();
        case DioExceptionType.connectionError:
          return NetworkException.noInternet();
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode ?? 0;
          final msg = _extractMessage(error.response?.data) ??
              error.message ?? 'Server error';
          switch (code) {
            case 401: return NetworkException.unauthorized();
            case 429: return NetworkException.rateLimited();
            case 402: return NetworkException.quotaExceeded();
            default: return NetworkException.serverError(code, msg);
          }
        default:
          return NetworkException(message: error.message ?? 'Network error');
      }
    }
    return NetworkException(message: error.toString());
  }

  static String? _extractMessage(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['error']?['message'] as String? ??
          data['message'] as String? ??
          data['error'] as String?;
    }
    return null;
  }
}
