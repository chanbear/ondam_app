import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/supabase_client_provider.dart';
import '../../data/datasources/notification_prefs_remote_datasource.dart';
import '../../data/repositories/notification_prefs_repository_impl.dart';
import '../../domain/repositories/notification_prefs_repository.dart';

final notificationPrefsRemoteDataSourceProvider = Provider(
  (ref) => NotificationPrefsRemoteDataSource(ref.watch(supabaseClientProvider)),
);

final notificationPrefsRepositoryProvider =
    Provider<NotificationPrefsRepository>((ref) {
      return NotificationPrefsRepositoryImpl(
        ref.watch(notificationPrefsRemoteDataSourceProvider),
      );
    });
