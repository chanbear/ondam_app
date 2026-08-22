import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/guardian_contact_repository.dart';
import '../datasources/guardian_contact_remote_datasource.dart';

/// Translates Supabase SDK exceptions into domain [Failure]s — same pattern
/// as `ConnectionRepositoryImpl` (api.md Repository responsibility).
class GuardianContactRepositoryImpl implements GuardianContactRepository {
  const GuardianContactRepositoryImpl(this._dataSource);

  final GuardianContactRemoteDataSource _dataSource;

  @override
  Future<Result<String?>> getGuardianPhone() async {
    try {
      final phone = await _dataSource.fetchGuardianPhone();
      return Ok(phone);
    } on PostgrestException catch (_) {
      return const Err(ServerFailure());
    } on AuthException catch (_) {
      return const Err(AuthFailure());
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
