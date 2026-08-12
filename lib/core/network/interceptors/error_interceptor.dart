import 'package:dio/dio.dart';

import '../network_exception.dart';

/// Maps DioException into typed NetworkException so callers never handle
/// raw Dio errors directly.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final mapped = switch (err.type) {
      DioExceptionType.connectionError => const ConnectionException(),
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const TimeoutException(),
      DioExceptionType.badResponse => _mapBadResponse(err.response?.statusCode),
      _ => const UnknownNetworkException(),
    };

    handler.next(err.copyWith(error: mapped));
  }

  NetworkException _mapBadResponse(int? statusCode) {
    if (statusCode == 401 || statusCode == 403) {
      return const UnauthorizedException();
    }
    if (statusCode != null && statusCode >= 500) {
      return const ServerException();
    }
    return const UnknownNetworkException();
  }
}
