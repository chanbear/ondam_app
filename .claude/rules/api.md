# api.md — 네트워크/API 규칙

## 구조

```
core/network/
├── dio_client.dart         # 공유 Dio 인스턴스 (DioClient)
├── network_providers.dart  # dioClientProvider
├── network_exception.dart  # NetworkException 계층 (data-layer 예외)
└── interceptors/
    └── error_interceptor.dart  # DioException → NetworkException 매핑
```

## Dio 사용 규칙

- `Dio()`를 feature 코드에서 직접 생성하지 않는다. 항상 `ref.watch(dioClientProvider)`를 통해 공유 인스턴스를 가져온다.
- base URL, timeout 등 공통 설정은 `DioClient`에서만 관리한다. feature datasource가 개별적으로 `BaseOptions`를 만들지 않는다.

## DataSource

- `features/<feature>/data/datasources/`에 위치. Dio 호출과 raw response(JSON) 파싱만 담당한다.
- DataSource는 domain entity를 모른다 — model(DTO)만 다룬다.
- 네트워크 에러는 여기서 처리하지 않는다. `ErrorInterceptor`가 이미 `NetworkException`으로 변환했으므로, DataSource는 그대로 던진다.

## Repository

- `features/<feature>/data/repositories/`에서 domain의 추상 repository를 구현한다.
- DataSource가 던진 `NetworkException`을 잡아서 domain의 `Failure`로 변환하는 것이 Repository의 핵심 책임이다.
  - `ConnectionException`/`TimeoutException` → `NetworkFailure`
  - `UnauthorizedException` → `AuthFailure`
  - `ServerException` → `ServerFailure`
  - 그 외 → `UnknownFailure`
- Repository 반환 타입은 `Future<Either<Failure, T>>` 또는 이에 준하는 명시적 성공/실패 표현을 사용한다. 예외를 그대로 UseCase까지 흘려보내지 않는다.

## Interceptor

- 공통 관심사(에러 매핑, 인증 토큰 첨부, 로깅)는 `core/network/interceptors/`에 Interceptor로 작성한다.
- feature별 특수 처리가 필요하면 해당 feature의 datasource에서 개별 요청 단위로 처리하고, 공통 Interceptor를 수정하지 않는다.

## Authentication

- 인증 토큰은 `flutter_secure_storage` 등 보안 저장소에 보관한다 (필요해지면 추가 — 현재 미설치).
- 토큰 첨부는 별도 `AuthInterceptor`로 분리하고, 401 응답 시 재발급/로그아웃 처리는 인증 feature의 책임으로 둔다. `ErrorInterceptor`는 매핑만 하고 side effect(로그아웃 등)를 갖지 않는다.

## Error Handling

- Widget/Provider는 `NetworkException`이나 `DioException`을 직접 catch하지 않는다 — Repository가 변환한 `Failure`만 다룬다.
- 사용자에게 보여줄 메시지는 `Failure.message`를 사용한다. 원본 예외의 기술적 메시지를 그대로 노출하지 않는다.

## API 모델

- API 응답 DTO는 `features/<feature>/data/models/`에 둔다.
- 현재 `freezed`/`json_serializable`은 미설치 상태 — 실제 API 연동 시점에 필요성을 판단해 추가하고, 그전까지는 수동으로 `fromJson`/`toJson`을 작성한다.
- Model → Entity 변환은 Model 쪽에 `toEntity()` 메서드로 둔다 (domain이 data를 몰라야 하므로 역방향 변환은 만들지 않는다).
