import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';
import 'package:ondam_senior/features/connection/domain/entities/connection_token.dart';
import 'package:ondam_senior/features/connection/domain/repositories/connection_repository.dart';

/// Configurable fake — same pattern as `FakeAuthRepository` (testing.md:
/// Repository is faked, not hit over network).
class FakeConnectionRepository implements ConnectionRepository {
  Result<ConnectionToken> generateConnectionTokenResult = Ok(
    ConnectionToken(
      token: 'token-abc',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ),
  );
  Result<List<GuardianLink>> getGuardianLinksResult = const Ok(
    <GuardianLink>[],
  );
  Result<void> respondToRequestResult = const Ok(null);
  Result<void> revokeLinkResult = const Ok(null);

  final List<({String linkId, bool accept})> respondToRequestCalls = [];
  final List<String> revokeLinkCalls = [];
  int getGuardianLinksCallCount = 0;

  @override
  Future<Result<ConnectionToken>> generateConnectionToken() async =>
      generateConnectionTokenResult;

  @override
  Future<Result<List<GuardianLink>>> getGuardianLinks() async {
    getGuardianLinksCallCount++;
    return getGuardianLinksResult;
  }

  @override
  Future<Result<void>> respondToRequest({
    required String linkId,
    required bool accept,
  }) async {
    respondToRequestCalls.add((linkId: linkId, accept: accept));
    return respondToRequestResult;
  }

  @override
  Future<Result<void>> revokeLink(String linkId) async {
    revokeLinkCalls.add(linkId);
    return revokeLinkResult;
  }
}
