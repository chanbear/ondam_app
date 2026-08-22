import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/auth/domain/entities/pin_verify_result.dart';
import 'package:ondam_senior/features/auth/domain/repositories/auth_repository.dart';

/// Configurable fake — each field is the [Result] the fake returns for that
/// method, and each `*Calls` list records the arguments it was called with,
/// so tests can assert both outcome and call shape without a mocking
/// package (testing.md: Repository is faked/mocked, not hit over network).
class FakeAuthRepository implements AuthRepository {
  Result<void> signUpResult = const Ok(null);
  Result<void> signOutResult = const Ok(null);
  Result<void> setPinResult = const Ok(null);
  Result<PinVerifyResult> verifyPinResult = const Ok(PinVerifyResult.success());
  Result<void> resetPinResult = const Ok(null);
  Result<bool> hasPinResult = const Ok(false);
  Result<void> deleteAccountResult = const Ok(null);
  Result<void> addRoleResult = const Ok(null);
  Result<List<UserRole>> getRolesResult = const Ok(<UserRole>[]);

  final List<({String name, String phoneNumber})> signUpCalls = [];
  final List<String> setPinCalls = [];
  final List<String> verifyPinCalls = [];
  final List<String> resetPinCalls = [];
  final List<UserRole> addRoleCalls = [];
  int signOutCalls = 0;
  int deleteAccountCalls = 0;
  int hasPinCalls = 0;
  int getRolesCalls = 0;

  @override
  Future<Result<void>> signUp({
    required String name,
    required String phoneNumber,
  }) async {
    signUpCalls.add((name: name, phoneNumber: phoneNumber));
    return signUpResult;
  }

  @override
  Future<Result<void>> signOut() async {
    signOutCalls++;
    return signOutResult;
  }

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
  Future<Result<bool>> hasPin() async {
    hasPinCalls++;
    return hasPinResult;
  }

  @override
  Future<Result<void>> deleteAccount() async {
    deleteAccountCalls++;
    return deleteAccountResult;
  }

  @override
  Future<Result<void>> addRole(UserRole role) async {
    addRoleCalls.add(role);
    return addRoleResult;
  }

  @override
  Future<Result<List<UserRole>>> getRoles() async {
    getRolesCalls++;
    return getRolesResult;
  }
}
