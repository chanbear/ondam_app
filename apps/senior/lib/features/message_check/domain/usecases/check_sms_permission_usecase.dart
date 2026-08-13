import 'package:ondam_core/ondam_core.dart';

import '../entities/sms_permission_status.dart';
import '../repositories/sms_inbox_repository.dart';

/// Reads the current SMS permission WITHOUT prompting the OS dialog — used
/// when the message-check entry screen loads, to decide which state to show
/// before ever asking the user for anything.
class CheckSmsPermissionUseCase {
  const CheckSmsPermissionUseCase(this._repository);

  final SmsInboxRepository _repository;

  Future<Result<SmsPermissionStatus>> call() => _repository.checkPermission();
}
