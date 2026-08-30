import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import 'notification_prefs_di_providers.dart';

/// "보호자 알림" 토글 — `settings`(알림 설정 화면)와 `message_check`(위험
/// 문자 확인 시 실제로 알릴지 판단)가 함께 구독하는 공유 상태이므로
/// `regionProvider`와 같은 이유로 core에 둔다(architecture.md "공유가
/// 필요한 도메인 개념은 core로 분리").
class GuardianNotifyPrefsNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref
        .read(notificationPrefsRepositoryProvider)
        .getGuardianNotifyEnabled();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> setEnabled(bool enabled) async {
    final result = await ref
        .read(notificationPrefsRepositoryProvider)
        .setGuardianNotifyEnabled(enabled);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final guardianNotifyEnabledProvider =
    AsyncNotifierProvider<GuardianNotifyPrefsNotifier, bool>(
      GuardianNotifyPrefsNotifier.new,
    );
