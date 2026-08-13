import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/connection_remote_datasource.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/usecases/generate_connection_token_usecase.dart';
import '../../domain/usecases/get_guardian_links_usecase.dart';
import '../../domain/usecases/respond_to_connection_request_usecase.dart';
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

final generateConnectionTokenUseCaseProvider = Provider(
  (ref) =>
      GenerateConnectionTokenUseCase(ref.watch(connectionRepositoryProvider)),
);

final getGuardianLinksUseCaseProvider = Provider(
  (ref) => GetGuardianLinksUseCase(ref.watch(connectionRepositoryProvider)),
);

final respondToConnectionRequestUseCaseProvider = Provider(
  (ref) => RespondToConnectionRequestUseCase(
    ref.watch(connectionRepositoryProvider),
  ),
);

final revokeGuardianLinkUseCaseProvider = Provider(
  (ref) => RevokeGuardianLinkUseCase(ref.watch(connectionRepositoryProvider)),
);
