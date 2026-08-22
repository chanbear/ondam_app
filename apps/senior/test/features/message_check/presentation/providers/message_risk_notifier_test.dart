import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_check_di_providers.dart';
import 'package:ondam_senior/features/message_check/presentation/providers/message_risk_notifier.dart';

import '../../domain/fakes/fake_message_risk_repository.dart';

void main() {
  final message = SmsMessage(
    sender: '010-1234-5678',
    body: '[Web발신] 계좌 정지 안내',
    receivedAt: DateTime(2026, 1, 1),
  );

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
