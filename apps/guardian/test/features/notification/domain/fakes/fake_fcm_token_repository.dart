import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/notification/domain/repositories/fcm_token_repository.dart';

/// Configurable fake — same pattern as `FakeAnalysisRepository`
/// (testing.md: Repository is faked, not hit over network).
class FakeFcmTokenRepository implements FcmTokenRepository {
  Result<void> registerTokenResult = const Ok(null);
  Result<void> invalidateTokenResult = const Ok(null);

  final List<({String token, Map<String, dynamic> deviceInfo})>
  registerTokenCalls = [];
  final List<String> invalidateTokenCalls = [];

  @override
  Future<Result<void>> registerToken({
    required String token,
    required Map<String, dynamic> deviceInfo,
  }) async {
    registerTokenCalls.add((token: token, deviceInfo: deviceInfo));
    return registerTokenResult;
  }

  @override
  Future<Result<void>> invalidateToken(String token) async {
    invalidateTokenCalls.add(token);
    return invalidateTokenResult;
  }
}
