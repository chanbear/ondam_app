import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/auth/domain/entities/pin_verify_result.dart';
import 'package:ondam_senior/features/auth/presentation/providers/auth_di_providers.dart';
import 'package:ondam_senior/features/auth/presentation/providers/login_notifier.dart';

import '../../domain/fakes/fake_auth_repository.dart';

/// ONDAM 2.0V 요구사항 2/3/4 — 휴대폰 번호+비밀번호(PIN) 로그인 화면이
/// 하나의 제출로 가입/PIN 최초 설정/PIN 확인/역할 자동 결정을 순서대로
/// 처리하는지 검증한다.
void main() {
  test(
    '신규 사용자(hasPin=false)는 setPin을 호출하고, 역할이 없으면 어르신 역할을 자동으로 추가한다',
    () async {
      final fake = FakeAuthRepository()
        ..hasPinResult = const Ok(false)
        ..getRolesResult = const Ok(<UserRole>[]);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(loginNotifierProvider.notifier)
          .submit(rawPhoneNumber: '01012345678', pin: '1234');

      expect(result, isA<Ok<PinVerifyResult>>());
      expect(fake.signUpCalls, hasLength(1));
      expect(fake.setPinCalls, ['1234']);
      expect(fake.verifyPinCalls, isEmpty);
      expect(fake.addRoleCalls, [UserRole.elder]);
    },
  );

  test(
    '기존 사용자(hasPin=true)는 verifyPin을 호출하고, 이미 역할이 있으면 다시 추가하지 않는다',
    () async {
      final fake = FakeAuthRepository()
        ..hasPinResult = const Ok(true)
        ..getRolesResult = const Ok([UserRole.elder]);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(loginNotifierProvider.notifier)
          .submit(rawPhoneNumber: '01012345678', pin: '1234');

      expect(result, isA<Ok<PinVerifyResult>>());
      expect(fake.verifyPinCalls, ['1234']);
      expect(fake.setPinCalls, isEmpty);
      expect(
        fake.addRoleCalls,
        isEmpty,
        reason:
            'user_roles의 (user_id, role) unique 제약을 어기지 않으려면 '
            '이미 역할이 있는 계정에는 다시 addRole을 호출하면 안 된다',
      );
    },
  );

  test('비밀번호가 틀리면 실패가 아닌 정상 결과(ok=false)로 반환되고 역할을 추가하지 않는다', () async {
    final fake = FakeAuthRepository()
      ..hasPinResult = const Ok(true)
      ..verifyPinResult = const Ok(
        PinVerifyResult.failure(reason: PinVerifyFailureReason.wrongPin),
      )
      ..getRolesResult = const Ok(<UserRole>[]);
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(fake)],
    );
    addTearDown(container.dispose);

    final result = await container
        .read(loginNotifierProvider.notifier)
        .submit(rawPhoneNumber: '01012345678', pin: '0000');

    expect(result, isA<Ok<PinVerifyResult>>());
    final value = (result as Ok<PinVerifyResult>).value;
    expect(value.ok, isFalse);
    expect(value.reason, PinVerifyFailureReason.wrongPin);
    expect(fake.addRoleCalls, isEmpty);
  });

  test(
    'signUp이 실패하면 그 이후 단계(hasPin/setPin/verifyPin/addRole)를 호출하지 않는다',
    () async {
      final fake = FakeAuthRepository()
        ..signUpResult = const Err(ValidationFailure('휴대폰 번호를 다시 확인해주세요.'));
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(loginNotifierProvider.notifier)
          .submit(rawPhoneNumber: 'invalid', pin: '1234');

      expect(result, isA<Err<PinVerifyResult>>());
      expect(fake.setPinCalls, isEmpty);
      expect(fake.verifyPinCalls, isEmpty);
      expect(fake.addRoleCalls, isEmpty);
    },
  );
}
