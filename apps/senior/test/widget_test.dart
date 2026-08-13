import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ondam_senior/app/app.dart';

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    // Dummy project — no network call happens during init/recoverSession
    // with empty local storage (see supabase_flutter's
    // SharedPreferencesLocalStorage). Real credentials come from .env via
    // AppConfig in main.dart, never hardcoded here or there.
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      publishableKey: 'test-anon-key',
    );
  });

  testWidgets('App boots with no session and lands on phone input', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('휴대폰 번호로 시작하기'), findsOneWidget);
  });
}
