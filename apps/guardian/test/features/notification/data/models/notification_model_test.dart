import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/notification/data/models/notification_model.dart';

void main() {
  test('fromJson이 read_at=null인 row를 미읽음 NotificationItem으로 변환한다', () {
    final model = NotificationModel.fromJson({
      'id': 'n1',
      'target_user_id': 'guardian-1',
      'type': 'risk_alert',
      'payload': {'elder_id': 'elder-1', 'analysis_result_id': 'r1'},
      'sent_via': 'push',
      'created_at': '2026-08-01T00:00:00.000Z',
      'read_at': null,
    });

    final entity = model.toEntity();

    expect(entity.id, 'n1');
    expect(entity.isRead, isFalse);
    expect(entity.elderId, 'elder-1');
    expect(entity.analysisResultId, 'r1');
  });

  test('fromJson이 read_at이 있는 row를 읽음 NotificationItem으로 변환한다', () {
    final model = NotificationModel.fromJson({
      'id': 'n2',
      'target_user_id': 'guardian-1',
      'type': 'risk_alert',
      'payload': <String, dynamic>{},
      'sent_via': 'push',
      'created_at': '2026-08-01T00:00:00.000Z',
      'read_at': '2026-08-02T00:00:00.000Z',
    });

    final entity = model.toEntity();

    expect(entity.isRead, isTrue);
    expect(entity.elderId, isNull);
    expect(entity.analysisResultId, isNull);
  });
}
