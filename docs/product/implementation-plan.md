# Implementation Plan — 온담 Flutter 구현 계획

> `feature-development` skill로 실제 기능 구현을 시작하기 **전** 단계 산출물이다. 이 문서 자체는 코드를 만들지 않는다.
>
> **개정 이력**
> - v1(초안): Architecture 미확정 상태를 전제로 한 계획.
> - v2: `docs/architecture/technical-decisions.md` v2에서 확정된 Backend(Supabase)/인증(OTP+PIN)/알림(Push+서버)/연결(어르신 수락)/위험판단(서버 AI)/저장(즉시삭제)/SMS(Android 격리)/Push(FCM)/Storage(Secure+Local 분리) 결정을 반영해 갱신.
> - v3: 신규 요구사항(음성 비서/쉬운 모드 Main 강화/카메라 플래시/답변 신뢰도/보호자 고지서 통계 동기화/관리자 시스템 PROPOSED)을 Feature 구조와 Phase 계획에 반영.
> - **v4(이 버전)**: Phase 1 실행 결과 반영. "하나의 앱, role 분기" 대신 **`apps/senior` + `apps/guardian` 별도 2개 Flutter 앱 + `packages/*` Monorepo**로 확정되어 Feature 구조를 두 앱으로 분리했다. Phase 1에서 실제로 스캐폴딩·구현된 부분은 아래에 "(Phase 1 완료)"로 표시했다.
>
> 기반 문서: `docs/product/current-app-analysis.md`, `docs/product/feature-spec.md`, `docs/product/user-flow.md`, `docs/architecture/architecture.md`, `docs/ui/ui-spec.md`, `docs/architecture/technical-decisions.md`

---

## 1. Flutter Feature 구조 최종 제안 (v4 — 2개 앱 + 공통 패키지)

```
apps/senior/lib/features/
├── auth/                 # 전화번호+OTP(가입)+PIN(로그인), 소셜 로그인
├── onboarding/            # 접근성 설정 → 프로필 입력 → 보호자 등록 요청(최초 1회 흐름)
├── profile/               # 내 정보 조회/수정
├── home/                  # 어르신 홈(쉬운 모드가 Main UX, 일반 모드 병행), 오늘 할 일 요약
├── document_scan/         # 문서 촬영(플래시 제어 포함) → AI 분석 → 결과 표시 (원본 즉시삭제 정책 반영)
├── message_check/         # 수상한 문자 확인 (Android 전용, sms_datasource로 격리)
├── analysis/              # 분석 기록(문서+문자 결과), 고지서 통계 생성(구조화 필드+신뢰도 메타데이터 포함)
├── schedule/               # 일정(할 일) 관리
├── welfare_center/        # 주변 경로당·복지센터 찾기
├── info/                  # 나이 기반 맞춤 정보
├── connection/             # 어르신 측: 보호자 목록 확인/연결 요청 수락·거절/해제
├── voice_assistant/       # 음성 입력(STT) → 의도분석/AI → 기능 호출 → 음성 출력(TTS)
├── emergency_help/        # 긴급 도움(보호자/119/112/118 연결)
├── settings/               # 글자크기/음성/언어/계정/보호자 정보/알림 설정
└── support/                # 사용 방법 안내, 고객센터, 개인정보 보관 안내

apps/guardian/lib/features/
├── auth/                 # (Senior와 별도 구현, 동일 Backend 계약)
├── onboarding/
├── profile/
├── home/                  # 보호자 홈 — 연결된 어르신 요약, 안심 상태
├── connection/             # 보호자 측: 연결 요청 생성
├── guardian/                # 받은 연락, 분석 기록 조회, 고지서 통계 조회
├── analysis/              # Senior가 만든 분석 데이터를 Backend를 통해 조회하는 뷰
├── schedule/               # 다가오는 일정 조회
├── notification/          # FCM 토큰 등록/수신/로컬 표시/딥링크
├── settings/
└── support/
```

> **관리자 시스템은 이 목록에 포함하지 않는다.** PROPOSED 상태이며, 포함 여부·형태가 결정되지 않아 일반 사용자용 어르신/보호자 앱 feature 구조와 분리해 별도로 검토한다(`architecture.md` "관리자 시스템(PROPOSED, 미포함)" 참고).

```
packages/
├── core/            # Failure — 프레임워크 비의존, pure Dart (Phase 1 완료)
├── design_system/    # AppColors/AppTextStyles/AppSpacing/AppRadius/AppTheme + AppButton/AppCard/AppEmptyState/AppError/AppLoading/AppTextField (Phase 1 완료)
├── models/           # AnalysisResult/AnalysisType/ReliabilityLevel/RiskLevel/GuardianLink/GuardianLinkStatus 스켈레톤 (Phase 1 완료)
├── network/           # DioClient(baseUrl 파라미터화)/NetworkException/ErrorInterceptor, pure Dart (Phase 1 완료)
├── storage/           # SecureStorageService(flutter_secure_storage)/LocalStorageService(shared_preferences) (Phase 1 완료)
└── shared/            # 아직 비어있음 — 실제 공통 유틸 필요해질 때 채운다
```

각 앱의 `core/`(패키지 아님, 앱 내부)에는 다음이 추가된다: `core/network/network_providers.dart`(Phase 1 완료 — `ondam_network`의 `DioClient`에 각 앱의 `AppConfig.apiBaseUrl`을 주입하는 얇은 wiring), `core/storage/storage_providers.dart`(Phase 1 완료 — `ondam_storage`의 두 서비스를 Riverpod Provider로 노출), 그리고 Senior 앱에는 `core/easy_mode/easy_mode_provider.dart`(Phase 1 완료 — §2 참고)가 추가된다. `notification`은 core가 아닌 Guardian 앱의 독립 feature로 확정(알림 수신 후 여러 feature로의 딥링크 오케스트레이션이 필요해 순수 core보다 feature 계층이 적합, `architecture.md` 원칙에 부합).

### 변경 이력 (v3 → v4)

- **가장 큰 변경**: `lib/features/` 단일 트리 전제를 폐기하고 `apps/senior/lib/features/` + `apps/guardian/lib/features/`로 분리. 두 앱 사이의 "공유"는 코드 공유가 아니라 `packages/models`의 타입 모양 공유 + Backend API 계약 공유로 이루어진다.
- **`connection` feature가 사실은 두 앱 모두에 필요하다는 점을 바로잡음**: v1~v3 문서는 이 feature를 마치 어르신 앱에는 없고 보호자 앱 전용인 것처럼 다루는 서술이 섞여 있었다. 실제로는 어르신 쪽(보호자 목록 확인/해제, 요청 수락)과 보호자 쪽(요청 생성) 모두 필요하며, Phase 1에서 두 앱 모두에 `connection/` 디렉터리를 만들어 반영했다.
- `connection`: `technical-decisions.md` §1-6(어르신 수락 방식) 확정으로 **요청(pending) → 어르신 확인 → 수락/거절** 상태 흐름을 갖는 것으로 구체화(변경 없음, v2에서 이미 반영).
- `notification`: Guardian 앱 전용 feature로 확정(Push(FCM) 수신은 보호자 쪽에서만 필요 — 어르신 쪽 "위험 알림 보내기"는 `message_check`/`analysis`가 Backend에 이벤트를 남기는 것으로 끝나고, 실제 Push 수신·표시는 보호자 앱 책임).
- `message_check`: `technical-decisions.md` §1-9의 정확한 디렉터리 구조(`data/datasources/sms_datasource.dart`)를 Phase 1에서 실제로 반영(Android 전용 DataSource 자리, 구현은 Phase 7).

### 각 Feature가 필요한 이유

- **auth**: 전화번호+OTP(가입 1회)+PIN(평상시) 흐름을 모두 이 feature가 책임진다. `technical-decisions.md` §1-3, §2-1/§2-2(OPEN QUESTIONS 포함)와 직접 연결.
- **onboarding**: 최초 1회 흐름을 홈/설정과 분리. 보호자 등록은 이제 "즉시 등록"이 아니라 "연결 요청 생성"이므로, 실제 연결 성사 로직은 `connection`에 위임하고 onboarding은 입력 UI만 담당.
- **profile**: `settings`의 "내 정보"와 데이터 소유를 공유.
- **home**: 어르신 앱 진입점, 쉬운 모드 전환 지점.
- **document_scan / message_check**: 입력 소스와 플랫폼 제약이 달라 분리 유지. 결과는 `analysis`에 기록. **v3**: `document_scan`의 촬영 화면은 플래시 ON/OFF/자동 상태를 항상 명확히 보여주고 쉬운 모드에서는 큰 버튼으로 제공(별도 feature로 분리하지 않음 — 카메라 캡처와 강하게 결합된 UI 상태이기 때문).
- **analysis**: 문서/문자 분석 결과와 고지서 통계 통합. `technical-decisions.md` §4의 `analysis_results` 테이블과 1:1 대응. **v3**: 신뢰도(reliability) 메타데이터와 고지서 통계용 구조화 필드(`structured_fields`)를 이 feature의 도메인 엔티티가 소유 — 문서 분석이든 문자 분석이든 결과가 나오는 지점이 하나이므로, 신뢰도 변환 로직과 통계 집계 로직을 여기 한 곳에서 관리해 `guardian`/`voice_assistant` 등 소비자가 중복 구현하지 않게 한다.
- **schedule**: 어르신 "기록 탭 - 일정"과 보호자 "다가오는 일정"의 공통 데이터 소유.
- **welfare_center / info**: 기존과 동일한 이유로 유지.
- **connection (양쪽 앱 모두에 존재)**: `guardian_links`(pending/accepted/rejected/revoked) 개념을 다루는 feature. 어르신 앱의 `connection`은 "보호자 목록 확인/요청 수락·거절/해제" UseCase를, 보호자 앱의 `connection`은 "연결 요청 생성" UseCase를 갖는다 — 코드는 공유하지 않고 `packages/models`의 `GuardianLink` 모양과 Backend API만 공유한다.
- **guardian (보호자 앱 전용)**: `analysis`, `schedule`을 Backend를 통해 조회만 한다. "통계" 화면에서 고지서 통계(구조화 필드 기반)를 조회 — 원본 문서 이미지는 조회하지 않는다(§1-8 원본 즉시삭제 정책과 일치).
- **emergency_help**: 상시 노출 로직, 독립 유지. **v3**: 쉬운 모드 Main에서 `home`/`voice_assistant`와 함께 "가장 자주 쓰는 기능" 동선에 포함되므로, `home`이 이 feature의 진입점을 최소 탭으로 노출해야 한다(§2 참고).
- **notification (보호자 앱 전용)**: FCM 토큰 등록·갱신, Push 수신 시 로컬 알림 표시, 알림 탭 시 올바른 화면으로 이동(딥링크)까지 책임진다. 발송(서버→FCM)은 Backend 책임이라 이 feature는 수신 측만 다룬다.
- **voice_assistant (v3 신규)**: 음성 입력을 받아 다른 feature의 UseCase를 호출하는 오케스트레이션 책임을 가진다. 여러 feature를 폭넓게 알아야 하므로 `core`가 아닌 독립 feature로 두고, 다른 feature는 `voice_assistant`를 참조하지 않는 단방향 의존을 유지한다(`architecture.md` "신규 요구사항 Architecture 반영" 참고).
- **settings**: 접근성 설정(Local Storage), 계정(Secure Storage 연동), 알림 채널 on/off.
- **support**: 정적 콘텐츠 + 문의 채널.

---

## 2. 쉬운 모드 상세 설계 (확정, v3: Main UX로 격상)

`technical-decisions.md` UI 결정 A에 따라 **다음은 모두 확정 사항**이다(v1에서는 "검토"로 표현했던 항목들도 이번에 확정으로 승격).

> **v3 갱신**: 쉬운 모드는 더 이상 "설정에서 켜고 끄는 옵션"이 아니라 **어르신용 앱의 핵심 Main UX**로 취급한다. 홈 화면에서는 (1) 쉬운 모드 Main, (2) 큰 버튼, (3) 핵심 기능 중심 Navigation, (4) 음성 비서, (5) 긴급 도움, (6) 직관적인 안내가 하나의 경험으로 자연스럽게 연결되어야 한다. 특히 홈 화면은 어르신이 가장 자주 쓰는 기능(문서 촬영/문자 확인/경로당 찾기/음성 비서/긴급 도움)을 **최소한의 선택(탭 1~2회)**으로 접근할 수 있게 설계한다. 실제 Main 화면 구조는 Phase 3(골격)과 Phase 9(완성)에서 구체화하며, 이 문서는 방향만 정의한다 — 화면 와이어프레임/코드는 아직 만들지 않는다.

| 항목 | 확정 내용 |
|---|---|
| **활성화 방식** | 홈 화면 상단 토글, 즉시 전환 |
| **일반 모드와의 차이** | 단순 글자 확대가 아니라 **버튼 크기 / 정보량 / Navigation / 화면 복잡도 / 텍스트 / 여백 / 주요 기능 우선순위**까지 바뀌는 별도 UX 모드 |
| **적용 범위** | **전체 앱**(하단 Navigation 포함, 구성 자체를 바꿀 수 있음 — 세부 범위는 `technical-decisions.md` OPEN QUESTIONS 8번) |
| **글자 크기 설정과의 관계** | **독립적인 설정**으로 유지(쉬운 모드 on + 글자 크기 "아주 크게" 조합 가능) |
| **상태 저장** | Local Storage(`core/storage`)에 영속화 |
| **앱 재실행 후 유지 여부** | **유지** |
| **정보량** | 보조 설명/부가 링크를 생략하고 핵심 행동 문구만 남김(v1 설계 유지) |
| **색상** | 팔레트는 일반 모드와 동일, 배경 대비만 강화 검토(v1 설계 유지) |
| **긴급 도움 노출 위치** | 플로팅 버튼 대신 하단 Navigation에 통합(기존 앱 관찰 기반 KEEP) |

### Flutter 구현 구조

- `easyModeProvider`: `core` 레벨 `keepAlive` Provider, Local Storage와 동기화.
- `home` feature 내부에 `HomeNormalView` / `HomeEasyView` 두 위젯, 상위에서 Provider 값으로 분기 렌더링.
- 하단 Navigation은 `app/router` 또는 `core/widgets`의 공용 셸(Shell) 위젯이 `easyModeProvider`를 구독해 두 가지 레이아웃(일반 탭바 vs 확대 탭바+통합 도움 버튼) 중 하나를 렌더링.
- 테마 레이어: `AppSpacing`/`AppTextStyles`를 완전히 새로 만들지 않고, 쉬운 모드 배율 헬퍼(예: `AppSpacing.md * kEasyModeScale`)를 우선 검토.
- 테스트: 두 모드 각각에서 동일 UseCase가 호출되는지 Widget Test로 검증(비즈니스 로직 동일성 보장).

---

## 3. Android / iOS 플랫폼 차이 (확정 반영)

`technical-decisions.md` §1-9와 동일한 방향을 재확인.

| 항목 | Android | iOS | 구분 |
|---|---|---|---|
| SMS 읽기 | `message_check/data/datasources/sms_datasource.dart`(Android 전용)로 구현 | **직접 읽기 시도하지 않음**(확정) | iOS는 붙여넣기/공유/직접입력/기능제한 중 구현 시점에 선택 |
| Push 알림(FCM) | 지원 | 지원(APNs 경유) | 구현 가능 |
| Background 실행 | 제한적, SMS 브로드캐스트 리시버 등으로 특정 이벤트 트리거 가능 | 매우 제한적 | "새 문자 도착 즉시 자동 분석"은 Android 전용 |
| 위치 권한 | Foreground 권한으로 충분(`welfare_center`) | Foreground 권한으로 충분 | 구현 가능 |
| 카메라/사진 접근 | 런타임 권한 | 런타임 권한(세분화 접근 가능) | 구현 가능 |
| 긴급 전화 연결 | 다이얼러 호출 | 다이얼러 호출 | 구현 가능 |

### 구현 가능한 것 vs 플랫폼 제약

- **양 플랫폼 구현 가능**: Push/로컬 알림, 위치 검색, 사진 업로드 분석, 긴급 전화, SMS 작성화면 열기(발송은 사용자 직접).
- **Android 전용**: 수신 문자함 직접 읽기 기반 위험 문자 자동 확인.
- **양쪽 제한적**: 백그라운드 자동 문자 감지 — 기본 흐름은 "사용자가 앱을 열어 확인"으로 설계하고, 완전 자동화는 로드맵 후순위.

---

## 4. UI 개발 계획 (확정 반영)

1. **Design Token 정합화** — `AppColors` placeholder 확정 + `technical-decisions.md` UI-B에 따라 `emergency` 토큰 신설 여부/값 결정(색상값은 `technical-decisions.md` OPEN QUESTIONS 7번).
2. **Typography 확정**.
3. **공통 컴포넌트 우선 구축** — `AppButton`, `AppLoading`(단순 로딩=Progress Indicator만 / 중요 작업=진행상태 텍스트+Progress Indicator, UI 결정 D 반영), **`AppEmptyState`(공통 컴포넌트, 문구/아이콘/Action 주입형 — UI 결정 C 반영, 화면마다 개별 제작 금지)**.
4. **어르신용 UI — 홈(일반 모드)부터**.
5. **쉬운 모드 UI** — §2 설계 반영, 일반 모드 이후 구현.
6. **보호자용 UI** — Mock 데이터 프리뷰 화면은 구현하지 않는다(UI 결정 E 확정). 연결 전 상태는 `AppEmptyState`로 "아직 연결된 어르신이 없습니다 → 어르신 연결하기" CTA를 표시. **v3**: 고지서 통계 UI(구조화 데이터 기반 카드/그래프)도 이 단계에서 함께 설계.
7. **긴급 도움 / 설정 / 지원 화면**.
8. **(v3 신규) 답변 신뢰도 표시** — `analysis` 결과를 보여주는 모든 화면(문서 분석 결과, 문자 확인 결과)에 공통으로 붙는 표시 요소이므로, 개별 결과 화면 UI가 안정된 뒤(4단계 이후) 공통 컴포넌트로 추가.
9. **(v3 신규) 카메라 플래시 제어** — `document_scan` 촬영 화면 UI(4단계)에 포함해 함께 구현.
10. **(v3 신규) 음성 비서 UI(진입 버튼/입력·처리중·답변 상태)** — 쉬운 모드 Main(5단계) 설계가 끝난 뒤, 가장 마지막에 추가되는 진입점으로 설계(다른 모든 기능에 연결되어야 하므로 대상 기능 UI가 먼저 존재해야 함).

---

## 5. 개발 우선순위 (Phase) — 확정 반영

> Architecture 결정이 모두 확정되어, v1에서 "선행 조건: OO 결정 필요"로 막혀 있던 항목들이 대부분 해소되었다. 남은 선행 조건은 `technical-decisions.md` §5 OPEN QUESTIONS(세부 구현 방식)뿐이다.
>
> **경로 표기 안내(v4)**: 아래 Phase 설명에서 `lib/features/<x>/` 같은 경로는 실제로는 `apps/senior/lib/features/<x>/` 또는 `apps/guardian/lib/features/<x>/`(해당 Phase가 다루는 앱에 따라)를 뜻한다. Phase 1은 두 앱과 6개 공용 패키지의 기반을 모두 만들었으므로, Phase 2부터는 각 Phase가 "어느 앱" 작업인지 명시한다.

### Phase 1 — 프로젝트 기반

- **구현 기능**: Supabase 프로젝트 생성, `core/network`의 `DioClient` 연결, `core/storage`(Secure+Local 분리) 골격, `.env`/`.env.example` 정비.
- **선행 조건**: 없음(Backend/DB 결정 완료).
- **예상 영향 범위**: `lib/core/network/`, `lib/core/storage/`(신규), `.env*`.
- **테스트 항목**: 헬스체크 연결 테스트 1건, `core/storage`의 Secure/Local 각각 read/write 단위 테스트.
- **완료 조건**: `dart format .` / `flutter analyze` / `flutter test` 통과, Supabase 실연결 확인.

### Phase 2 — 인증(Auth)

- **구현 기능**: 전화번호 입력 → OTP 인증 → PIN 설정(가입), 전화번호+PIN 로그인(평상시), 로그인 상태 전역 Provider.
- **선행 조건**: Phase 1, **`technical-decisions.md` OPEN QUESTIONS 1번(Supabase Auth OTP+PIN 결합 방식) 결정 필요** — 이 Phase 착수 전 반드시 확정.
- **예상 영향 범위**: `lib/features/auth/`, `lib/core/storage/`, `lib/app/router/`.
- **테스트 항목**: OTP 검증 성공/실패, PIN 설정/검증(§2-2 보안 요구사항 — 해시 저장, 시도 횟수 제한 포함) UseCase 테스트, Repository Failure 변환 테스트, 로그인 화면 Widget Test.
- **완료 조건**: 가입(OTP+PIN)→로그인(PIN)→로그아웃 전체 흐름이 Supabase와 통신하며 동작, PIN이 평문으로 어디에도 저장되지 않음을 코드 리뷰로 확인.

### Phase 3 — 어르신 핵심 기능(홈/프로필/온보딩) + 쉬운 모드 Main 골격

- **구현 기능**: 온보딩(접근성/프로필/보호자 등록 **요청** — 즉시 연결 아님) → 홈(**쉬운 모드를 Main으로 하는 골격** + 일반 모드) → `profile` → `settings` 기본형. **v3**: 홈 화면 설계 시점부터 쉬운 모드를 부가 옵션이 아니라 기본 진입 경험으로 두고, 핵심 기능(문서/문자/경로당/긴급도움) 접근 동선을 최소화하는 구조를 잡는다(음성 비서 진입점은 Phase 10에서 실제 연결).
- **선행 조건**: Phase 2 완료.
- **예상 영향 범위**: `lib/features/onboarding/`, `lib/features/home/`, `lib/features/profile/`, `lib/features/settings/`(일부).
- **테스트 항목**: 온보딩 각 단계 UseCase 테스트, 홈 화면(쉬운 모드/일반 모드 둘 다) Widget Test, 보호자 등록 요청이 `connection` UseCase를 호출하는지 확인.
- **완료 조건**: 신규 가입 사용자가 온보딩을 마치고 홈에 진입해 쉬운 모드/일반 모드를 전환할 수 있고, 쉬운 모드가 핵심 기능 중심의 단순화된 Main 구조로 렌더링됨(기본 on/off 여부는 별도 UI 결정 사항 — OPEN QUESTIONS 미포함, 필요 시 추가 논의). 보호자 연결 요청이 `pending` 상태로 생성됨.

### Phase 4 — 어르신 분석 기능(문서/경로당/정보) + 카메라 플래시 + 고지서 구조화

- **구현 기능**: `document_scan`(촬영/업로드→분석→**원본 즉시 삭제**, **v3: 플래시 ON/OFF/자동 제어 포함**), `welfare_center`, `info`, `analysis`/`schedule` 골격(**v3: `analysis_results`에 신뢰도 메타데이터 + 고지서 구조화 필드(`structured_fields`) 포함해 설계** — UI 표시는 이후 Phase에서 하되, 데이터 구조는 이 시점에 확정해야 Phase 6/9에서 재작업이 없음).
- **선행 조건**: Phase 3 완료. Risk Detection/원본 삭제 정책은 이미 확정(§1-7, §1-8)되어 추가 결정 불필요. 고지서 통계 최종 항목(OPEN QUESTIONS 12)은 이 Phase 착수 시점까지 최소 초안이라도 필요.
- **예상 영향 범위**: `lib/features/document_scan/`, `lib/features/welfare_center/`, `lib/features/info/`, `lib/features/analysis/`, `lib/features/schedule/`.
- **테스트 항목**: 분석 Repository Failure 매핑 테스트, 원본 삭제가 실제로 트리거되는지(Storage 수명주기 정책 포함, §2-9) 통합 테스트, 위치 권한 거부 폴백 테스트, `AppEmptyState` Widget Test, 플래시 상태 전환 Widget Test, 고지서 구조화 필드 파싱 UseCase 테스트.
- **완료 조건**: 실제 사진 업로드→분석 결과가 `analysis_results`(신뢰도·구조화 필드 포함)에 저장되고 원본이 남지 않음(Android/에뮬레이터 검증, iOS는 Windows 환경상 `NOT AVAILABLE`). 촬영 화면에서 플래시 상태가 항상 명확히 보임.

### Phase 5 — 어르신↔보호자 연결(Connection)

- **구현 기능**: `connection` feature(요청 생성/어르신 확인 화면/수락·거절/해제), 보호자 앱 랜딩(전화번호 또는 연결 코드 입력 — 방식은 `technical-decisions.md` OPEN QUESTIONS 2번), 어르신 측 "연결된 보호자 목록" 화면(신규 확정 요구사항).
- **선행 조건**: Phase 3 완료. **OPEN QUESTIONS 2번(전화번호 vs 연결코드) 결정 권장**(둘 다 지원해도 되므로 강한 블로커는 아님).
- **예상 영향 범위**: `lib/features/connection/`(신규).
- **테스트 항목**: 요청 생성→어르신 화면 노출→수락 통합 테스트, 거절/미응답 케이스, 어르신의 연결 해제 테스트, `guardian_links` RLS 정책이 의도대로 동작하는지 검증(보호자가 pending 링크를 직접 accepted로 바꿀 수 없어야 함).
- **완료 조건**: 실제 두 계정 간 연결이 **어르신 수락을 거쳐** 성립, 어르신이 언제든 연결을 해제할 수 있음.

### Phase 6 — 보호자 핵심 기능(Guardian) + 고지서 통계 동기화

- **구현 기능**: 보호자 홈, 받은 연락, 기록, 통계(**v3: `analysis`의 구조화된 고지서 데이터를 조회하는 통계 화면 포함** — 원본 문서 이미지는 노출하지 않음). **연결 전 화면은 Mock 프리뷰 대신 `AppEmptyState`("아직 연결된 어르신이 없습니다")**.
- **선행 조건**: Phase 4, 5 완료(Phase 4에서 고지서 구조화 필드가 이미 설계되어 있어야 함).
- **예상 영향 범위**: `lib/features/guardian/`(신규).
- **테스트 항목**: 도메인 엔티티 조회·집계 테스트, RLS로 인해 비연결 어르신 데이터가 조회되지 않는지 확인하는 보안 테스트, 고지서 통계 집계(월별/변화율 등) UseCase 테스트.
- **완료 조건**: 연결된 어르신의 실제 데이터만 보호자 앱에 반영되고, 비연결 상태에서는 명확한 Empty State가 표시됨. 고지서 통계가 원본 없이 구조화 데이터만으로 표시됨.

### Phase 7 — 문자/위험 기능(Android 전용)

- **구현 기능**: `message_check`(`sms_datasource.dart`), 서버 Risk Detection 호출, "보호자에게 알리기" → `notification` 이벤트 생성.
- **선행 조건**: Phase 4, 6 완료. SMS 패키지 선정(`technical-decisions.md` OPEN QUESTIONS 4번)은 이 Phase 착수 시점에 확정.
- **예상 영향 범위**: `lib/features/message_check/`.
- **테스트 항목**: SMS 권한 거부 대체 UX, 위험 판정 매핑 테스트, iOS 빌드에서 기능 비활성 확인(코드 리뷰, `NOT AVAILABLE` 명시).
- **완료 조건**: Android 실기기/에뮬레이터에서 문자 분석→"보호자에게 알리기"까지 동작.

### Phase 8 — 알림(Notification)

- **구현 기능**: `features/notification`(FCM 토큰 등록/수신/로컬 표시/딥링크), 서버 측 알림 발송 트리거(`notifications` 테이블 insert → Edge Function → FCM).
- **선행 조건**: Phase 7 완료.
- **예상 영향 범위**: `lib/features/notification/`(신규), 서버 측 Edge Function(이 저장소 범위 밖일 수 있음 — 별도 확인 필요).
- **테스트 항목**: 권한 요청 흐름 Widget Test, 알림 수신 시 올바른 화면 딥링크 통합 테스트, FCM 토큰 갱신/무효화 테스트(§2-5).
- **완료 조건**: 위험 문자 발생 시 보호자 기기에 실제 Push 도달, 알림 탭 시 해당 "받은 연락" 상세로 이동.

### Phase 9 — UI 개선(쉬운 모드 완성 + 디자인 다듬기 + 답변 신뢰도)

- **구현 기능**: 쉬운 모드 Main 완성(하단 Navigation 포함, 핵심 기능 최소 동선 확정), 접근성 재검수, 긴급 도움/지원 화면 마감. **v3: 답변 신뢰도 UI**(`analysis` 결과가 표시되는 모든 화면에 "높음/보통/낮음"류 사용자 친화적 표현 추가 — 숫자·복잡한 그래프 배제, `ui-spec.md` 신뢰도 표현 규칙 참고).
- **선행 조건**: Phase 3~8이 일반 모드에서 안정적으로 동작. Phase 4에서 신뢰도 메타데이터가 이미 저장되고 있어야 함.
- **예상 영향 범위**: 전 feature `presentation/` 계층, 특히 `document_scan`/`message_check`/`analysis`/`guardian`의 결과 표시 화면.
- **테스트 항목**: 두 모드 동일 UseCase 호출 검증, 접근성 대비 점검, 재실행 후 쉬운 모드 유지 확인, 신뢰도 값→사용자 표현 매핑 단위 테스트(OPEN QUESTIONS 11의 기준 확정 후).
- **완료 조건**: 쉬운 모드 토글만으로 하단 Navigation까지 포함한 전체 앱이 일관 전환. 분석 결과 화면마다 신뢰도 안내가 일관되게 표시됨.

### Phase 10 — 음성 비서(Voice Assistant)

- **구현 기능**: 음성 입력(STT) → 의도 분석 → 온담 기능 UseCase 호출 또는 서버 AI 처리 → 답변 → 음성 출력(TTS)의 기본 파이프라인. 최초 구현은 소수의 핵심 명령(예: "문서 찍어줘", "경로당 찾아줘")만 지원하는 것으로 범위를 좁히는 것을 권장.
- **선행 조건**: Phase 3~9 완료(연결할 대상 기능들이 이미 존재해야 함). **OPEN QUESTIONS 9~10(STT/TTS 서비스, AI 처리 방식) 결정 필수** — 이 Phase는 다른 어떤 Phase보다 선행 결정 의존도가 높다.
- **예상 영향 범위**: `lib/features/voice_assistant/`(신규), `home`(음성 비서 진입 버튼 추가).
- **테스트 항목**: STT 인식 실패/무음 시 폴백 UX 테스트, 의도 분류 정확도에 대한 수동 QA(자동화 단위 테스트로는 한계), 다른 feature UseCase 호출 시 Failure 전파 테스트, TTS 재생 실패 시 텍스트 표시 폴백 테스트.
- **완료 조건**: 지원 범위로 명시한 핵심 명령 2~3개가 음성 입력→기능 실행→음성 답변까지 실제로 동작.

### Phase 11 — 통합 테스트 및 안정화

- **구현 기능**: 가입(OTP+PIN)→핵심기능→로그아웃, 보호자 연결요청→어르신수락→위험문자→Push알림, 음성 비서를 통한 핵심 기능 실행 등 주요 흐름 Integration Test.
- **선행 조건**: Phase 1~10 전체 완료.
- **예상 영향 범위**: `test/` 전반.
- **테스트 항목**: 핵심 흐름 2~3개 end-to-end 테스트, 계정 탈퇴 시 데이터/연결 삭제 정책(§2-10) 검증 테스트.
- **완료 조건**: `dart format .` / `flutter analyze` / `flutter test` 전체 통과, Android 빌드 검증(iOS는 `NOT AVAILABLE` 명시).

> **관리자 시스템은 Phase 계획에 포함하지 않는다.** MVP 포함 여부 자체가 OPEN QUESTIONS 14로 미결정이라, 포함이 확정되면 별도 Phase(또는 별도 프로젝트)로 그때 계획한다.

---

## 6. 이번 단계에서 하지 않은 것

- 실제 Feature/API/Database/Provider/UI 구현
- Supabase 프로젝트 생성 / Database 생성
- `pubspec.yaml` package 추가
- 코드 작성 일체

`technical-decisions.md` §5 OPEN QUESTIONS 중 Phase 2(1번)/Phase 5(2번)/Phase 7(4번)/Phase 10(9~10번) 착수 전 필요한 항목이 정리되면, `feature-development` skill로 Phase 1부터 순차 착수한다.
