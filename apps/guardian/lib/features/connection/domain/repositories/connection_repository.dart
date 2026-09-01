import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../entities/demo_usage_stats.dart';

/// Guardian-side of the `connection` feature: redeeming a scanned QR token
/// to create a pending connection request, and managing the resulting
/// guardian_links rows. Implemented by
/// `data/repositories/connection_repository_impl.dart`.
abstract class ConnectionRepository {
  /// Sends a scanned QR token to the server. Success only means a `pending`
  /// request now exists — the elder still has to accept it
  /// (technical-decisions.md §1-6 v9).
  Future<Result<GuardianLink>> redeemConnectionToken(String token);

  /// All guardian_links rows where the current user is the guardian.
  Future<Result<List<GuardianLink>>> getMyLinks();

  /// Ends an `accepted` connection from the guardian's side.
  Future<Result<void>> revokeLink(String linkId);

  /// Demo-only "used for N months" figure for [elderId], or `null` if none
  /// was seeded (e.g. connection never went through the QR accept trigger).
  Future<Result<DemoUsageStats?>> getDemoUsageStats(String elderId);
}
