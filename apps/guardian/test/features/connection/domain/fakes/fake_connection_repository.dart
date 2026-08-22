import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_guardian/features/connection/domain/repositories/connection_repository.dart';
import 'package:ondam_models/ondam_models.dart';

/// Configurable fake — same pattern as the Senior app's
/// `FakeConnectionRepository` (testing.md: Repository is faked, not hit
/// over network). Not shared code between apps by design (architecture.md).
class FakeConnectionRepository implements ConnectionRepository {
  Result<GuardianLink> redeemConnectionTokenResult = Ok(
    GuardianLink(
      id: 'link-1',
      elderId: 'elder-1',
      guardianId: 'guardian-1',
      status: GuardianLinkStatus.pending,
      createdAt: DateTime.now(),
    ),
  );
  Result<List<GuardianLink>> getMyLinksResult = const Ok(<GuardianLink>[]);
  Result<void> revokeLinkResult = const Ok(null);

  final List<String> redeemConnectionTokenCalls = [];
  final List<String> revokeLinkCalls = [];
  int getMyLinksCallCount = 0;

  @override
  Future<Result<GuardianLink>> redeemConnectionToken(String token) async {
    redeemConnectionTokenCalls.add(token);
    return redeemConnectionTokenResult;
  }

  @override
  Future<Result<List<GuardianLink>>> getMyLinks() async {
    getMyLinksCallCount++;
    return getMyLinksResult;
  }

  @override
  Future<Result<void>> revokeLink(String linkId) async {
    revokeLinkCalls.add(linkId);
    return revokeLinkResult;
  }
}
