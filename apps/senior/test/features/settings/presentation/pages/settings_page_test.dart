import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/locale/locale_provider.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/core/location/presentation/providers/region_provider.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_di_providers.dart';
import 'package:ondam_senior/features/analysis/presentation/providers/analysis_records_notifier.dart';
import 'package:ondam_senior/features/auth/presentation/providers/auth_di_providers.dart';
import 'package:ondam_senior/features/auth/presentation/providers/has_pin_provider.dart';
import 'package:ondam_senior/features/auth/presentation/providers/role_notifier.dart';
import 'package:ondam_senior/features/connection/presentation/providers/connection_di_providers.dart';
import 'package:ondam_senior/features/connection/presentation/providers/guardian_links_notifier.dart';
import 'package:ondam_senior/features/settings/presentation/pages/settings_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/location/domain/fakes/fake_location_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../../analysis/domain/fakes/fake_analysis_records_repository.dart';
import '../../../auth/domain/fakes/fake_auth_repository.dart';
import '../../../connection/domain/fakes/fake_connection_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('로그아웃하면 이전 사용자의 저장된 지역이 캐시에서 무효화되어 다시 조회한다'
      '(다른 계정 전환 시 지역 노출 방지)', (tester) async {
    final authRepository = FakeAuthRepository();
    final regionRepository = FakeRegionRepository();
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          regionRepositoryProvider.overrideWithValue(regionRepository),
          locationRepositoryProvider.overrideWithValue(
            FakeLocationRepository(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Column(
            children: [
              const Expanded(child: SettingsPage()),
              // regionProvider를 실제로 구독하는 화면이 있어야
              // invalidate 이후 재조회가 일어난다 — profile_page 등
              // 실제 사용 화면을 흉내낸다.
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(regionProvider);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(regionRepository.getMyRegionCalls, 1);

    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(authRepository.signOutCalls, 1);
    // invalidate 후 여전히 regionProvider를 구독하는 위젯이 있으므로
    // 다시 조회된다 — 이전 사용자의 값이 그대로 캐시된 채 남지 않는다.
    expect(regionRepository.getMyRegionCalls, 2);
  });

  testWidgets('로그아웃하면 분석 기록/보호자 목록/역할/PIN 여부도 함께 무효화되어 '
      '다음 계정에게 이전 계정 데이터가 남지 않는다', (tester) async {
    final authRepository = FakeAuthRepository();
    final analysisRecordsRepository = FakeAnalysisRecordsRepository();
    final connectionRepository = FakeConnectionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          regionRepositoryProvider.overrideWithValue(FakeRegionRepository()),
          locationRepositoryProvider.overrideWithValue(
            FakeLocationRepository(),
          ),
          analysisRecordsRepositoryProvider.overrideWithValue(
            analysisRecordsRepository,
          ),
          connectionRepositoryProvider.overrideWithValue(connectionRepository),
        ],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Column(
            children: [
              const Expanded(child: SettingsPage()),
              // 각 Provider를 실제로 구독하는 화면들을 흉내낸다 — 그래야
              // invalidate 이후 재조회 여부를 관찰할 수 있다.
              Consumer(
                builder: (context, ref, _) {
                  ref.watch(analysisRecordsProvider);
                  ref.watch(guardianLinksProvider);
                  ref.watch(roleNotifierProvider);
                  ref.watch(hasPinProvider);
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(analysisRecordsRepository.getMyRecordsCallCount, 1);
    expect(connectionRepository.getGuardianLinksCallCount, 1);
    expect(authRepository.getRolesCalls, 1);
    expect(authRepository.hasPinCalls, 1);

    await tester.ensureVisible(find.text('로그아웃'));
    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(authRepository.signOutCalls, 1);
    expect(analysisRecordsRepository.getMyRecordsCallCount, 2);
    expect(connectionRepository.getGuardianLinksCallCount, 2);
    expect(authRepository.getRolesCalls, 2);
    expect(authRepository.hasPinCalls, 2);
  });

  testWidgets('언어를 선택하면 화면 문구가 즉시 해당 언어로 바뀌고 저장된다', (tester) async {
    late WidgetRef capturedRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          regionRepositoryProvider.overrideWithValue(FakeRegionRepository()),
          locationRepositoryProvider.overrideWithValue(
            FakeLocationRepository(),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            capturedRef = ref;
            final locale = ref.watch(localeControllerProvider);
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsPage(),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);

    // 2026-08-30 설정 화면이 섹션 카드 3개(쉬운 모드/접근성/언어)로 나뉘며
    // 길어져, 기본 테스트 뷰포트(800x600)에서 "English"가 화면 밖으로
    // 밀려났다 — 탭하기 전에 스크롤해서 보이게 한다.
    await tester.ensureVisible(find.text('English'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app_locale'), 'en');
    expect(capturedRef.read(localeControllerProvider), const Locale('en'));
  });
}
