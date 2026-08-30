import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/pin_verify_result.dart';
import '../entities/social_auth_provider.dart';

/// Auth/PIN/Role operations for the Senior app. Implemented by
/// `data/repositories/auth_repository_impl.dart`, which is the boundary
/// that turns Supabase SDK exceptions into [Failure]s — presentation code
/// never sees `AuthException`/`PostgrestException`/`FunctionException`.
abstract class AuthRepository {
  /// Signs up (first time) or signs in (returning) by phone number alone —
  /// no OTP/SMS verification (technical-decisions.md §1-3-A "OTP 제거").
  /// [phoneNumber] must be E.164 format (e.g. `+8210...`). [name] is only
  /// actually stored on first signup; returning callers may pass anything
  /// non-empty. Establishes a Supabase Auth session on success.
  Future<Result<void>> signUp({
    required String name,
    required String phoneNumber,
  });

  /// Opens the system browser for [provider]'s OAuth consent screen. Returns
  /// once the browser has been launched — NOT once the user has finished
  /// authenticating. The resulting session (if the user completes the flow)
  /// arrives later via the deep-link redirect and shows up through Supabase's
  /// own auth-state stream ([AuthRepository] has no separate "wait for OAuth
  /// result" call; callers watch `authStateChangesProvider`/`hasPinProvider`
  /// same as any other session change).
  Future<Result<void>> signInWithOAuth(SocialAuthProvider provider);

  /// Starts an anonymous Supabase session — no phone/OAuth identity attached.
  /// The caller still goes through the same first-time PIN-setup step as any
  /// other new session (an anonymous user's `currentUser.phone` is also
  /// null/empty, so it naturally routes into the existing OAuth-session PIN
  /// UI branch in `phone_input_page.dart`).
  Future<Result<void>> signInAsGuest();

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
