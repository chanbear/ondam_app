import 'package:ondam_core/ondam_core.dart';

import '../entities/sms_permission_status.dart';
import '../repositories/sms_inbox_repository.dart';

/// Triggers the OS permission prompt (first-time request only — if already
/// permanently denied, the OS silently returns the current status without
/// prompting; the UI must detect that case separately and offer a
/// settings-open path instead of calling this again).
class RequestSmsPermissionUseCase {
  const RequestSmsPermissionUseCase(this._repository);

  final SmsInboxRepository _repository;

  Future<Result<SmsPermissionStatus>> call() => _repository.requestPermission();
}
