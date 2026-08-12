import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ondam_senior/app/app.dart';

void main() {
  testWidgets('App boots and renders the placeholder home route', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('ondam_senior'), findsOneWidget);
  });
}
