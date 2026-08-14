import 'package:ondam_core/ondam_core.dart';

/// Write access to `fcm_tokens` (id, user_id, token, device_info,
/// updated_at — technical-decisions.md §4/§2-5). The actual Push send never
/// happens on the client (§1-10) — this repository only keeps the
/// token-to-user mapping current.
abstract class FcmTokenRepository {
  /// Registers or refreshes this device's current FCM token for the signed
  /// in user. Called on login and whenever FCM rotates the token.
  Future<Result<void>> registerToken({
    required String token,
    required Map<String, dynamic> deviceInfo,
  });

  /// Removes the token-to-user mapping so a stale/logged-out device stops
  /// receiving Push meant for that user (technical-decisions.md §2 checklist
  /// item 5: "로그아웃/기기 변경 시 토큰 무효화 절차 필요").
  Future<Result<void>> invalidateToken(String token);
}
