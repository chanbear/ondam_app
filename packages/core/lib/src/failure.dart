/// Domain-level failure shown to the UI — repositories translate data-layer
/// exceptions (e.g. NetworkException from `ondam_network`) into one of these
/// so presentation code never depends on Dio/network types directly.
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

/// A feature whose backend doesn't exist yet (no Edge Function/AI service
/// deployed). Distinct from [ServerFailure] — that means "the server tried
/// and failed"; this means "there is nothing to call yet". Repositories
/// must return this instead of attempting a call that would only fail by
/// accident, and instead of fabricating a fake success (see Phase 4 rule:
/// "Mock 분석 결과 생성 금지").
final class UnavailableFailure extends Failure {
  const UnavailableFailure([super.message = '이 기능은 아직 준비 중이에요.']);
}

/// Couldn't determine a location — GPS timeout, no signal, or reverse
/// geocoding failed to turn coordinates into an address. Distinct from
/// [NetworkFailure]/[ServerFailure]: the device/OS-level location pipeline
/// failed, not a request to this app's own backend.
final class LocationFailure extends Failure {
  const LocationFailure([super.message = '현재 위치를 확인할 수 없어요.']);
}
