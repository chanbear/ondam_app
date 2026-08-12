/// Domain-level failure shown to the UI — repositories translate data-layer
/// exceptions (e.g. NetworkException) into one of these so presentation code
/// never depends on Dio/network types directly.
sealed class Failure {
  const Failure(this.message);

  /// User-facing message. Keep technical details out of this string;
  /// log the original exception separately for developers.
  final String message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = '네트워크 연결을 확인해주세요.']);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message = '로그인이 필요합니다.']);
}

final class ServerFailure extends Failure {
  const ServerFailure([super.message = '서버에 문제가 발생했습니다.']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = '알 수 없는 오류가 발생했습니다.']);
}
