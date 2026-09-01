import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/connection_remote_datasource.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/entities/demo_usage_stats.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/get_my_links_usecase.dart';
import '../../domain/usecases/redeem_connection_token_usecase.dart';
import '../../domain/usecases/revoke_guardian_link_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final connectionRemoteDataSourceProvider = Provider<ConnectionRemoteDataSource>(
  (ref) {
    return ConnectionRemoteDataSource(ref.watch(supabaseClientProvider));
  },
);

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  return ConnectionRepositoryImpl(
    ref.watch(connectionRemoteDataSourceProvider),
  );
});

final redeemConnectionTokenUseCaseProvider = Provider(
  (ref) =>
      RedeemConnectionTokenUseCase(ref.watch(connectionRepositoryProvider)),
);

final getMyLinksUseCaseProvider = Provider(
  (ref) => GetMyLinksUseCase(ref.watch(connectionRepositoryProvider)),
);

final revokeGuardianLinkUseCaseProvider = Provider(
  (ref) => RevokeGuardianLinkUseCase(ref.watch(connectionRepositoryProvider)),
);

/// 단순 조회라 usecase 없이 provider가 직접 repository를 호출한다
/// (architecture.md — "usecase가 단순 CRUD 하나뿐이면 provider에서 직접
/// repository 호출 허용"). 조회 실패는 장식용 배지를 안 보여주는 것으로
/// 충분해 null로 흡수한다 — 에러 UI를 따로 두지 않는다.
final demoUsageStatsProvider = FutureProvider.family<DemoUsageStats?, String>((
  ref,
  elderId,
) async {
  final result = await ref
      .watch(connectionRepositoryProvider)
      .getDemoUsageStats(elderId);
  return switch (result) {
    Ok(:final value) => value,
    Err() => null,
  };
});
