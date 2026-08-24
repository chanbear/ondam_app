import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/features/analysis/presentation/pages/analysis_record_detail_page.dart';
import 'package:ondam_guardian/features/connection/presentation/providers/my_links_notifier.dart';
import 'package:ondam_guardian/l10n/generated/app_localizations.dart';
import 'package:ondam_models/ondam_models.dart';

class _FixedMyLinksNotifier extends MyLinksNotifier {
  _FixedMyLinksNotifier(this._links);

  final List<GuardianLink> _links;

  @override
  Future<List<GuardianLink>> build() async => _links;
}

void main() {
  Widget wrap(AnalysisResult result, {List<GuardianLink> links = const []}) {
    return ProviderScope(
      overrides: [
        myLinksProvider.overrideWith(() => _FixedMyLinksNotifier(links)),
      ],
      child: MaterialApp(
        locale: const Locale('ko'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AnalysisRecordDetailPage(result: result),
      ),
    );
  }

  AnalysisResult buildResult({
    required ReliabilityLevel reliability,
    RiskLevel? riskLevel,
    String? sourceExcerpt,
    Map<String, Object?>? structuredFields,
  }) {
    return AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.message,
      reliability: reliability,
      summary: '전기요금 고지서예요.',
      createdAt: DateTime(2026, 1, 1),
      riskLevel: riskLevel,
      sourceExcerpt: sourceExcerpt,
      structuredFields: structuredFields,
    );
  }

  testWidgets('renders a risk badge only when riskLevel is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        buildResult(
          reliability: ReliabilityLevel.high,
          riskLevel: RiskLevel.dangerous,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('위험 감지'), findsOneWidget);
  });

  testWidgets('omits the risk badge when riskLevel is null', (tester) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );
    await tester.pumpAndSettle();

    expect(find.text('위험 감지'), findsNothing);
    expect(find.text('주의'), findsNothing);
  });

  group('상세정보 (기본 접힘)', () {
    testWidgets('기본적으로 접혀 있어 신뢰도/필드/원문이 보이지 않는다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            sourceExcerpt: '[Web발신] 택배 배송 조회...',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('상세정보 보기'), findsOneWidget);
      expect(find.text('신뢰도'), findsNothing);
      expect(find.text('원문'), findsNothing);
    });

    testWidgets('펼치면 신뢰도(%)와 원문을 보여준다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            sourceExcerpt: '[Web발신] 택배 배송 조회...',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('상세정보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('신뢰도'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('원문'), findsOneWidget);
      expect(find.text('[Web발신] 택배 배송 조회...'), findsOneWidget);
    });

    testWidgets('원문이 없으면 펼쳐도 원문 라벨을 보여주지 않는다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('상세정보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('신뢰도'), findsOneWidget);
      expect(find.text('원문'), findsNothing);
    });

    testWidgets('펼치면 구조화 필드를 라벨-값으로 나열한다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            structuredFields: const {'금액': '32,000원', '납부기한': '2026-01-31'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('상세정보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('금액'), findsOneWidget);
      expect(find.text('32,000원'), findsOneWidget);
      expect(find.text('납부기한'), findsOneWidget);
      expect(find.text('2026-01-31'), findsOneWidget);
    });
  });

  group('확인 완료', () {
    testWidgets('아직 확인하지 않았으면 확인 완료 버튼을 보여준다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );
      await tester.pumpAndSettle();

      expect(find.text('확인 완료'), findsOneWidget);
      expect(find.text('확인 완료했어요'), findsNothing);
    });

    testWidgets('확인 완료를 누르면 완료 배너로 바뀐다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('확인 완료'));
      await tester.pumpAndSettle();

      expect(find.text('확인 완료했어요'), findsOneWidget);
      expect(find.text('확인 완료'), findsNothing);
    });
  });
}
