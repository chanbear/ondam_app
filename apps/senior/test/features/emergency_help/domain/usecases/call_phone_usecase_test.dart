import 'package:flutter_test/flutter_test.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_senior/features/emergency_help/domain/usecases/call_phone_usecase.dart';

import '../fakes/fake_dialer_repository.dart';

void main() {
  late FakeDialerRepository repository;
  late CallPhoneUseCase usecase;

  setUp(() {
    repository = FakeDialerRepository();
    usecase = CallPhoneUseCase(repository);
  });

  test('전화번호가 비어있으면 ValidationFailure를 반환하고 repository를 호출하지 않는다', () async {
    final result = await usecase.call('');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<ValidationFailure>());
    expect(repository.lastCalledNumber, isNull);
  });

  test('전화번호가 있으면 repository에 그대로 위임한다', () async {
    final result = await usecase.call('119');

    expect(result, isA<Ok<void>>());
    expect(repository.lastCalledNumber, '119');
  });

  test('repository가 실패를 반환하면 그대로 전달한다', () async {
    repository.result = const Err(UnavailableFailure('전화 앱을 열 수 없어요.'));

    final result = await usecase.call('112');

    expect(result, isA<Err<void>>());
    expect((result as Err<void>).failure, isA<UnavailableFailure>());
  });
}
