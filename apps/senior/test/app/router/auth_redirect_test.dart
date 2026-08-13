import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/app/router/auth_redirect.dart';
import 'package:ondam_senior/app/router/auth_routes.dart';

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

    test('allows staying on the otp-verify route', () {
      expect(
        decideAuthRedirect(
          hasSession: false,
          hasPin: null,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.otpVerify,
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
    test('sends a new signup to PIN setup', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.home,
        ),
        AuthRoutes.pinSetup,
      );
    });

    test('allows staying on the pin-setup route', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: false,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.pinSetup,
        ),
        isNull,
      );
    });
  });

  group('Session, PIN set but not verified this session', () {
    test('sends a returning user to PIN entry', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.home,
        ),
        AuthRoutes.pinEntry,
      );
    });

    test('allows staying on the pin-entry route', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: false,
          roles: null,
          location: AuthRoutes.pinEntry,
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

  group('Session + PIN verified, role not chosen yet', () {
    test('sends to role selection', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: true,
          roles: const <UserRole>[],
          location: AuthRoutes.home,
        ),
        AuthRoutes.roleSelect,
      );
    });
  });

  group('Session + PIN verified + role chosen', () {
    test('sends the auth flow to home', () {
      expect(
        decideAuthRedirect(
          hasSession: true,
          hasPin: true,
          pinVerified: true,
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
          roles: const [UserRole.elder],
          location: AuthRoutes.home,
        ),
        isNull,
      );
    });
  });

  group('idle-timeout re-entry', () {
    test(
      're-locking (pinVerified: false) after a timeout sends back to PIN entry even from home',
      () {
        // Simulates IdleTimeoutController having called pinVerifiedProvider.reset()
        // after the app was backgrounded past the threshold.
        expect(
          decideAuthRedirect(
            hasSession: true,
            hasPin: true,
            pinVerified: false,
            roles: const [UserRole.elder],
            location: AuthRoutes.home,
          ),
          AuthRoutes.pinEntry,
        );
      },
    );
  });
}
