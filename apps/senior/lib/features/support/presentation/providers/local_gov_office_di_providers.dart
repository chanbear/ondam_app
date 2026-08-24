import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/local_gov_office_remote_datasource.dart';
import '../../data/repositories/local_gov_office_repository_impl.dart';
import '../../domain/repositories/local_gov_office_repository.dart';
import '../../domain/usecases/search_local_gov_office_usecase.dart';

final localGovOfficeRemoteDataSourceProvider = Provider(
  (ref) => LocalGovOfficeRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final localGovOfficeRepositoryProvider = Provider<LocalGovOfficeRepository>((
  ref,
) {
  return LocalGovOfficeRepositoryImpl(
    ref.watch(localGovOfficeRemoteDataSourceProvider),
  );
});

final searchLocalGovOfficeUseCaseProvider = Provider(
  (ref) =>
      SearchLocalGovOfficeUseCase(ref.watch(localGovOfficeRepositoryProvider)),
);
