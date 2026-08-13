# UI Component Spec

> `packages/design_system`를 ONDAM UI의 기반으로 유지한다. 기존 컴포넌트를 먼저 검토하고, 실제 화면(`ui-information-architecture.md`)에서 반복 사용이 확인된 경우에만 신규 컴포넌트를 제안한다. **아직 실제 코드로 구현하지 않는다** — 이 문서는 Phase 3+ 구현 시 따를 스펙이다. Figma 작업 이후 값(색상 hex, 정확한 spacing 등)이 바뀔 수 있으므로, 여기서는 토큰 이름과 규칙만 정의하고 구체적 시각값은 고정하지 않는다.

---

## 1. 기존 컴포넌트 검토

| 컴포넌트 | 현재 상태 | 검토 결과 |
|---|---|---|
| `AppColors`/`AppTextStyles`/`AppSpacing`/`AppRadius` | 구현됨(placeholder 값) | 유지. 실제 값은 Figma 확정 후 갱신(9번 "Figma에서 수정하기 쉬운 부분" 참고) |
| `AppTheme` | 구현됨(light/dark) | 유지. 새 컴포넌트 추가 시 이 테마의 토큰만 참조하도록 함 |
| `AppButton` | 구현됨(단일 크기) | **변경 필요** — 아래 "AppButton 확장" 참고 |
| `AppCard` | 구현됨(범용 컨테이너) | 유지. 아이콘+텍스트+우측 액션 레이아웃은 신규 컴포넌트 없이 `AppCard`의 `child` 슬롯 구성 규칙으로 안내(아래 "AppCard 사용 규칙") |
| `AppEmptyState` | 구현됨 | 유지, 변경 없음 |
| `AppError` | 구현됨 | 유지, 변경 없음 |
| `AppLoading` | 구현됨(단순/설명형 2 variant) | 유지, 변경 없음 |
| `AppTextField` | 구현됨 | 유지, 변경 없음 |

### AppButton 확장 (신규 컴포넌트 대신 기존 컴포넌트 확장)

Easy Mode는 일반 모드보다 큰 버튼이 필요하지만(`ui-principles.md` "큰 터치 영역"), 이를 위해 `AppPrimaryAction` 같은 별도 컴포넌트를 새로 만들지 않는다 — `AppButton`에 크기 파라미터를 추가하는 것으로 충분하다.

```
AppButton({
  required label,
  required onPressed,
  isLoading = false,
  size = AppButtonSize.standard,  // 신규: standard | large
})
```

- `standard`: 최소 높이 48dp(일반 모드 기본값).
- `large`: 최소 높이 56~64dp(Easy Mode 기본값, 긴급 상황성 CTA에도 사용 가능).
- 폰트 크기는 `size`에 따라 `AppTextStyles.bodyLarge`/확대된 스타일을 내부에서 선택 — 화면에서 직접 폰트 크기를 지정하지 않는다.

### AppCard 사용 규칙 (신규 컴포넌트 없이 합성 규칙으로 표준화)

리스트형 카드(아이콘+텍스트+우측 화살표/액션) 패턴은 `ui-spec.md`에서 이미 확인된 반복 레이아웃이다. 새 위젯을 만들지 않고, `AppCard`의 `child`를 항상 아래 구조로 합성하도록 규칙화한다:

```
AppCard(
  child: Row(
    children: [
      <원형 컬러 배경 아이콘>,   // AppSpacing.md 간격
      Expanded(<제목 + 보조텍스트>),
      <우측 화살표 또는 아이콘 버튼(AppIconButton)>,
    ],
  ),
)
```

---

## 2. 신규 컴포넌트 (반복 사용이 확인된 것만)

각 컴포넌트마다 근거 화면(≥2곳 반복 확인)을 명시한다. 근거가 1곳뿐인 후보는 "보류" 절에 남긴다.

### AppScaffold
- **근거**: 모든 화면이 동일한 `Scaffold + SafeArea + 화면 좌우 패딩(AppSpacing.lg)` 구조를 반복(Auth 화면 7개에서 이미 확인됨 + Phase 3+ 전 화면 예정).
- **역할**: 배경색/SafeArea/기본 패딩을 한 곳에서 관리해 화면마다 `EdgeInsets.all(AppSpacing.lg)`를 반복 하드코딩하지 않게 한다.
- **상태**: 없음(순수 레이아웃 컨테이너).
- **API 방향**: `AppScaffold({title?, body, floatingAction?, bottomBar?})` — `title`이 있으면 내부에서 `AppHeader` 사용.

### AppHeader
- **근거**: "← 홈으로" 텍스트+화살표 뒤로가기 패턴이 Senior/Guardian 상세 화면 전반에서 반복(기존 `ui-spec.md` 확인 사항, `ui-information-architecture.md`의 모든 상세 화면에 적용됨).
- **역할**: 제목 + 뒤로가기(텍스트+화살표, 아이콘 단독 금지) + 선택적 우측 액션.
- **Accessibility**: 뒤로가기는 최소 44x44 터치 영역, `Semantics(label: '뒤로가기')`.

### AppBottomNavigation
- **근거**: Senior(정보/홈/기록/더보기)와 Guardian(홈/알림/기록/통계/더보기) 양쪽 모두 하단 고정 탭바를 사용하지만 탭 구성이 다르다 — 공통 셸(활성/비활성 스타일, 배지 카운트, 최소 터치 영역)만 공유하고 탭 항목은 앱별로 주입.
- **역할**: 활성 탭 강조(Primary 색상), 배지 카운트(안읽음 등), 아이콘+라벨 조합.
- **상태**: 활성/비활성/배지 있음.
- **API 방향**: `AppBottomNavigation({items: List<AppBottomNavItem>, currentIndex, onTap})`.

### AppIconButton
- **근거**: `AppHeader`의 뒤로가기, `AppCard`의 우측 액션(전화 아이콘 등), 촬영 화면 컨트롤 등에서 반복.
- **역할**: 아이콘 전용 버튼이지만 **항상 `Semantics`/`tooltip`을 강제**하는 래퍼(아이콘만으로 의미가 전달되지 않는다는 접근성 원칙을 컴포넌트 레벨에서 강제).
- **API 방향**: `AppIconButton({required icon, required semanticLabel, onPressed})` — `semanticLabel`을 필수 파라미터로 두어 실수로 누락하지 못하게 한다.

### AppStatusCard
- **근거**: Senior 홈의 "오늘 해야 할 일" 요약, Guardian 홈의 "오늘의 안심 상태" 배너 — 두 앱 홈 화면 최상단에 반복되는 "현재 상태를 한 문장/카드로 요약" 패턴(`ui-principles.md` Guardian 1, `ui-research.md` Guardian 종합 1).
- **역할**: 큰 상태 문구 + 보조 텍스트 + (선택) 상태 아이콘. 위험 색상(`AppRiskBadge`와 동일 색상 계열)을 상태에 따라 반영 가능.
- **상태**: 정상/주의/위험(Guardian), 완료/대기(Senior 일정 요약).

### AppElderSwitcher (신규, Decision 2 반영)
- **근거**: Guardian 앱의 홈/알림/기록/통계 4개 탭 전체에서 "현재 선택된 어르신"을 동일하게 표시·전환해야 한다(`ui-information-architecture.md` "Guardian 1:N 어르신 선택 구조").
- **역할**: 어르신이 1명이면 이름만 조용히 표시(선택 UI 최소화), 2명 이상이면 Dropdown 또는 Bottom Sheet로 전환 UI 제공. 선택 상태는 탭 이동 간 유지된다(상위 상태 관리, 컴포넌트 자체는 표시/전환 UI만 책임).
- **상태**: 1명(정적 표시) / 2명 이상(전환 가능) / 로딩(연결된 어르신 목록 조회 중).
- **API 방향**: `AppElderSwitcher({elders: List<ElderSummary>, selectedElderId, onSelect})` — `ElderSummary`는 이름 정도의 최소 정보만(개인정보 최소 노출 원칙).

### AppAlertCard
- **근거**: Senior 문자 분석 결과의 위험 표시, Guardian 알림 상세, Guardian 고지서 급증 강조 카드 — 3곳 이상 반복(`ui-spec.md` 기존 "위험/경고 정보 표시" 원칙, `ui-principles.md` Senior 6).
- **역할**: 색상+아이콘+텍스트 배지 3중 표현을 하나의 컴포넌트로 강제 — 화면마다 개별 구현 시 3중 표현 중 하나를 빠뜨릴 위험을 방지.
- **상태**: 위험/주의/정보(위험도에 대응, `AppRiskBadge`와 색상 계열 공유하되 카드 형태).

### AppSectionHeader
- **근거**: 정보/기록/더보기/통계 등 리스트형 화면 대부분에서 섹션 구분 제목이 반복.
- **역할**: 섹션 제목 타이포/spacing 일관성(화면마다 `Text(style: ...)` + `SizedBox` 하드코딩 방지).

### AppInfoRow
- **근거**: 프로필 정보 표시, 고지서 항목(금액/기한), "확인할 일" 체크리스트 — key-value 또는 체크 항목 반복 레이아웃.
- **역할**: 좌측 라벨 + 우측 값(또는 체크박스) 한 줄 레이아웃 표준화.

### AppConfirmDialog
- **근거**: 계정 탈퇴, 보호자 연결 해제, 음성 비서를 통한 보호자 알림 발송 등 "되돌리기 어려운 행동에만 확인"(`ui-principles.md` Error/Loading/Empty UX 원칙 - Confirmation) 원칙을 컴포넌트 레벨에서 일관되게 강제.
- **역할**: 제목 + 설명 + 확인/취소 버튼(파괴적 행동은 확인 버튼에 위험 색상 적용).

### AppConfidenceIndicator
- **근거**: `document_scan`/`message_check` 분석 결과 화면 양쪽에서 반복(`ui-spec.md` "답변 신뢰도 표시" 기존 결정, 도메인 모델 `ReliabilityLevel` 이미 존재).
- **역할**: 숫자/퍼센트 없이 문장형(예: "이 답변은 비교적 확실해요") + 보조 색상 + 아이콘. 결과 화면 **최상단**(원문/요약보다 먼저)에 배치하는 것을 컴포넌트 사용 규칙으로 강제.
- **주의**: 위험도(`AppRiskBadge`)와 **색상 토큰 계열을 반드시 분리**(`ui-research.md` 9 — 신뢰도 낮음에 위험 색상인 빨강을 쓰지 않는다).

### AppRiskBadge
- **근거**: `message_check` 결과, Guardian 알림 리스트/상세, Guardian 홈 안심 배너, 기록 필터 배지 — 가장 반복 빈도가 높은 후보.
- **역할**: 위험도(예: 위험/주의/정상 3단계 — 표시는 3단계, 실제 푸시 발송 정책은 2단계로 단순화하는 것과는 별개, `ui-principles.md` Guardian 6)를 색상+아이콘+텍스트로 표현.

### AppStatCard
- **근거**: Guardian 통계 화면의 "이번 달 분석 수 / 위험 문자 수 / 일정 완료·잔여" 카드들 — 한 화면 안에서도 반복.
- **역할**: 숫자 + 라벨 + (선택) 증감 추세 표시(추세 우선 원칙, `ui-research.md` Guardian 5).
- **확정(Decision 3)**: 차트 라이브러리는 지금 선택하지 않는다. Phase 6에서 실제 `structuredFields` 데이터/통계 요구사항이 확정된 뒤 결정한다. 지금 단계에서는 `AppStatCard`(숫자+라벨) + 추세 문장(텍스트) + **차트를 나중에 끼워 넣을 수 있는 빈 영역을 가진 컨테이너 구조**만 고려하고, 특정 chart 패키지를 `pubspec.yaml`에 추가하지 않는다.

---

## 3. 보류(신규 컴포넌트로 추가하지 않음)

| 후보 | 보류 사유 |
|---|---|
| `AppPrimaryAction` | `AppButton`에 `size` 파라미터를 추가하는 것으로 충분 — 별도 컴포넌트를 만들면 두 개의 유사 버튼 컴포넌트가 공존하게 되어 오히려 일관성을 해친다. |
| `AppNumberPad` | PIN 입력용 키패드는 이미 각 앱의 `features/auth/presentation/widgets/pin_keypad.dart`에 feature-local로 구현되어 있다(Senior/Guardian 크기가 의도적으로 다름). 현재 PIN 외에 숫자 입력이 반복되는 화면이 없어 `design_system`으로 승격할 근거가 없다 — 두 번째 사용처가 생기면 재검토. |
| `AppVoiceButton` | 음성 비서는 Phase 10+ 예정이며 현재 화면 스펙상 사용처가 홈 진입 버튼 1곳뿐이다("듣는 중" 상태는 같은 버튼의 상태 변화이지 별도 컴포넌트 근거가 아님). Phase 10 착수 시점에 실제 화면이 확정되면 재검토. |

---

## 4. 공통 규칙 (모든 신규/기존 컴포넌트 공통)

- **State**: 컴포넌트가 비동기 데이터를 다루면 loading/error/empty 상태를 `AppLoading`/`AppError`/`AppEmptyState`로 위임하고, 컴포넌트 자체는 data 상태의 렌더링만 책임진다(riverpod.md AsyncValue 원칙과 일치).
- **Size**: 모든 터치 가능 요소는 `ui-principles.md` "큰 터치 영역" 표(일반 48dp / Easy Mode 56~76dp)를 따른다.
- **Spacing/Typography**: `AppSpacing`/`AppTextStyles` 토큰만 사용, 컴포넌트 내부든 사용처든 하드코딩 금지.
- **Accessibility**: 아이콘 단독 사용 금지(텍스트/배지 병행), 색상 단독 의존 금지, `Semantics` 필수.
- **사용 규칙**: 신규 컴포넌트는 반드시 `packages/design_system`에 위치하고, 두 앱이 실제로 동시에 참조해야 한다(둘 중 한 앱만 쓰는 위젯은 feature-local로 유지 — `AppNumberPad` 보류 사유와 동일 기준).
