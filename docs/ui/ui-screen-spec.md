# UI Screen Spec

> `ui-information-architecture.md`의 화면 트리를 화면 단위로 구체화한다. Auth 화면(phone_input/otp_verify/pin_setup/pin_entry/pin_forgot/role_select/session_loading)은 Phase 2에서, `document_scan`(아래 두 절)은 Phase 4에서 이미 구현이 끝났으므로 이 문서에서 다시 스펙을 정의하지 않는다 — 실제 코드가 명세다(단, 분석 요청은 백엔드가 없어 항상 "준비 중" 상태로 귀결됨 — `technical-decisions.md` §6 참고). 아래는 그 외 **아직 구현하지 않은 화면**의 스펙이다. 시각적 세부 값(정확한 색상/간격 px)은 고정하지 않고 토큰 이름으로만 표기한다 — Figma 확정 후 값이 채워진다.

---

## Senior App

### 홈 (Normal Mode)
- **목적**: 핵심 기능 진입 + 오늘 상태 요약.
- **주요 정보**: 핵심 기능 카드(문서 촬영/문자 확인/경로당 찾기/음성 비서), 오늘 해야 할 일 요약, 나이 기반 맞춤 정보 카드.
- **Primary CTA**: 핵심 기능 카드 탭.
- **Secondary CTA**: "오늘 해야 할 일 - 전체 보기", 맞춤 정보 카드 상세보기.
- **상태**: 데이터 있음(카드+요약 노출) / 로딩(`AppLoading` 단순형) / 에러(`AppError`, 재시도).
- **오류**: 맞춤 정보 조회 실패 시 카드 영역만 `AppError`로 대체(다른 영역은 정상 노출).
- **Empty State**: "오늘 해야 할 일" 없음 → `AppEmptyState`("오늘은 예정된 일정이 없어요").
- **Easy Mode 차이**: 카드 5개 이하로 축소, 맞춤 정보 카드는 "더보기"로 이동, 긴급 도움 버튼과 음성 비서 버튼을 동등하게 눈에 띄는 위치(하단 고정)에 배치.
- **필요 컴포넌트**: `AppScaffold`, `AppCard`(핵심 기능), `AppStatusCard`(오늘 요약), `AppBottomNavigation`, 긴급 도움 플로팅 버튼(feature-local).

### 정보 (info)
- **목적**: 개인화된 복지/안전 정보 + 근처 경로당·복지센터 탐색.
- **주요 정보**: 맞춤 정보 카드 3개, 근처 시설 리스트(거리순).
- **Primary CTA**: 시설 리스트 항목 탭 → 상세.
- **Secondary CTA**: 위치 재조회, 주소 직접 입력(권한 거부/실패 시).
- **상태**: 로딩(`AppLoading` 단순형, "내 위치를 확인하고 있어요" 설명형은 위치 조회에 한해 사용) / 데이터 있음 / 위치 권한 거부.
- **오류**: "주변 시설 정보를 불러오지 못했어요. 잠시 후 다시 시도해주세요." + 재시도(`AppError`).
- **Empty State**: 검색 결과 없음 → `AppEmptyState`("이 지역에는 등록된 시설이 없어요" + 주소 다시 검색 Action).
- **Easy Mode 차이**: 리스트 항목 카드 크기 확대, 전화 걸기 아이콘을 텍스트 라벨과 함께.
- **필요 컴포넌트**: `AppScaffold`, `AppCard`, `AppEmptyState`, `AppError`, `AppLoading`.

### 시설 상세
- **목적**: 특정 경로당/복지센터의 신청방법·연락처 안내.
- **주요 정보**: 설명, 신청방법, 외부링크, 전화번호.
- **Primary CTA**: 전화 걸기.
- **Secondary CTA**: 외부 링크 열기.
- **상태/오류/Empty**: 해당 없음(정적 상세).
- **Easy Mode 차이**: 전화 버튼을 화면 하단 고정 큰 버튼으로.
- **필요 컴포넌트**: `AppScaffold`, `AppHeader`, `AppInfoRow`.

### document_scan — 촬영
- **목적**: 문서/문자 사진을 촬영해 분석을 시작.
- **주요 정보**: 실시간 프레임 가이드, 플래시 상태(항상 텍스트/아이콘 라벨 병행).
- **Primary CTA**: 촬영(수동) — 안정 시 자동 촬영도 병행 지원.
- **Secondary CTA**: 플래시 전환(OFF/ON/자동), 갤러리에서 불러오기.
- **상태**: 카메라 권한 대기/거부, 촬영 준비 완료, 촬영 직후(확인 화면으로 전환).
- **오류**: 카메라 권한 거부 시 설정 이동 안내(`AppError` variant).
- **Empty State**: 해당 없음.
- **Easy Mode 차이**: 플래시 컨트롤을 작은 아이콘 토글이 아니라 큰 버튼(선택 상태가 배경/테두리로 뚜렷이 구분)으로. 촬영 버튼 크기 확대.
- **필요 컴포넌트**: `AppIconButton`(플래시), feature-local 카메라 프리뷰 위젯(design_system 대상 아님 — 카메라 SDK 의존).

### document_scan — 분석 중 / 결과
- **목적**: 촬영/업로드한 문서의 분석 결과 확인.
- **주요 정보**: 신뢰도(최상단) → 요약 → 구조화 필드(금액/기한/항목) → 원본 이미지(임시 열람).
- **Primary CTA**: "보호자에게 알리기"(위험 감지 시 노출, 옵트인) 또는 "기록에 저장"(위험 없을 시 기본 동작).
- **Secondary CTA**: 다시 촬영, 원본 다시 보기.
- **상태**: 분석 중(`AppLoading` 설명형 — "문서 내용을 확인하고 있어요"), 완료, 신뢰도 낮음(재확인 유도 문구 추가).
- **오류**: 분석 실패 시 "다시 시도" + 원본은 정책대로 즉시 삭제되었음을 안내.
- **Empty State**: 해당 없음.
- **Easy Mode 차이**: 구조화 필드를 카드 대신 큰 텍스트 블록으로 단순화, "보호자에게 알리기" 버튼을 확인 다이얼로그(`AppConfirmDialog`)와 함께 큰 버튼으로.
- **필요 컴포넌트**: `AppConfidenceIndicator`, `AppRiskBadge`(위험 감지 시), `AppInfoRow`(구조화 필드), `AppConfirmDialog`, `AppLoading`(설명형).

### message_check — 진입 / 목록 / 확인(Android) · 붙여넣기(iOS) (v11: 구현 완료, 범위 재조정)
- **목적**: 어르신이 받은 문자를 확인하고 위험 여부 분석을 요청한다. 진입점 하나(`MessageCheckEntryPage`)가 SMS 권한 상태만으로 Android/iOS 두 Flow를 분기한다.
- **주요 정보(Android, 권한 허용)**: 최근 SMS 목록(발신자+본문 미리보기) → 탭하면 원문 전체를 보여주는 확인 화면 → "분석하기".
- **주요 정보(iOS, 또는 자동 조회 미지원 플랫폼)**: 클립보드 붙여넣기 버튼 + 직접 입력 텍스트 필드 → "분석하기"(내용이 비어있으면 비활성화).
- **Primary CTA**: (Android) 목록에서 문자 선택 → 확인 화면의 "분석하기". (iOS) "분석하기".
- **Secondary CTA**: (iOS) "클립보드에서 붙여넣기".
- **상태**: 권한 확인 중(`AppLoading`) → 허용/거부/영구거부/미지원(iOS) 4분기, 목록 로딩 중/빈 목록.
- **오류**: SMS 권한 거부 시 "문자 권한 허용하기" 버튼(재요청), 영구거부 시 "설정 열기"(재요청 대신 시스템 설정 이동) — `document_scan`의 카메라 권한 화면과 동일한 3단계 패턴. 목록을 불러오지 못하면 `AppError`+재시도.
- **Empty State**: 최근 받은 문자가 없으면 "최근 받은 문자가 없어요."(가짜 문자로 채우지 않음).
- **Easy Mode 차이**: 권한 요청/분석 버튼을 `AppButtonSize.large`로.
- **필요 컴포넌트**: `AppCard`(문자 목록 타일), `AppInfoRow`, `AppButton`, `AppTextField` 대신 멀티라인 `TextField`(직접 입력 — 여러 줄 본문 입력이 필요해 `AppTextField`의 1줄 전용 구조로는 부족, feature-local로 유지).
- **구현과 계획의 차이**: "확인할 일 체크리스트"는 위험도 분석 자체가 아직 없어(백엔드 부재) 만들 근거 데이터가 없다 — 구현하지 않음. "보호자에게 알리기"는 `notification` feature(Phase 8)가 없어 이번 범위에서 제외. iOS 오류 문구 "이 기능은 안드로이드에서만 이용할 수 있어요"는 채택하지 않았다 — 대신 붙여넣기/직접 입력 Flow로 곧장 안내해 iOS 사용자도 실제로 기능을 쓸 수 있게 했다(단순 "미지원" 안내보다 실질적).

### message_check — 분석 결과
- **목적**: `document_scan`과 동일한 `AnalysisResultView`(이번에 `core/widgets/`로 승격)를 재사용해 위험도 분석 결과를 보여준다.
- **주요 정보**: 신뢰도(최상단), 위험 배지(있을 때만), 요약, 구조화 필드(있을 때만).
- **상태**: 분석 중(`AppLoading` — "문자 내용을 확인하고 있어요"), 완료.
- **오류**: 실제 분석 백엔드가 없어 지금은 항상 "분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요."(`AppEmptyState`, 재시도 버튼 없음 — 일반 오류와 구분, `document_scan`과 동일 원칙)로 귀결. 실제 서버 오류(있다면)는 `AppError`+재시도로 별도 구분.
- **Empty State**: 해당 없음.
- **Easy Mode 차이**: 없음(내용 표시 화면이라 버튼 크기 차이가 크지 않음 — `document_scan` 결과 화면과 동일 판단).
- **필요 컴포넌트**: `AppConfidenceIndicator`, `AppRiskBadge`, `AppInfoRow`, `AppLoading`, `AppEmptyState`.

### voice_assistant (Phase 10+ 예정 — 구조만 명시)
- **목적**: 음성으로 기존 기능(문서/문자/경로당/일정)을 이용.
- **주요 정보**: 듣는 중 상태, 처리 중 상태, 답변 텍스트.
- **Primary CTA**: 마이크 버튼(누르고 말하기 또는 상시 듣기 — STT 방식은 미확정).
- **Secondary CTA**: 다시 듣기(TTS 재생).
- **상태**: 대기/듣는 중(파형+텍스트)/처리 중(`AppLoading` 설명형)/답변 완료/인식 실패("다시 한번 말씀해주세요" — 에러로 취급하지 않음).
- **오류**: 무음/인식 실패는 부드러운 재시도 유도로 처리, 진짜 오류(네트워크 등)만 `AppError`.
- **Empty State**: 해당 없음.
- **Easy Mode 차이**: 이 화면 자체가 Easy Mode 홈의 핵심 진입점 중 하나 — 별도 축소 버전 없음.
- **필요 컴포넌트**: 마이크 버튼(현재는 보류 컴포넌트 `AppVoiceButton` — `ui-component-spec.md` §3 참고, Phase 10 착수 시 재검토), `AppLoading`(설명형).

### emergency_help — 모달
- **목적**: 긴급 상황에서 즉시 도움 요청.
- **주요 정보**: 보호자 전화, 119/112/118 연결.
- **Primary CTA**: 각 연락처 전화 걸기(즉시 실행 — 확인 다이얼로그 없음, 긴급성이 확인 절차보다 우선).
- **Secondary CTA**: "사용법 다시보기".
- **상태/오류/Empty**: 해당 없음(정적 모달).
- **Easy Mode 차이**: 이미 확정된 원형 플로팅 버튼 + 위험 색상 유지, 변경 없음.
- **필요 컴포넌트**: `AppIconButton`, feature-local 모달.

### 기록 — 분석 기록 / 일정
- **목적**: 과거 분석 결과와 일정을 확인.
- **주요 정보**: 리스트(위험/문서/문자 필터), 일정 리스트.
- **Primary CTA**: 항목 탭 → 상세.
- **Secondary CTA**: 필터 전환.
- **상태**: 데이터 있음/로딩/에러.
- **오류**: `AppError` + 재시도.
- **Empty State**: "아직 분석한 기록이 없습니다. 문서 찍기나 문자 보기를 이용해보세요."(기존 문구 유지).
- **Easy Mode 차이**: 필터를 드롭다운 대신 큰 탭 버튼으로.
- **필요 컴포넌트**: `AppCard`, `AppRiskBadge`(필터 배지), `AppEmptyState`.

### 더보기 — 연결된 보호자 목록
- **목적**: 등록된 보호자 확인 및 해제.
- **주요 정보**: 보호자 이름/연결 상태 리스트.
- **Primary CTA**: 개별 "연결 해제".
- **Secondary CTA**: "보호자 연결하기"(QR 표시 화면으로 이동, v9: 연결 요청 자체는 보호자의 스캔으로 생성되지만 어르신이 먼저 QR을 보여줘야 흐름이 시작된다).
- **상태**: 데이터 있음/로딩.
- **오류**: `AppError`.
- **Empty State**: "아직 연결된 보호자가 없습니다 → 보호자 연결하기"(QR 화면으로 연결).
- **Easy Mode 차이**: 해제 버튼에 반드시 `AppConfirmDialog`(되돌리기 어려운 행동).
- **필요 컴포넌트**: `AppCard`, `AppConfirmDialog`, `AppEmptyState`.

### 더보기 — 보호자 연결 QR (v9 신규)
- **목적**: 어르신이 보호자에게 보여줄 QR 코드를 표시해 연결 요청을 시작하게 한다.
- **주요 정보**: QR 코드 이미지(서버 발급 단기 유효 토큰), "보호자에게 이 QR을 보여주세요" 안내 문구, 남은 유효 시간(선택).
- **Primary CTA**: 없음(QR을 보여주는 것 자체가 행동, 쉬운 모드에서도 동일 흐름).
- **Secondary CTA**: QR 재발급(토큰 만료 시).
- **상태**: 토큰 발급 중, 표시 중, 만료됨(재발급 유도).
- **오류**: 발급 실패 시 `AppError` + 재시도.
- **Empty State**: 해당 없음.
- **Easy Mode 차이**: QR을 화면 중앙에 크게, 문구는 행동 중심으로 단순하게.
- **필요 컴포넌트**: QR 렌더링 위젯(신규, Phase 5에서 패키지 결정), `AppLoading`, `AppError`.

### 설정 — 개인정보 공개 범위 안내 (신규)
- **목적**: "보호자에게 무엇이 보이고 안 보이는지"를 명시적으로 안내(`ui-research.md` Guardian 6 근거로 신규 확정).
- **주요 정보**: 보호자에게 전달되는 정보 화이트리스트를 평이한 문장으로("문자 원문이 아니라 요약만 전달돼요" 등).
- **Primary CTA**: 없음(정적 안내).
- **Secondary CTA**: 고객 지원의 "개인정보는 어떻게 보관되나요?"로 이동.
- **상태/오류/Empty**: 해당 없음.
- **Easy Mode 차이**: 문장을 더 짧게, 목록 대신 핵심 1~2문장만.
- **필요 컴포넌트**: `AppScaffold`, `AppInfoRow`.

---

## Guardian App

### 홈 (v10: 구현 완료)
- **목적**: "지금 우리 어르신 괜찮으신가"에 최상단에서 즉시 답한다.
- **주요 정보**: 어르신 선택(`AppElderSwitcher`), 오늘의 안심 상태 배너(`analysis_results.risk_level` 중 최고 심각도 — `RiskSummary.worst()`), 최근 활동 최대 3개, 다가오는 일정 요약.
- **Primary CTA**: 안심 상태 배너 탭 → 관련 알림/기록으로.
- **Secondary CTA**: 어르신에게 전화, "최근 활동 전체보기" → 기록 탭.
- **상태**: 데이터 있음/로딩/연결된 어르신 없음.
- **오류**: `AppError` + 재시도.
- **Empty State**: 연결된 어르신 없음 → `AppEmptyState`("아직 연결된 어르신이 없습니다" + "어르신 연결하기" Action, Phase 5 QR 스캔 화면으로 연결) — 기존 확정 사항 유지, Mock 프리뷰 사용 안 함. `analysis_results`가 항상 빈 테이블이라 최근 활동/일정은 연결된 어르신이 있어도 실제로 늘 Empty.
- **Easy Mode 차이**: 없음(Guardian 앱은 Easy Mode 대상 아님).
- **필요 컴포넌트**: `AppElderSwitcher`, `AppStatusCard`/`AppAlertCard`(안심 상태 — 위험 있으면 `AppAlertCard`, 없으면 `AppStatusCard`), `AppCard`(최근 활동), `AppEmptyState`.
- **구현과 계획의 차이**: "일정 완료·잔여"는 `schedule` domain이 아직 없어(Phase 6 범위 밖, 지시 11) 항상 Empty State만 표시.

### 알림 (notification) — 리스트 / 상세 (v10: 구현 완료, 범위 축소)
- **목적**: 위험/일반 알림 확인, 원문이 아닌 구조화된 요약 열람.
- **주요 정보(리스트)**: 위험도 배지, 요약, 날짜(`riskLevel`이 caution/dangerous인 `analysis_results`만).
- **주요 정보(상세)**: 신뢰도 문장(`AppConfidenceIndicator`), 위험 배지, 요약, 원문(`source_excerpt` — RLS로 accepted guardian까지는 허용, `technical-decisions.md` §2 item 6), 구조화 필드.
- **Primary CTA**: 리스트 항목 탭 → 상세.
- **상태**: 데이터 있음/로딩/연결된 어르신 없음.
- **오류**: `AppError`.
- **Empty State**: "아직 받은 알림이 없습니다."
- **Easy Mode 차이**: 해당 없음.
- **필요 컴포넌트**: `AppRiskBadge`, `AppCard`, `AppInfoRow`(구조화 필드), `AppEmptyState`.
- **구현과 계획의 차이**: "안읽음 배지"/읽음-안읽음 상태와 "확인할 일" 체크리스트는 `AnalysisResult` 모델에 그런 필드가 없어 구현하지 않음(feature-spec.md v10 참고). "기록에서 보기" 상호 이동 버튼은 두 탭이 이미 같은 상세 화면(`AnalysisRecordDetailPage`)을 공유해 별도 버튼 없이도 동일 경험 — 목록 상단 `AppElderSwitcher`는 홈 탭에서 이미 전역으로 선택되므로(공유 `selectedElderIdProvider`) 이 탭에서 중복 노출하지 않음.

### 기록 (analysis) (v10: 구현 완료, 범위 축소 — schedule 제외)
- **목적**: 어르신의 전체 분석 이력 열람(리스트→상세).
- **주요 정보**: `analysis_results` 전체 리스트(문서+문자, 최신순).
- **Primary CTA**: 항목 탭 → 상세(알림 상세와 동일 `AnalysisRecordDetailPage` 재사용).
- **상태/오류**: 알림 리스트와 동일 패턴.
- **Empty State**: "아직 분석 기록이 없습니다."
- **필요 컴포넌트**: `AppCard`, `AppRiskBadge`, `AppEmptyState`.
- **구현과 계획의 차이**: "필터(전체/위험/문서/문자)"는 이번에 구현하지 않음(항상 전체 표시) — 실제 데이터가 없는 현재로선 필터의 실익이 낮아 후순위로 미룸. `schedule`은 별도 domain(Phase 6 범위 밖)이라 이 화면에 합치지 않음(Phase 6 지시 11).

### 통계 (v10: 구현 완료, 범위 축소 — OPEN QUESTIONS #12 미해소)
- **목적**: 이번 달 활동을 간단히 요약(다중 차트 지양).
- **주요 정보**: 이번 달 분석 수(추세 문장 포함)/위험 문자 수(`AppStatCard` 2개 — 스키마 무관 집계만), 고지서 구조화 필드 원본 나열(기록별, 집계 아님).
- **Primary CTA**: 없음(열람 전용).
- **상태**: 데이터 있음/로딩/연결된 어르신 없음.
- **오류**: `AppError`.
- **Empty State**: "아직 통계로 보여드릴 데이터가 없습니다." / 고지서 섹션은 "아직 고지서 정보가 없습니다."
- **Easy Mode 차이**: 해당 없음.
- **필요 컴포넌트**: `AppStatCard`, `AppCard`+`AppInfoRow`(고지서 원본 나열), `AppEmptyState`. 차트 영역은 여전히 만들지 않음(**Decision 3 유지 — OPEN QUESTIONS #12가 미해소라 차트 라이브러리를 여전히 선택하지 않는다**).
- **구현과 계획의 차이**: "일정 완료·잔여" 통계, "고지서 금액 추세 선그래프", "기간 필터"는 전부 미구현 — 각각 `schedule` domain 부재, 고지서 통계 항목 미확정(OPEN QUESTIONS #12), 차트 라이브러리 미선택이 이유. 이번 Phase가 "아직 결정되지 않았다면" 분기(Phase 6 지시 9)를 그대로 따른 결과다.

### 더보기 — 어르신 연결 관리 (v9: QR 스캔 기반으로 갱신)
- **목적**: 신규 연결 요청 생성, 기존 연결 해제, 다중 어르신 관리.
- **주요 정보**: 연결된 어르신 리스트(1:N), 연결 요청 상태(pending/accepted/rejected).
- **Primary CTA**: "어르신 연결하기" → QR 코드 스캔 화면 진입(카메라 프리뷰 + 스캔 가이드).
- **Secondary CTA**: 개별 연결 해제.
- **상태**: 카메라 권한 확인 중/거부, QR 스캔 중, 요청 생성 중, pending 대기 중, 연결됨.
- **오류**: 만료/이미 사용된 QR, 카메라 권한 거부(설정 이동 안내), 이미 연결된 상태 등을 명확히 안내.
- **Empty State**: `AppEmptyState`(홈과 동일 문구 재사용).
- **Easy Mode 차이**: 해당 없음.
- **필요 컴포넌트**: `AppCard`, `AppConfirmDialog`(연결 해제), `AppEmptyState`, QR 스캔 프리뷰 위젯(신규, `document_scan`의 카메라 프리뷰와 별개 — Phase 5에서 패키지 결정).

---

## 공통 메모

- 위 화면 스펙은 **레이아웃/정보 구조/상태 처리 방향**만 정의한다. 정확한 색상/spacing/폰트 크기는 `ui-component-spec.md`의 토큰 규칙을 따르되 구체 값은 Figma 확정 후 채운다.
- "필요 컴포넌트"에 나열되지 않은 화면 전용 UI(카메라 프리뷰, 차트 등)는 feature-local 위젯으로 구현하고 `packages/design_system`에 넣지 않는다(2개 이상 feature/화면에서 재사용이 확인될 때만 승격).
