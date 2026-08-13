import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/pin_verify_result.dart';

/// Auth/PIN/Role operations for the Guardian app. Implemented by
/// `data/repositories/auth_repository_impl.dart`, which is the boundary
/// that turns Supabase SDK exceptions into [Failure]s — presentation code
/// never sees `AuthException`/`PostgrestException`/`FunctionException`.
abstract class AuthRepository {
  /// Sends an OTP SMS to [phoneNumber] (E.164 format, e.g. `+8210...`).
  Future<Result<void>> requestOtp(String phoneNumber);

  /// Verifies the OTP code, establishing a Supabase Auth session on success.
  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  /// Ends the Supabase Auth session (full sign-out, not just the PIN gate).
  Future<Result<void>> signOut();

  /// Sets the PIN for the current session's user (first-time setup).
  Future<Result<void>> setPin(String pin);

  /// Verifies [pin] for the current session's user against the
  /// server-side lockout policy.
  Future<Result<PinVerifyResult>> verifyPin(String pin);

  /// Overwrites the PIN after fresh OTP re-authentication (forgot-PIN flow).
  Future<Result<void>> resetPin(String pin);

  /// Whether the current session's user already has a PIN set — used to
  /// route to PIN setup vs PIN entry. Never reveals anything about the PIN
  /// itself.
  Future<Result<bool>> hasPin();

  /// Deletes the current user's account and all owned data (cascades per
  /// technical-decisions.md §2 item 10).
  Future<Result<void>> deleteAccount();

  /// Adds [role] to the current session's user (onboarding role choice).
  Future<Result<void>> addRole(UserRole role);

  /// Roles currently held by the signed-in user.
  Future<Result<List<UserRole>>> getRoles();
}
