import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/easy_mode/easy_mode_provider.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';
import 'package:ondam_senior/features/welfare_center/domain/entities/senior_center.dart';
import 'package:ondam_senior/features/welfare_center/presentation/pages/welfare_center_list_page.dart';
import 'package:ondam_senior/features/welfare_center/presentation/providers/welfare_center_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../domain/fakes/fake_welfare_center_repository.dart';

class _FixedEasyModeNotifier extends EasyModeNotifier {
  @override
  bool build() => false;
}

void main() {
  late FakeRegionRepository regionRepository;
  late FakeWelfareCenterRepository welfareCenterRepository;

  setUp(() {
    regionRepository = FakeRegionRepository();
    welfareCenterRepository = FakeWelfareCenterRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        welfareCenterRepositoryProvider.overrideWithValue(
          welfareCenterRepository,
        ),
        // 이 파일의 검증 대상은 Normal Mode 카드 레이아웃(인라인 전화
        // 아이콘 버튼 등)이다 — Easy Mode가 기본값이 된 뒤에도 그 의도를
        // 그대로 유지하기 위해 고정한다.
        easyModeProvider.overrideWith(_FixedEasyModeNotifier.new),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const WelfareCenterListPage(),
      ),
    );
  }

  testWidgets('지역이 없으면 지역 등록을 먼저 유도하고 검색을 시도하지 않는다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('경로당을 찾으려면 먼저 내 지역을 등록해주세요.'), findsOneWidget);
    expect(welfareCenterRepository.searchCalls, 0);

    await tester.tap(find.text('내 지역 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RegionInputPage), findsOneWidget);
  });

  testWidgets('지역이 있으면 지역을 보여주고, 검색 버튼을 눌러야 검색한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서울특별시 강남구 역삼동'), findsOneWidget);
    expect(welfareCenterRepository.searchCalls, 0);

    await tester.tap(find.text('내 주변 경로당 찾기'));
    await tester.pumpAndSettle();

    expect(welfareCenterRepository.searchCalls, 1);
  });

  testWidgets('검색 결과가 있으면 목록으로 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    welfareCenterRepository.searchResult = const Ok([
      SeniorCenter(id: '1', name: '역삼경로당', address: '서울 강남구 역삼동 1'),
      SeniorCenter(
        id: '2',
        name: '개포경로당',
        address: '서울 강남구 개포동 2',
        phoneNumber: '02-1234-5678',
      ),
    ]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 주변 경로당 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('역삼경로당'), findsOneWidget);
    expect(find.text('개포경로당'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsOneWidget);
  });

  testWidgets('검색 결과가 없으면 정직한 빈 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    welfareCenterRepository.searchResult = const Ok([]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 주변 경로당 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('근처에서 경로당을 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('실제 데이터 소스가 아직 없으면 정직하게 안내하고 가짜 목록을 보여주지 않는다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    welfareCenterRepository.searchResult = const Err(
      UnavailableFailure('경로당 정보를 아직 제공하지 않아요.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 주변 경로당 찾기'));
    await tester.pumpAndSettle();

    expect(find.text('경로당 정보를 아직 제공하지 않아요.'), findsOneWidget);
    expect(find.byIcon(Icons.call), findsNothing);
  });
}
