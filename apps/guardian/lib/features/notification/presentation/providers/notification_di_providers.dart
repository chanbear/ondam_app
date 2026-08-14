import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../../data/datasources/fcm_token_remote_datasource.dart';
import '../../data/datasources/notification_remote_datasource.dart';
import '../../data/repositories/fcm_token_repository_impl.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../domain/repositories/fcm_token_repository.dart';
import '../../domain/repositories/notification_repository.dart';
import '../../domain/usecases/get_my_notifications_usecase.dart';
import '../../domain/usecases/invalidate_fcm_token_usecase.dart';
import '../../domain/usecases/mark_notification_read_usecase.dart';
import '../../domain/usecases/register_fcm_token_usecase.dart';

// Dependency injection wiring only — no business logic (riverpod.md).

final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      return NotificationRemoteDataSource(ref.watch(supabaseClientProvider));
    });

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(
    ref.watch(notificationRemoteDataSourceProvider),
  );
});

final getMyNotificationsUseCaseProvider = Provider(
  (ref) => GetMyNotificationsUseCase(ref.watch(notificationRepositoryProvider)),
);

final markNotificationReadUseCaseProvider = Provider(
  (ref) =>
      MarkNotificationReadUseCase(ref.watch(notificationRepositoryProvider)),
);

final fcmTokenRemoteDataSourceProvider = Provider<FcmTokenRemoteDataSource>((
  ref,
) {
  return FcmTokenRemoteDataSource(ref.watch(supabaseClientProvider));
});

final fcmTokenRepositoryProvider = Provider<FcmTokenRepository>((ref) {
  return FcmTokenRepositoryImpl(ref.watch(fcmTokenRemoteDataSourceProvider));
});

final registerFcmTokenUseCaseProvider = Provider(
  (ref) => RegisterFcmTokenUseCase(ref.watch(fcmTokenRepositoryProvider)),
);

final invalidateFcmTokenUseCaseProvider = Provider(
  (ref) => InvalidateFcmTokenUseCase(ref.watch(fcmTokenRepositoryProvider)),
);
