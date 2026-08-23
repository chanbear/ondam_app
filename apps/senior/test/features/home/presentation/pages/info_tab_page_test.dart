import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/home/presentation/pages/info_tab_page.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/presentation/pages/benefit_service_detail_page.dart';
import 'package:ondam_senior/features/info/presentation/providers/benefit_service_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/pages/profile_page.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/demographics/domain/fakes/fake_demographics_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../../info/domain/fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeDemographicsRepository demographicsRepository;
  late FakeBenefitServiceRepository benefitServiceRepository;

  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    regionRepository = FakeRegionRepository();
    demographicsRepository = FakeDemographicsRepository();
    benefitServiceRepository = FakeBenefitServiceRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        demographicsRepositoryProvider.overrideWithValue(
          demographicsRepository,
        ),
        benefitServiceRepositoryProvider.overrideWithValue(
          benefitServiceRepository,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: InfoTabPage()),
      ),
    );
  }

  testWidgets('나이/성별/지역이 없으면 내 정보 입력을 먼저 유도하고 검색을 시도하지 않는다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    demographicsRepository.getMyDemographicsResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('내 정보 입력하기'), findsOneWidget);
    expect(benefitServiceRepository.searchCalls, 0);

    await tester.tap(find.text('내 정보 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('나이/성별/지역이 모두 있으면 자동으로 검색해 목록을 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(benefitServiceRepository.searchCalls, 1);
    expect(find.text('기초연금'), findsOneWidget);
  });

  testWidgets('검색 결과가 없으면 정직한 빈 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('지금 조건에 맞는 혜택 정보를 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('실제 데이터 소스가 아직 없으면 정직하게 안내한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Err(
      UnavailableFailure('맞춤 혜택 정보를 아직 제공하지 않아요.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('맞춤 혜택 정보를 아직 제공하지 않아요.'), findsOneWidget);
  });

  testWidgets('카드를 탭하면 상세 화면으로 이동한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ]);
    benefitServiceRepository.getDetailResult = const Ok(
      BenefitServiceDetail(id: 'WLF001', title: '기초연금', summary: '만 65세 이상 지원'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('기초연금'));
    await tester.pumpAndSettle();

    expect(find.byType(BenefitServiceDetailPage), findsOneWidget);
  });
}
