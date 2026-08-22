import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/guardian_contact_remote_datasource.dart';
import '../../data/repositories/dialer_repository_impl.dart';
import '../../data/repositories/guardian_contact_repository_impl.dart';
import '../../domain/repositories/dialer_repository.dart';
import '../../domain/repositories/guardian_contact_repository.dart';
import '../../domain/usecases/call_phone_usecase.dart';
import '../../domain/usecases/get_guardian_phone_usecase.dart';

final dialerRepositoryProvider = Provider<DialerRepository>(
  (ref) => const DialerRepositoryImpl(),
);

final callPhoneUseCaseProvider = Provider(
  (ref) => CallPhoneUseCase(ref.watch(dialerRepositoryProvider)),
);

final guardianContactRemoteDataSourceProvider =
    Provider<GuardianContactRemoteDataSource>(
      (ref) =>
          GuardianContactRemoteDataSource(ref.watch(supabaseClientProvider)),
    );

final guardianContactRepositoryProvider = Provider<GuardianContactRepository>(
  (ref) => GuardianContactRepositoryImpl(
    ref.watch(guardianContactRemoteDataSourceProvider),
  ),
);

final getGuardianPhoneUseCaseProvider = Provider(
  (ref) =>
      GetGuardianPhoneUseCase(ref.watch(guardianContactRepositoryProvider)),
);
