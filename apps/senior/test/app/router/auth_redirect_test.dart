import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/app/router/auth_redirect.dart';
import 'package:ondam_senior/app/router/auth_routes.dart';

/// ONDAM 2.0V(요구사항 2/3/4) — 휴대폰 번호+비밀번호(PIN) 로그인, PIN
/// 최초 설정/확인, 역할 자동 결정이 모두 [AuthRoutes.phoneInput] 하나의
/// 화면으로 합쳐졌다. 이 테스트는 `/auth/pin/setup`, `/auth/pin/entry`,
/// `/auth/role-select`로 더 이상 리다이렉트되지 않는다는 것을 검증한다.
void main() {
  group('No Session', () {
    test('allows staying on the splash route (initialLocation)', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          skipsPinGate: false,
          roles: null,
          location: AuthRoutes.splash,
        ),
        isNull,
      );
    });

    test('allows staying on the login route', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          skipsPinGate: false,
          roles: null,
          location: AuthRoutes.phoneInput,
        ),
        isNull,
      );
    });

    test('redirects any other route back to the login route', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          skipsPinGate: false,
          roles: null,
          location: AuthRoutes.home,
        ),
        AuthRoutes.phoneInput,
      );
    });
  });

  group('Session, PIN not set yet', () {
    test(
      'sends a new signup back to the login screen, not a separate PIN setup route',
      () {
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: false,
            pinVerified: false,
            skipsPinGate: false,
            roles: null,
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );

    test('allows staying on the login route while PIN is unset', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          skipsPinGate: false,
          roles: null,
          location: AuthRoutes.phoneInput,
        ),
        isNull,
      );
    });
  });

  group('Session, PIN set but not verified this session', () {
    test(
      'sends a returning user back to the login screen, not a separate PIN entry route',
      () {
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: true,
            pinVerified: false,
            skipsPinGate: false,
            roles: null,
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );

    test('allows staying on the login route while PIN is unverified', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: false,
          skipsPinGate: false,
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
          skipsPinGate: false,
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
          skipsPinGate: false,
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
          skipsPinGate: false,
          roles: const [UserRole.elder],
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
          skipsPinGate: false,
          roles: const [UserRole.elder],
          location: AuthRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('Social login/게스트 세션 (사용자 요청: PIN 입력 생략, 2026-08-31 게스트도 포함)', () {
    test('hasPin이 false여도 PIN 화면으로 보내지 않고 곧장 통과시킨다', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          skipsPinGate: true,
          roles: const [UserRole.elder],
          location: AuthRoutes.home,
        ),
        isNull,
      );
    });

    test('hasPin이 아직 로딩 중(null)이어도 session-loading으로 보내지 않는다', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: null,
          pinVerified: false,
          skipsPinGate: true,
          roles: const [UserRole.elder],
          location: AuthRoutes.home,
        ),
        isNull,
      );
    });

    test('역할이 아직 없으면(자동 부여 전) session-loading에서 기다린다', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          skipsPinGate: true,
          roles: const <UserRole>[],
          location: AuthRoutes.home,
        ),
        AuthRoutes.sessionLoading,
      );
    });

    test('역할 부여가 끝나면 로그인 화면에서 홈으로 보낸다', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          skipsPinGate: true,
          roles: const [UserRole.elder],
          location: AuthRoutes.phoneInput,
        ),
        AuthRoutes.home,
      );
    });

    // 회귀 테스트(2026-08-30 실기기): 역할 부여가 비동기로 끝나면 이미
    // session-loading으로 이동해 있는 상태에서 role이 채워질 수 있다 —
    // 이때도 홈으로 보내야 한다. onLogin(location==phoneInput)만 확인하면
    // 이 경우를 놓쳐 role이 채워져도 session-loading에 영원히 멈춘다.
    test('역할 부여가 session-loading에서 끝나도 홈으로 보낸다', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          skipsPinGate: true,
          roles: const [UserRole.elder],
          location: AuthRoutes.sessionLoading,
        ),
        AuthRoutes.home,
      );
    });
  });

  group('idle-timeout re-entry', () {
    test(
      're-locking (pinVerified: false) after a timeout sends back to the login screen even from home',
      () {
        // Simulates IdleTimeoutController having called pinVerifiedProvider.reset()
        // after the app was backgrounded past the threshold.
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: true,
            pinVerified: false,
            skipsPinGate: false,
            roles: const [UserRole.elder],
            location: AuthRoutes.home,
          ),
          AuthRoutes.phoneInput,
        );
      },
    );
  });
}
