import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_senior/features/support/presentation/pages/privacy_info_page.dart';
import 'package:ondam_senior/features/support/presentation/pages/support_page.dart';

void main() {
  testWidgets('고객센터 연락처는 실제 번호 없이 정직한 준비중 안내를 보여준다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    expect(find.text('전화·이메일 연락처를 준비하고 있어요. 곧 안내해드릴게요.'), findsOneWidget);
  });

  testWidgets('개인정보 보관 안내를 탭하면 PrivacyInfoPage로 이동한다', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupportPage()));

    await tester.tap(find.text('내 정보가 어떻게 보관되는지 확인해요'));
    await tester.pumpAndSettle();

    expect(find.byType(PrivacyInfoPage), findsOneWidget);
    expect(find.text('비밀번호(PIN)'), findsOneWidget);
  });
}
