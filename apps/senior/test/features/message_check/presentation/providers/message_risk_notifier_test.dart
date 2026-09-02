import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/core/notification_prefs/presentation/providers/notification_prefs_di_providers.dart';
import 'package:ondam_senior/features/connection/presentation/providers/connection_di_providers.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_check_di_providers.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_risk_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/notification_prefs/domain/fakes/fake_notification_prefs_repository.dart';
import '../../../connection/domain/fakes/fake_connection_repository.dart';
import '../../domain/fakes/fake_message_risk_repository.dart';

void main() {
  // Case 5는 analyze()를 실제로 호출하는데, 그 안에서 읽는
  // localeControllerProvider가 SharedPreferences를 거친다 —
  // 바인딩이 초기화돼 있어야 한다(voice_guide_service_test.dart와 동일 이유).
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final message = SmsMessage(
    sender: '010-1234-5678',
    body: '[Web발신] 계좌 정지 안내',
    receivedAt: DateTime(2026, 1, 1),
  );

  AnalysisResult resultWith(RiskLevel? riskLevel) => AnalysisResult(
    id: 'a1',
    elderId: 'e1',
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    riskLevel: riskLevel,
    summary: '요약',
    createdAt: DateTime(2026, 1, 1),
  );

  final acceptedGuardian = GuardianLink(
    id: 'link1',
    elderId: 'e1',
    guardianId: 'g1',
    status: GuardianLinkStatus.accepted,
    createdAt: DateTime(2026, 1, 1),
  );

  ({
    ProviderContainer container,
    FakeMessageRiskRepository messageRiskRepository,
    FakeNotificationPrefsRepository notificationPrefsRepository,
    FakeConnectionRepository connectionRepository,
  })
  buildContainer() {
    final messageRiskRepository = FakeMessageRiskRepository();
    final notificationPrefsRepository = FakeNotificationPrefsRepository();
    final connectionRepository = FakeConnectionRepository();
    final container = ProviderContainer(
      overrides: [
        messageRiskRepositoryProvider.overrideWithValue(messageRiskRepository),
        notificationPrefsRepositoryProvider.overrideWithValue(
          notificationPrefsRepository,
        ),
        connectionRepositoryProvider.overrideWithValue(connectionRepository),
      ],
    );
    return (
      container: container,
      messageRiskRepository: messageRiskRepository,
      notificationPrefsRepository: notificationPrefsRepository,
      connectionRepository: connectionRepository,
    );
  }

  test('안심(safe) 결과는 보호자 알림을 보내지 않는다', () async {
    final ctx = buildContainer();
    addTearDown(ctx.container.dispose);
    ctx.notificationPrefsRepository.getGuardianNotifyEnabledResult = const Ok(
      true,
    );
    ctx.connectionRepository.getGuardianLinksResult = Ok([acceptedGuardian]);

    final notified = await ctx.container
        .read(messageRiskNotifierProvider.notifier)
        .notifyGuardianIfNeeded(resultWith(RiskLevel.safe));

    expect(notified, false);
    expect(ctx.messageRiskRepository.notifyGuardianCalls, isEmpty);
  });

  test('위험/주의 결과라도 "보호자 알림"이 꺼져 있으면 보내지 않는다', () async {
    final ctx = buildContainer();
    addTearDown(ctx.container.dispose);
    ctx.notificationPrefsRepository.getGuardianNotifyEnabledResult = const Ok(
      false,
    );
    ctx.connectionRepository.getGuardianLinksResult = Ok([acceptedGuardian]);

    final notified = await ctx.container
        .read(messageRiskNotifierProvider.notifier)
        .notifyGuardianIfNeeded(resultWith(RiskLevel.dangerous));

    expect(notified, false);
    expect(ctx.messageRiskRepository.notifyGuardianCalls, isEmpty);
  });

  test('보호자 알림이 켜져 있어도 accepted 상태인 보호자가 없으면 보내지 않는다', () async {
    final ctx = buildContainer();
    addTearDown(ctx.container.dispose);
    ctx.notificationPrefsRepository.getGuardianNotifyEnabledResult = const Ok(
      true,
    );
    ctx.connectionRepository.getGuardianLinksResult = const Ok([]);

    final notified = await ctx.container
        .read(messageRiskNotifierProvider.notifier)
        .notifyGuardianIfNeeded(resultWith(RiskLevel.dangerous));

    expect(notified, false);
    expect(ctx.messageRiskRepository.notifyGuardianCalls, isEmpty);
  });

  test('위험/주의 + 알림 켜짐 + accepted 보호자가 있으면 실제로 알림을 보내고 true를 반환한다', () async {
    final ctx = buildContainer();
    addTearDown(ctx.container.dispose);
    ctx.notificationPrefsRepository.getGuardianNotifyEnabledResult = const Ok(
      true,
    );
    ctx.connectionRepository.getGuardianLinksResult = Ok([acceptedGuardian]);

    final notified = await ctx.container
        .read(messageRiskNotifierProvider.notifier)
        .notifyGuardianIfNeeded(resultWith(RiskLevel.caution));

    expect(notified, true);
    expect(ctx.messageRiskRepository.notifyGuardianCalls, ['g1']);
  });

  test('알림 전송 자체가 실패하면(Err) 성공했다고 알리지 않는다', () async {
    final ctx = buildContainer();
    addTearDown(ctx.container.dispose);
    ctx.notificationPrefsRepository.getGuardianNotifyEnabledResult = const Ok(
      true,
    );
    ctx.connectionRepository.getGuardianLinksResult = Ok([acceptedGuardian]);
    ctx.messageRiskRepository.notifyGuardianResult = const Err(ServerFailure());

    final notified = await ctx.container
        .read(messageRiskNotifierProvider.notifier)
        .notifyGuardianIfNeeded(resultWith(RiskLevel.dangerous));

    expect(notified, false);
  });

  test(
    'Case 5: re-analyzing does not let the previous result leak into the next one',
    () async {
      final repository = FakeMessageRiskRepository();
      final container = ProviderContainer(
        overrides: [
          messageRiskRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      // First analysis: caution, high confidence.
      repository.result = Ok(
        AnalysisResult(
          id: 'a1',
          elderId: 'e1',
          type: AnalysisType.message,
          reliability: ReliabilityLevel.high,
          riskLevel: RiskLevel.caution,
          summary: '주의가 필요한 문자예요.',
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await container
          .read(messageRiskNotifierProvider.notifier)
          .analyze(message);
      final firstState = container.read(messageRiskNotifierProvider);
      expect(firstState.value?.riskLevel, RiskLevel.caution);
      expect(firstState.value?.reliability, ReliabilityLevel.high);

      // Second analysis of the same message: safe, low confidence — set up
      // before triggering the call, since the fake resolves synchronously.
      repository.result = Ok(
        AnalysisResult(
          id: 'a2',
          elderId: 'e1',
          type: AnalysisType.message,
          reliability: ReliabilityLevel.low,
          riskLevel: RiskLevel.safe,
          summary: '일반적인 안내 문자예요.',
          createdAt: DateTime(2026, 1, 2),
        ),
      );

      // AsyncNotifier preserves the previous value across
      // `state = AsyncLoading()` (Riverpod's built-in "seamless refresh"
      // behavior), so `.value` legitimately still holds the first result
      // here — that's expected at the notifier level. What must not happen
      // is the *page* rendering that stale value as if it were current;
      // the result pages opt out of that via `skipLoadingOnRefresh: false`
      // (message_risk_result_page.dart / document_scan_result_page.dart),
      // which this asserts directly against the raw AsyncValue.
      final loadingFuture = container
          .read(messageRiskNotifierProvider.notifier)
          .analyze(message);
      final loadingState = container.read(messageRiskNotifierProvider);
      expect(loadingState.isLoading, true);
      final rendersAsLoading = loadingState.when(
        skipLoadingOnRefresh: false,
        loading: () => true,
        error: (_, _) => false,
        data: (_) => false,
      );
      expect(
        rendersAsLoading,
        true,
        reason:
            'the result page must show the loading state, not the '
            'previous AnalysisResult, while a new analysis is in flight',
      );

      await loadingFuture;

      final secondState = container.read(messageRiskNotifierProvider);
      expect(secondState.value?.id, 'a2');
      expect(secondState.value?.riskLevel, RiskLevel.safe);
      expect(secondState.value?.reliability, ReliabilityLevel.low);
      expect(repository.calls, [message, message]);
    },
  );
}
