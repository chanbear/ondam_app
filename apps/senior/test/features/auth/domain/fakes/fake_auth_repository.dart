import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/auth/domain/entities/pin_verify_result.dart';
import 'package:ondam_senior/features/auth/domain/repositories/auth_repository.dart';

/// Configurable fake — each field is the [Result] the fake returns for that
/// method, and each `*Calls` list records the arguments it was called with,
/// so tests can assert both outcome and call shape without a mocking
/// package (testing.md: Repository is faked/mocked, not hit over network).
class FakeAuthRepository implements AuthRepository {
  Result<void> requestOtpResult = const Ok(null);
  Result<void> verifyOtpResult = const Ok(null);
  Result<void> signOutResult = const Ok(null);
  Result<void> setPinResult = const Ok(null);
  Result<PinVerifyResult> verifyPinResult = const Ok(PinVerifyResult.success());
  Result<void> resetPinResult = const Ok(null);
  Result<bool> hasPinResult = const Ok(false);
  Result<void> deleteAccountResult = const Ok(null);
  Result<void> addRoleResult = const Ok(null);
  Result<List<UserRole>> getRolesResult = const Ok(<UserRole>[]);

  final List<String> requestOtpCalls = [];
  final List<({String phoneNumber, String otp})> verifyOtpCalls = [];
  final List<String> setPinCalls = [];
  final List<String> verifyPinCalls = [];
  final List<String> resetPinCalls = [];
  final List<UserRole> addRoleCalls = [];

  @override
  Future<Result<void>> requestOtp(String phoneNumber) async {
    requestOtpCalls.add(phoneNumber);
    return requestOtpResult;
  }

  @override
  Future<Result<void>> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    verifyOtpCalls.add((phoneNumber: phoneNumber, otp: otp));
    return verifyOtpResult;
  }

  @override
  Future<Result<void>> signOut() async => signOutResult;

  @override
  Future<Result<void>> setPin(String pin) async {
    setPinCalls.add(pin);
    return setPinResult;
  }

  @override
  Future<Result<PinVerifyResult>> verifyPin(String pin) async {
    verifyPinCalls.add(pin);
    return verifyPinResult;
  }

  @override
  Future<Result<void>> resetPin(String pin) async {
    resetPinCalls.add(pin);
    return resetPinResult;
  }

  @override
  Future<Result<bool>> hasPin() async => hasPinResult;

  @override
  Future<Result<void>> deleteAccount() async => deleteAccountResult;

  @override
  Future<Result<void>> addRole(UserRole role) async {
    addRoleCalls.add(role);
    return addRoleResult;
  }

  @override
  Future<Result<List<UserRole>>> getRoles() async => getRolesResult;
}
