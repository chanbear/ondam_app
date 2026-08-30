import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/pin_verify_result.dart';
import '../../domain/entities/social_auth_provider.dart';
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

  /// OAuth(구글/카카오) 로그인 브라우저를 연다. 실제 세션은 딥링크로 앱에
  /// 돌아온 뒤 비동기로 생성되므로, 이 메서드는 브라우저가 열렸는지만
  /// 알려준다 — PIN 설정/역할 부여는 세션이 실제로 생기고 난 뒤
  /// [submitPinForExistingSession]이 담당한다(라우터가 `hasPin==false`를
  /// 보고 phoneInput으로 되돌리면, 그 화면이 세션 존재 여부로 이 경로를
  /// 자동으로 고른다).
  Future<Result<void>> signInWithOAuth(SocialAuthProvider provider) async {
    state = const AsyncLoading();
    final result = await ref
        .read(signInWithOAuthUseCaseProvider)
        .call(provider);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  /// 회원가입 없이 사용하기 — 익명 Supabase 세션을 만든다. [signInWithOAuth]와
  /// 마찬가지로 세션이 실제로 생기면 라우터가 phoneInput으로 되돌리고,
  /// `phone_input_page.dart`의 `isOAuthSession` 분기(휴대폰 번호 없는
  /// 세션)가 그대로 PIN 설정 UI를 보여준다.
  Future<Result<void>> signInAsGuest() async {
    state = const AsyncLoading();
    final result = await ref.read(signInAsGuestUseCaseProvider).call();
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  /// OAuth로 이미 세션이 생긴 뒤 PIN만 입력받는 경로 — [_submit]의 signUp
  /// 호출(휴대폰 가입/로그인 전용)을 건너뛰고 곧장 PIN 설정/확인 + 역할
  /// 부여 단계로 들어간다.
  Future<Result<PinVerifyResult>> submitPinForExistingSession(
    String pin,
  ) async {
    state = const AsyncLoading();
    final result = await _completePinAndRole(pin);
    state = switch (result) {
      Ok() => const AsyncData(null),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }

  /// 소셜 로그인(구글/카카오) 세션 전용 — PIN 설정/확인을 완전히 건너뛰고
  /// 곧장 역할 자동 부여로 넘어간다(사용자 요청: 소셜 로그인 시 PIN 입력
  /// 생략). [_completePinAndRole]과 달리 hasPin/setPin/verifyPin을 전혀
  /// 호출하지 않는다 — 라우터(`decideAuthRedirect`)도 소셜 로그인 세션에서는
  /// hasPin/pinVerified를 아예 보지 않으므로 이 값들을 쓸 필요가 없다.
  Future<Result<void>> completeSocialLoginSession() async {
    state = const AsyncLoading();
    final rolesResult = await ref.read(getRolesUseCaseProvider).call();
    final List<UserRole> roles;
    switch (rolesResult) {
      case Ok(:final value):
        roles = value;
      case Err(:final failure):
        state = AsyncError(failure, StackTrace.current);
        return Err(failure);
    }
    if (roles.isEmpty) {
      final addRoleResult = await ref
          .read(roleNotifierProvider.notifier)
          .addRole(UserRole.elder);
      if (addRoleResult case Err(:final failure)) {
        state = AsyncError(failure, StackTrace.current);
        return Err(failure);
      }
    }
    state = const AsyncData(null);
    return const Ok(null);
  }

  Future<Result<PinVerifyResult>> _submit({
    required String rawPhoneNumber,
    required String pin,
  }) async {
    // ONDAM 2.0V 로그인 화면에는 이름 입력이 없다(요구사항 2). 서버는
    // signup-with-phone 호출 시 이름을 필수로 요구하지만, 이 값은
    // auth.users의 메타데이터로만 저장되고 앱 어디에서도 읽거나 표시하지
    // 않는다 — 실제 표시용 이름은 이후 ProfilePage(`profileProvider`)에서
    // 별도로 입력/저장한다. 여기서는 그 값과 무관하게 DB 스키마를 바꾸지
    // 않기 위해 고정값을 사용한다.
    final signUpResult = await ref
        .read(signUpUseCaseProvider)
        .call(name: '온담 이용자', rawPhoneNumber: rawPhoneNumber);
    if (signUpResult case Err(:final failure)) return Err(failure);

    return _completePinAndRole(pin);
  }

  /// signUp(휴대폰) 또는 signInWithOAuth(소셜) 어느 쪽으로 세션이 생겼든,
  /// 그 다음부터는 동일하다: PIN 최초 설정/확인 → (신규면) 어르신 역할
  /// 자동 부여.
  Future<Result<PinVerifyResult>> _completePinAndRole(String pin) async {
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
