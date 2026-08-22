# UI 전체 리디자인 — 디자인 토큰 리서치 계획

> 상태: 계획 합의 완료, 리서치 미실행. 다음 세션에서 "실행" 단계부터 이어간다.

## 최종 목표

ONDAM(Senior + Guardian) 앱의 **전체 화면 UI 리디자인**. 이 문서가 다루는 "디자인 토큰 재검토"는 그 첫 단계(디자인 언어/토큰 확립)이며, 전체 리디자인의 전부가 아니다. 토큰 확정 후 화면별로 `ui-redesign` skill을 따라 순차 적용한다.

## 현재 상태 (2026-08-21 확인)

- `packages/design_system`의 색상/타이포 토큰은 **기존 온담 구버전 실측값** 기반 placeholder (`docs/ui/ui-spec.md` "토큰 매핑" 절).
- `docs/ui/ui-principles.md`에 UX 원칙은 이미 상세히 문서화되어 있음(고령층 접근성, Easy Mode, Guardian 대시보드 원칙 등) — 이번 작업은 원칙이 아니라 **시각 토큰(색상/타이포/spacing/radius) 값**을 외부 레퍼런스 기반으로 재검토하는 것.
- Phase 10~11까지 다수 화면이 이미 이 placeholder 토큰으로 구현됨 — 토큰 변경 시 기존 화면 시각적 재작업이 뒤따름(예상된 트레이드오프, 사용자 승인됨).

## 합의된 리서치 실행 계획

리서치는 컨텍스트 오염을 막기 위해 3개 fork(서브에이전트)로 나눠 위임 → 결과만 메인 세션에서 종합.

| Fork | 사이트 | 목적 |
|---|---|---|
| Fork 1 (Flow) | Mobbin, WWIT, Page Flows | Login/Onboarding/Home/Dashboard 흐름, 한국형 UI 패턴 |
| Fork 2 (Visual) | Behance, Dribbble, Awwwards | Healthcare/Senior/Finance 앱 컬러시스템·타이포·카드 디자인 |
| Fork 3 (Principle) | Apple HIG, Material 3, KRDS, WCAG | 접근성/플랫폼 원칙, 색상 대비비 기준 |

조사 범위(화면 카테고리)는 토큰 결정에 실질적으로 영향을 주는 것만: **Login/Onboarding, Home/Dashboard, Card/Button/Form, Statistics/Charts(Guardian), Accessibility 원칙**. Camera/Search/Settings 등 흐름 중심 화면은 이번엔 제외 — 필요 시 이후 화면별 `ui-redesign` 작업에서 개별 조사.

각 fork는 브라우저 자동화(mcp__claude-in-chrome)로 실제 사이트를 방문해 패턴을 추출하고, 스크린샷 원본이 아니라 **요약된 패턴 + 근거**만 보고한다.

## 산출물

세 fork 결과를 종합해 `docs/ui/design-token-refresh.md`에 작성:
- 리서치 근거 (사이트별 패턴 → ONDAM 적용 판단)
- 새 토큰 제안: 색상(`AppColors`) / 타이포(`AppTextStyles`) / spacing(`AppSpacing`) / radius(`AppRadius`), 각각 변경 근거 포함
- 기존 placeholder 값과의 diff

작성 후 **사용자 검토 필수** (미승인 토큰은 코드에 반영하지 않음).

## 다음 단계

1. (다음 세션) 3개 fork 실행
2. 결과 종합 → `docs/ui/design-token-refresh.md` 작성
3. 사용자 승인
4. 별도 `ui/<name>` 브랜치에서 `packages/design_system` 토큰 코드 반영
5. 토큰 확정 후, 화면별 우선순위(예: Home → Dashboard → Statistics) 로드맵 수립해 `ui-redesign` skill로 순차 진행
