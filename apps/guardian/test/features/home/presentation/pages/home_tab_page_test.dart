import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/analysis/domain/usecases/get_analysis_records_usecase.dart';
import 'package:ondam_guardian/features/analysis/presentation/providers/analysis_di_providers.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/my_links_notifier.dart';
import 'package:ondam_guardian/features/home/presentation/pages/home_tab_page.dart';
import 'package:ondam_guardian/features/notification/domain/entities/notification_item.dart';
import 'package:ondam_guardian/features/notification/presentation/providers/notifications_notifier.dart';
import 'package:ondam_guardian/features/schedule/domain/usecases/get_schedules_for_elder_usecase.dart';
import 'package:ondam_guardian/features/schedule/presentation/providers/schedule_di_providers.dart';
import 'package:ondam_guardian/l10n/generated/app_localizations.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../analysis/domain/fakes/fake_analysis_repository.dart';
import '../../../schedule/domain/fakes/fake_schedule_repository.dart';

class _FixedMyLinksNotifier extends MyLinksNotifier {
  _FixedMyLinksNotifier(this._links);

  final List<GuardianLink> _links;

  @override
  Future<List<GuardianLink>> build() async => _links;
}

class _FixedNotificationsNotifier extends NotificationsNotifier {
  _FixedNotificationsNotifier(this._items);

  final List<NotificationItem> _items;

  @override
  Future<List<NotificationItem>> build() async => _items;
}

Widget _wrap({
  required List<GuardianLink> links,
  required FakeAnalysisRepository repository,
  List<NotificationItem> notifications = const [],
  FakeScheduleRepository? scheduleRepository,
}) {
  return ProviderScope(
    overrides: [
      myLinksProvider.overrideWith(() => _FixedMyLinksNotifier(links)),
      getAnalysisRecordsUseCaseProvider.overrideWithValue(
        GetAnalysisRecordsUseCase(repository),
      ),
      getSchedulesForElderUseCaseProvider.overrideWithValue(
        GetSchedulesForElderUseCase(
          scheduleRepository ?? FakeScheduleRepository(),
        ),
      ),
      notificationsProvider.overrideWith(
        () => _FixedNotificationsNotifier(notifications),
      ),
    ],
    child: MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: HomeTabPage()),
    ),
  );
}

void main() {
  /// Regression test for the "최근 알림" section header — it was originally
  /// wrapped in an extra `Row(children: [AppSectionHeader(...), TextButton])`,
  /// which nests `AppSectionHeader`'s own internal `Expanded` inside a Row
  /// that gives it unbounded width. That throws a RenderFlex
  /// "unbounded width constraints" layout error that silently blanks the
  /// whole Home tab on a real device without any crash or logcat error —
  /// caught here by using `AppSectionHeader(trailing: ...)` instead and
  /// asserting every section actually renders when an elder is connected.
  testWidgets('연결된 어르신이 있으면 모든 섹션 헤더가 정상적으로 렌더링된다', (tester) async {
    // 어르신 카드/eyebrow 라벨이 추가되면서 "최근 활동" 섹션이 기본 테스트
    // 뷰포트(800x600)보다 아래로 밀렸다 — `ListView(children:...)`는 화면
    // 밖 자식을 지연 빌드하므로, 표면을 넉넉히 키워 모든 섹션이 한 번에
    // 빌드되게 한다(앱 동작 자체는 정상, 스크롤이 필요할 뿐).
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _wrap(
        links: [
          GuardianLink(
            id: 'link-1',
            elderId: 'elder-1',
            guardianId: 'guardian-1',
            status: GuardianLinkStatus.accepted,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        repository: FakeAnalysisRepository()
          ..getRecordsForElderResult = const Ok(<AnalysisResult>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('최근 알림'), findsOneWidget);
    expect(find.text('전체보기'), findsOneWidget);
    expect(find.text('다가오는 일정'), findsOneWidget);
    expect(find.text('최근 활동'), findsOneWidget);
  });

  testWidgets('다가오는 일정이 있으면 실제 데이터를 목록으로 보여준다', (tester) async {
    final scheduleRepository = FakeScheduleRepository();
    scheduleRepository.getSchedulesForElderResult = Ok([
      Schedule(
        id: 's1',
        elderId: 'elder-1',
        title: '병원 방문',
        scheduledAt: DateTime(2026, 8, 25, 10, 0),
        completed: false,
        createdAt: DateTime(2026, 8, 24),
      ),
    ]);

    await tester.pumpWidget(
      _wrap(
        links: [
          GuardianLink(
            id: 'link-1',
            elderId: 'elder-1',
            guardianId: 'guardian-1',
            status: GuardianLinkStatus.accepted,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        repository: FakeAnalysisRepository()
          ..getRecordsForElderResult = const Ok(<AnalysisResult>[]),
        scheduleRepository: scheduleRepository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('병원 방문'), findsOneWidget);
  });
}
