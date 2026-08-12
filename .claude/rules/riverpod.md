# riverpod.md — 상태관리 규칙

현재 `riverpod_generator`는 미설치 (freezed와 analyzer 버전 충돌). 코드젠 없이 수동으로 Provider를 작성한다.

## Provider 종류와 용도

- `Provider<T>`: 변경되지 않는 의존성 주입용 (예: `dioClientProvider`, `appRouterProvider`). 서비스/repository/usecase 인스턴스를 노출할 때 사용.
- `StateProvider<T>`: 단순한 UI 로컬 상태 (토글, 선택된 탭 인덱스 등) — 비즈니스 로직이 없는 원시 상태에만 사용한다.
- `NotifierProvider<N, T>` / `AsyncNotifierProvider<N, T>`: 상태 변경 로직이 있는 경우. 비동기 데이터를 다루면 `AsyncNotifierProvider`를 우선 사용한다.
- `FutureProvider<T>`: 한 번 호출하고 캐시하는 단순 비동기 조회 (재시도/재계산 로직이 없을 때).

## Naming

- Provider 변수명은 `xxxProvider` 형태로 짓고, 이름만 보고 역할을 알 수 있어야 한다.
  - 좋은 예: `userProfileProvider`, `loginFormNotifierProvider`
  - 나쁜 예: `provider1`, `dataProvider`

## 비동기 상태

- 비동기 데이터는 `AsyncValue<T>`로 노출한다. `try/catch` + 별도 `isLoading`/`error` bool 플래그를 직접 만들지 않는다.
- UI에서는 `.when(data: ..., loading: ..., error: ...)`로 분기한다. 로딩/에러 위젯은 `core/widgets`의 `AppLoading`/`AppError`를 사용한다.

## 상태 범위

- 화면 하나에서만 쓰는 상태는 전역 Provider로 만들지 않는다 — 필요하면 해당 페이지 안에서 `ref.watch`/`ref.read`로 지역적으로 관리하거나, `autoDispose`를 사용해 화면을 벗어나면 폐기되게 한다.
- 여러 화면/feature가 공유해야 하는 상태만 전역(feature 루트 또는 core)에 둔다.
- `keepAlive`는 실제로 앱 전역에서 유지되어야 하는 상태(예: 인증 세션)에만 사용한다.

## Dependency Injection

- Repository/UseCase는 생성자에서 직접 의존성을 `new`하지 않고 Provider를 통해 주입받는다.
- 예: `final loginUseCaseProvider = Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));`
- 테스트에서 `ProviderScope(overrides: [...])`로 mock을 주입할 수 있도록 항상 인터페이스(추상 repository)에 의존한다.

## UI와 business logic 분리

- Widget에서 `ref.read(...).someBusinessMethod()`를 호출하는 것은 허용하되, 그 메서드 내부의 로직(계산, 검증, API 조합)은 Notifier/UseCase에 있어야 한다.
- `build()` 메서드 안에서 `ref.watch`로 읽은 값을 가공하는 것은 단순 표시용 변환(포맷팅 등)까지만 허용한다.
