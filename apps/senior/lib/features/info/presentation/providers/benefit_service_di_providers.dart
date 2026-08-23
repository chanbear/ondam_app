import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/benefit_service_remote_datasource.dart';
import '../../data/repositories/benefit_service_repository_impl.dart';
import '../../domain/repositories/benefit_service_repository.dart';
import '../../domain/usecases/get_benefit_service_detail_usecase.dart';
import '../../domain/usecases/search_benefit_services_usecase.dart';

final benefitServiceRemoteDataSourceProvider = Provider(
  (ref) => BenefitServiceRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final benefitServiceRepositoryProvider = Provider<BenefitServiceRepository>((
  ref,
) {
  return BenefitServiceRepositoryImpl(
    ref.watch(benefitServiceRemoteDataSourceProvider),
  );
});

final searchBenefitServicesUseCaseProvider = Provider(
  (ref) =>
      SearchBenefitServicesUseCase(ref.watch(benefitServiceRepositoryProvider)),
);

final getBenefitServiceDetailUseCaseProvider = Provider(
  (ref) => GetBenefitServiceDetailUseCase(
    ref.watch(benefitServiceRepositoryProvider),
  ),
);
