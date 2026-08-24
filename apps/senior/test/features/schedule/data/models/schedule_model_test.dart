import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/schedule/data/models/schedule_model.dart';

void main() {
  test('반복이 아닌 row는 recurrenceHour/Minute가 null로 변환된다', () {
    final model = ScheduleModel.fromJson({
      'id': 's1',
      'elder_id': 'e1',
      'title': '병원 방문',
      'scheduled_at': '2026-08-25T10:00:00.000Z',
      'is_recurring': false,
      'completed': false,
      'created_at': '2026-08-24T00:00:00.000Z',
      'recurrence_time': null,
    });

    final entity = model.toEntity();

    expect(entity.id, 's1');
    expect(entity.elderId, 'e1');
    expect(entity.title, '병원 방문');
    expect(entity.scheduledAt, DateTime.parse('2026-08-25T10:00:00.000Z'));
    expect(entity.isRecurring, isFalse);
    expect(entity.completed, isFalse);
    expect(entity.recurrenceHour, isNull);
    expect(entity.recurrenceMinute, isNull);
  });

  test('반복 row는 recurrence_time(HH:MM:SS)을 시/분으로 파싱한다', () {
    final model = ScheduleModel.fromJson({
      'id': 's2',
      'elder_id': 'e1',
      'title': '혈압약 복용',
      'scheduled_at': '2026-08-25T08:30:00.000Z',
      'is_recurring': true,
      'completed': false,
      'created_at': '2026-08-24T00:00:00.000Z',
      'recurrence_time': '08:30:00',
    });

    final entity = model.toEntity();

    expect(entity.isRecurring, isTrue);
    expect(entity.recurrenceHour, 8);
    expect(entity.recurrenceMinute, 30);
  });

  test('completed row도 정상 변환된다', () {
    final model = ScheduleModel.fromJson({
      'id': 's3',
      'elder_id': 'e1',
      'title': '병원 방문',
      'scheduled_at': '2026-08-25T10:00:00.000Z',
      'is_recurring': false,
      'completed': true,
      'created_at': '2026-08-24T00:00:00.000Z',
    });

    final entity = model.toEntity();

    expect(entity.completed, isTrue);
  });
}
