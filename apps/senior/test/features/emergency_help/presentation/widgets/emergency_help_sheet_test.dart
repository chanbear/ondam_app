import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/presentation/providers/emergency_help_di_providers.dart';
import 'package:ondam_senior/features/emergency_help/presentation/widgets/emergency_help_sheet.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

import '../../domain/fakes/fake_dialer_repository.dart';

void main() {
  late FakeDialerRepository repository;

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dialerRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => EmergencyHelpSheet.show(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    repository = FakeDialerRepository();
  });

  // 2026-08-29 product decision(ui-prototype `S("emergency")`) — SOS 구성이
  // 보호자 전화/119/112에서 112·119·110·120 4개 공공 긴급/상담 번호로
  // 교체됐다.
  testWidgets('112를 탭하면 실제 전화번호로 dialer를 호출한다', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('112 신고하기 (경찰)'));
    await tester.pumpAndSettle();

    expect(repository.lastCalledNumber, '112');
  });

  testWidgets('119를 탭하면 실제 전화번호로 dialer를 호출한다', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('119 신고하기 (소방·구급)'));
    await tester.pumpAndSettle();

    expect(repository.lastCalledNumber, '119');
  });

  testWidgets('110을 탭하면 실제 전화번호로 dialer를 호출한다', (tester) async {
    await pumpSheet(tester);

    // 시트 안에 4개 버튼이 스크롤 영역에 들어 있어, 작은 테스트 뷰포트에서는
    // 아래쪽 항목이 화면 밖에 있을 수 있다 — 탭 전에 스크롤해 보이게 한다.
    await tester.ensureVisible(find.text('110 상담하기 (정부민원안내)'));
    await tester.tap(find.text('110 상담하기 (정부민원안내)'));
    await tester.pumpAndSettle();

    expect(repository.lastCalledNumber, '110');
  });

  testWidgets('120을 탭하면 실제 전화번호로 dialer를 호출한다', (tester) async {
    await pumpSheet(tester);

    await tester.ensureVisible(find.text('120 상담하기 (다산콜센터)'));
    await tester.tap(find.text('120 상담하기 (다산콜센터)'));
    await tester.pumpAndSettle();

    expect(repository.lastCalledNumber, '120');
  });

  testWidgets('dialer 실행이 실패하면 실패 메시지를 보여준다', (tester) async {
    repository.result = const Err(UnavailableFailure('전화 앱을 열 수 없어요.'));
    await pumpSheet(tester);

    await tester.tap(find.text('112 신고하기 (경찰)'));
    await tester.pumpAndSettle();

    expect(find.text('전화 앱을 열 수 없어요.'), findsOneWidget);
  });
}
