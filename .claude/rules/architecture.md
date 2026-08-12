# architecture.md — 아키텍처 규칙

## 최상위 구조

```
lib/
├── app/        # 전역 설정: router, theme, config
├── core/       # feature에 종속되지 않는 공통 코드
├── features/   # 실제 기능
└── main.dart
```

## Feature-first

각 기능은 `lib/features/<feature_name>/` 아래에 자기 완결적으로 존재한다.

```
features/<feature_name>/
├── data/
│   ├── datasources/    # Dio/DB 호출 — API 응답 원형(JSON 등)을 다룸
│   ├── models/          # DTO — fromJson/toJson, domain entity로 변환
│   └── repositories/    # domain repository 인터페이스의 구현체
├── domain/
│   ├── entities/         # 순수 Dart 객체, Flutter/외부 패키지 의존 없음
│   ├── repositories/     # 추상 인터페이스 (data 계층이 구현)
│   └── usecases/         # 단일 책임의 비즈니스 로직 단위
└── presentation/
    ├── pages/            # 화면 단위 Widget (라우트에 연결)
    ├── widgets/           # 해당 feature 전용 하위 Widget
    └── providers/         # Riverpod Provider/Notifier
```

작은 기능은 이 구조를 전부 강제하지 않는다. 예를 들어 usecase가 단순 CRUD 하나뿐이면 `usecases/` 없이 repository를 provider에서 직접 호출해도 된다. 단, presentation이 data를 직접 참조하는 것은 금지.

## 의존성 방향

```
Presentation → Domain → Data
```

- domain은 Flutter SDK, Dio, Riverpod 등 어떤 외부 패키지에도 의존하지 않는다. 순수 Dart만 사용한다.
- data는 domain의 인터페이스(추상 repository)를 구현한다. domain은 data를 모른다.
- presentation은 domain의 usecase/entity만 알고, data의 model/datasource를 직접 참조하지 않는다.

## 호출 흐름

```
UI → Provider(Riverpod) → UseCase → Repository → DataSource → API/DB
```

- Widget에서 API를 직접 호출하지 않는다 (Dio, http client를 Widget에서 import 금지).
- Provider는 UseCase를 호출하고 결과를 `AsyncValue`로 노출한다.
- Repository는 domain 인터페이스이자 data 구현체 — data 계층 예외(`NetworkException`)를 domain 실패(`Failure`)로 변환하는 경계다.

## 폴더 책임

- `app/`: 앱 전역 설정(테마, 라우터, 환경설정)만 둔다. 기능 로직을 넣지 않는다.
- `core/`: 두 개 이상의 feature가 실제로 공유하는 코드만 둔다. 특정 feature 전용 코드를 core로 올리지 않는다.
- `features/`: 기능별 코드. feature 간 서로의 내부(data/domain 구현 detail)를 직접 import하지 않는다 — 공유가 필요하면 core로 승격을 검토한다.

## Feature 간 결합 최소화

- feature A가 feature B의 presentation/provider를 직접 참조하지 않는다.
- 공유가 필요한 도메인 개념(예: 로그인 상태)은 core 또는 별도 공유 feature로 분리한다.
- 라우팅을 통한 이동만 허용 (go_router path 기반), 위젯 직접 import를 통한 화면 전환은 지양한다.
