import 'action_item.dart';
import 'analysis_type.dart';
import 'important_date.dart';
import 'reliability_level.dart';
import 'risk_level.dart';

/// Shared shape for a document/message analysis result — produced by the
/// Senior app (`document_scan`, `message_check`) and read by the Guardian
/// app (`guardian`, billing statistics). Field list is a skeleton matching
/// the `analysis_results` table sketched in technical-decisions.md §4; it
/// will grow as those features are actually implemented.
class AnalysisResult {
  const AnalysisResult({
    required this.id,
    required this.elderId,
    required this.type,
    required this.reliability,
    required this.summary,
    required this.createdAt,
    this.riskLevel,
    this.sourceExcerpt,
    this.structuredFields,
    this.actionItems,
    this.importantDates,
    this.clarifyingQuestions,
    this.confirmedAt,
    this.billingAmountKrw,
    this.billingDate,
  });

  final String id;
  final String elderId;
  final AnalysisType type;
  final ReliabilityLevel reliability;
  final String summary;
  final DateTime createdAt;

  /// Both `document`- and `message`-type results carry a real riskLevel as
  /// of ONDAM 2.0 Phase 2 (`analyze-document`/`analyze-message` Edge
  /// Functions share the same deterministic floor —
  /// `supabase/functions/_shared/risk_floor.ts`). Still nullable because a
  /// row inserted before that Phase (or a future source type without risk
  /// scoring) may have none — never assume non-null from [type] alone.
  /// Independent from [reliability] by design: never derive one from the
  /// other (`caution` riskLevel with `low` reliability, or `safe` with
  /// `low`, are both valid and expected).
  final RiskLevel? riskLevel;

  final String? sourceExcerpt;

  /// Bill/document structured fields (amount, due date, category, ...) used
  /// by the Guardian app's billing statistics. Shape intentionally open
  /// (`Map`) until feature-spec.md ADD/NEW-5 finalizes the concrete fields.
  final Map<String, Object?>? structuredFields;

  /// ONDAM 2.0 결과 화면의 "해야 할 일" 체크리스트. AI가 채워주는 초안일 뿐,
  /// 사용자가 체크한 상태(`ActionItem.completed`)의 영속화 방식은 아직
  /// 결정되지 않았다 — 이 필드 자체는 `structuredFields`처럼 열려있는
  /// 컨테이너다. 현재 어떤 백엔드도 이 필드를 채우지 않으므로 항상 null일
  /// 수 있다.
  final List<ActionItem>? actionItems;

  /// ONDAM 2.0의 "날짜/기한 정보" — `structuredFields`의 자유 텍스트
  /// key-value로는 표현할 수 없는 종류/우선순위/근거 필요 여부를 담는다.
  /// 현재 어떤 백엔드도 이 필드를 채우지 않으므로 항상 null일 수 있다.
  final List<ImportantDate>? importantDates;

  /// ONDAM 2.0의 "사용자에게 추가 질문할 수 있는 정보" — AI가 문서/문자를
  /// 분석하면서 확신하지 못해 사용자에게 되물을 수 있는 질문 목록. 현재
  /// 어떤 백엔드도 이 필드를 채우지 않으므로 항상 null일 수 있다.
  final List<String>? clarifyingQuestions;

  /// 어르신 본인이 결과 화면에서 "확인 완료"를 누른 시각(ONDAM 2.0
  /// 요구사항 20/29) — `analysis_results.confirmed_at` 컬럼과 1:1 대응.
  /// 방금 만든 신규 분석 응답(document_scan/message_check의 Edge Function
  /// 응답)에는 이 값이 없으므로 항상 null이고, `analysis` feature가 DB에서
  /// 다시 읽어온 기록에서만 실제 값이 채워질 수 있다.
  final DateTime? confirmedAt;

  /// 요금/고지서 통계(ONDAM 2.0 요금 통계 기능)를 위해 `analyze-document`가
  /// 채워주는 원화 금액 — `structuredFields`처럼 AI가 매번 다른 자유 텍스트
  /// 라벨로 적는 값이 아니라, 스키마로 강제된 전용 정수 필드다.
  /// `analysis_results.billing_amount_krw` 컬럼과 1:1 대응. null이면 이
  /// 문서에서 금액을 신뢰성 있게 추출하지 못했다는 뜻이고, 통계 계산에서
  /// 제외해야 한다(가짜 0으로 대체하지 않는다) — `message`-type 레코드나
  /// 이 컬럼이 생기기 전에 분석된 레코드도 항상 null이다.
  final int? billingAmountKrw;

  /// 문서에 실제로 인쇄된 청구/납부일 — `analysis_results.billing_date`
  /// 컬럼과 1:1 대응. AI가 완전한 연-월-일을 확신할 수 있을 때만 채워지고,
  /// 그렇지 않으면 null이다(연도를 임의로 추정하지 않는다는 원칙은
  /// `importantDates`와 동일). null이면 통계 집계는 [createdAt]을 기준
  /// 날짜로 사용한다(우선순위: billingDate → createdAt).
  final DateTime? billingDate;
}
