import 'package:ondam_core/ondam_core.dart';

import '../entities/sms_message.dart';
import '../repositories/sms_inbox_repository.dart';

/// Reads recent SMS messages from the device inbox. Callers must only
/// invoke this after `checkPermission()`/`requestPermission()` resolves to
/// `granted` — the repository does not re-check permission itself.
class FetchRecentSmsUseCase {
  const FetchRecentSmsUseCase(this._repository);

  final SmsInboxRepository _repository;

  Future<Result<List<SmsMessage>>> call() => _repository.fetchRecentMessages();
}
