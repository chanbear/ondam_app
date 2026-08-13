import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/connection_token.dart';

/// Senior-side of the `connection` feature: showing a QR token for a
/// guardian to scan, and managing the resulting guardian_links rows
/// (list/accept/reject/revoke). Implemented by
/// `data/repositories/connection_repository_impl.dart`.
abstract class ConnectionRepository {
  /// Requests a new short-lived token from the server to render as a QR
  /// code (technical-decisions.md §1-6 v9).
  Future<Result<ConnectionToken>> generateConnectionToken();

  /// All guardian_links rows where the current user is the elder, regardless
  /// of status (pending/accepted/rejected/revoked) — the UI filters by
  /// status as needed.
  Future<Result<List<GuardianLink>>> getGuardianLinks();

  /// Accepts or rejects a `pending` request. Only valid while the link is
  /// still pending — enforced server-side by RLS, not just here.
  Future<Result<void>> respondToRequest({
    required String linkId,
    required bool accept,
  });

  /// Ends an `accepted` connection. Only the elder can do this
  /// (technical-decisions.md §1-5 필수요구사항 2).
  Future<Result<void>> revokeLink(String linkId);
}
