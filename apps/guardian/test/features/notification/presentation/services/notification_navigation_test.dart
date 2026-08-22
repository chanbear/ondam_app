import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/notification/presentation/services/notification_navigation.dart';
import 'package:ondam_models/ondam_models.dart';

// ProviderContainer isn't itself a Ref — this is the standard Riverpod
// testing trick to obtain one bound to the container under test.
final _refProvider = Provider<Ref>((ref) => ref);

AnalysisResult _record(String id) {
  return AnalysisResult(
    id: id,
    elderId: 'elder-1',
    type: AnalysisType.message,
    reliability: ReliabilityLevel.high,
    summary: '요약-$id',
    createdAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('findNotificationTarget', () {
    test('id가 일치하는 AnalysisResult를 찾는다', () {
      final records = [_record('r1'), _record('r2')];

      final result = findNotificationTarget(records, 'r2');

      expect(result?.id, 'r2');
    });

    test('일치하는 id가 없으면 null을 반환한다(임의 레코드를 지어내지 않음)', () {
      final records = [_record('r1')];

      final result = findNotificationTarget(records, 'r-missing');

      expect(result, isNull);
    });

    test('목록이 비어있으면 null을 반환한다', () {
      final result = findNotificationTarget(const [], 'r1');

      expect(result, isNull);
    });
  });

  group('handleNotificationTapData', () {
    // 실기기 Phase 8 검증에서 발견된 버그의 회귀 방지: PIN이 잠긴 상태에서
    // 알림을 탭하면 즉시 push하지 않고 pendingNotificationTargetProvider에
    // 저장만 해야 한다 — 즉시 push하면 PIN 해제 직후 go_router의
    // redirect 리빌드에 씻겨나간다(notification_navigation.dart doc 참고).
    test('PIN이 잠겨 있으면 즉시 이동하지 않고 pending에 저장한다', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final ref = container.read(_refProvider);
      final data = {'elder_id': 'elder-1', 'analysis_result_id': 'r1'};

      handleNotificationTapData(ref, data);

      expect(container.read(pendingNotificationTargetProvider), data);
    });
  });
}
