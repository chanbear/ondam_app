import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('내 정보 단계에서 현재 위치로 지역을 채우고 다음으로 넘어가면 다른 화면으로 이동하지 않고 지역이 저장된다', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // 접근성 스텝 → 내 정보 스텝.
    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('현재 위치로 자동 입력'));
    await tester.tap(find.text('현재 위치로 자동 입력'));
    await tester.pumpAndSettle();

    // 위치 조회 결과가 표시돼도 다른 화면(RegionInputPage)으로 이동하지 않는다.
    expect(find.byType(RegionInputPage), findsNothing);
    expect(find.text('서울특별시 강남구 역삼동'), findsOneWidget);

    await tester.ensureVisible(find.text('보호자 등록으로 넘어가기'));
    await tester.tap(find.text('보호자 등록으로 넘어가기'));
    await tester.pumpAndSettle();

    expect(regionRepository.saveCalls, 1);
    expect(regionRepository.savedRegion?.sido, '서울특별시');
    expect(regionRepository.savedRegion?.sigungu, '강남구');
    expect(regionRepository.savedRegion?.dong, '역삼동');
  });

  testWidgets('내 정보 단계에서 시/도를 고르지 않고 다음으로 넘어가면 지역 저장을 시도하지 않는다', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('다음'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('보호자 등록으로 넘어가기'));
    await tester.tap(find.text('보호자 등록으로 넘어가기'));
    await tester.pumpAndSettle();

    expect(regionRepository.saveCalls, 0);
  });
}
