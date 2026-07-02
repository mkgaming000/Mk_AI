import 'package:dio/dio.dart';
import '../../error/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = _map(err);
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: mapped,
      message: mapped.message,
    ));
  }

  AppException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException.timeout();
      case DioExceptionType.connectionError:
        return NetworkException.noInternet();
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode ?? 0;
        final msg = _msg(err.response?.data) ?? err.message ?? 'Server error';
        switch (code) {
          case 401: return NetworkException.unauthorized();
          case 402: return NetworkException.quotaExceeded();
          case 429: return NetworkException.rateLimited();
          default:  return NetworkException.serverError(code, msg);
        }
      case DioExceptionType.cancel:
        return NetworkException(message: 'Request cancelled.', code: 'CANCELLED');
      default:
        return NetworkException(
            message: err.message ?? 'Unexpected network error.', code: 'UNKNOWN');
    }
  }

  String? _msg(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) {
      return data['error']?['message'] as String? ??
          data['error'] as String? ??
          data['message'] as String?;
    }
    return null;
  }
}
