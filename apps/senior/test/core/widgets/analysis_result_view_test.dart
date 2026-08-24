import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/core/widgets/analysis_result_view.dart';
import 'package:ondam_senior/l10n/generated/app_localizations.dart';

void main() {
  Widget wrap(
    AnalysisResult result, {
    VoidCallback? onAskByVoice,
    Future<Result<void>> Function()? onConfirm,
    bool easyMode = false,
  }) {
    return MaterialApp(
      locale: const Locale('ko'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AnalysisResultView(
          result: result,
          onAskByVoice: onAskByVoice ?? () {},
          onConfirm: onConfirm,
          easyMode: easyMode,
        ),
      ),
    );
  }

  AnalysisResult buildResult({
    required ReliabilityLevel reliability,
    RiskLevel? riskLevel,
    Map<String, Object?>? structuredFields,
    List<ActionItem>? actionItems,
    List<ImportantDate>? importantDates,
    List<String>? clarifyingQuestions,
    String? sourceExcerpt,
    String summary = '전기요금 고지서예요.',
    DateTime? confirmedAt,
  }) {
    return AnalysisResult(
      id: 'a1',
      elderId: 'e1',
      type: AnalysisType.document,
      reliability: reliability,
      summary: summary,
      createdAt: DateTime(2026, 1, 1),
      riskLevel: riskLevel,
      structuredFields: structuredFields,
      actionItems: actionItems,
      importantDates: importantDates,
      clarifyingQuestions: clarifyingQuestions,
      sourceExcerpt: sourceExcerpt,
      confirmedAt: confirmedAt,
    );
  }

  // Phase 44: 신뢰도는 문장 하나만 상단에 보여준다 — 퍼센트는 "상세정보
  // 보기"를 펼쳐야 보인다(아래 '상세정보' 그룹에서 검증).
  testWidgets('high reliability shows the plain-language sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.high)),
    );

    expect(find.text('이 답변은 비교적 확실해요.'), findsOneWidget);
  });

  testWidgets('medium reliability shows the "조금 더 확인" sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.medium)),
    );

    expect(find.text('조금 더 확인이 필요해요.'), findsOneWidget);
  });

  testWidgets('low reliability shows the "정확하지 않을 수 있어요" sentence', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(buildResult(reliability: ReliabilityLevel.low)),
    );

    expect(find.text('정확하지 않을 수 있어요.'), findsOneWidget);
  });

  group('riskLevel', () {
    testWidgets('safe shows the 안전 badge', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            riskLevel: RiskLevel.safe,
          ),
        ),
      );

      expect(find.text('안전'), findsOneWidget);
    });

    testWidgets('caution shows the 주의 badge', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            riskLevel: RiskLevel.caution,
          ),
        ),
      );

      expect(find.text('주의'), findsOneWidget);
    });

    testWidgets('dangerous shows the 위험 감지 badge', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            riskLevel: RiskLevel.dangerous,
          ),
        ),
      );

      expect(find.text('위험 감지'), findsOneWidget);
    });

    testWidgets('null renders normally without any risk badge', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('위험 감지'), findsNothing);
      expect(find.text('안전'), findsNothing);
      expect(find.text('주의'), findsNothing);
      expect(find.text('전기요금 고지서예요.'), findsOneWidget);
    });

    testWidgets('caution + low reliability는 서로 영향을 주지 않고 둘 다 그대로 표시된다', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.low,
            riskLevel: RiskLevel.caution,
          ),
        ),
      );

      expect(find.text('주의'), findsOneWidget);
      expect(find.text('정확하지 않을 수 있어요.'), findsOneWidget);
    });
  });

  group('상세정보 (기본 접힘)', () {
    testWidgets('기본적으로 접혀 있어 신뢰도/필드/원문이 보이지 않는다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            structuredFields: const {'금액': '32,000원'},
            sourceExcerpt: '전기요금 32,000원을 8월 25일까지 납부해주세요.',
          ),
        ),
      );

      expect(find.text('상세정보 보기'), findsOneWidget);
      expect(find.text('80%'), findsNothing);
      expect(find.text('금액'), findsNothing);
      expect(find.text('원문'), findsNothing);
    });

    testWidgets('펼치면 신뢰도(%)/구조화 필드/원문을 모두 보여준다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            structuredFields: const {'금액': '32,000원', '납부기한': '2026-01-31'},
            sourceExcerpt: '전기요금 32,000원을 8월 25일까지 납부해주세요.',
          ),
        ),
      );

      await tester.tap(find.text('상세정보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('신뢰도'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('금액'), findsOneWidget);
      expect(find.text('32,000원'), findsOneWidget);
      expect(find.text('납부기한'), findsOneWidget);
      expect(find.text('2026-01-31'), findsOneWidget);
      expect(find.text('원문'), findsOneWidget);
      expect(find.text('전기요금 32,000원을 8월 25일까지 납부해주세요.'), findsOneWidget);
    });

    testWidgets('구조화 필드/원문이 없어도 신뢰도는 펼치면 항상 보인다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.medium)),
      );

      await tester.tap(find.text('상세정보 보기'));
      await tester.pumpAndSettle();

      expect(find.text('신뢰도'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('원문'), findsNothing);
    });
  });

  group('importantDates', () {
    testWidgets('있으면 "중요한 날짜" 섹션이 한국어 label과 함께 우선순위 순으로 보인다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            importantDates: [
              ImportantDate(
                date: DateTime(2026, 8, 25),
                kind: ImportantDateKind.expiration,
                priority: ImportantDatePriority.low,
              ),
              ImportantDate(
                date: DateTime(2026, 8, 20),
                kind: ImportantDateKind.paymentDue,
                priority: ImportantDatePriority.high,
              ),
            ],
          ),
        ),
      );

      expect(find.text('중요한 날짜'), findsOneWidget);
      expect(find.text('납부 기한'), findsOneWidget);
      expect(find.text('8월 20일'), findsOneWidget);
      expect(find.text('만료일'), findsOneWidget);
      expect(find.text('8월 25일'), findsOneWidget);

      // priority가 높은(high) 항목이 낮은(low) 항목보다 먼저 그려진다.
      final highOffset = tester.getTopLeft(find.text('납부 기한')).dy;
      final lowOffset = tester.getTopLeft(find.text('만료일')).dy;
      expect(highOffset, lessThan(lowOffset));
    });

    testWidgets('없으면(null/empty) 섹션 자체를 숨긴다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('중요한 날짜'), findsNothing);
    });

    testWidgets('AI 요약에 같은 날짜가 포함돼 있으면 표시 단계에서만 중복을 걷어낸다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            summary: '8월 20일까지 전기요금을 납부해주세요.',
            importantDates: [
              ImportantDate(
                date: DateTime(2026, 8, 20),
                kind: ImportantDateKind.paymentDue,
              ),
            ],
          ),
        ),
      );

      // 날짜 카드에는 그대로 "8월 20일"이 보이지만, 요약 문단에서는 같은
      // 표현이 제거된 채로 보인다 — AI 원본 summary 자체는 바뀌지 않는다
      // (buildResult에 넘긴 문자열 그대로가 위젯 트리에 다시 나타나지
      // 않아야 한다는 뜻).
      expect(find.text('8월 20일'), findsOneWidget); // 날짜 카드에서 1번만.
      expect(find.text('8월 20일까지 전기요금을 납부해주세요.'), findsNothing);
      expect(find.textContaining('전기요금을 납부해주세요.'), findsOneWidget);
    });
  });

  group('actionItems', () {
    testWidgets('있으면 체크리스트가 보이고 탭하면 로컬 상태로 체크된다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            actionItems: const [ActionItem(id: 'ai1', title: '관리비 납부')],
          ),
        ),
      );

      expect(find.text('해야 할 일'), findsOneWidget);
      expect(find.text('관리비 납부'), findsOneWidget);

      final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      final toggled = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(toggled.value, isTrue);
    });

    testWidgets('없으면(null/empty) 체크리스트 섹션을 표시하지 않는다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('해야 할 일'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('Phase 6: 여러 항목이 서로 독립적으로 체크된다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            actionItems: const [
              ActionItem(id: 'ai1', title: '관리비 납부'),
              ActionItem(id: 'ai2', title: '주민센터 방문'),
            ],
          ),
        ),
      );

      final checkboxesBefore = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .toList();
      expect(checkboxesBefore.map((c) => c.value), [false, false]);

      // 첫 번째 항목만 체크한다.
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();

      final checkboxesAfter = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .toList();
      expect(
        checkboxesAfter.map((c) => c.value),
        [true, false],
        reason: '체크한 항목만 바뀌고 나머지 항목은 영향받지 않아야 한다',
      );
    });
  });

  group('음성 질문', () {
    testWidgets('AI가 준 질문이 있으면 목록으로 보여주고, 진입 버튼도 함께 보인다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            clarifyingQuestions: const ['이 고지서가 본인 명의가 맞나요?'],
          ),
        ),
      );

      expect(find.textContaining('이 고지서가 본인 명의가 맞나요?'), findsOneWidget);
      expect(find.text('이 내용 물어보기'), findsOneWidget);
    });

    testWidgets('질문이 없어도 진입 버튼은 항상 보여준다', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          buildResult(reliability: ReliabilityLevel.high),
          onAskByVoice: () => tapped = true,
        ),
      );

      expect(find.text('이 내용 물어보기'), findsOneWidget);

      await tester.tap(find.text('이 내용 물어보기'));
      expect(tapped, isTrue);
    });
  });

  group('확인 완료', () {
    testWidgets('버튼을 누르면 완료 상태로 바뀌고 DB/서버 호출 없이 로컬에서만 처리된다', (tester) async {
      await tester.pumpWidget(
        wrap(buildResult(reliability: ReliabilityLevel.high)),
      );

      expect(find.text('확인 완료'), findsOneWidget);
      expect(find.text('확인 완료했어요'), findsNothing);

      await tester.tap(find.text('확인 완료'));
      await tester.pump();

      expect(find.text('확인 완료'), findsNothing);
      expect(find.text('확인 완료했어요'), findsOneWidget);
    });
  });

  testWidgets('summary만 있는 구형 데이터도 크래시 없이 렌더링된다', (tester) async {
    await tester.pumpWidget(
      wrap(
        AnalysisResult(
          id: 'legacy',
          elderId: 'e1',
          type: AnalysisType.document,
          reliability: ReliabilityLevel.medium,
          summary: '오래된 분석 결과예요.',
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
    );

    expect(find.text('오래된 분석 결과예요.'), findsOneWidget);
    expect(find.text('중요한 날짜'), findsNothing);
    expect(find.text('해야 할 일'), findsNothing);
    expect(find.text('이 내용 물어보기'), findsOneWidget);
  });

  group('확인 완료 — 서버 저장(onConfirm)', () {
    testWidgets('confirmedAt이 이미 있으면 다시 열었을 때 확인 완료 상태로 시작한다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(
            reliability: ReliabilityLevel.high,
            confirmedAt: DateTime(2026, 1, 2),
          ),
        ),
      );

      expect(find.text('확인 완료했어요'), findsOneWidget);
      expect(find.text('확인 완료'), findsNothing);
    });

    testWidgets('onConfirm이 성공하면 완료 상태로 바뀐다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(reliability: ReliabilityLevel.high),
          onConfirm: () async => const Ok(null),
        ),
      );

      await tester.tap(find.text('확인 완료'));
      await tester.pump();
      await tester.pump();

      expect(find.text('확인 완료했어요'), findsOneWidget);
    });

    testWidgets('onConfirm이 실패하면 오류 메시지를 보여주고 완료로 바뀌지 않는다', (tester) async {
      await tester.pumpWidget(
        wrap(
          buildResult(reliability: ReliabilityLevel.high),
          onConfirm: () async => const Err(NetworkFailure()),
        ),
      );

      await tester.tap(find.text('확인 완료'));
      await tester.pump();
      await tester.pump();

      expect(find.text('확인 완료했어요'), findsNothing);
      expect(find.text('확인 완료'), findsOneWidget);
      expect(find.text(const NetworkFailure().message), findsOneWidget);
    });
  });
}
