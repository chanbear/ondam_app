# ondam_app

Flutter (Android + iOS) 앱. Feature-first architecture.

## 프로젝트 목적

기존 온담앱은 코드 오류와 구조적 문제가 많아 이어서 개발하지 않는다. 기존 앱은 **레퍼런스/요구사항 분석 자료**로만 사용하고, 이 저장소에서 안정적인 구조로 처음부터 다시 구축한다.

기존 기능을 그대로 옮기지 않는다 — 분석 후 KEEP / MODIFY / REMOVE / ADD로 분류하고, 분류 결과를 문서화(`docs/product/`)한 뒤 기능을 구현한다. 자세한 절차는 `app-analysis` skill 참고.

## 아키텍처

```
lib/
├── app/        # 전역 설정: router, theme, config
├── core/       # feature에 종속되지 않는 공통 코드: network, errors, widgets, storage, utils, constants
├── features/   # 실제 기능. 각 feature는 data/domain/presentation 3계층
└── main.dart
```

Feature 내부 계층 흐름: `UI → Provider(Riverpod) → UseCase → Repository → DataSource → API/DB`

- domain 계층은 Flutter/외부 패키지에 의존하지 않음
- presentation은 API를 직접 호출하지 않고 Provider/UseCase를 통해서만 접근
- 색상/spacing/타이포그래피는 `lib/app/theme/`의 토큰만 사용, 하드코딩 금지

## 기술 스택

- 상태관리: Riverpod (`flutter_riverpod`, 코드젠 없이 수동 Provider 작성 — `riverpod_generator`는 `freezed`와 analyzer 버전이 충돌해 현재 미설치)
- 라우팅: go_router (`lib/app/router/app_router.dart`)
- 네트워크: Dio (`lib/core/network/dio_client.dart`, `dioClientProvider`)
- 환경변수: flutter_dotenv (`.env`, `.env.example`)

## 아직 없는 것 (의도적으로 보류, YAGNI)

- `freezed` / `json_serializable` / `build_runner`: 실제 데이터 모델이 생기면 추가
- `core/widgets/app_text_field.dart`, `app_empty_state.dart`: 폼/리스트 기능이 생기면 추가
- `assets/*` pubspec 등록: 폴더 구조만 존재, 실제 에셋 파일이 생기면 pubspec에 등록
- iOS 빌드: Windows에서는 근본적으로 불가 — macOS/Xcode 필요 (코드 작성은 가능)

## 개발 환경

컴퓨터마다 다를 수 있는 SDK 경로 등은 `.claude/CLAUDE.local.md`(gitignore됨)에 적는다. 새 컴퓨터에서 작업을 시작하면 그 파일이 없을 수 있으니 먼저 확인하고 없으면 새로 작성한다.

## 문서

기존 온담앱 분석 및 신규 기능 명세는 `docs/`에 문서화한다 (`app-analysis` skill 참고).

```
docs/
├── product/current-app-analysis.md, feature-spec.md, user-flow.md
├── architecture/architecture.md
└── ui/ui-spec.md
```

## 개발 원칙

- 화면/기능을 요청받기 전에 임의로 만들지 않는다
- 새 코드 추가 전 기존 구조·파일을 먼저 확인한다
- API 호출을 위젯에서 직접 하지 않는다
- 기존 온담앱 코드를 무작정 복사하지 않는다 — 구조는 새로 설계한다
- 기능은 한 번에 전체가 아니라 feature 단위로 나눠서 구현한다 (`feature-development` skill)
- 요구사항에 없는 기능/화면/패키지를 임의로 추가하지 않는다

## UI 원칙

- 색상/spacing/타이포그래피/radius는 `lib/app/theme/`의 토큰만 사용, 하드코딩 금지 (`ui-design.md`)
- 기존 온담앱 UI는 참고 자료일 뿐 그대로 복제하지 않는다 — 문제점을 개선한 새 UI로 재구성한다
- UI 변경이 필요할 때는 `ui-redesign` skill을 따르고, business logic(Provider/Repository/API)은 UI 변경을 이유로 임의로 건드리지 않는다

## 기능 개발 방식

`UI → Provider(Riverpod) → UseCase → Repository → DataSource → API/DB` 순서로 설계 후 구현한다 (`architecture.md`, `feature-development` skill). 기존 기능 수정/삭제는 영향 범위(UI/Provider/Repository/API/Model/Test)를 먼저 확인한 뒤 진행한다.

## 테스트 방식

domain(UseCase)은 Unit Test 가능해야 한다. 중요 UI는 Widget Test, 중요 사용자 흐름은 Integration Test를 고려한다 (`testing.md`). 테스트 없이 기능 완료를 선언하지 않는다.

## 금지사항

```text
기존 코드 무작정 복사
요구사항 없는 기능/UI 추가
API Key 하드코딩
Widget에서 API 직접 호출
Provider 무분별한 생성
dynamic 남용
거대한 Widget / 중복 코드
불필요한 package / plugin / abstraction
테스트 없이 완료 선언
analyze 오류 무시, build 오류 무시
```

## 완료 조건

다음이 모두 통과해야 "완료"로 보고한다. 실패 시 완료로 보고하지 않는다.

```text
dart format .
flutter analyze
flutter test
```

Android/iOS 관련 변경이 있으면 가능한 환경에서 build 검증도 수행한다. 검증 불가능한 환경(SDK 미설치, Windows에서의 iOS)은 실패가 아니라 "NOT AVAILABLE"로 명시한다.
