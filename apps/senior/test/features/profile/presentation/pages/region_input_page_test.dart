import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/location_permission_status.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
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
        home: const RegionInputPage(),
      ),
    );
  }

  group('지역 입력 UI', () {
    testWidgets('시/도·시/군/구·읍/면/동 입력 UI와 저장 버튼이 모두 보인다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      expect(find.text('시/도'), findsOneWidget);
      expect(find.text('시/군/구'), findsOneWidget);
      expect(find.text('읍/면/동'), findsOneWidget);
      expect(find.text('현재 위치로 자동 입력'), findsOneWidget);
      expect(find.text('저장'), findsOneWidget);
    });

    testWidgets('시/도 목록에서 하나를 고르면 선택된 값이 표시된다', (tester) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('눌러서 선택해주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울특별시').last);
      await tester.pumpAndSettle();

      expect(find.text('서울특별시'), findsWidgets);
    });
  });

  group('지역 저장', () {
    testWidgets('저장 성공 시 안내 스낵바를 보여주고 이전 화면으로 돌아간다', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationRepositoryProvider.overrideWithValue(locationRepository),
            regionRepositoryProvider.overrideWithValue(regionRepository),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegionInputPage(),
                      ),
                    ),
                    child: const Text('열기'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('눌러서 선택해주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울특별시').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '강남구');
      await tester.enterText(find.byType(TextField).at(1), '역삼동');

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(regionRepository.saveCalls, 1);
      expect(find.text('내 지역이 저장되었어요.'), findsOneWidget);
      expect(find.byType(RegionInputPage), findsNothing);
    });

    testWidgets('저장 실패 시 화면에 남아 오류 메시지를 보여준다', (tester) async {
      regionRepository.saveRegionResult = const Err(ServerFailure());
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('눌러서 선택해주세요'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('서울특별시').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), '강남구');
      await tester.enterText(find.byType(TextField).at(1), '역삼동');

      await tester.tap(find.text('저장'));
      await tester.pumpAndSettle();

      expect(find.text('서버에 문제가 발생했습니다.'), findsOneWidget);
      expect(find.byType(RegionInputPage), findsOneWidget);
    });
  });

  group('현재 위치로 자동 입력', () {
    testWidgets('위치 권한이 허용되어 있으면 현재 위치로 필드를 채운다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.granted,
      );
      locationRepository.currentRegionResult = const Ok(
        Region(sido: '경기도', sigungu: '수원시', dong: '인계동'),
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('경기도'), findsWidgets);
      expect(locationRepository.getCurrentRegionCalls, 1);
    });

    testWidgets('위치 권한을 거부하면 허용을 유도하는 안내를 보여준다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.denied,
      );
      locationRepository.requestResult = const Ok(
        LocationPermissionStatus.denied,
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('위치 권한을 허용해야 현재 위치를 사용할 수 있어요.'), findsOneWidget);
      expect(locationRepository.requestCalls, 1);
      expect(locationRepository.getCurrentRegionCalls, 0);
    });

    testWidgets('위치 권한이 영구 거부되어 있으면 설정 안내를 보여준다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.permanentlyDenied,
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('기기 설정에서 위치 권한을 허용한 뒤 다시 시도해주세요.'), findsOneWidget);
      expect(locationRepository.requestCalls, 0);
    });

    testWidgets('위치 서비스가 꺼져 있으면 서비스를 켜라는 안내를 보여준다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.serviceDisabled,
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('위치 서비스를 켜신 뒤 다시 시도해주세요.'), findsOneWidget);
    });

    testWidgets('현재 위치 조회 자체가 실패하면 오류 메시지를 보여준다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.granted,
      );
      locationRepository.currentRegionResult = const Err(
        LocationFailure('현재 위치를 확인할 수 없어요.'),
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('현재 위치를 확인할 수 없어요.'), findsOneWidget);
    });

    testWidgets('reverse geocoding이 실패하면 그 사유를 그대로 보여준다', (tester) async {
      locationRepository.checkResult = const Ok(
        LocationPermissionStatus.granted,
      );
      locationRepository.currentRegionResult = const Err(
        LocationFailure('현재 위치를 지역명으로 바꾸지 못했어요.'),
      );
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('현재 위치로 자동 입력'));
      await tester.pumpAndSettle();

      expect(find.text('현재 위치를 지역명으로 바꾸지 못했어요.'), findsOneWidget);
    });
  });
}
