import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/pin_verify_result.dart';
import 'auth_di_providers.dart';
import 'pin_notifier.dart';
import 'role_notifier.dart';

/// ONDAM 2.0V 요구사항 2/3/4 — 휴대폰 번호 + 비밀번호(PIN)를 하나의 로그인
/// 화면에서 입력받아, 기존 인증 인프라(signUp/hasPin/setPin/verifyPin/
/// addRole usecase와 그 뒤의 Edge Function)를 그대로 순서대로 호출하는
/// 오케스트레이션 계층. 화면 전환 없이 이 하나의 제출로 가입/로그인/PIN
/// 최초 설정/PIN 확인/역할 자동 결정까지 모두 끝난다.
///
/// signup-with-phone은 번호 기준 idempotent(같은 번호 = 같은 계정)라 신규/
/// 기존 가입을 이 화면에서 미리 구분하지 않는다 — 세션을 만들거나 찾은
/// 뒤, 서버가 돌려주는 실제 hasPin 값으로 PIN을 새로 설정할지(신규)
/// 확인할지(기존)를 그때 결정한다.
class LoginNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Result<PinVerifyResult>> submit({
    required String rawPhoneNumber,
    required String pin,
  }) async {
    state = const AsyncLoading();
    final result = await _submit(rawPhoneNumber: rawPhoneNumber, pin: pin);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  Future<Result<PinVerifyResult>> _submit({
    required String rawPhoneNumber,
    required String pin,
  }) async {
    // ONDAM 2.0V 로그인 화면에는 이름 입력이 없다(요구사항 2). 서버는
    // signup-with-phone 호출 시 이름을 필수로 요구하지만, 이 값은
    // auth.users의 메타데이터로만 저장되고 앱 어디에서도 읽거나 표시하지
    // 않는다(ProfilePage는 별도의 미구현 기능) — DB 스키마를 바꾸지 않고
    // 화면에도 노출하지 않기 위해 고정값을 사용한다.
    final signUpResult = await ref
        .read(signUpUseCaseProvider)
        .call(name: '온담 이용자', rawPhoneNumber: rawPhoneNumber);
    if (signUpResult case Err(:final failure)) return Err(failure);

    // 방금 세션이 새로 만들어졌거나 다른 계정으로 바뀌었을 수 있으므로
    // 캐시(hasPinProvider)를 거치지 않고 항상 새로 조회한다.
    final hasPinResult = await ref.read(hasPinUseCaseProvider).call();
    final bool hasPin;
    switch (hasPinResult) {
      case Ok(:final value):
        hasPin = value;
      case Err(:final failure):
        return Err(failure);
    }

    final PinVerifyResult verifyResult;
    if (hasPin) {
      final verifyPinResult = await ref
          .read(pinNotifierProvider.notifier)
          .verifyPin(pin);
      switch (verifyPinResult) {
        case Ok(:final value):
          verifyResult = value;
        case Err(:final failure):
          return Err(failure);
      }
    } else {
      final setPinResult = await ref
          .read(pinNotifierProvider.notifier)
          .setPin(pin);
      if (setPinResult case Err(:final failure)) return Err(failure);
      verifyResult = const PinVerifyResult.success();
    }
    // 비밀번호가 틀렸거나 잠긴 경우 — Failure가 아니라 정상적인 도메인
    // 결과다. 로그인 화면에 그대로 머무르며 안내 문구만 보여준다.
    if (!verifyResult.ok) return Ok(verifyResult);

    // ONDAM 2.0V 요구사항 4 — Senior 앱은 역할을 물어보지 않고 어르신
    // 역할을 자동으로 부여한다. 이미 역할이 있으면(재로그인) 다시
    // 추가하지 않는다 — user_roles의 (user_id, role) unique 제약을 그대로
    // 존중한다.
    final rolesResult = await ref.read(getRolesUseCaseProvider).call();
    final List<UserRole> roles;
    switch (rolesResult) {
      case Ok(:final value):
        roles = value;
      case Err(:final failure):
        return Err(failure);
    }
    if (roles.isEmpty) {
      final addRoleResult = await ref
          .read(roleNotifierProvider.notifier)
          .addRole(UserRole.elder);
      if (addRoleResult case Err(:final failure)) return Err(failure);
    }

    return const Ok(PinVerifyResult.success());
  }
}

final loginNotifierProvider = AsyncNotifierProvider<LoginNotifier, void>(
  LoginNotifier.new,
);
