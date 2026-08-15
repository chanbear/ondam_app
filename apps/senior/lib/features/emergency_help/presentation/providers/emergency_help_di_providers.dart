import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/dialer_repository_impl.dart';
import '../../domain/repositories/dialer_repository.dart';
import '../../domain/usecases/call_phone_usecase.dart';

final dialerRepositoryProvider = Provider<DialerRepository>(
  (ref) => const DialerRepositoryImpl(),
);

final callPhoneUseCaseProvider = Provider(
  (ref) => CallPhoneUseCase(ref.watch(dialerRepositoryProvider)),
);
