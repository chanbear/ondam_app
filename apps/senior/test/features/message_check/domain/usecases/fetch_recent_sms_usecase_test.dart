import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/message_check/domain/entities/sms_message.dart';
import 'package:ondam_senior/features/message_check/domain/usecases/fetch_recent_sms_usecase.dart';

import '../fakes/fake_sms_inbox_repository.dart';

void main() {
  late FakeSmsInboxRepository repository;
  late FetchRecentSmsUseCase useCase;

  setUp(() {
    repository = FakeSmsInboxRepository();
    useCase = FetchRecentSmsUseCase(repository);
  });

  test('returns an empty list when the inbox has no messages', () async {
    repository.fetchResult = const Ok(<SmsMessage>[]);

    final result = await useCase();

    expect((result as Ok<List<SmsMessage>>).value, isEmpty);
  });

  test('returns the repository-provided message list unchanged', () async {
    final messages = [
      SmsMessage(
        sender: '010-1234-5678',
        body: '안녕하세요',
        receivedAt: DateTime(2026, 1, 1),
      ),
    ];
    repository.fetchResult = Ok(messages);

    final result = await useCase();

    expect((result as Ok<List<SmsMessage>>).value, messages);
  });

  test('propagates a repository failure (e.g. unsupported platform)', () async {
    repository.fetchResult = const Err(
      UnavailableFailure('이 기기에서는 문자 자동 확인을 지원하지 않아요.'),
    );

    final result = await useCase();

    expect(result, isA<Err<List<SmsMessage>>>());
    expect(
      (result as Err<List<SmsMessage>>).failure,
      isA<UnavailableFailure>(),
    );
  });
}
