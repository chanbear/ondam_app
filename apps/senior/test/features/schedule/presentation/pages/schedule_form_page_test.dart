import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/schedule/presentation/pages/schedule_form_page.dart';
import 'package:ondam_senior/features/schedule/presentation/providers/schedule_di_providers.dart';

import '../../domain/fakes/fake_schedule_repository.dart';

Widget _wrap(FakeScheduleRepository repository) {
  return ProviderScope(
    overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: ScheduleFormPage()),
  );
}

void main() {
  testWidgets('제목을 입력하고 저장하면 일정 생성을 요청하고 화면을 닫는다', (tester) async {
    final repository = FakeScheduleRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '병원 방문');
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repository.createScheduleCalls.single['title'], '병원 방문');
    expect(find.byType(ScheduleFormPage), findsNothing);
  });

  testWidgets('제목 없이 저장하면 실패 메시지를 보여주고 화면에 남는다', (tester) async {
    final repository = FakeScheduleRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('일정 제목을 입력해주세요.'), findsOneWidget);
    expect(find.byType(ScheduleFormPage), findsOneWidget);
  });

  testWidgets('매일 반복을 켜면 반복 안내 문구가 보인다', (tester) async {
    final repository = FakeScheduleRepository();
    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(Switch));
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '혈압약 복용');
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(repository.createScheduleCalls.single['isRecurring'], isTrue);
    expect(repository.createScheduleCalls.single['recurrenceHour'], isNotNull);
    expect(
      repository.createScheduleCalls.single['recurrenceMinute'],
      isNotNull,
    );
  });
}
