import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/profile/domain/entities/profile.dart';
import 'package:ondam_senior/features/profile/domain/usecases/get_my_profile_usecase.dart';
import 'package:ondam_senior/features/profile/domain/usecases/save_profile_usecase.dart';

import '../fakes/fake_profile_repository.dart';

void main() {
  late FakeProfileRepository repository;

  setUp(() {
    repository = FakeProfileRepository();
  });

  group('GetMyProfileUseCase', () {
    test('저장된 프로필이 없으면 null을 정직하게 반환한다', () async {
      repository.getMyProfileResult = const Ok(null);
      final useCase = GetMyProfileUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Profile?>).value, isNull);
    });

    test('저장된 프로필이 있으면 그대로 반환한다', () async {
      const profile = Profile(name: '홍길동', age: 73);
      repository.getMyProfileResult = const Ok(profile);
      final useCase = GetMyProfileUseCase(repository);

      final result = await useCase();

      expect((result as Ok<Profile?>).value, isNotNull);
      expect(result.value!.name, '홍길동');
      expect(result.value!.age, 73);
    });
  });

  group('SaveProfileUseCase', () {
    test('저장 성공', () async {
      final useCase = SaveProfileUseCase(repository);

      final result = await useCase(name: '홍길동', age: '73');

      expect(result, isA<Ok<void>>());
      expect(repository.saveCalls, 1);
      expect(repository.savedProfile?.name, '홍길동');
      expect(repository.savedProfile?.age, 73);
    });

    test('이름 앞뒤 공백은 잘라서 저장한다', () async {
      final useCase = SaveProfileUseCase(repository);

      await useCase(name: '  홍길동  ', age: '73');

      expect(repository.savedProfile?.name, '홍길동');
    });

    test('이름이 비어 있으면 저장을 시도하지 않고 ValidationFailure를 반환한다', () async {
      final useCase = SaveProfileUseCase(repository);

      final result = await useCase(name: '   ', age: '73');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('나이가 숫자가 아니면 저장을 시도하지 않고 ValidationFailure를 반환한다', () async {
      final useCase = SaveProfileUseCase(repository);

      final result = await useCase(name: '홍길동', age: '칠십셋');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ValidationFailure>());
      expect(repository.saveCalls, 0);
    });

    test('나이가 범위를 벗어나면(0 이하/120 이상) 저장을 시도하지 않는다', () async {
      final useCase = SaveProfileUseCase(repository);

      final zeroResult = await useCase(name: '홍길동', age: '0');
      final tooOldResult = await useCase(name: '홍길동', age: '120');

      expect(zeroResult, isA<Err<void>>());
      expect(tooOldResult, isA<Err<void>>());
      expect(repository.saveCalls, 0);
    });

    test('저장 실패(예: 네트워크 오류)를 그대로 전달한다', () async {
      repository.saveProfileResult = const Err(ServerFailure());
      final useCase = SaveProfileUseCase(repository);

      final result = await useCase(name: '홍길동', age: '73');

      expect(result, isA<Err<void>>());
      expect((result as Err<void>).failure, isA<ServerFailure>());
    });
  });
}
