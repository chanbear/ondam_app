import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/welfare_center_remote_datasource.dart';
import '../../data/repositories/welfare_center_repository_impl.dart';
import '../../domain/repositories/welfare_center_repository.dart';
import '../../domain/usecases/search_welfare_centers_usecase.dart';

final welfareCenterRemoteDataSourceProvider = Provider(
  (ref) => WelfareCenterRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final welfareCenterRepositoryProvider = Provider<WelfareCenterRepository>((
  ref,
) {
  return WelfareCenterRepositoryImpl(
    ref.watch(welfareCenterRemoteDataSourceProvider),
  );
});

final searchWelfareCentersUseCaseProvider = Provider(
  (ref) =>
      SearchWelfareCentersUseCase(ref.watch(welfareCenterRepositoryProvider)),
);
