import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/presentation/providers/emergency_help_di_providers.dart';
import 'package:ondam_senior/features/emergency_help/presentation/widgets/emergency_help_sheet.dart';

import '../../domain/fakes/fake_dialer_repository.dart';

void main() {
  late FakeDialerRepository repository;

  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dialerRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
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

  testWidgets('119을 탭하면 실제 전화번호로 dialer를 호출한다', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('119 (응급구조)'));
    await tester.pumpAndSettle();

    expect(repository.lastCalledNumber, '119');
  });

  testWidgets('dialer 실행이 실패하면 실패 메시지를 보여준다', (tester) async {
    repository.result = const Err(UnavailableFailure('전화 앱을 열 수 없어요.'));
    await pumpSheet(tester);

    await tester.tap(find.text('112 (경찰)'));
    await tester.pumpAndSettle();

    expect(find.text('전화 앱을 열 수 없어요.'), findsOneWidget);
  });

  testWidgets('보호자에게 전화는 저장된 번호가 없어 정직한 안내만 보여주고 dialer를 호출하지 않는다', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tester.tap(find.text('보호자에게 전화'));
    await tester.pumpAndSettle();

    expect(find.text('보호자 전화번호를 아직 알 수 없어요.'), findsOneWidget);
    expect(repository.lastCalledNumber, isNull);
  });
}
