/// Categorized network/API failure — thrown by DioClient interceptors and
/// caught by repositories to map into domain-level Failure (see ondam_core).
sealed class NetworkException implements Exception {
  const NetworkException(this.message);

  final String message;
}

final class ConnectionException extends NetworkException {
  const ConnectionException([super.message = '네트워크 연결을 확인해주세요.']);
}

final class TimeoutException extends NetworkException {
  const TimeoutException([super.message = '요청 시간이 초과되었습니다.']);
}

final class UnauthorizedException extends NetworkException {
  const UnauthorizedException([super.message = '로그인이 필요합니다.']);
}

final class ServerException extends NetworkException {
  const ServerException([super.message = '서버에 문제가 발생했습니다.']);
}

final class UnknownNetworkException extends NetworkException {
  const UnknownNetworkException([super.message = '알 수 없는 오류가 발생했습니다.']);
}
