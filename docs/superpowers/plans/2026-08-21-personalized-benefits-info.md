# 나이/성별/지역 기반 맞춤 혜택 정보 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `apps/senior`의 빈 "정보" 탭을 나이·성별·거주 지역에 따라 결과가 달라지는 실시간 맞춤 혜택 정보 목록/상세 화면으로 채운다.

**Architecture:** `region`/`welfare_center` feature와 동일한 3계층 패턴(UI→Provider→UseCase→Repository→DataSource→Edge Function)을 그대로 따른다. 나이/성별은 `core/demographics`(region과 동일하게 `profile`/`info` 두 feature가 공유)에 신규로 만들고, 혜택 정보는 `features/info`에 domain/data/presentation을 채운다. 공공데이터포털 API 호출은 `search-benefit-services`/`get-benefit-service-detail` 두 Edge Function이 전담한다(서비스키를 클라이언트에 노출하지 않음, `search-welfare-centers`와 동일 이유).

**Tech Stack:** Flutter/Dart(`ondam_senior` 패키지), Riverpod(수동 Provider), Supabase(Postgres + Edge Functions, Deno/TypeScript), `ondam_core`의 `Result`/`Failure`.

**Spec:** `docs/superpowers/specs/2026-08-21-personalized-benefits-info-design.md`

## Global Constraints

- 색상/spacing/타이포그래피/radius는 `ondam_design_system`의 `AppColors`/`AppSpacing`/`AppTextStyles`/`AppRadius` 토큰만 사용한다. 위젯 안에 `Color(0xFF...)`, 숫자 padding 등을 직접 쓰지 않는다.
- Riverpod은 코드젠 없이 수동 Provider로 작성한다(`riverpod_generator` 미설치). 비동기 상태는 `AsyncNotifier`로 노출하고 `AsyncValue.when(...)`으로 분기한다.
- Repository는 항상 `Future<Result<T>>`(`ondam_core`의 `Ok`/`Err`)를 반환하고, data-layer 예외(`PostgrestException`/`AuthException`/`FunctionException`)를 `Failure`로 매핑한다. UseCase/Provider/Widget에는 예외를 흘려보내지 않는다.
- domain 계층(entity/repository interface/usecase)은 Flutter/Dio/Supabase 등 외부 패키지에 의존하지 않는다.
- Widget에서 Dio/Supabase를 직접 호출하지 않는다 — Provider/UseCase를 통해서만 접근한다.
- Edge Function은 `index.ts`(I/O)와 순수 로직 파일을 분리한다. `_shared/cors.ts`/`_shared/http.ts`/`_shared/auth.ts`를 재사용하고 공통 Interceptor·헬퍼를 다시 만들지 않는다.
- 가짜 데이터/가짜 성공을 만들지 않는다 — 데이터 소스가 준비되지 않았거나(서비스키 미등록) 응답이 불완전하면 `UnavailableFailure`/`null`/빈 목록으로 정직하게 표현한다(`welfare_center`의 기존 원칙과 동일).
- 완료 조건: `apps/senior` 디렉터리에서 `dart format .`, `flutter analyze`, `flutter test`가 모두 통과해야 "완료"로 보고한다. 이 환경에는 `flutter`/`dart`/`supabase` CLI가 설치되어 있으므로 static 분석·단위/위젯 테스트·`supabase db diff`/migration lint는 실제로 실행한다. 단, **Deno 단위테스트(Edge Function)는 이 환경에 Deno CLI가 없어 NOT AVAILABLE** — `welfare_center_client.test.ts`와 동일하게 best-effort 아티팩트로만 작성한다. 실제 `DATA_GO_KR_SERVICE_KEY` 라이브 호출/Supabase 프로젝트 배포도 이 환경에는 자격증명이 없어 NOT AVAILABLE.
- Gender/BenefitServiceSource 같은 enum은 wire-value(DB 컬럼 값, Edge Function JSON 값)를 enum 자체의 `value` 필드 + `fromValue()` 정적 메서드로 관리한다(별도 free function 금지, 단일 정의 유지).

---

### Task 1: DB Migration — `users.age`/`users.gender`

**Files:**
- Create: `supabase/migrations/20260821000002_users_age_gender.sql`

**Interfaces:**
- Produces: `public.users` 테이블에 nullable `age smallint`, `gender text check (gender in ('male','female'))` 컬럼. 이후 모든 Dart datasource가 이 컬럼명을 그대로 사용한다.

- [ ] **Step 1: migration 파일 작성**

`supabase/migrations/20260821000002_users_age_gender.sql`:

```sql
-- users.age/gender: 나이/성별 기반 맞춤 혜택 정보(정보 탭) 요구사항을 위해
-- 신규 추가한다. technical-decisions.md §4의 users 스케치(v1)에는 age는
-- 있었지만 gender는 없었다 — 이번 기능이 처음으로 필요로 하는 필드라
-- 신규로 추가한다(v19). region_* 컬럼(20260819000002)과 동일하게 nullable
-- — 아직 입력하지 않은 사용자도 존재한다(profile_page의 "저장" 흐름 참고).
-- RLS는 이미 users_select_own/users_insert_own/users_update_own이 행 전체를
-- id = auth.uid() 기준으로 다루므로 정책을 추가하지 않는다.

alter table public.users
  add column age smallint,
  add column gender text check (gender in ('male', 'female'));

comment on column public.users.age is
  '어르신 나이 — 정보 탭의 나이 기반 맞춤 혜택 정보 검색 조건으로 쓰인다. profile_page에서 입력, 저장 전까지 null(미입력).';

comment on column public.users.gender is
  '어르신 성별(male/female) — 정보 탭의 맞춤 혜택 정보 검색 조건으로 쓰인다. profile_page에서 입력, 저장 전까지 null(미입력).';
```

- [ ] **Step 2: migration lint/구문 검증**

Run: `supabase db lint --schema public` (프로젝트가 아직 링크돼 있지 않으면 `supabase migration list` 대신 `supabase db diff --file 20260821000002_users_age_gender --linked=false`가 실패할 수 있다 — 그 경우 `supabase --workdir . migration list`로 파일이 인식되는지만 확인). 실제 원격 DB 적용은 이 환경에 프로젝트 자격증명이 없어 **NOT AVAILABLE**로 기록한다.

Expected: SQL 구문 오류 없음(파일이 마이그레이션 목록에 정상 인식됨).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260821000002_users_age_gender.sql
git commit -m "feat(db): add users.age/gender columns for personalized benefit info"
```

---

### Task 2: `core/demographics` domain — entity, repository interface, usecase 2개

**Files:**
- Create: `apps/senior/lib/core/demographics/domain/entities/demographics.dart`
- Create: `apps/senior/lib/core/demographics/domain/repositories/demographics_repository.dart`
- Create: `apps/senior/lib/core/demographics/domain/usecases/get_my_demographics_usecase.dart`
- Create: `apps/senior/lib/core/demographics/domain/usecases/save_demographics_usecase.dart`
- Test: `apps/senior/test/core/demographics/domain/fakes/fake_demographics_repository.dart`
- Test: `apps/senior/test/core/demographics/domain/usecases/demographics_usecases_test.dart`

**Interfaces:**
- Produces: `Gender` enum(`Gender.male`/`Gender.female`, `.value` getter, `Gender.fromValue(String?)`), `Demographics(age: int?, gender: Gender?)`(`isComplete` getter, `==`/`hashCode`), `DemographicsRepository`(`getMyDemographics()`/`saveDemographics(Demographics)`), `GetMyDemographicsUseCase.call()`, `SaveDemographicsUseCase.call(Demographics)`. Task 8(`features/info`)이 `Gender`/`Demographics`를 그대로 import해서 쓴다.

- [ ] **Step 1: fake repository 작성**

`apps/senior/test/core/demographics/domain/fakes/fake_demographics_repository.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/domain/repositories/demographics_repository.dart';

class FakeDemographicsRepository implements DemographicsRepository {
  Result<Demographics?> getMyDemographicsResult = const Ok(null);
  Result<void> saveDemographicsResult = const Ok(null);

  Demographics? savedDemographics;
  int saveCalls = 0;
  int getMyDemographicsCalls = 0;

  @override
  Future<Result<Demographics?>> getMyDemographics() async {
    getMyDemographicsCalls++;
    return getMyDemographicsResult;
  }

  @override
  Future<Result<void>> saveDemographics(Demographics demographics) async {
    saveCalls++;
    savedDemographics = demographics;
    return saveDemographicsResult;
  }
}
```

- [ ] **Step 2: 실패하는 테스트 작성**

`apps/senior/test/core/demographics/domain/usecases/demographics_usecases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/domain/usecases/get_my_demographics_usecase.dart';
import 'package:ondam_senior/core/demographics/domain/usecases/save_demographics_usecase.dart';

import '../fakes/fake_demographics_repository.dart';

void main() {
  late FakeDemographicsRepository repository;

  setUp(() {
    repository = FakeDemographicsRepository();
  });

  group('GetMyDemographicsUseCase', () {
    test('저장된 정보가 없으면 null을 정직하게 반환한다', () async {
      repository.getMyDemographicsResult = const Ok(null);
      final useCase = GetMyDemographicsUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Demographics?>).value, isNull);
    });

    test('저장된 정보가 있으면 그대로 반환한다', () async {
      const demographics = Demographics(age: 72, gender: Gender.female);
      repository.getMyDemographicsResult = const Ok(demographics);
      final useCase = GetMyDemographicsUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Demographics?>).value, demographics);
    });
  });

  group('SaveDemographicsUseCase', () {
    test('저장 성공', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: Gender.female);

      final result = await useCase(demographics);

      expect(result, isA<Ok<void>>());
      expect(repository.saveCalls, 1);
      expect(repository.savedDemographics, demographics);
    });

    test('나이가 없으면 저장을 시도하지 않고 ValidationFailure를 반환한다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: null, gender: Gender.female);

      final result = await useCase(demographics);

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('나이가 범위를 벗어나면 저장을 시도하지 않는다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 150, gender: Gender.male);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('성별이 없으면 저장을 시도하지 않는다', () async {
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: null);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('저장 실패(예: 네트워크 오류)를 그대로 전달한다', () async {
      repository.saveDemographicsResult = const Err(ServerFailure());
      final useCase = SaveDemographicsUseCase(repository);
      const demographics = Demographics(age: 72, gender: Gender.female);

      final result = await useCase(demographics);

      expect((result as Err<void>).failure, isA<ServerFailure>());
    });
  });
}
```

- [ ] **Step 3: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/core/demographics/domain/usecases/demographics_usecases_test.dart`
Expected: FAIL (엔티티/usecase 파일이 아직 없어 컴파일 오류)

- [ ] **Step 4: entity 작성**

`apps/senior/lib/core/demographics/domain/entities/demographics.dart`:

```dart
/// 어르신의 나이/성별 — `profile`(입력)과 `info`(맞춤 혜택 정보 검색 조건
/// 읽기) feature가 함께 구독하는 공유 상태이므로 `core/location`의
/// `Region`과 동일한 이유로 core에 둔다.
enum Gender {
  male('male'),
  female('female');

  const Gender(this.value);

  /// DB 컬럼 값이자 Edge Function 요청 바디에 실리는 wire value.
  final String value;

  static Gender? fromValue(String? raw) => switch (raw) {
    'male' => Gender.male,
    'female' => Gender.female,
    _ => null,
  };
}

class Demographics {
  const Demographics({required this.age, required this.gender});

  final int? age;
  final Gender? gender;

  /// 둘 다 입력됐을 때만 "완전하다" — `features/info`가 검색 조건으로
  /// 쓸 수 있는지 판단하는 기준이다.
  bool get isComplete => age != null && gender != null;

  @override
  bool operator ==(Object other) {
    return other is Demographics && other.age == age && other.gender == gender;
  }

  @override
  int get hashCode => Object.hash(age, gender);
}
```

- [ ] **Step 5: repository interface 작성**

`apps/senior/lib/core/demographics/domain/repositories/demographics_repository.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';

/// 어르신의 나이/성별 — 저장 전까지는 `null`(또는 `Demographics`의 일부
/// 필드가 `null`)이 정직한 "미입력" 상태다(`RegionRepository`와 동일한
/// 원칙).
abstract class DemographicsRepository {
  Future<Result<Demographics?>> getMyDemographics();

  Future<Result<void>> saveDemographics(Demographics demographics);
}
```

- [ ] **Step 6: usecase 2개 작성**

`apps/senior/lib/core/demographics/domain/usecases/get_my_demographics_usecase.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';
import '../repositories/demographics_repository.dart';

class GetMyDemographicsUseCase {
  const GetMyDemographicsUseCase(this._repository);

  final DemographicsRepository _repository;

  Future<Result<Demographics?>> call() => _repository.getMyDemographics();
}
```

`apps/senior/lib/core/demographics/domain/usecases/save_demographics_usecase.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../entities/demographics.dart';
import '../repositories/demographics_repository.dart';

class SaveDemographicsUseCase {
  const SaveDemographicsUseCase(this._repository);

  final DemographicsRepository _repository;

  Future<Result<void>> call(Demographics demographics) {
    final age = demographics.age;
    if (age == null || age <= 0 || age > 120) {
      return Future.value(const Err(ValidationFailure('나이를 올바르게 입력해주세요.')));
    }
    if (demographics.gender == null) {
      return Future.value(const Err(ValidationFailure('성별을 선택해주세요.')));
    }
    return _repository.saveDemographics(demographics);
  }
}
```

- [ ] **Step 7: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/core/demographics/domain/usecases/demographics_usecases_test.dart`
Expected: PASS (7 tests)

- [ ] **Step 8: Commit**

```bash
git add apps/senior/lib/core/demographics/domain apps/senior/test/core/demographics/domain
git commit -m "feat(demographics): add domain layer (entity, repository interface, usecases)"
```

---

### Task 3: `core/demographics` data — datasource, repository impl

**Files:**
- Create: `apps/senior/lib/core/demographics/data/datasources/demographics_remote_datasource.dart`
- Create: `apps/senior/lib/core/demographics/data/models/demographics_model.dart`
- Create: `apps/senior/lib/core/demographics/data/repositories/demographics_repository_impl.dart`
- Test: `apps/senior/test/core/demographics/data/repositories/demographics_repository_impl_test.dart`

**Interfaces:**
- Consumes: Task 2의 `Demographics`/`Gender`/`DemographicsRepository`.
- Produces: `DemographicsRemoteDataSource(SupabaseClient)`(`fetchMine()`/`upsertMine({age, gender})`), `DemographicsRepositoryImpl(DemographicsRemoteDataSource)`. Task 4의 DI provider가 이 두 클래스를 그대로 연결한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`apps/senior/test/core/demographics/data/repositories/demographics_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/data/datasources/demographics_remote_datasource.dart';
import 'package:ondam_senior/core/demographics/data/repositories/demographics_repository_impl.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockDemographicsRemoteDataSource extends Mock
    implements DemographicsRemoteDataSource {}

void main() {
  late _MockDemographicsRemoteDataSource dataSource;
  late DemographicsRepositoryImpl repository;

  setUp(() {
    dataSource = _MockDemographicsRemoteDataSource();
    repository = DemographicsRepositoryImpl(dataSource);
  });

  group('getMyDemographics', () {
    test('저장된 행이 없으면 null을 정직하게 반환한다', () async {
      when(() => dataSource.fetchMine()).thenAnswer((_) async => null);

      final result = await repository.getMyDemographics();

      expect((result as Ok<Demographics?>).value, isNull);
    });

    test('저장된 행이 있으면 엔티티로 변환한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenAnswer((_) async => {'age': 72, 'gender': 'female'});

      final result = await repository.getMyDemographics();

      final value = (result as Ok<Demographics?>).value;
      expect(value?.age, 72);
      expect(value?.gender, Gender.female);
    });

    test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.fetchMine(),
      ).thenThrow(const AuthException('로그인이 필요해요.'));

      final result = await repository.getMyDemographics();

      expect((result as Err<Demographics?>).failure, isA<AuthFailure>());
    });

    test('PostgrestException은 ServerFailure로 매핑한다', () async {
      when(() => dataSource.fetchMine()).thenThrow(
        const PostgrestException(message: 'boom', code: '500'),
      );

      final result = await repository.getMyDemographics();

      expect((result as Err<Demographics?>).failure, isA<ServerFailure>());
    });
  });

  group('saveDemographics', () {
    const demographics = Demographics(age: 72, gender: Gender.female);

    test('저장 성공', () async {
      when(
        () => dataSource.upsertMine(age: 72, gender: 'female'),
      ).thenAnswer((_) async {});

      final result = await repository.saveDemographics(demographics);

      expect(result, isA<Ok<void>>());
      verify(() => dataSource.upsertMine(age: 72, gender: 'female')).called(1);
    });

    test('권한 오류(RLS)는 AuthFailure로 매핑한다', () async {
      when(() => dataSource.upsertMine(age: 72, gender: 'female')).thenThrow(
        const PostgrestException(message: 'denied', code: '42501'),
      );

      final result = await repository.saveDemographics(demographics);

      expect((result as Err<void>).failure, isA<AuthFailure>());
    });
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/core/demographics/data/repositories/demographics_repository_impl_test.dart`
Expected: FAIL (구현 파일 없음)

- [ ] **Step 3: datasource 작성**

`apps/senior/lib/core/demographics/data/datasources/demographics_remote_datasource.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// `users` 테이블의 age/gender 컬럼만 읽고/쓴다 — `RegionRemoteDataSource`
/// 와 동일한 행(같은 PK)을 다루지만, PostgREST upsert는 요청 바디에 담긴
/// 컬럼만 갱신하므로 region_* 컬럼을 건드리지 않는다(반대도 마찬가지).
class DemographicsRemoteDataSource {
  const DemographicsRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>?> fetchMine() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    return await _client.from('users').select().eq('id', userId).maybeSingle();
  }

  Future<void> upsertMine({required int age, required String gender}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AuthException('로그인이 필요해요.');
    }
    await _client.from('users').upsert({
      'id': userId,
      'age': age,
      'gender': gender,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
```

- [ ] **Step 4: model 작성**

`apps/senior/lib/core/demographics/data/models/demographics_model.dart`:

```dart
import '../../domain/entities/demographics.dart';

/// DTO for a `users` row's age/gender columns. `fromRow`는 둘 다 없으면
/// `null`(완전 미입력)을 반환한다 — `RegionModel.fromRow`와 동일한 원칙.
class DemographicsModel {
  const DemographicsModel({required this.age, required this.gender});

  final int? age;
  final Gender? gender;

  static DemographicsModel? fromRow(Map<String, dynamic>? row) {
    if (row == null) return null;
    final age = row['age'] as int?;
    final gender = Gender.fromValue(row['gender'] as String?);
    if (age == null && gender == null) return null;
    return DemographicsModel(age: age, gender: gender);
  }

  Demographics toEntity() => Demographics(age: age, gender: gender);
}
```

- [ ] **Step 5: repository impl 작성**

`apps/senior/lib/core/demographics/data/repositories/demographics_repository_impl.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/demographics.dart';
import '../../domain/repositories/demographics_repository.dart';
import '../datasources/demographics_remote_datasource.dart';
import '../models/demographics_model.dart';

/// `RegionRepositoryImpl`과 동일한 예외→Failure 매핑 패턴(api.md).
class DemographicsRepositoryImpl implements DemographicsRepository {
  const DemographicsRepositoryImpl(this._dataSource);

  final DemographicsRemoteDataSource _dataSource;

  @override
  Future<Result<Demographics?>> getMyDemographics() async {
    try {
      final row = await _dataSource.fetchMine();
      return Ok(DemographicsModel.fromRow(row)?.toEntity());
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<void>> saveDemographics(Demographics demographics) async {
    try {
      await _dataSource.upsertMine(
        age: demographics.age!,
        gender: demographics.gender!.value,
      );
      return const Ok(null);
    } on PostgrestException catch (e) {
      return Err(_mapPostgrestException(e));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  Failure _mapPostgrestException(PostgrestException e) {
    if (e.code == 'PGRST301' || e.code == '42501') {
      return const AuthFailure();
    }
    return const ServerFailure();
  }
}
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/core/demographics/data/repositories/demographics_repository_impl_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 7: Commit**

```bash
git add apps/senior/lib/core/demographics/data apps/senior/test/core/demographics/data
git commit -m "feat(demographics): add data layer (datasource, model, repository impl)"
```

---

### Task 4: `core/demographics` presentation — DI + AsyncNotifier

**Files:**
- Create: `apps/senior/lib/core/demographics/presentation/providers/demographics_di_providers.dart`
- Create: `apps/senior/lib/core/demographics/presentation/providers/demographics_provider.dart`
- Test: `apps/senior/test/core/demographics/presentation/providers/demographics_provider_test.dart`

**Interfaces:**
- Consumes: Task 2/3의 모든 클래스, `apps/senior/lib/core/auth/supabase_client_provider.dart`의 `supabaseClientProvider`.
- Produces: `demographicsRepositoryProvider`(`Provider<DemographicsRepository>`), `demographicsProvider`(`AsyncNotifierProvider<DemographicsNotifier, Demographics?>`, `.save(Demographics)` 메서드 포함). Task 5(profile_page)와 Task 10(features/info notifier)이 이 두 provider를 그대로 watch/read한다.

- [ ] **Step 1: 실패하는 테스트 작성**

`apps/senior/test/core/demographics/presentation/providers/demographics_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_provider.dart';

import '../../domain/fakes/fake_demographics_repository.dart';

void main() {
  test('저장 성공 후에는 요청 값을 그대로 믿지 않고 서버에서 다시 조회한다(저장 후 재조회)', () async {
    final repository = FakeDemographicsRepository();
    repository.getMyDemographicsResult = const Ok(null);
    final container = ProviderContainer(
      overrides: [
        demographicsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(demographicsProvider.future);
    expect(repository.getMyDemographicsCalls, 1);

    const demographics = Demographics(age: 72, gender: Gender.female);
    repository.getMyDemographicsResult = const Ok(demographics);

    final result = await container
        .read(demographicsProvider.notifier)
        .save(demographics);

    expect(result, isA<Ok<void>>());
    expect(repository.saveCalls, 1);
    expect(repository.getMyDemographicsCalls, greaterThanOrEqualTo(2));
    expect(container.read(demographicsProvider).value, demographics);
  });

  test('저장 실패 시에는 재조회하지 않는다', () async {
    final repository = FakeDemographicsRepository();
    repository.getMyDemographicsResult = const Ok(null);
    repository.saveDemographicsResult = const Err(ServerFailure());
    final container = ProviderContainer(
      overrides: [
        demographicsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(demographicsProvider.future);
    final callsAfterInitialLoad = repository.getMyDemographicsCalls;

    const demographics = Demographics(age: 72, gender: Gender.female);
    final result = await container
        .read(demographicsProvider.notifier)
        .save(demographics);

    expect(result, isA<Err<void>>());
    expect(repository.getMyDemographicsCalls, callsAfterInitialLoad);
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/core/demographics/presentation/providers/demographics_provider_test.dart`
Expected: FAIL (provider 파일 없음)

- [ ] **Step 3: DI providers 작성**

`apps/senior/lib/core/demographics/presentation/providers/demographics_di_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/supabase_client_provider.dart';
import '../../data/datasources/demographics_remote_datasource.dart';
import '../../data/repositories/demographics_repository_impl.dart';
import '../../domain/repositories/demographics_repository.dart';
import '../../domain/usecases/get_my_demographics_usecase.dart';
import '../../domain/usecases/save_demographics_usecase.dart';

final demographicsRemoteDataSourceProvider = Provider(
  (ref) => DemographicsRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final demographicsRepositoryProvider = Provider<DemographicsRepository>((ref) {
  return DemographicsRepositoryImpl(
    ref.watch(demographicsRemoteDataSourceProvider),
  );
});

final getMyDemographicsUseCaseProvider = Provider(
  (ref) => GetMyDemographicsUseCase(ref.watch(demographicsRepositoryProvider)),
);

final saveDemographicsUseCaseProvider = Provider(
  (ref) => SaveDemographicsUseCase(ref.watch(demographicsRepositoryProvider)),
);
```

- [ ] **Step 4: AsyncNotifier 작성**

`apps/senior/lib/core/demographics/presentation/providers/demographics_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/demographics.dart';
import 'demographics_di_providers.dart';

/// `RegionNotifier`와 동일한 패턴 — 저장 후 요청 값을 그대로 믿지 않고
/// 서버에서 다시 조회한다.
class DemographicsNotifier extends AsyncNotifier<Demographics?> {
  @override
  Future<Demographics?> build() async {
    final result = await ref.read(getMyDemographicsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  Future<Result<void>> save(Demographics demographics) async {
    final result = await ref
        .read(saveDemographicsUseCaseProvider)
        .call(demographics);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final demographicsProvider =
    AsyncNotifierProvider<DemographicsNotifier, Demographics?>(
      DemographicsNotifier.new,
    );
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/core/demographics/presentation/providers/demographics_provider_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 6: Commit**

```bash
git add apps/senior/lib/core/demographics/presentation apps/senior/test/core/demographics/presentation
git commit -m "feat(demographics): add DI providers and AsyncNotifier"
```

---

### Task 5: `profile_page.dart` — 성별 선택 UI + 실제 저장 연결

**Files:**
- Modify: `apps/senior/lib/features/profile/presentation/pages/profile_page.dart`
- Modify: `apps/senior/test/features/profile/presentation/pages/profile_page_test.dart`

**Interfaces:**
- Consumes: Task 4의 `demographicsProvider`, Task 2의 `Demographics`/`Gender`.
- Produces: 변경 없음(같은 `ProfilePage` 위젯) — Task 11의 `info_tab_page.dart`가 "내 정보 입력하기" CTA에서 계속 이 페이지로 이동한다.

- [ ] **Step 1: 실패하는 테스트 추가**

`apps/senior/test/features/profile/presentation/pages/profile_page_test.dart` 전체를 아래로 교체한다(기존 지역 관련 3개 테스트는 그대로 유지하고 `demographicsRepositoryProvider` override와 신규 테스트 3개를 추가):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/pages/profile_page.dart';
import 'package:ondam_senior/features/profile/presentation/pages/region_input_page.dart';

import '../../../../core/demographics/domain/fakes/fake_demographics_repository.dart';
import '../../../../core/location/domain/fakes/fake_location_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeDemographicsRepository demographicsRepository;

  setUp(() {
    regionRepository = FakeRegionRepository();
    demographicsRepository = FakeDemographicsRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        locationRepositoryProvider.overrideWithValue(FakeLocationRepository()),
        demographicsRepositoryProvider.overrideWithValue(demographicsRepository),
      ],
      child: const MaterialApp(home: ProfilePage()),
    );
  }

  testWidgets('저장된 지역이 없으면 정직하게 미등록 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('아직 등록하지 않았어요'), findsOneWidget);
  });

  testWidgets('저장된 지역이 있으면 그대로 표시한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(
      Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서울특별시 강남구 역삼동'), findsOneWidget);
  });

  testWidgets('"내 지역 입력하기"를 누르면 지역 입력 화면으로 이동한다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('내 지역 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(RegionInputPage), findsOneWidget);
  });

  testWidgets('저장된 나이/성별이 있으면 화면에 미리 채워진다', (tester) async {
    demographicsRepository.getMyDemographicsResult = const Ok(
      Demographics(age: 72, gender: Gender.female),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('72'), findsOneWidget);
  });

  testWidgets('나이 입력 + 성별 선택 후 저장하면 실제로 저장을 요청한다', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), '72');
    await tester.tap(find.text('남성'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(demographicsRepository.saveCalls, 1);
    expect(demographicsRepository.savedDemographics?.age, 72);
    expect(demographicsRepository.savedDemographics?.gender, Gender.male);
    expect(find.text('내 정보가 저장되었어요.'), findsOneWidget);
  });

  testWidgets('저장이 실패하면 에러 메시지를 보여준다', (tester) async {
    demographicsRepository.saveDemographicsResult = const Err(
      ServerFailure('서버에 문제가 발생했습니다.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('남성'));
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('서버에 문제가 발생했습니다.'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: FAIL (신규 3개 테스트 — `demographicsRepositoryProvider` 미존재로 컴파일 오류는 없지만("Task 4에서 이미 존재") 성별 UI/저장 로직이 없어 "남성" 텍스트를 찾지 못하고 실패)

- [ ] **Step 3: `profile_page.dart` 전체 교체**

`apps/senior/lib/features/profile/presentation/pages/profile_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/demographics/presentation/providers/demographics_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import 'region_input_page.dart';

/// 내 정보 — 나이/성별은 ONDAM 2.0 "정보" 탭의 맞춤 혜택 정보 검색 조건으로
/// 쓰이며, `core/demographics`의 공유 `demographicsProvider`를 통해 실제로
/// 저장/조회된다. 내 지역은 이미 실제로 저장/조회되는 흐름으로 연결돼
/// 있었다(요구사항 31/32) — `core/location`의 공유 `regionProvider`를 그대로
/// 구독한다.
class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  Gender? _gender;

  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromSaved());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _seedFromSaved() {
    final saved = ref.read(demographicsProvider).value;
    if (saved == null || !mounted) return;
    setState(() {
      if (saved.age != null) _ageController.text = saved.age.toString();
      _gender = saved.gender;
    });
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text.trim());
    final demographics = Demographics(age: age, gender: _gender);
    setState(() {
      _saving = true;
      _saveError = null;
    });

    final result = await ref
        .read(demographicsProvider.notifier)
        .save(demographics);
    if (!mounted) return;

    switch (result) {
      case Ok():
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('내 정보가 저장되었어요.')));
      case Err(:final failure):
        setState(() {
          _saving = false;
          _saveError = failure.message;
        });
    }
  }

  void _openRegionInput() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegionInputPage()));
  }

  @override
  Widget build(BuildContext context) {
    final regionAsync = ref.watch(regionProvider);

    return AppScaffold(
      title: '내 정보',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: '이름', controller: _nameController),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: '나이',
            controller: _ageController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('성별', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _GenderOption(
                  label: '남성',
                  selected: _gender == Gender.male,
                  onTap: () => setState(() => _gender = Gender.male),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _GenderOption(
                  label: '여성',
                  selected: _gender == Gender.female,
                  onTap: () => setState(() => _gender = Gender.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text('내 지역', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: regionAsync.when(
              loading: () => const AppLoading(),
              error: (_, _) => const Text(
                '지역 정보를 불러오지 못했어요.',
                style: AppTextStyles.bodyMedium,
              ),
              data: (region) => AppInfoRow(
                label: '현재 지역',
                value: region?.displayName ?? '아직 등록하지 않았어요',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton(
            label: '내 지역 입력하기',
            size: AppButtonSize.large,
            onPressed: _openRegionInput,
          ),
          const SizedBox(height: AppSpacing.xxl),
          AppButton(
            label: '저장',
            isLoading: _saving,
            size: AppButtonSize.large,
            onPressed: _saving ? null : _save,
          ),
          if (_saveError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _saveError!,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}

/// 성별 2지선다 — 디자인 시스템에 segmented control이 없어 이 화면
/// 전용으로 작은 토글 위젯을 둔다(`region_input_page.dart`의
/// `_SidoPickerSheet`와 동일하게, 재사용이 실제로 필요해지기 전까지는
/// feature-local로 둔다).
class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyLarge.copyWith(
              color: selected ? AppColors.primary : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/features/profile/presentation/pages/profile_page_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add apps/senior/lib/features/profile/presentation/pages/profile_page.dart apps/senior/test/features/profile/presentation/pages/profile_page_test.dart
git commit -m "feat(profile): wire up age/gender save and add gender selector UI"
```

---

### Task 6: Edge Function `search-benefit-services`

**Files:**
- Create: `supabase/functions/search-benefit-services/benefit_service_client.ts`
- Create: `supabase/functions/search-benefit-services/benefit_service_client.test.ts`
- Create: `supabase/functions/search-benefit-services/index.ts`

**Interfaces:**
- Produces: `POST search-benefit-services` — 요청 `{ age: number, gender: 'male'|'female', region: { sido, sigungu } }`, 응답 `{ ok: true, results: Array<{ id, source: 'local'|'central', title, summary }> }` 또는 `{ ok: false, reason }`. Task 9(`BenefitServiceRemoteDataSource`)가 이 계약을 그대로 호출한다.

**중요(정직하게 명시)**: 공공데이터포털 SWAGGER 문서는 로그인 없이 열람할 수 없어, 아래 필드명/엔드포인트는 이 API 계열(한국사회보장정보원 복지서비스 Open API)에 대한 **최선 추정 초안**이다 — `welfare_center_client.ts`가 PHASE 26(초안) → PHASE 35(실제 서비스키로 라이브 검증 후 수정)를 거친 것과 동일한 상황이다. 이 Task는 PHASE 26에 해당한다. 성별은 업스트림 API가 실제로 지원하는지 확인되지 않아 업스트림 요청에는 보내지 않는다(요청 바디에는 받되 현재는 미사용) — 지역 필터도 100% 신뢰할 수 있는 필드가 없어(지자체 API만 `ctpvNm`/`sggNm` 추정 필드로 느슨하게 시도) 결과가 비지 않도록 안전하게 처리한다.

- [ ] **Step 1: 순수 로직 파일 작성**

`supabase/functions/search-benefit-services/benefit_service_client.ts`:

```ts
// Pure validation/request-building/response-parsing logic for
// `search-benefit-services`, split out of `index.ts` for the same reason as
// `welfare_center_client.ts` — unit-testable without triggering
// `Deno.serve()`'s side effect.
//
// Data source: 공공데이터포털(data.go.kr) 한국사회보장정보원_지자체복지서비스
// (dataset 15108347) + 한국사회보장정보원_중앙부처복지서비스(dataset
// 15090532) Open API. 공식 페이지에서 "목록조회/상세조회 2개 오퍼레이션"
// 이라는 것만 확인했고, 로그인 없이는 SWAGGER 문서를 볼 수 없어 정확한
// 요청/응답 필드명은 확인하지 못했다 — 아래 필드명은 이 API 계열에 대한
// **최선 추정 초안**이다. welfare_center_client.ts의 PHASE 26→35와 동일하게,
// 실제 서비스키로 라이브 검증한 뒤 필드명을 교정해야 한다(ponytail: 검증
// 전까지는 최선 추정치 — 라이브 검증은 서비스키 발급 후 진행).
//
// 지역 필터: 지자체 API 항목에는 관할 시/도·시/군/구 필드(추정: ctpvNm/
// sggNm)가 있을 것으로 보고 시도하되, 없거나 매치 실패해도 항목 자체를
// 버리지 않는다(welfare_center의 "완전일치만 지원, 대체 파라미터 거부"
// 사례처럼 검증 전 지역 필터를 과신하지 않기 위함 — 결과가 조용히 0건이
// 되는 상황을 피한다). 중앙부처 API 항목은 전국 대상이라 지역 필드가 아예
// 없을 것으로 보고 필터하지 않는다.

export const LOCAL_GOV_ENDPOINT =
  "https://apis.data.go.kr/B554287/LocalGovernmentWelfareInformations/WlfareInfoOpenAPI";
export const CENTRAL_GOV_ENDPOINT =
  "https://apis.data.go.kr/B554287/NationalWelfareInformations/wlfareInfo";

export type RegionQuery = { sido: string; sigungu: string };

export type SearchRequest = {
  age: number;
  gender: "male" | "female";
  region: RegionQuery;
};

export type BenefitServiceDto = {
  id: string;
  title: string;
  summary: string;
};

export function validateSearchBody(
  raw: unknown,
): { ok: true; value: SearchRequest } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const obj = raw as Record<string, unknown>;
  const age = typeof obj.age === "number" ? obj.age : NaN;
  const gender = obj.gender;
  const region = obj.region;

  if (!Number.isFinite(age) || age <= 0 || age > 120) {
    return { ok: false, reason: "invalid_request" };
  }
  if (gender !== "male" && gender !== "female") {
    return { ok: false, reason: "invalid_request" };
  }
  if (region === null || typeof region !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const regionObj = region as Record<string, unknown>;
  const sido = typeof regionObj.sido === "string" ? regionObj.sido.trim() : "";
  const sigungu = typeof regionObj.sigungu === "string"
    ? regionObj.sigungu.trim()
    : "";
  if (sido.length === 0 || sigungu.length === 0) {
    return { ok: false, reason: "invalid_request" };
  }
  return { ok: true, value: { age, gender, region: { sido, sigungu } } };
}

// 65세를 경계로 "노년"/그 외 성인 생애주기로만 나눈다 — 이 앱의 사용자층
// (어르신)에서 의미 있는 경계는 사실상 이것뿐이라, 전체 생애주기 코드
// 표를 다 추정해서 틀리기보다 가장 확신 있는 경계 하나만 쓴다.
export function lifeStageCodeForAge(age: number): string {
  return age >= 65 ? "006" : "005";
}

export function buildRequestUrl(
  endpoint: string,
  serviceKey: string,
  pageNo: number,
  age: number,
): string {
  const url = new URL(endpoint);
  url.searchParams.set("serviceKey", serviceKey);
  url.searchParams.set("callTp", "list");
  url.searchParams.set("pageNo", String(pageNo));
  url.searchParams.set("numOfRows", "500");
  url.searchParams.set("lifeArray", lifeStageCodeForAge(age));
  return url.toString();
}

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

type RawItem = Record<string, unknown>;

function mapItem(raw: RawItem): BenefitServiceDto | null {
  const id = asTrimmedStringOrNull(raw.servId);
  const title = asTrimmedStringOrNull(raw.servNm);
  // id/제목 중 하나라도 없으면 목록에 의미 있게 표시할 수 없다 — 존재하지
  // 않는 혜택을 지어내지 않고 이 항목만 건너뛴다(welfare_center와 동일).
  if (id === null || title === null) return null;
  const summary = asTrimmedStringOrNull(raw.servDgst) ??
    asTrimmedStringOrNull(raw.aplyMtdNm) ?? "";
  return { id, title, summary };
}

// welfare_center와 같은 계열(한국사회보장정보원) API라 동일한 header/body
// 구조(response 래퍼 없음, resultCode "03"=결과없음)를 가정한다 — 확인
// 전까지는 최선 추정치(파일 상단 주석 참고).
export function parseSearchResponse(
  raw: unknown,
): { ok: true; value: BenefitServiceDto[] } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const { header, body } = raw as Record<string, unknown>;
  const resultCode = header !== null && typeof header === "object"
    ? (header as Record<string, unknown>).resultCode
    : undefined;

  if (resultCode === "03") return { ok: true, value: [] };
  if (resultCode !== "00" && resultCode !== "0") {
    return { ok: false, reason: "upstream_error" };
  }
  if (body === null || typeof body !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const items = (body as Record<string, unknown>).items;
  if (items === "" || items === null || items === undefined) {
    return { ok: true, value: [] };
  }
  if (typeof items !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const rawItem = (items as Record<string, unknown>).item;
  if (rawItem === undefined || rawItem === "" || rawItem === null) {
    return { ok: true, value: [] };
  }
  const rawList: unknown[] = Array.isArray(rawItem) ? rawItem : [rawItem];
  const results: BenefitServiceDto[] = [];
  for (const entry of rawList) {
    if (entry === null || typeof entry !== "object") continue;
    const mapped = mapItem(entry as RawItem);
    if (mapped !== null) results.push(mapped);
  }
  return { ok: true, value: results };
}
```

- [ ] **Step 2: 순수 로직 테스트 작성**

`supabase/functions/search-benefit-services/benefit_service_client.test.ts`:

```ts
// NOT AVAILABLE: not executed in this environment (no Deno CLI — same as
// welfare_center_client.test.ts). Provided as a best-effort artifact for
// review/future execution.
//
// 이 파일이 검증하는 필드명 자체가 benefit_service_client.ts 상단 주석에
// 적힌 대로 "미확인 초안"이다 — 실제 서비스키로 라이브 검증한 뒤 필드명이
// 바뀌면 이 테스트도 welfare_center_client.test.ts의 PHASE 35 사례처럼
// 함께 갱신해야 한다.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildRequestUrl,
  lifeStageCodeForAge,
  parseSearchResponse,
  validateSearchBody,
} from "./benefit_service_client.ts";

// --- validateSearchBody ------------------------------------------------------

Deno.test("validateSearchBody: 나이/성별/지역이 모두 있으면 통과한다", () => {
  const result = validateSearchBody({
    age: 72,
    gender: "female",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, true);
});

Deno.test("validateSearchBody: 나이가 범위를 벗어나면 invalid_request", () => {
  const result = validateSearchBody({
    age: 0,
    gender: "female",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "invalid_request");
});

Deno.test("validateSearchBody: 성별이 male/female이 아니면 invalid_request", () => {
  const result = validateSearchBody({
    age: 72,
    gender: "unknown",
    region: { sido: "서울특별시", sigungu: "강남구" },
  });
  assertEquals(result.ok, false);
});

Deno.test("validateSearchBody: 지역이 없으면 invalid_request", () => {
  const result = validateSearchBody({ age: 72, gender: "female" });
  assertEquals(result.ok, false);
});

// --- lifeStageCodeForAge ------------------------------------------------------

Deno.test("lifeStageCodeForAge: 65세 미만은 005, 65세 이상은 006", () => {
  assertEquals(lifeStageCodeForAge(64), "005");
  assertEquals(lifeStageCodeForAge(65), "006");
});

// --- buildRequestUrl -----------------------------------------------------------

Deno.test("buildRequestUrl: 서비스키/생애주기코드/페이지 번호를 담는다", () => {
  const url = buildRequestUrl("https://example.com/api", "test-key", 2, 70);
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("callTp"), "list");
  assertEquals(parsed.searchParams.get("pageNo"), "2");
  assertEquals(parsed.searchParams.get("lifeArray"), "006");
});

// --- parseSearchResponse ---------------------------------------------------------

function envelope(body: unknown, resultCode = "00") {
  return { header: { resultCode }, body };
}

Deno.test("정상 검색: 배열 결과를 그대로 매핑한다", () => {
  const raw = envelope({
    items: {
      item: [
        { servId: "WLF001", servNm: "기초연금", servDgst: "만 65세 이상 지원" },
      ],
    },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: unknown[] }).value;
  assertEquals(value.length, 1);
  assertEquals((value[0] as { title: string }).title, "기초연금");
});

Deno.test("정상 검색: 단건 결과는 item이 배열이 아니라 객체로 와도 처리한다", () => {
  const raw = envelope({
    items: { item: { servId: "WLF002", servNm: "무료 건강검진" } },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value.length, 1);
});

Deno.test("결과 없음: resultCode 03은 오류가 아니라 빈 목록이다", () => {
  const raw = { header: { resultCode: "03" }, body: null };
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown[] }).value, []);
});

Deno.test("API 오류: resultCode가 00/03이 아니면 upstream_error", () => {
  const raw = envelope({ items: "" }, "99");
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "upstream_error");
});

Deno.test("잘못된 데이터: id/제목이 둘 다 없는 항목은 지어내지 않고 건너뛴다", () => {
  const raw = envelope({
    items: {
      item: [
        { servDgst: "이름 없는 항목" },
        { servId: "WLF003", servNm: "정상 항목" },
      ],
    },
  });
  const result = parseSearchResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as { value: { title: string }[] }).value;
  assertEquals(value.length, 1);
  assertEquals(value[0].title, "정상 항목");
});

Deno.test("잘못된 데이터: raw 자체가 객체가 아니면 upstream_invalid_response", () => {
  const result = parseSearchResponse("not an object");
  assertEquals(result.ok, false);
  assertEquals(
    (result as { reason: string }).reason,
    "upstream_invalid_response",
  );
});
```

- [ ] **Step 3: 테스트 실행 시도(NOT AVAILABLE 확인)**

Run: `deno test supabase/functions/search-benefit-services/benefit_service_client.test.ts`
Expected: **NOT AVAILABLE** — 이 환경에 Deno CLI가 없다(`welfare_center_client.test.ts`와 동일). 코드 리뷰로 로직을 재확인하고 다음 단계로 진행한다.

- [ ] **Step 4: `index.ts` 작성**

`supabase/functions/search-benefit-services/index.ts`:

```ts
import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  BenefitServiceDto,
  buildRequestUrl,
  CENTRAL_GOV_ENDPOINT,
  LOCAL_GOV_ENDPOINT,
  parseSearchResponse,
  validateSearchBody,
} from "./benefit_service_client.ts";

// ONDAM 2.0 — 나이/성별/지역 기반 맞춤 혜택 정보(정보 탭). 서버 측에서만
// data.go.kr을 호출한다(서비스키 비노출, search-welfare-centers와 동일
// 이유). 지자체+중앙부처 두 데이터셋을 병렬로 조회해 합친다.

const REQUEST_TIMEOUT_MS = 10000;
const MAX_PAGES_PER_SOURCE = 5;
const TARGET_RESULT_COUNT = 30;

type Source = "local" | "central";

async function fetchPage(
  endpoint: string,
  serviceKey: string,
  pageNo: number,
  age: number,
  source: Source,
): Promise<
  { ok: true; value: BenefitServiceDto[] } | { ok: false; reason: string }
> {
  const url = buildRequestUrl(endpoint, serviceKey, pageNo, age);
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);

  let response: Response;
  try {
    response = await fetch(url, { signal: controller.signal });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return { ok: false, reason: "upstream_timeout" };
    }
    console.error(`search-benefit-services: fetch to ${source} threw`, e);
    return { ok: false, reason: "upstream_error" };
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `search-benefit-services: ${source} responded ${response.status}`,
      errorBody.slice(0, 500),
    );
    return { ok: false, reason: "upstream_error" };
  }

  let rawJson: unknown;
  try {
    rawJson = await response.json();
  } catch {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  return parseSearchResponse(rawJson);
}

async function fetchSource(
  endpoint: string,
  serviceKey: string,
  age: number,
  source: Source,
): Promise<Array<BenefitServiceDto & { source: Source }>> {
  const collected: Array<BenefitServiceDto & { source: Source }> = [];
  for (let pageNo = 1; pageNo <= MAX_PAGES_PER_SOURCE; pageNo++) {
    const page = await fetchPage(endpoint, serviceKey, pageNo, age, source);
    // 한 소스가 실패해도 다른 소스 결과는 정직하게 반환한다 — 이미 찾은
    // 결과가 있으면 그대로 두고, 없으면 이 소스는 빈 목록으로 취급한다.
    if (!page.ok) break;
    if (page.value.length === 0) break;
    collected.push(...page.value.map((item) => ({ ...item, source })));
    if (collected.length >= TARGET_RESULT_COUNT) break;
  }
  return collected;
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const caller = await verifyCaller(req);
  if ("error" in caller) {
    return json({ ok: false, reason: caller.error }, 401);
  }

  const body = await req.json().catch(() => null);
  const validated = validateSearchBody(body);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }

  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const { age } = validated.value;
  const [local, central] = await Promise.all([
    fetchSource(LOCAL_GOV_ENDPOINT, serviceKey, age, "local"),
    fetchSource(CENTRAL_GOV_ENDPOINT, serviceKey, age, "central"),
  ]);

  return json({ ok: true, results: [...local, ...central] });
});
```

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/search-benefit-services
git commit -m "feat(edge-function): add search-benefit-services (draft, pending live verification)"
```

---

### Task 7: Edge Function `get-benefit-service-detail`

**Files:**
- Create: `supabase/functions/get-benefit-service-detail/benefit_service_detail_client.ts`
- Create: `supabase/functions/get-benefit-service-detail/benefit_service_detail_client.test.ts`
- Create: `supabase/functions/get-benefit-service-detail/index.ts`

**Interfaces:**
- Consumes: Task 6과 동일한 두 엔드포인트(상세조회 오퍼레이션).
- Produces: `POST get-benefit-service-detail` — 요청 `{ id: string, source: 'local'|'central' }`, 응답 `{ ok: true, result: { id, title, summary, supportTarget, applyMethod, contact, externalUrl } }` 또는 `{ ok: false, reason }`(`reason: 'not_found'` 포함). Task 9가 이 계약을 그대로 호출한다.

- [ ] **Step 1: 순수 로직 파일 작성**

`supabase/functions/get-benefit-service-detail/benefit_service_detail_client.ts`:

```ts
// benefit_service_client.ts 상단 주석과 동일한 이유로, 상세조회 오퍼레이션
// 파라미터명도 미확인 초안이다. 목록 응답의 servId를 상세조회 키로 그대로
// 쓴다고 가정한다(이 API 계열의 일반적인 패턴).

export const LOCAL_GOV_DETAIL_ENDPOINT =
  "https://apis.data.go.kr/B554287/LocalGovernmentWelfareInformations/WlfareInfoOpenAPI";
export const CENTRAL_GOV_DETAIL_ENDPOINT =
  "https://apis.data.go.kr/B554287/NationalWelfareInformations/wlfareInfo";

export type Source = "local" | "central";

export type DetailRequest = { id: string; source: Source };

export type BenefitServiceDetailDto = {
  title: string;
  summary: string;
  supportTarget: string | null;
  applyMethod: string | null;
  contact: string | null;
  externalUrl: string | null;
};

export function validateDetailBody(
  raw: unknown,
): { ok: true; value: DetailRequest } | { ok: false; reason: string } {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "invalid_request" };
  }
  const obj = raw as Record<string, unknown>;
  const id = typeof obj.id === "string" ? obj.id.trim() : "";
  const source = obj.source;
  if (id.length === 0) return { ok: false, reason: "invalid_request" };
  if (source !== "local" && source !== "central") {
    return { ok: false, reason: "invalid_request" };
  }
  return { ok: true, value: { id, source } };
}

export function buildDetailRequestUrl(
  endpoint: string,
  serviceKey: string,
  id: string,
): string {
  const url = new URL(endpoint);
  url.searchParams.set("serviceKey", serviceKey);
  url.searchParams.set("callTp", "d");
  url.searchParams.set("servId", id);
  return url.toString();
}

function asTrimmedStringOrNull(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length === 0 ? null : trimmed;
}

function mapDetailItem(
  raw: Record<string, unknown>,
): BenefitServiceDetailDto | null {
  const title = asTrimmedStringOrNull(raw.servNm);
  // 제목이 없으면 존재하지 않는 혜택을 지어내지 않고 null을 반환한다 —
  // index.ts가 이를 "not_found"로 취급한다.
  if (title === null) return null;
  return {
    title,
    summary: asTrimmedStringOrNull(raw.servDgst) ?? "",
    supportTarget: asTrimmedStringOrNull(raw.slctCritCn),
    applyMethod: asTrimmedStringOrNull(raw.aplyMtdCn) ??
      asTrimmedStringOrNull(raw.aplyMtdNm),
    contact: asTrimmedStringOrNull(raw.rprsCtadr),
    // 이 API에 외부 링크 필드가 있는지 확인되지 않아 항상 null — 지어내지
    // 않는다. 라이브 검증 후 실제 필드가 확인되면 연결한다.
    externalUrl: null,
  };
}

export function parseDetailResponse(
  raw: unknown,
): { ok: true; value: BenefitServiceDetailDto | null } | {
  ok: false;
  reason: string;
} {
  if (raw === null || typeof raw !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const { header, body } = raw as Record<string, unknown>;
  const resultCode = header !== null && typeof header === "object"
    ? (header as Record<string, unknown>).resultCode
    : undefined;

  if (resultCode === "03") return { ok: true, value: null };
  if (resultCode !== "00" && resultCode !== "0") {
    return { ok: false, reason: "upstream_error" };
  }
  if (body === null || typeof body !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const items = (body as Record<string, unknown>).items;
  if (items === "" || items === null || items === undefined) {
    return { ok: true, value: null };
  }
  if (typeof items !== "object") {
    return { ok: false, reason: "upstream_invalid_response" };
  }
  const rawItem = (items as Record<string, unknown>).item;
  if (rawItem === undefined || rawItem === "" || rawItem === null) {
    return { ok: true, value: null };
  }
  const first = Array.isArray(rawItem) ? rawItem[0] : rawItem;
  if (first === null || typeof first !== "object") {
    return { ok: true, value: null };
  }
  return { ok: true, value: mapDetailItem(first as Record<string, unknown>) };
}
```

- [ ] **Step 2: 순수 로직 테스트 작성**

`supabase/functions/get-benefit-service-detail/benefit_service_detail_client.test.ts`:

```ts
// NOT AVAILABLE: not executed in this environment (no Deno CLI). See
// benefit_service_client.test.ts 상단 주석과 동일한 이유.

import { assertEquals } from "jsr:@std/assert@1";
import {
  buildDetailRequestUrl,
  parseDetailResponse,
  validateDetailBody,
} from "./benefit_service_detail_client.ts";

Deno.test("validateDetailBody: id/source가 모두 있으면 통과한다", () => {
  const result = validateDetailBody({ id: "WLF001", source: "local" });
  assertEquals(result.ok, true);
});

Deno.test("validateDetailBody: source가 local/central이 아니면 invalid_request", () => {
  const result = validateDetailBody({ id: "WLF001", source: "unknown" });
  assertEquals(result.ok, false);
});

Deno.test("validateDetailBody: id가 비어 있으면 invalid_request", () => {
  const result = validateDetailBody({ id: "", source: "local" });
  assertEquals(result.ok, false);
});

Deno.test("buildDetailRequestUrl: 서비스키/servId를 담는다", () => {
  const url = buildDetailRequestUrl(
    "https://example.com/api",
    "test-key",
    "WLF001",
  );
  const parsed = new URL(url);
  assertEquals(parsed.searchParams.get("serviceKey"), "test-key");
  assertEquals(parsed.searchParams.get("callTp"), "d");
  assertEquals(parsed.searchParams.get("servId"), "WLF001");
});

function envelope(body: unknown, resultCode = "00") {
  return { header: { resultCode }, body };
}

Deno.test("정상 상세: 단건 객체를 매핑한다", () => {
  const raw = envelope({
    items: {
      item: {
        servNm: "기초연금",
        servDgst: "만 65세 이상 지원",
        slctCritCn: "소득 하위 70%",
        aplyMtdCn: "주민센터 방문 신청",
        rprsCtadr: "129",
      },
    },
  });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  const value = (result as {
    value: { title: string; supportTarget: string | null } | null;
  }).value;
  assertEquals(value?.title, "기초연금");
  assertEquals(value?.supportTarget, "소득 하위 70%");
});

Deno.test("정상 상세: item이 배열로 와도 첫 항목을 사용한다", () => {
  const raw = envelope({ items: { item: [{ servNm: "기초연금" }] } });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals(
    (result as { value: { title: string } | null }).value?.title,
    "기초연금",
  );
});

Deno.test("결과 없음: resultCode 03이면 오류가 아니라 null이다", () => {
  const raw = { header: { resultCode: "03" }, body: null };
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown }).value, null);
});

Deno.test("제목이 없는 항목은 지어내지 않고 null을 반환한다", () => {
  const raw = envelope({ items: { item: { servDgst: "제목 없음" } } });
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, true);
  assertEquals((result as { value: unknown }).value, null);
});

Deno.test("API 오류: resultCode가 00/03이 아니면 upstream_error", () => {
  const raw = envelope({ items: "" }, "99");
  const result = parseDetailResponse(raw);
  assertEquals(result.ok, false);
  assertEquals((result as { reason: string }).reason, "upstream_error");
});
```

- [ ] **Step 3: 테스트 실행 시도(NOT AVAILABLE 확인)**

Run: `deno test supabase/functions/get-benefit-service-detail/benefit_service_detail_client.test.ts`
Expected: **NOT AVAILABLE**(Task 6 Step 3과 동일한 이유). 코드 리뷰로 재확인 후 다음 단계로 진행한다.

- [ ] **Step 4: `index.ts` 작성**

`supabase/functions/get-benefit-service-detail/index.ts`:

```ts
import { corsHeaders } from "../_shared/cors.ts";
import { json } from "../_shared/http.ts";
import { verifyCaller } from "../_shared/auth.ts";
import {
  buildDetailRequestUrl,
  CENTRAL_GOV_DETAIL_ENDPOINT,
  LOCAL_GOV_DETAIL_ENDPOINT,
  parseDetailResponse,
  validateDetailBody,
} from "./benefit_service_detail_client.ts";

const REQUEST_TIMEOUT_MS = 10000;

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") {
    return json({ ok: false, reason: "method_not_allowed" }, 405);
  }

  const caller = await verifyCaller(req);
  if ("error" in caller) {
    return json({ ok: false, reason: caller.error }, 401);
  }

  const body = await req.json().catch(() => null);
  const validated = validateDetailBody(body);
  if (!validated.ok) {
    return json({ ok: false, reason: validated.reason }, 400);
  }

  const serviceKey = Deno.env.get("DATA_GO_KR_SERVICE_KEY")?.trim();
  if (!serviceKey) {
    return json({ ok: false, reason: "data_source_not_configured" }, 503);
  }

  const { id, source } = validated.value;
  const endpoint = source === "local"
    ? LOCAL_GOV_DETAIL_ENDPOINT
    : CENTRAL_GOV_DETAIL_ENDPOINT;
  const url = buildDetailRequestUrl(endpoint, serviceKey, id);

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
  let response: Response;
  try {
    response = await fetch(url, { signal: controller.signal });
  } catch (e) {
    clearTimeout(timeout);
    if (e instanceof DOMException && e.name === "AbortError") {
      return json({ ok: false, reason: "upstream_timeout" }, 502);
    }
    console.error("get-benefit-service-detail: fetch threw", e);
    return json({ ok: false, reason: "upstream_error" }, 502);
  }
  clearTimeout(timeout);

  if (!response.ok) {
    const errorBody = await response.text().catch(() => "<unreadable>");
    console.error(
      `get-benefit-service-detail: upstream responded ${response.status}`,
      errorBody.slice(0, 500),
    );
    return json({ ok: false, reason: "upstream_error" }, 502);
  }

  let rawJson: unknown;
  try {
    rawJson = await response.json();
  } catch {
    return json({ ok: false, reason: "upstream_invalid_response" }, 502);
  }

  const parsed = parseDetailResponse(rawJson);
  if (!parsed.ok) return json({ ok: false, reason: parsed.reason }, 502);
  if (parsed.value === null) {
    return json({ ok: false, reason: "not_found" }, 404);
  }

  return json({ ok: true, result: { id, ...parsed.value } });
});
```

- [ ] **Step 5: Commit**

```bash
git add supabase/functions/get-benefit-service-detail
git commit -m "feat(edge-function): add get-benefit-service-detail (draft, pending live verification)"
```

---

### Task 8: `features/info` domain — entities, repository interface, usecase 2개

**Files:**
- Create: `apps/senior/lib/features/info/domain/entities/benefit_service.dart`
- Create: `apps/senior/lib/features/info/domain/entities/benefit_service_detail.dart`
- Create: `apps/senior/lib/features/info/domain/repositories/benefit_service_repository.dart`
- Create: `apps/senior/lib/features/info/domain/usecases/search_benefit_services_usecase.dart`
- Create: `apps/senior/lib/features/info/domain/usecases/get_benefit_service_detail_usecase.dart`
- Test: `apps/senior/test/features/info/domain/fakes/fake_benefit_service_repository.dart`
- Test: `apps/senior/test/features/info/domain/usecases/search_benefit_services_usecase_test.dart`
- Test: `apps/senior/test/features/info/domain/usecases/get_benefit_service_detail_usecase_test.dart`

**Interfaces:**
- Consumes: Task 2의 `Demographics`/`Gender`, `apps/senior/lib/core/location/domain/entities/region.dart`의 `Region`.
- Produces: `BenefitServiceSource` enum, `BenefitService(id, source, title, summary)`, `BenefitServiceDetail(id, title, summary, supportTarget?, applyMethod?, contact?, externalUrl?)`, `BenefitServiceRepository`(`search(Demographics, Region)`/`getDetail(String, BenefitServiceSource)`), `SearchBenefitServicesUseCase.call(Demographics?, Region?)`, `GetBenefitServiceDetailUseCase.call(String, BenefitServiceSource)`. Task 9/10/11이 이 타입들을 그대로 사용한다.

- [ ] **Step 1: fake repository 작성**

`apps/senior/test/features/info/domain/fakes/fake_benefit_service_repository.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/domain/repositories/benefit_service_repository.dart';

class FakeBenefitServiceRepository implements BenefitServiceRepository {
  Result<List<BenefitService>> searchResult = const Ok([]);
  Result<BenefitServiceDetail> getDetailResult = const Err(UnknownFailure());

  Demographics? lastSearchedDemographics;
  Region? lastSearchedRegion;
  int searchCalls = 0;

  String? lastDetailId;
  BenefitServiceSource? lastDetailSource;
  int getDetailCalls = 0;

  @override
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  ) async {
    searchCalls++;
    lastSearchedDemographics = demographics;
    lastSearchedRegion = region;
    return searchResult;
  }

  @override
  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  ) async {
    getDetailCalls++;
    lastDetailId = id;
    lastDetailSource = source;
    return getDetailResult;
  }
}
```

- [ ] **Step 2: 실패하는 usecase 테스트 작성**

`apps/senior/test/features/info/domain/usecases/search_benefit_services_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/usecases/search_benefit_services_usecase.dart';

import '../fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;
  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  test('나이/성별이 없으면 검색을 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(
      const Demographics(age: null, gender: null),
      region,
    );

    expect(result, isA<Err<List<BenefitService>>>());
    expect(repository.searchCalls, 0);
  });

  test('지역이 없으면 검색을 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, null);

    expect(result, isA<Err<List<BenefitService>>>());
    expect(repository.searchCalls, 0);
  });

  test('나이/성별/지역이 모두 있으면 검색을 위임한다', () async {
    const services = [
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ];
    repository.searchResult = const Ok(services);
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect((result as Ok<List<BenefitService>>).value, services);
    expect(repository.lastSearchedDemographics, demographics);
    expect(repository.lastSearchedRegion, region);
  });

  test('결과가 없으면 빈 목록을 정직하게 반환한다', () async {
    repository.searchResult = const Ok([]);
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect((result as Ok<List<BenefitService>>).value, isEmpty);
  });

  test('검색 실패를 그대로 전달한다', () async {
    repository.searchResult = const Err(
      UnavailableFailure('맞춤 혜택 정보를 아직 제공하지 않아요.'),
    );
    final useCase = SearchBenefitServicesUseCase(repository);

    final result = await useCase(demographics, region);

    expect(
      (result as Err<List<BenefitService>>).failure,
      isA<UnavailableFailure>(),
    );
  });
}
```

`apps/senior/test/features/info/domain/usecases/get_benefit_service_detail_usecase_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/domain/usecases/get_benefit_service_detail_usecase.dart';

import '../fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  test('id가 비어 있으면 조회를 시도하지 않고 ValidationFailure를 반환한다', () async {
    final useCase = GetBenefitServiceDetailUseCase(repository);

    final result = await useCase('', BenefitServiceSource.central);

    expect(result, isA<Err<BenefitServiceDetail>>());
    expect(repository.getDetailCalls, 0);
  });

  test('id가 있으면 조회를 위임한다', () async {
    const detail = BenefitServiceDetail(
      id: 'WLF001',
      title: '기초연금',
      summary: '만 65세 이상 지원',
    );
    repository.getDetailResult = const Ok(detail);
    final useCase = GetBenefitServiceDetailUseCase(repository);

    final result = await useCase('WLF001', BenefitServiceSource.central);

    expect((result as Ok<BenefitServiceDetail>).value, detail);
    expect(repository.lastDetailId, 'WLF001');
    expect(repository.lastDetailSource, BenefitServiceSource.central);
  });
}
```

- [ ] **Step 3: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/features/info/domain/usecases/`
Expected: FAIL (엔티티/repository/usecase 파일 없음)

- [ ] **Step 4: entity 2개 작성**

`apps/senior/lib/features/info/domain/entities/benefit_service.dart`:

```dart
/// 목록 항목 — 어느 공공데이터 소스(지자체/중앙부처)에서 왔는지를
/// `source`로 들고 있어야, 상세조회 시 올바른 업스트림 엔드포인트를 고를
/// 수 있다(`get-benefit-service-detail`이 source별로 다른 엔드포인트를
/// 호출한다).
enum BenefitServiceSource {
  local('local'),
  central('central');

  const BenefitServiceSource(this.value);

  final String value;

  static BenefitServiceSource? fromValue(String? raw) => switch (raw) {
    'local' => BenefitServiceSource.local,
    'central' => BenefitServiceSource.central,
    _ => null,
  };
}

class BenefitService {
  const BenefitService({
    required this.id,
    required this.source,
    required this.title,
    required this.summary,
  });

  final String id;
  final BenefitServiceSource source;
  final String title;
  final String summary;
}
```

`apps/senior/lib/features/info/domain/entities/benefit_service_detail.dart`:

```dart
/// 상세 화면 전용 엔티티 — 목록 API가 반환하지 않는 필드(지원대상/
/// 신청방법/문의처/외부 링크)를 담는다. 업스트림 API가 해당 필드를 주지
/// 않으면 `null`(정직한 "제공하지 않음")이지, 빈 문자열을 지어내지 않는다.
class BenefitServiceDetail {
  const BenefitServiceDetail({
    required this.id,
    required this.title,
    required this.summary,
    this.supportTarget,
    this.applyMethod,
    this.contact,
    this.externalUrl,
  });

  final String id;
  final String title;
  final String summary;
  final String? supportTarget;
  final String? applyMethod;
  final String? contact;
  final String? externalUrl;
}
```

- [ ] **Step 5: repository interface 작성**

`apps/senior/lib/features/info/domain/repositories/benefit_service_repository.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../entities/benefit_service.dart';
import '../entities/benefit_service_detail.dart';

/// 나이/성별/지역 기반 맞춤 혜택 정보 검색 — `search-benefit-services`/
/// `get-benefit-service-detail` Edge Function을 호출한다. 데이터 소스가
/// 아직 설정되지 않았으면(서비스키 미등록) `UnavailableFailure`로 정직하게
/// 안내한다(`WelfareCenterRepository`와 동일한 원칙).
abstract class BenefitServiceRepository {
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  );

  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  );
}
```

- [ ] **Step 6: usecase 2개 작성**

`apps/senior/lib/features/info/domain/usecases/search_benefit_services_usecase.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../entities/benefit_service.dart';
import '../repositories/benefit_service_repository.dart';

/// 나이/성별/지역이 모두 있을 때만 검색을 시도한다 — "정보가 모두 채워졌을
/// 때만 검색" 요구사항을 usecase 레벨에서 보장한다(`SearchWelfareCentersUseCase`
/// 의 지역 검증 패턴과 동일).
class SearchBenefitServicesUseCase {
  const SearchBenefitServicesUseCase(this._repository);

  final BenefitServiceRepository _repository;

  Future<Result<List<BenefitService>>> call(
    Demographics? demographics,
    Region? region,
  ) {
    if (demographics == null || !demographics.isComplete) {
      return Future.value(
        const Err(ValidationFailure('나이와 성별을 먼저 입력해주세요.')),
      );
    }
    if (region == null) {
      return Future.value(const Err(ValidationFailure('내 지역을 먼저 등록해주세요.')));
    }
    return _repository.search(demographics, region);
  }
}
```

`apps/senior/lib/features/info/domain/usecases/get_benefit_service_detail_usecase.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';

import '../entities/benefit_service.dart';
import '../entities/benefit_service_detail.dart';
import '../repositories/benefit_service_repository.dart';

class GetBenefitServiceDetailUseCase {
  const GetBenefitServiceDetailUseCase(this._repository);

  final BenefitServiceRepository _repository;

  Future<Result<BenefitServiceDetail>> call(
    String id,
    BenefitServiceSource source,
  ) {
    if (id.trim().isEmpty) {
      return Future.value(const Err(ValidationFailure('잘못된 혜택 정보예요.')));
    }
    return _repository.getDetail(id, source);
  }
}
```

- [ ] **Step 7: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/features/info/domain/usecases/`
Expected: PASS (7 tests)

- [ ] **Step 8: Commit**

```bash
git add apps/senior/lib/features/info/domain apps/senior/test/features/info/domain
git commit -m "feat(info): add domain layer (entities, repository interface, usecases)"
```

---

### Task 9: `features/info` data — datasource, repository impl

**Files:**
- Create: `apps/senior/lib/features/info/data/datasources/benefit_service_remote_datasource.dart`
- Create: `apps/senior/lib/features/info/data/repositories/benefit_service_repository_impl.dart`
- Test: `apps/senior/test/features/info/data/repositories/benefit_service_repository_impl_test.dart`

**Interfaces:**
- Consumes: Task 8의 모든 domain 타입, Task 6/7 Edge Function 계약.
- Produces: `BenefitServiceRemoteDataSource(SupabaseClient)`(`search({age, gender, region})`/`getDetail({id, source})`), `BenefitServiceRepositoryImpl(BenefitServiceRemoteDataSource)`. `data/models/`는 만들지 않는다 — `welfare_center`가 이미 확립한 관례대로, Edge Function 응답이 이미 entity와 거의 1:1이라 Repository에서 직접 매핑한다(불필요한 DTO 계층 생략).

- [ ] **Step 1: 실패하는 테스트 작성**

`apps/senior/test/features/info/data/repositories/benefit_service_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/features/info/data/datasources/benefit_service_remote_datasource.dart';
import 'package:ondam_senior/features/info/data/repositories/benefit_service_repository_impl.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockBenefitServiceRemoteDataSource extends Mock
    implements BenefitServiceRemoteDataSource {}

void main() {
  late _MockBenefitServiceRemoteDataSource dataSource;
  late BenefitServiceRepositoryImpl repository;
  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    dataSource = _MockBenefitServiceRemoteDataSource();
    repository = BenefitServiceRepositoryImpl(dataSource);
  });

  group('search', () {
    test('정상 검색: 응답을 BenefitService 목록으로 변환한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenAnswer(
        (_) async => {
          'ok': true,
          'results': [
            {
              'id': 'WLF001',
              'source': 'central',
              'title': '기초연금',
              'summary': '만 65세 이상 지원',
            },
          ],
        },
      );

      final result = await repository.search(demographics, region);

      final value = (result as Ok<List<BenefitService>>).value;
      expect(value.length, 1);
      expect(value.first.title, '기초연금');
      expect(value.first.source, BenefitServiceSource.central);
    });

    test('데이터 소스가 아직 설정되지 않았으면 UnavailableFailure로 정직하게 안내한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenThrow(
        const FunctionException(
          status: 503,
          details: {'ok': false, 'reason': 'data_source_not_configured'},
        ),
      );

      final result = await repository.search(demographics, region);

      expect(
        (result as Err<List<BenefitService>>).failure,
        isA<UnavailableFailure>(),
      );
    });

    test('로그인되어 있지 않으면 AuthFailure로 매핑한다', () async {
      when(
        () => dataSource.search(age: 72, gender: 'female', region: region),
      ).thenThrow(const AuthException('로그인이 필요해요.'));

      final result = await repository.search(demographics, region);

      expect(
        (result as Err<List<BenefitService>>).failure,
        isA<AuthFailure>(),
      );
    });
  });

  group('getDetail', () {
    test('정상 조회: 응답을 BenefitServiceDetail로 변환한다', () async {
      when(
        () => dataSource.getDetail(id: 'WLF001', source: 'central'),
      ).thenAnswer(
        (_) async => {
          'ok': true,
          'result': {
            'id': 'WLF001',
            'title': '기초연금',
            'summary': '만 65세 이상 지원',
            'supportTarget': '소득 하위 70%',
            'applyMethod': '주민센터 방문 신청',
            'contact': '129',
            'externalUrl': null,
          },
        },
      );

      final result = await repository.getDetail(
        'WLF001',
        BenefitServiceSource.central,
      );

      final value = (result as Ok<BenefitServiceDetail>).value;
      expect(value.title, '기초연금');
      expect(value.contact, '129');
    });

    test('업스트림 오류는 ServerFailure로 매핑한다', () async {
      when(
        () => dataSource.getDetail(id: 'WLF001', source: 'central'),
      ).thenThrow(
        const FunctionException(
          status: 502,
          details: {'ok': false, 'reason': 'upstream_error'},
        ),
      );

      final result = await repository.getDetail(
        'WLF001',
        BenefitServiceSource.central,
      );

      expect(
        (result as Err<BenefitServiceDetail>).failure,
        isA<ServerFailure>(),
      );
    });
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/features/info/data/repositories/benefit_service_repository_impl_test.dart`
Expected: FAIL (구현 파일 없음)

- [ ] **Step 3: datasource 작성**

`apps/senior/lib/features/info/data/datasources/benefit_service_remote_datasource.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/location/domain/entities/region.dart';

/// `search-welfare-centers`와 동일한 invoke-and-return-raw-map 패턴.
class BenefitServiceRemoteDataSource {
  const BenefitServiceRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> search({
    required int age,
    required String gender,
    required Region region,
  }) async {
    final response = await _client.functions.invoke(
      'search-benefit-services',
      body: {
        'age': age,
        'gender': gender,
        'region': {'sido': region.sido, 'sigungu': region.sigungu},
      },
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }

  Future<Map<String, dynamic>> getDetail({
    required String id,
    required String source,
  }) async {
    final response = await _client.functions.invoke(
      'get-benefit-service-detail',
      body: {'id': id, 'source': source},
    );
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    throw FunctionException(
      status: response.status,
      details: 'Unexpected Edge Function response shape: $data',
    );
  }
}
```

- [ ] **Step 4: repository impl 작성**

`apps/senior/lib/features/info/data/repositories/benefit_service_repository_impl.dart`:

```dart
import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/demographics/domain/entities/demographics.dart';
import '../../../../core/location/domain/entities/region.dart';
import '../../domain/entities/benefit_service.dart';
import '../../domain/entities/benefit_service_detail.dart';
import '../../domain/repositories/benefit_service_repository.dart';
import '../datasources/benefit_service_remote_datasource.dart';

/// `WelfareCenterRepositoryImpl`과 동일한 예외→Failure 매핑 패턴.
class BenefitServiceRepositoryImpl implements BenefitServiceRepository {
  const BenefitServiceRepositoryImpl(this._dataSource);

  final BenefitServiceRemoteDataSource _dataSource;

  @override
  Future<Result<List<BenefitService>>> search(
    Demographics demographics,
    Region region,
  ) async {
    try {
      final data = await _dataSource.search(
        age: demographics.age!,
        gender: demographics.gender!.value,
        region: region,
      );
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      final rows = (data['results'] as List).cast<Map<String, dynamic>>();
      return Ok(rows.map(_toBenefitService).toList());
    } on FunctionException catch (e) {
      return Err(_mapReason(_reasonFrom(e)));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<BenefitServiceDetail>> getDetail(
    String id,
    BenefitServiceSource source,
  ) async {
    try {
      final data = await _dataSource.getDetail(id: id, source: source.value);
      if (data['ok'] != true) {
        return Err(_mapReason(data['reason'] as String?));
      }
      return Ok(_toBenefitServiceDetail(data['result'] as Map<String, dynamic>));
    } on FunctionException catch (e) {
      return Err(_mapReason(_reasonFrom(e)));
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  String? _reasonFrom(FunctionException e) {
    final details = e.details;
    return details is Map ? details['reason'] as String? : null;
  }

  BenefitService _toBenefitService(Map<String, dynamic> row) {
    return BenefitService(
      id: row['id'] as String,
      source: BenefitServiceSource.fromValue(row['source'] as String?) ??
          BenefitServiceSource.central,
      title: row['title'] as String,
      summary: row['summary'] as String,
    );
  }

  BenefitServiceDetail _toBenefitServiceDetail(Map<String, dynamic> row) {
    return BenefitServiceDetail(
      id: row['id'] as String,
      title: row['title'] as String,
      summary: row['summary'] as String,
      supportTarget: row['supportTarget'] as String?,
      applyMethod: row['applyMethod'] as String?,
      contact: row['contact'] as String?,
      externalUrl: row['externalUrl'] as String?,
    );
  }

  Failure _mapReason(String? reason) {
    return switch (reason) {
      'missing_authorization' || 'invalid_session' => const AuthFailure(),
      'invalid_request' => const ValidationFailure('요청 정보를 다시 확인해주세요.'),
      'not_found' => const ValidationFailure('더 이상 제공되지 않는 혜택 정보예요.'),
      'data_source_not_configured' => const UnavailableFailure(
        '맞춤 혜택 정보를 아직 제공하지 않아요.',
      ),
      'upstream_timeout' ||
      'upstream_error' ||
      'upstream_invalid_response' => const ServerFailure(),
      _ => const UnknownFailure(),
    };
  }
}
```

- [ ] **Step 5: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/features/info/data/repositories/benefit_service_repository_impl_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 6: Commit**

```bash
git add apps/senior/lib/features/info/data apps/senior/test/features/info/data
git commit -m "feat(info): add data layer (datasource, repository impl)"
```

---

### Task 10: `features/info` presentation — DI, AsyncNotifier(목록), FutureProvider.family(상세)

**Files:**
- Create: `apps/senior/lib/features/info/presentation/providers/benefit_service_di_providers.dart`
- Create: `apps/senior/lib/features/info/presentation/providers/benefit_service_notifier.dart`
- Create: `apps/senior/lib/features/info/presentation/providers/benefit_service_detail_provider.dart`

**Interfaces:**
- Consumes: Task 9의 모든 클래스, Task 4의 `demographicsProvider`, `apps/senior/lib/core/location/presentation/providers/region_provider.dart`의 `regionProvider`.
- Produces: `benefitServiceRepositoryProvider`, `benefitServiceNotifierProvider`(`AsyncNotifierProvider<BenefitServiceNotifier, List<BenefitService>?>` — 나이/성별/지역이 모두 채워지면 자동으로 검색), `benefitServiceDetailProvider`(`FutureProvider.autoDispose.family<BenefitServiceDetail, ({String id, BenefitServiceSource source})>`). Task 11의 `info_tab_page.dart`/`benefit_service_detail_page.dart`가 이 provider들을 watch한다.

이 Task는 순수 상태 관리 코드라 별도 유닛 테스트 파일을 새로 만들지 않는다 — Task 11의 위젯 테스트가 `benefitServiceNotifierProvider`의 동작(자동 검색, 에러 분기)을 실제 화면을 통해 검증한다(`welfare_center_list_page_test.dart`가 `WelfareCenterNotifier`를 별도 테스트하지 않고 위젯 테스트로만 검증한 것과 동일한 전례).

- [ ] **Step 1: DI providers 작성**

`apps/senior/lib/features/info/presentation/providers/benefit_service_di_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/benefit_service_remote_datasource.dart';
import '../../data/repositories/benefit_service_repository_impl.dart';
import '../../domain/repositories/benefit_service_repository.dart';
import '../../domain/usecases/get_benefit_service_detail_usecase.dart';
import '../../domain/usecases/search_benefit_services_usecase.dart';

final benefitServiceRemoteDataSourceProvider = Provider(
  (ref) => BenefitServiceRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final benefitServiceRepositoryProvider = Provider<BenefitServiceRepository>((
  ref,
) {
  return BenefitServiceRepositoryImpl(
    ref.watch(benefitServiceRemoteDataSourceProvider),
  );
});

final searchBenefitServicesUseCaseProvider = Provider(
  (ref) =>
      SearchBenefitServicesUseCase(ref.watch(benefitServiceRepositoryProvider)),
);

final getBenefitServiceDetailUseCaseProvider = Provider(
  (ref) => GetBenefitServiceDetailUseCase(
    ref.watch(benefitServiceRepositoryProvider),
  ),
);
```

- [ ] **Step 2: 목록 AsyncNotifier 작성**

`apps/senior/lib/features/info/presentation/providers/benefit_service_notifier.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/demographics/presentation/providers/demographics_provider.dart';
import '../../../../core/location/presentation/providers/region_provider.dart';
import '../../domain/entities/benefit_service.dart';
import 'benefit_service_di_providers.dart';

/// 나이/성별/지역이 모두 채워지면 자동으로 검색한다(요구사항: "사람마다
/// 결과가 바뀌었으면 좋겠다" — 하드코딩 카드 대신 실시간 조건 기반 검색).
/// `demographicsProvider`/`regionProvider`가 갱신되면(예: 프로필 저장 후)
/// `build()`가 다시 실행되어 자동으로 재검색된다.
class BenefitServiceNotifier extends AsyncNotifier<List<BenefitService>?> {
  @override
  Future<List<BenefitService>?> build() async {
    final demographics = await ref.watch(demographicsProvider.future);
    final region = await ref.watch(regionProvider.future);
    final result = await ref
        .read(searchBenefitServicesUseCaseProvider)
        .call(demographics, region);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final benefitServiceNotifierProvider =
    AsyncNotifierProvider<BenefitServiceNotifier, List<BenefitService>?>(
      BenefitServiceNotifier.new,
    );
```

- [ ] **Step 3: 상세 FutureProvider 작성**

`apps/senior/lib/features/info/presentation/providers/benefit_service_detail_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/benefit_service.dart';
import '../../domain/entities/benefit_service_detail.dart';
import 'benefit_service_di_providers.dart';

/// 화면 하나에서만 쓰는 단순 비동기 조회(재시도는 `ref.invalidate`) —
/// riverpod.md의 "재시도/재계산 로직이 없을 때는 FutureProvider" 원칙,
/// `autoDispose`로 화면을 벗어나면 폐기된다.
final benefitServiceDetailProvider = FutureProvider.autoDispose
    .family<BenefitServiceDetail, ({String id, BenefitServiceSource source})>(
      (ref, args) async {
        final result = await ref
            .read(getBenefitServiceDetailUseCaseProvider)
            .call(args.id, args.source);
        return switch (result) {
          Ok(:final value) => value,
          Err(:final failure) => throw failure,
        };
      },
    );
```

- [ ] **Step 4: 정적 분석으로 컴파일 확인**

Run: `cd apps/senior && flutter analyze lib/features/info/presentation`
Expected: No issues found (아직 이 provider들을 쓰는 화면이 없어 "사용되지 않음" 경고는 없다 — Dart는 top-level provider 미사용을 경고하지 않는다)

- [ ] **Step 5: Commit**

```bash
git add apps/senior/lib/features/info/presentation/providers
git commit -m "feat(info): add DI providers, list notifier, and detail provider"
```

---

### Task 11: `info_tab_page.dart` 재작성 + `benefit_service_detail_page.dart` 신규

**Files:**
- Modify: `apps/senior/lib/features/home/presentation/pages/info_tab_page.dart`
- Create: `apps/senior/lib/features/info/presentation/pages/benefit_service_detail_page.dart`
- Create: `apps/senior/test/features/home/presentation/pages/info_tab_page_test.dart`
- Create: `apps/senior/test/features/info/presentation/pages/benefit_service_detail_page_test.dart`

**Interfaces:**
- Consumes: Task 10의 `benefitServiceNotifierProvider`/`benefitServiceDetailProvider`, `apps/senior/lib/features/profile/presentation/pages/profile_page.dart`의 `ProfilePage`.
- Produces: 사용자에게 보이는 최종 화면. `home_shell_page.dart`는 이미 `info_tab_page.dart`를 `const InfoTabPage()`로 참조하고 있어 라우팅 변경이 필요 없다(생성자 시그니처 유지).

- [ ] **Step 1: 실패하는 위젯 테스트 작성**

`apps/senior/test/features/home/presentation/pages/info_tab_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/core/demographics/domain/entities/demographics.dart';
import 'package:ondam_senior/core/demographics/presentation/providers/demographics_di_providers.dart';
import 'package:ondam_senior/core/location/domain/entities/region.dart';
import 'package:ondam_senior/core/location/presentation/providers/location_di_providers.dart';
import 'package:ondam_senior/features/home/presentation/pages/info_tab_page.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/presentation/pages/benefit_service_detail_page.dart';
import 'package:ondam_senior/features/info/presentation/providers/benefit_service_di_providers.dart';
import 'package:ondam_senior/features/profile/presentation/pages/profile_page.dart';

import '../../../../core/demographics/domain/fakes/fake_demographics_repository.dart';
import '../../../../core/location/domain/fakes/fake_region_repository.dart';
import '../../../info/domain/fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeRegionRepository regionRepository;
  late FakeDemographicsRepository demographicsRepository;
  late FakeBenefitServiceRepository benefitServiceRepository;

  const demographics = Demographics(age: 72, gender: Gender.female);
  const region = Region(sido: '서울특별시', sigungu: '강남구', dong: '역삼동');

  setUp(() {
    regionRepository = FakeRegionRepository();
    demographicsRepository = FakeDemographicsRepository();
    benefitServiceRepository = FakeBenefitServiceRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        regionRepositoryProvider.overrideWithValue(regionRepository),
        demographicsRepositoryProvider.overrideWithValue(
          demographicsRepository,
        ),
        benefitServiceRepositoryProvider.overrideWithValue(
          benefitServiceRepository,
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: InfoTabPage())),
    );
  }

  testWidgets('나이/성별/지역이 없으면 내 정보 입력을 먼저 유도하고 검색을 시도하지 않는다', (
    tester,
  ) async {
    regionRepository.getMyRegionResult = const Ok(null);
    demographicsRepository.getMyDemographicsResult = const Ok(null);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('내 정보 입력하기'), findsOneWidget);
    expect(benefitServiceRepository.searchCalls, 0);

    await tester.tap(find.text('내 정보 입력하기'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfilePage), findsOneWidget);
  });

  testWidgets('나이/성별/지역이 모두 있으면 자동으로 검색해 목록을 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(benefitServiceRepository.searchCalls, 1);
    expect(find.text('기초연금'), findsOneWidget);
  });

  testWidgets('검색 결과가 없으면 정직한 빈 상태를 보여준다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([]);
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('지금 조건에 맞는 혜택 정보를 찾지 못했어요.'), findsOneWidget);
  });

  testWidgets('실제 데이터 소스가 아직 없으면 정직하게 안내한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Err(
      UnavailableFailure('맞춤 혜택 정보를 아직 제공하지 않아요.'),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('맞춤 혜택 정보를 아직 제공하지 않아요.'), findsOneWidget);
  });

  testWidgets('카드를 탭하면 상세 화면으로 이동한다', (tester) async {
    regionRepository.getMyRegionResult = const Ok(region);
    demographicsRepository.getMyDemographicsResult = const Ok(demographics);
    benefitServiceRepository.searchResult = const Ok([
      BenefitService(
        id: 'WLF001',
        source: BenefitServiceSource.central,
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    ]);
    benefitServiceRepository.getDetailResult = const Ok(
      BenefitServiceDetail(
        id: 'WLF001',
        title: '기초연금',
        summary: '만 65세 이상 지원',
      ),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('기초연금'));
    await tester.pumpAndSettle();

    expect(find.byType(BenefitServiceDetailPage), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트가 실패하는지 확인**

Run: `cd apps/senior && flutter test test/features/home/presentation/pages/info_tab_page_test.dart`
Expected: FAIL (`info_tab_page.dart`가 아직 빈 상태만 렌더링, `BenefitServiceDetailPage` 파일 없음 — 컴파일 오류)

- [ ] **Step 3: `info_tab_page.dart` 전체 교체**

`apps/senior/lib/features/home/presentation/pages/info_tab_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../info/domain/entities/benefit_service.dart';
import '../../../info/presentation/pages/benefit_service_detail_page.dart';
import '../../../info/presentation/providers/benefit_service_notifier.dart';
import '../../../profile/presentation/pages/profile_page.dart';

/// 정보 탭 — 나이/성별/지역 기반 맞춤 혜택 정보. 기존 온담앱은 나이만
/// 기준으로 카드 3개를 하드코딩했지만(콘텐츠가 고정돼 개인화 폭이
/// 제한적이었다), 이 구현은 `search-benefit-services` Edge Function을 통해
/// 실시간으로 검색하므로 사람마다(나이·성별·지역 조합) 결과가 달라진다.
class InfoTabPage extends ConsumerWidget {
  const InfoTabPage({super.key});

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfilePage()));
  }

  void _openDetail(BuildContext context, BenefitService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BenefitServiceDetailPage(
          id: service.id,
          source: service.source,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(benefitServiceNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: AppSectionHeader(title: '정보'),
        ),
        Expanded(
          child: resultsAsync.when(
            loading: () => const AppLoading(),
            error: (error, _) {
              if (error is ValidationFailure) {
                return AppEmptyState(
                  icon: Icons.person_outline,
                  message: error.message,
                  actionLabel: '내 정보 입력하기',
                  onAction: () => _openProfile(context),
                );
              }
              if (error is UnavailableFailure) {
                return AppEmptyState(
                  icon: Icons.info_outline,
                  message: error.message,
                );
              }
              final message = error is Failure
                  ? error.message
                  : '맞춤 혜택 정보를 불러오지 못했어요.';
              return AppError(
                message: message,
                onRetry: () => ref.invalidate(benefitServiceNotifierProvider),
              );
            },
            data: (results) {
              if (results == null || results.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off,
                  message: '지금 조건에 맞는 혜택 정보를 찾지 못했어요.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: results.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final service = results[index];
                  return AppCard(
                    onTap: () => _openDetail(context, service),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(service.title, style: AppTextStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(service.summary, style: AppTextStyles.bodyMedium),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: `benefit_service_detail_page.dart` 작성**

`apps/senior/lib/features/info/presentation/pages/benefit_service_detail_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/benefit_service.dart';
import '../providers/benefit_service_detail_provider.dart';

/// 혜택 정보 상세 — `welfare_center_list_page.dart`의 전화 연결 패턴을
/// 그대로 재사용한다.
class BenefitServiceDetailPage extends ConsumerWidget {
  const BenefitServiceDetailPage({
    super.key,
    required this.id,
    required this.source,
  });

  final String id;
  final BenefitServiceSource source;

  Future<void> _openExternalUrl(BuildContext context, String url) async {
    final launched = await launchUrl(Uri.parse(url));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('링크를 열 수 없어요.')));
    }
  }

  Future<void> _callPhone(BuildContext context, String phoneNumber) async {
    final launched = await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('전화 앱을 열 수 없어요.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(
      benefitServiceDetailProvider((id: id, source: source)),
    );

    return AppScaffold(
      title: '혜택 정보',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: detailAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) {
          final message = error is Failure
              ? error.message
              : '혜택 정보를 불러오지 못했어요.';
          return AppError(
            message: message,
            onRetry: () => ref.invalidate(
              benefitServiceDetailProvider((id: id, source: source)),
            ),
          );
        },
        data: (detail) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail.title, style: AppTextStyles.headlineMedium),
            const SizedBox(height: AppSpacing.md),
            Text(detail.summary, style: AppTextStyles.bodyLarge),
            if (detail.supportTarget != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppInfoRow(label: '지원대상', value: detail.supportTarget),
            ],
            if (detail.applyMethod != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppInfoRow(label: '신청방법', value: detail.applyMethod),
            ],
            if (detail.contact != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: '문의처 전화하기',
                size: AppButtonSize.large,
                onPressed: () => _callPhone(context, detail.contact!),
              ),
            ],
            if (detail.externalUrl != null) ...[
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: '자세히 보기',
                size: AppButtonSize.large,
                onPressed: () => _openExternalUrl(context, detail.externalUrl!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 상세 페이지 위젯 테스트 작성**

`apps/senior/test/features/info/presentation/pages/benefit_service_detail_page_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service.dart';
import 'package:ondam_senior/features/info/domain/entities/benefit_service_detail.dart';
import 'package:ondam_senior/features/info/presentation/pages/benefit_service_detail_page.dart';
import 'package:ondam_senior/features/info/presentation/providers/benefit_service_di_providers.dart';

import '../../domain/fakes/fake_benefit_service_repository.dart';

void main() {
  late FakeBenefitServiceRepository repository;

  setUp(() {
    repository = FakeBenefitServiceRepository();
  });

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        benefitServiceRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: BenefitServiceDetailPage(
          id: 'WLF001',
          source: BenefitServiceSource.central,
        ),
      ),
    );
  }

  testWidgets('상세 정보를 지원대상/신청방법/문의처와 함께 보여준다', (tester) async {
    repository.getDetailResult = const Ok(
      BenefitServiceDetail(
        id: 'WLF001',
        title: '기초연금',
        summary: '만 65세 이상 지원',
        supportTarget: '소득 하위 70%',
        applyMethod: '주민센터 방문 신청',
        contact: '129',
      ),
    );
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('기초연금'), findsOneWidget);
    expect(find.text('소득 하위 70%'), findsOneWidget);
    expect(find.text('주민센터 방문 신청'), findsOneWidget);
    expect(find.text('문의처 전화하기'), findsOneWidget);
  });

  testWidgets('조회 실패 시 에러와 재시도를 보여준다', (tester) async {
    repository.getDetailResult = const Err(ServerFailure());
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('서버에 문제가 발생했습니다.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `cd apps/senior && flutter test test/features/home/presentation/pages/info_tab_page_test.dart test/features/info/presentation/pages/benefit_service_detail_page_test.dart`
Expected: PASS (5 + 2 = 7 tests)

- [ ] **Step 7: Commit**

```bash
git add apps/senior/lib/features/home/presentation/pages/info_tab_page.dart apps/senior/lib/features/info/presentation/pages apps/senior/test/features/home/presentation/pages/info_tab_page_test.dart apps/senior/test/features/info/presentation/pages
git commit -m "feat(info): replace empty info tab with personalized benefit list/detail screens"
```

---

### Task 12: 문서 갱신 — `technical-decisions.md` v19

**Files:**
- Modify: `docs/architecture/technical-decisions.md`

**Interfaces:** 없음(문서 전용 변경).

- [ ] **Step 1: 개정 이력에 v19 항목 추가**

`docs/architecture/technical-decisions.md`의 `> - **v18(이 버전)**: ...` 줄 바로 뒤, `> 함께 읽는 문서: ...` 줄 바로 앞에 아래 항목을 추가한다(기존 `v18` 줄 앞의 `**이 버전**` 굵게 표시는 `v18`에서 제거하고 `v19`로 옮긴다):

```
> - **v19(이 버전)**: `apps/senior` "정보" 탭(그동안 완전히 빈 상태)에 나이/성별/지역 기반 맞춤 혜택 정보를 구현했다. `users` 테이블에 `age`/`gender` 컬럼을 신규 추가했다(migration `20260821000002`) — §4의 `users` 스케치(v1)에는 `age`만 있었고 `gender`는 이번에 처음 필요해져 추가했다. `core/demographics`(region과 동일하게 `profile`/`info` feature가 공유)를 신설해 `profile_page`의 "저장" 버튼이 실제로 나이/성별을 저장하도록 연결했다(그동안 "저장 기능은 아직 준비 중"이라는 안내만 있었다) — 성별 선택 UI(2지선다)도 신규 추가. `features/info`에 domain/data/presentation 3계층을 채우고, 공공데이터포털(data.go.kr) 한국사회보장정보원_지자체복지서비스+중앙부처복지서비스 Open API를 `search-benefit-services`/`get-benefit-service-detail` 두 Edge Function으로 서버 측에서만 호출한다(서비스키 비노출, `search-welfare-centers`와 동일 원칙). **기존 온담앱은 나이만 기준으로 카드 3개(기초연금/건강검진/보이스피싱)를 하드코딩했지만, 이번 구현은 하드코딩 없이 나이·성별·지역 조합에 따라 실시간으로 결과가 달라진다** — `docs/product/current-app-analysis.md` §2-6이 지적한 "콘텐츠가 3개로 고정되어 개인화 폭이 제한적" 문제를 해소한다. **중요한 미확정 사항**: 이 API 계열은 로그인 없이 SWAGGER 문서를 볼 수 없어, 요청/응답 필드명(`benefit_service_client.ts`/`benefit_service_detail_client.ts`)이 `welfare_center_client.ts`의 PHASE 26과 동일하게 **최선 추정 초안**이다 — 실제 서비스키 발급 후 라이브 검증이 필요하다(신규 OPEN QUESTIONS로 §5에 추가). 성별은 업스트림 API가 실제로 지원하는지 확인되지 않아 이번 구현에서는 업스트림 요청에 포함하지 않았다(요청 계약에는 있으나 미사용) — 나이(생애주기 추정 코드)와 지역(지자체 API 한정, 확인되지 않은 필드로 느슨한 필터)만 시도한다. 이 환경에 `DATA_GO_KR_SERVICE_KEY`/실제 Supabase 프로젝트가 없어 실제 라이브 호출/migration 적용은 **NOT AVAILABLE**(정적 코드 검토 + Dart 단위/위젯 테스트만 완료, Deno 테스트 파일은 작성했으나 Deno CLI가 없어 미실행). 상세는 `docs/superpowers/specs/2026-08-21-personalized-benefits-info-design.md`, `docs/superpowers/plans/2026-08-21-personalized-benefits-info.md`.
```

- [ ] **Step 2: §4 데이터 모델 표의 `users` 행 갱신**

`users` 행의 비고 열 끝에 다음 문장을 추가한다: "`age`/`gender` 컬럼은 v19에서 실제로 생성됨(`20260821000002`) — name/easy_mode_enabled는 여전히 미생성."

- [ ] **Step 3: §5 OPEN QUESTIONS에 항목 추가**

기존 마지막 번호 다음 번호로 추가한다: "**(v19 신규) 지자체복지서비스/중앙부처복지서비스 API의 실제 요청/응답 필드명과 성별 필터 지원 여부** — SWAGGER 문서를 로그인 없이 확인하지 못해 `benefit_service_client.ts`/`benefit_service_detail_client.ts`의 필드명이 미확인 초안이다. 서비스키 발급 후 라이브 검증 필요(`welfare_center`의 PHASE 26→35와 동일한 절차)."

- [ ] **Step 4: Commit**

```bash
git add docs/architecture/technical-decisions.md
git commit -m "docs: record v19 (personalized benefit info) in technical-decisions.md"
```

---

### Task 13: 전체 검증

**Files:** 없음(검증 전용).

- [ ] **Step 1: 포맷 검사**

Run: `cd apps/senior && dart format --output=none --set-exit-if-changed .`
Expected: 변경 필요한 파일 없음(있으면 `dart format .`로 수정 후 재확인)

- [ ] **Step 2: 정적 분석**

Run: `cd apps/senior && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: 전체 테스트 실행**

Run: `cd apps/senior && flutter test`
Expected: 기존 테스트 전부 + 이번에 추가한 테스트(7+6+2+5+7+5+7 = 39개 신규) 전부 PASS, 실패 0개

- [ ] **Step 4: Android 빌드 검증(가능한 범위)**

Run: `cd apps/senior && flutter build apk --debug`
Expected: 빌드 성공. 이 환경에 Android SDK가 없으면 **NOT AVAILABLE**로 기록한다(iOS는 Windows에서 항상 NOT AVAILABLE — CLAUDE.md).

- [ ] **Step 5: 최종 커밋(필요 시)**

Step 1에서 `dart format`이 실제로 파일을 변경했다면:

```bash
git add -u apps/senior
git commit -m "chore: dart format"
```

변경이 없었다면 이 스텝은 건너뛴다.

---

## Self-Review 요약

- **스펙 커버리지**: 스펙의 "데이터 모델"→Task 1, "core/demographics"→Task 2~4, "features/profile 변경"→Task 5, "Edge Functions"→Task 6~7, "features/info"→Task 8~11, "테스트"→각 Task에 통합, "리스크"→Task 6/7 상단 주석 + Task 12 문서화. 스펙의 "범위 밖" 항목(guardian 연동, 소득/재산 필터, 알림)은 이 계획에 포함하지 않았다 — 의도적.
- **플레이스홀더 스캔**: "TODO"/"나중에" 문구 없음. 모든 코드 블록은 실제로 실행 가능한 완전한 내용이다.
- **타입 일관성**: `Demographics`/`Gender`(Task 2)→`SaveDemographicsUseCase`/`DemographicsRepositoryImpl`/`profile_page.dart`(Task 3/5)→`SearchBenefitServicesUseCase`/`BenefitServiceRepository`(Task 8)까지 시그니처가 일치한다. `BenefitServiceSource`(Task 8)→`BenefitServiceRemoteDataSource.getDetail(source: String)`(Task 9, `.value` 사용)→`BenefitServiceDetailPage(source: BenefitServiceSource)`(Task 11)까지 동일하게 이어진다. `benefitServiceDetailProvider`의 family 인자 타입(`({String id, BenefitServiceSource source})`, Task 10)과 `BenefitServiceDetailPage`의 호출부(Task 11)가 정확히 일치한다.
