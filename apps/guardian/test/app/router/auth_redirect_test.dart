import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_guardian/app/router/auth_redirect.dart';
import 'package:ondam_guardian/app/router/auth_routes.dart';
import 'package:ondam_models/ondam_models.dart';

/// Guardian UI Application Round 1 §4 — 휴대폰 번호+비밀번호(PIN) 로그인, PIN
/// 최초 설정/확인, 역할 자동 결정이 모두 [AuthRoutes.phoneInput] 하나의
/// 화면으로 합쳐졌다. 이 테스트는 `/auth/pin/setup`, `/auth/pin/entry`,
/// `/auth/role-select`로 더 이상 리다이렉트되지 않는다는 것을 검증한다.
void main() {
  group('No Session', () {
    test('allows staying on the phone-input route', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.phoneInput,
        ),
        isNull,
      );
    });

    test('redirects any other route back to phone input', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.home,
        ),
        AuthRoutes.phoneInput,
      );
    });
  });

  group('Session, PIN not set yet', () {
    test(
      'sends a new signup back to the phone-input screen, not a separate PIN setup route',
      () {
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: false,
            pinVerified: false,
            roles: null,
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );

    test('allows staying on the phone-input route while PIN is unset', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.phoneInput,
        ),
        isNull,
      );
    });
  });

  group('Session, PIN set but not verified this session', () {
    test(
      'sends a returning user back to the phone-input screen, not a separate PIN entry route',
      () {
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: true,
            pinVerified: false,
            roles: null,
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );

    test('allows staying on the phone-input route while PIN is unverified', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.phoneInput,
        ),
        isNull,
      );
    });

    test('lets pin-forgot proceed even though PIN is not verified', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.pinForgot,
        ),
        isNull,
      );
    });
  });

  group('Session + PIN verified, role not auto-added yet', () {
    test('waits on session-loading instead of a role-selection screen', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: true,
          roles: const <UserRole>[],
          location: AuthRoutes.home,
        ),
        AuthRoutes.sessionLoading,
      );
    });
  });

  group('Session + PIN verified + role present', () {
    test('sends the auth flow to home', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: true,
          roles: const [UserRole.guardian],
          location: AuthRoutes.phoneInput,
        ),
        AuthRoutes.home,
      );
    });

    test('allows staying on home', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: true,
          roles: const [UserRole.guardian],
          location: AuthRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('idle-timeout re-entry', () {
    test(
      're-locking (pinVerified: false) after a timeout sends back to the phone-input screen even from home',
      () {
        // Simulates IdleTimeoutController having called pinVerifiedProvider.reset()
        // after the app was backgrounded past the (5-minute) threshold.
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: true,
            pinVerified: false,
            roles: const [UserRole.guardian],
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );
  });
}
