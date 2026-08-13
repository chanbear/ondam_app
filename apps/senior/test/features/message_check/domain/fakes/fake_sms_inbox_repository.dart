import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_permission_status.dart';
import 'package:ondam_senior/features/message_check/domain/repositories/sms_inbox_repository.dart';

class FakeSmsInboxRepository implements SmsInboxRepository {
  Result<SmsPermissionStatus> checkResult = const Ok(
    SmsPermissionStatus.denied,
  );
  Result<SmsPermissionStatus> requestResult = const Ok(
    SmsPermissionStatus.granted,
  );
  Result<List<SmsMessage>> fetchResult = const Ok(<SmsMessage>[]);

  int checkCalls = 0;
  int requestCalls = 0;
  int fetchCalls = 0;

  @override
  Future<Result<SmsPermissionStatus>> checkPermission() async {
    checkCalls++;
    return checkResult;
  }

  @override
  Future<Result<SmsPermissionStatus>> requestPermission() async {
    requestCalls++;
    return requestResult;
  }

  @override
  Future<Result<List<SmsMessage>>> fetchRecentMessages() async {
    fetchCalls++;
    return fetchResult;
  }
}
