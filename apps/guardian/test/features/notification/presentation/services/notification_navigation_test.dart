import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/notification/presentation/services/notification_navigation.dart';
import 'package:ondam_models/ondam_models.dart';

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
}
