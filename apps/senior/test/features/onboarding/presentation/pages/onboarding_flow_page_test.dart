import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/location_permission_status.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/onboarding/presentation/pages/onboarding_flow_page.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/location/domain/fakes/fake_location_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';

void main() {
  late FakeLocationRepository locationRepository;
  late FakeRegionRepository regionRepository;

  setUp(() {
    locationRepository = FakeLocationRepository();
    regionRepository = FakeRegionRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        locationRepositoryProvider.overrideWithValue(locationRepository),
        regionRepositoryProvider.overrideWithValue(regionRepository),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const OnboardingFlowPage(),
      ),
    );
  }

  // BUG 회귀 테스트 — "내 지역 입력하기"가 RegionInputPage로 이동해버려서
  // 온보딩 흐름이 끊기고, 지역이 저장되지 않았다.
  // 2026-09-02 — ui-prototype에 맞춰 시/도 수동 선택이 없어지고 "현재 위치로
  // 자동 입력" 버튼만 남아, 이 테스트도 위치 조회 흐름으로 갱신했다.
  // 2026-09-02 (2) — 값이 label 옆에 작게 표시되던 것을 예시가 있는 입력칸
  // 하나로 바꿨다(사용자 요청) — "현재 위치로 자동 입력" 버튼은 그대로
  // 유지했다(버튼을 없애면 안 된다는 사용자 피드백).
  // 2026-09-02 (3) — 화면 진입 시 자동으로 위치를 시도하던 것을 없앴다
  // (사용자 요청) — 버튼을 눌러야 채워지므로, 그 흐름과 직접 타이핑해서
  // 채우는 흐름을 각각 검증한다.
  testWidgets('내 정보 단계에 들어가면 지역 입력칸은 비어있고, 버튼을 눌러야 현재 위치가 채워진다', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // 접근성 스텝 → 내 정보 스텝.
    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    // 화면 진입만으로는 채워지지 않는다 — 버튼을 눌러야 한다.
    expect(find.byType(RegionInputPage), findsNothing);
    expect(find.text('서울특별시 강남구 역삼동'), findsNothing);
    expect(locationRepository.getCurrentRegionCalls, 0);

    await tester.ensureVisible(find.text('현재 위치로 자동 입력'));
    await tester.tap(find.text('현재 위치로 자동 입력'));
    await tester.pumpAndSettle();

    expect(find.text('서울특별시 강남구 역삼동'), findsOneWidget);

    await tester.ensureVisible(find.text('보호자 등록으로 넘어가기'));
    await tester.tap(find.text('보호자 등록으로 넘어가기'));
    await tester.pumpAndSettle();

    expect(regionRepository.saveCalls, 1);
    expect(regionRepository.savedRegion?.sido, '서울특별시');
    expect(regionRepository.savedRegion?.sigungu, '강남구');
    expect(regionRepository.savedRegion?.dong, '역삼동');
  });

  testWidgets('지역 입력칸에 직접 지역명을 입력하고 다음으로 넘어가면 그 값이 저장된다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '부산광역시 해운대구 우동');
    await tester.pumpAndSettle();

    // 버튼을 누르지 않아도 직접 입력한 값이 그대로 유지된다.
    expect(locationRepository.getCurrentRegionCalls, 0);

    await tester.ensureVisible(find.text('보호자 등록으로 넘어가기'));
    await tester.tap(find.text('보호자 등록으로 넘어가기'));
    await tester.pumpAndSettle();

    expect(regionRepository.saveCalls, 1);
    expect(regionRepository.savedRegion?.sido, '부산광역시');
    expect(regionRepository.savedRegion?.sigungu, '해운대구');
    expect(regionRepository.savedRegion?.dong, '우동');
  });

  testWidgets('위치를 가져올 수 없으면 버튼을 눌러도 입력칸이 비어있고, 다음으로 넘어가도 지역 저장을 시도하지 않는다', (
    tester,
  ) async {
    locationRepository.checkResult = const Ok(
      LocationPermissionStatus.permanentlyDenied,
    );

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('현재 위치로 자동 입력'));
    await tester.tap(find.text('현재 위치로 자동 입력'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('보호자 등록으로 넘어가기'));
    await tester.tap(find.text('보호자 등록으로 넘어가기'));
    await tester.pumpAndSettle();

    expect(regionRepository.saveCalls, 0);
  });
}
