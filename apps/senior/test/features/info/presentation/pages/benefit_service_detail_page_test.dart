import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/presentation/pages/benefit_service_detail_page.dart';
import 'package:ondam_senior/features/info/presentation/providers/benefit_service_di_providers.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../domain/fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        benefitServiceRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const BenefitServiceDetailPage(
          id: 'WLF001',
          source: BenefitServiceSource.central,
        ),
      ),
    );
  }

  testWidgets('상세 정보를 지원대상/신청방법/문의처와 함께 보여준다', (tester) async {
    repository.getDetailResult = const Ok(
      BenefitServiceDetail(
        id: 'WLF001',
        title: '기초연금',
        summary: '만 65세 이상 지원',
        supportTarget: '소득 하위 70%',
        applyMethod: '주민센터 방문 신청',
        contact: '129',
      ),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('기초연금'), findsOneWidget);
    expect(find.text('소득 하위 70%'), findsOneWidget);
    expect(find.text('주민센터 방문 신청'), findsOneWidget);
    expect(find.text('문의처 전화하기'), findsOneWidget);
  });

  testWidgets('조회 실패 시 에러와 재시도를 보여준다', (tester) async {
    repository.getDetailResult = const Err(ServerFailure());
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서버에 문제가 발생했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
