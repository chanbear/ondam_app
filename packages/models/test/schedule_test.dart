import 'package:ondam_models/ondam_models.dart';
import 'package:test/test.dart';

void main() {
  test(
    'isRecurring/recurrenceHour/recurrenceMinute를 지정하지 않으면 기본값(false/null/null)을 쓴다',
    () {
      final schedule = Schedule(
        id: 's1',
        elderId: 'e1',
        title: '병원 방문',
        scheduledAt: DateTime(2026, 8, 25, 10, 0),
        completed: false,
        createdAt: DateTime(2026, 8, 24),
      );

      expect(schedule.isRecurring, isFalse);
      expect(schedule.recurrenceHour, isNull);
      expect(schedule.recurrenceMinute, isNull);
    },
  );

  test('반복 일정은 recurrenceHour/recurrenceMinute를 그대로 보존한다', () {
    final schedule = Schedule(
      id: 's2',
      elderId: 'e1',
      title: '혈압약 복용',
      scheduledAt: DateTime(2026, 8, 25, 8, 30),
      completed: false,
      createdAt: DateTime(2026, 8, 24),
      isRecurring: true,
      recurrenceHour: 8,
      recurrenceMinute: 30,
    );

    expect(schedule.isRecurring, isTrue);
    expect(schedule.recurrenceHour, 8);
    expect(schedule.recurrenceMinute, 30);
  });
}
