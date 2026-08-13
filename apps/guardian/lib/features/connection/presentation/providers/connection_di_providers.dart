import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/connection_remote_datasource.dart';
import '../../data/repositories/connection_repository_impl.dart';
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
