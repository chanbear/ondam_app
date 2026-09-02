import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/schedule/presentation/providers/schedule_di_providers.dart';
import 'package:ondam_senior/features/schedule/presentation/widgets/schedule_tab_view.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../domain/fakes/fake_schedule_repository.dart';

Schedule _schedule(String id, String title, {bool completed = false}) {
  return Schedule(
    id: id,
    elderId: 'e1',
    title: title,
    scheduledAt: DateTime(2026, 8, 25, 10, 0),
    completed: completed,
    createdAt: DateTime(2026, 8, 24),
  );
}

Widget _wrap(FakeScheduleRepository repository) {
  return ProviderScope(
    overrides: [scheduleRepositoryProvider.overrideWithValue(repository)],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ScheduleTabView()),
    ),
  );
}

void main() {
  testWidgets('일정이 없으면 빈 상태 문구를 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(FakeScheduleRepository()));
    await tester.pumpAndSettle();

    expect(find.text('등록된 일정이 없어요.'), findsOneWidget);
  });

  testWidgets('일정 목록을 제목과 함께 그린다', (tester) async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = Ok([_schedule('s1', '병원 방문')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    expect(find.text('병원 방문'), findsOneWidget);
  });

  testWidgets('체크박스를 누르면 완료 처리를 요청한다', (tester) async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = Ok([_schedule('s1', '병원 방문')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(repository.toggleCompletedCalls, [('s1', true)]);
  });

  testWidgets('삭제 버튼 → 확인 다이얼로그에서 삭제를 누르면 삭제를 요청한다', (tester) async {
    final repository = FakeScheduleRepository();
    repository.getMySchedulesResult = Ok([_schedule('s1', '병원 방문')]);

    await tester.pumpWidget(_wrap(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(repository.deleteScheduleCalls, ['s1']);
  });
}
