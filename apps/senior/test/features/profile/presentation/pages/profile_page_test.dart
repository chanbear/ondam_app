import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/presentation/pages/profile_page.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';
import 'package:ondam_senior/features/profile/presentation/providers/profile_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../../../core/location/domain/fakes/fake_location_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../domain/fakes/fake_profile_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeProfileRepository profileRepository;

  setUp(() {
    regionRepository = FakeRegionRepository();
    profileRepository = FakeProfileRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        locationRepositoryProvider.overrideWithValue(FakeLocationRepository()),
        profileRepositoryProvider.overrideWithValue(profileRepository),
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

  testWidgets('이름/나이를 입력하고 저장하면 저장 완료 안내를 보여준다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), '홍길동');
    await tester.enterText(find.byType(TextField).at(1), '73');
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

    await tester.enterText(find.byType(TextField).at(1), '73');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(profileRepository.saveCalls, 0);
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
  });
}
