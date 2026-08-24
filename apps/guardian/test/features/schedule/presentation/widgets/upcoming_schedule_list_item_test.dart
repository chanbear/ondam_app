import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/schedule/presentation/widgets/upcoming_schedule_list_item.dart';
import 'package:ondam_models/ondam_models.dart';

void main() {
  testWidgets('제목과 날짜/시간을 보여준다', (tester) async {
    final schedule = Schedule(
      id: 's1',
      elderId: 'elder-1',
      title: '병원 방문',
      scheduledAt: DateTime(2026, 8, 25, 10, 30),
      completed: false,
      createdAt: DateTime(2026, 8, 24),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UpcomingScheduleListItem(schedule: schedule)),
      ),
    );

    expect(find.text('병원 방문'), findsOneWidget);
    expect(find.text('8월 25일 10:30'), findsOneWidget);
    expect(find.byIcon(Icons.repeat), findsNothing);
  });

  testWidgets('반복 일정은 반복 아이콘과 안내 문구를 보여준다', (tester) async {
    final schedule = Schedule(
      id: 's2',
      elderId: 'elder-1',
      title: '혈압약 복용',
      scheduledAt: DateTime(2026, 8, 25, 8, 30),
      completed: false,
      createdAt: DateTime(2026, 8, 24),
      isRecurring: true,
      recurrenceHour: 8,
      recurrenceMinute: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: UpcomingScheduleListItem(schedule: schedule)),
      ),
    );

    expect(find.byIcon(Icons.repeat), findsOneWidget);
    expect(find.text(' 매일 반복'), findsOneWidget);
  });
}
