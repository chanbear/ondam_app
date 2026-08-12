# testing.md — 테스트 규칙

## 구조

```
test/
├── core/       # core 공통 코드 테스트
└── features/   # feature별 테스트 (lib/features/<feature>/ 구조를 미러링)
```

## Unit Test

- domain 계층(UseCase, Entity)은 Flutter 의존이 없으므로 반드시 Unit Test 가능해야 한다.
- Repository는 DataSource를 mock으로 대체해 "data-layer 예외 → Failure 변환"이 올바른지 검증한다.
- Notifier/UseCase의 핵심 분기(성공/실패/빈 값)는 Unit Test로 커버한다.

## Widget Test

- 사용자와 상호작용이 있는 중요 화면(폼 제출, 목록 렌더링 등)은 Widget Test를 고려한다.
- `ProviderScope(overrides: [...])`로 Provider를 mock/fake로 교체해 네트워크 의존 없이 테스트한다.
- `AsyncValue`의 loading/error/data 세 가지 상태가 올바른 위젯(`AppLoading`/`AppError`/실제 콘텐츠)을 그리는지 확인한다.

## Integration Test

- 로그인 → 핵심 기능 사용 → 로그아웃처럼 여러 화면을 거치는 중요 사용자 흐름은 Integration Test를 고려한다.
- 실제 기능이 추가되기 전(현재 단계)에는 작성하지 않는다 — 테스트할 흐름 자체가 아직 없다.

## Feature별 테스트 기준

- 새 feature를 추가하면 최소한 domain(UseCase) 테스트는 함께 작성한다.
- data/datasources는 실제 네트워크를 타지 않고 mock Dio(`DioAdapter` 등) 또는 mock DataSource로 테스트한다.
- presentation은 모든 화면을 다 테스트하지 않아도 되지만, 핵심 사용자 경로는 커버한다.

## 작성 기준

- 테스트 이름은 "무엇을 하면 무엇이 되어야 한다"를 설명한다 (예: `'로그인 실패 시 AuthFailure를 반환한다'`).
- 하나의 테스트는 하나의 동작만 검증한다.
- 의미 없는 커버리지를 위한 테스트(getter 하나 확인 등)는 작성하지 않는다.

## 완료 전 검증

기능 구현 후 다음을 실행하고, 실패하면 "완료"로 보고하지 않는다.

```
dart format .
flutter analyze
flutter test
```

Android/iOS 관련 변경이 있으면 가능한 환경에서 build 검증도 수행한다. 검증 불가능한 환경(예: Flutter SDK 미설치, Windows에서의 iOS 빌드)에서는 실패로 간주하지 않되 "NOT AVAILABLE"로 명시한다.
