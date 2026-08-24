import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';
import 'package:ondam_senior/features/support/domain/entities/local_gov_office.dart';
import 'package:ondam_senior/features/support/presentation/pages/privacy_info_page.dart';
import 'package:ondam_senior/features/support/presentation/pages/support_page.dart';
import 'package:ondam_senior/features/support/presentation/providers/local_gov_office_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../domain/fakes/fake_local_gov_office_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeLocalGovOfficeRepository localGovOfficeRepository;

  setUp(() {
    regionRepository = FakeRegionRepository();
    localGovOfficeRepository = FakeLocalGovOfficeRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        localGovOfficeRepositoryProvider.overrideWithValue(
          localGovOfficeRepository,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SupportPage(),
      ),
    );
  }

  testWidgets('지역이 없으면 지역 등록을 먼저 유도하고 조회를 시도하지 않는다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('관할 행정복지센터 연락처를 보려면 먼저 내 지역을 등록해주세요.'), findsOneWidget);
    expect(localGovOfficeRepository.searchCalls, 0);

    await tester.tap(find.text('내 지역 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RegionInputPage), findsOneWidget);
  });

  testWidgets('지역이 있으면 관할 행정복지센터 주소를 자동으로 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    localGovOfficeRepository.searchResult = const Ok(
      LocalGovOffice(address: '서울특별시 강남구 테헤란로 지하 426', postalCode: '06236'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서울특별시 강남구 테헤란로 지하 426'), findsOneWidget);
    expect(localGovOfficeRepository.searchCalls, 1);
    expect(localGovOfficeRepository.lastSearchedRegion?.dong, '역삼동');
  });

  testWidgets('전화번호가 있으면 전화 아이콘을 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    localGovOfficeRepository.searchResult = const Ok(
      LocalGovOffice(
        address: '서울특별시 강남구 테헤란로 지하 426',
        phoneNumber: '02-1234-5678',
      ),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  testWidgets('전화번호가 없으면(현재 데이터 소스의 알려진 한계) 정직하게 안내하고 전화 아이콘을 숨긴다', (
    tester,
  ) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    localGovOfficeRepository.searchResult = const Ok(
      LocalGovOffice(address: '서울특별시 강남구 테헤란로 지하 426'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('전화번호 정보가 아직 없어요.'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('일치하는 기관을 찾지 못하면 정직한 빈 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    localGovOfficeRepository.searchResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('내 지역의 행정복지센터 정보를 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('실제 데이터 소스가 아직 없으면 정직하게 안내하고 가짜 연락처를 보여주지 않는다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    localGovOfficeRepository.searchResult = const Err(
      UnavailableFailure('관할 행정복지센터 연락처를 아직 제공하지 않아요.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('관할 행정복지센터 연락처를 아직 제공하지 않아요.'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing);
  });

  testWidgets('개인정보 보관 안내를 탭하면 PrivacyInfoPage로 이동한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 정보가 어떻게 보관되는지 확인해요'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyInfoPage), findsOneWidget);
    expect(find.text('비밀번호(PIN)'), findsOneWidget);
  });
}
