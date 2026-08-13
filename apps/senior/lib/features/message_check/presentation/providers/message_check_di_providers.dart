import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/message_risk_repository_impl.dart';
import '../../data/repositories/sms_inbox_repository_factory.dart';
import '../../domain/repositories/message_risk_repository.dart';
import '../../domain/repositories/sms_inbox_repository.dart';
import '../../domain/usecases/check_message_risk_usecase.dart';
import '../../domain/usecases/check_sms_permission_usecase.dart';
import '../../domain/usecases/fetch_recent_sms_usecase.dart';
import '../../domain/usecases/request_sms_permission_usecase.dart';

final smsInboxRepositoryProvider = Provider<SmsInboxRepository>((ref) {
  return createSmsInboxRepository();
});

final messageRiskRepositoryProvider = Provider<MessageRiskRepository>((ref) {
  return const MessageRiskRepositoryImpl();
});

final checkSmsPermissionUseCaseProvider = Provider(
  (ref) => CheckSmsPermissionUseCase(ref.watch(smsInboxRepositoryProvider)),
);

final requestSmsPermissionUseCaseProvider = Provider(
  (ref) => RequestSmsPermissionUseCase(ref.watch(smsInboxRepositoryProvider)),
);

final fetchRecentSmsUseCaseProvider = Provider(
  (ref) => FetchRecentSmsUseCase(ref.watch(smsInboxRepositoryProvider)),
);

final checkMessageRiskUseCaseProvider = Provider(
  (ref) => CheckMessageRiskUseCase(ref.watch(messageRiskRepositoryProvider)),
);
