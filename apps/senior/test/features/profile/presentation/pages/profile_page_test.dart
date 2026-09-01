import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/presentation/pages/profile_page.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';
import 'package:ondam_senior/features/profile/presentation/providers/profile_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/demographics/domain/fakes/fake_demographics_repository.dart';
import '../../../../core/location/domain/fakes/fake_location_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../domain/fakes/fake_profile_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeProfileRepository profileRepository;
  late FakeDemographicsRepository demographicsRepository;

  // 나이 입력이 텍스트 필드에서 스테퍼(+/-)로 바뀌어(2026-08-31), 기본값
  // 60에서 목표값까지 "+" 버튼을 눌러서 도달한다.
  Future<void> setAge(WidgetTester tester, int target) async {
    for (var age = 60; age < target; age++) {
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
    }
  }

  setUp(() {
    regionRepository = FakeRegionRepository();
    profileRepository = FakeProfileRepository();
    demographicsRepository = FakeDemographicsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        locationRepositoryProvider.overrideWithValue(FakeLocationRepository()),
        profileRepositoryProvider.overrideWithValue(profileRepository),
        demographicsRepositoryProvider.overrideWithValue(
          demographicsRepository,
        ),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ProfilePage(),
      ),
    );
  }

  testWidgets('저장된 지역이 없으면 정직하게 미등록 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('아직 등록하지 않았어요'), findsOneWidget);
  });

  testWidgets('저장된 지역이 있으면 그대로 표시한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서울특별시 강남구 역삼동'), findsOneWidget);
  });

  testWidgets('"내 지역 입력하기"를 누르면 지역 입력 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('내 지역 입력하기'));
    await tester.tap(find.text('내 지역 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RegionInputPage), findsOneWidget);
  });

  testWidgets('저장된 이름/나이가 있으면 입력창에 채워서 보여준다', (tester) async {
    profileRepository.getMyProfileResult = const Ok(
      Profile(name: '홍길동', age: 73),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('홍길동'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);
  });

  testWidgets('이름/성별/나이를 입력하고 저장하면 저장 완료 안내를 보여준다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await setAge(tester, 73);
    await tester.ensureVisible(find.text('남성'));
    await tester.tap(find.text('남성'));
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(profileRepository.saveCalls, 1);
    expect(profileRepository.savedProfile?.name, '홍길동');
    expect(profileRepository.savedProfile?.age, 73);
    expect(find.text('프로필이 저장되었어요.'), findsOneWidget);
  });

  testWidgets('이름 없이 저장하면 오류 메시지를 보여주고 저장을 시도하지 않는다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await setAge(tester, 73);
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(profileRepository.saveCalls, 0);
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
  });

  testWidgets('저장된 성별이 있으면 저장 시 그대로 다시 저장된다(미리 채워짐)', (tester) async {
    demographicsRepository.getMyDemographicsResult = const Ok(
      Demographics(age: 72, gender: Gender.female),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await setAge(tester, 73);
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(demographicsRepository.saveCalls, 1);
    expect(demographicsRepository.savedDemographics?.gender, Gender.female);
  });

  testWidgets('나이 입력 + 성별 선택 후 저장하면 성별도 함께 저장된다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await setAge(tester, 73);
    await tester.ensureVisible(find.text('남성'));
    await tester.tap(find.text('남성'));
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(profileRepository.saveCalls, 1);
    expect(demographicsRepository.saveCalls, 1);
    expect(demographicsRepository.savedDemographics?.age, 73);
    expect(demographicsRepository.savedDemographics?.gender, Gender.male);
    expect(find.text('프로필이 저장되었어요.'), findsOneWidget);
  });

  testWidgets('성별을 선택하지 않고 저장하면 성별은 저장을 시도하지 않고 안내를 보여준다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await setAge(tester, 73);
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(profileRepository.saveCalls, 1);
    expect(demographicsRepository.saveCalls, 0);
    // BUG 회귀 테스트 — 성별 미선택 시 "저장되었어요"로 오해하게 두지 않고
    // 왜 정보 탭에 아무것도 안 나오는지 알 수 있는 안내를 보여준다.
    expect(find.text('프로필이 저장되었어요.'), findsNothing);
    expect(find.text('성별을 선택해주세요. 맞춤 정보 검색에 꼭 필요해요.'), findsOneWidget);
  });

  testWidgets('성별 저장이 실패하면 에러 메시지를 보여준다', (tester) async {
    demographicsRepository.saveDemographicsResult = const Err(
      ServerFailure('서버에 문제가 발생했습니다.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await setAge(tester, 73);
    await tester.ensureVisible(find.text('남성'));
    await tester.tap(find.text('남성'));
    await tester.ensureVisible(find.text('저장'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('서버에 문제가 발생했습니다.'), findsOneWidget);
  });
}
