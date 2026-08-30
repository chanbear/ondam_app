import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/notification_prefs/presentation/providers/notification_prefs_provider.dart';
import '../../../connection/presentation/providers/guardian_links_notifier.dart';
import '../../domain/entities/sms_message.dart';
import 'message_check_di_providers.dart';

/// Drives the "분석 요청" step — mirrors `document_scan`'s
/// `AnalysisNotifier`. `state` is `AsyncValue<AnalysisResult>` so the result
/// screen renders loading/error/data uniformly; an `UnavailableFailure` (no
/// backend yet) is a normal, expected `AsyncError`, not a bug.
class MessageRiskNotifier extends AsyncNotifier<AnalysisResult?> {
  @override
  FutureOr<AnalysisResult?> build() => null;

  Future<Result<AnalysisResult>> analyze(SmsMessage message) async {
    state = const AsyncLoading();
    final result = await ref
        .read(checkMessageRiskUseCaseProvider)
        .call(message);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  /// 확인(confirm)된 결과가 위험/주의이고, 사용자가 "보호자 알림"을 켜뒀고,
  /// accepted 상태인 보호자가 최소 1명 있을 때만 실제로 알림을 보낸다.
  /// 반환값은 "실제로 최소 1건 성공했는가"다 — msg-guardian-notice 화면은
  /// 이게 true일 때만 보여준다("정직하게 안내" 원칙, 알리지도 않고 알렸다고
  /// 말하지 않는다). 개별 알림 실패는 사용자에게 노출하지 않는다 — 이미
  /// 문자 확인을 마친 사용자를 기술적 오류로 다시 붙잡을 이유가 없다.
  Future<bool> notifyGuardianIfNeeded(AnalysisResult result) async {
    if (result.riskLevel == null || result.riskLevel == RiskLevel.safe) {
      return false;
    }

    final notifyEnabled = await ref.read(guardianNotifyEnabledProvider.future);
    if (!notifyEnabled) return false;

    final links = await ref.read(guardianLinksProvider.future);
    final accepted = links.where(
      (link) => link.status == GuardianLinkStatus.accepted,
    );
    if (accepted.isEmpty) return false;

    final results = await Future.wait(
      accepted.map(
        (link) => ref
            .read(notifyGuardianUseCaseProvider)
            .call(targetUserId: link.guardianId, analysisResultId: result.id),
      ),
    );
    return results.any((r) => r is Ok<void>);
  }
}

final messageRiskNotifierProvider =
    AsyncNotifierProvider<MessageRiskNotifier, AnalysisResult?>(
      MessageRiskNotifier.new,
    );
