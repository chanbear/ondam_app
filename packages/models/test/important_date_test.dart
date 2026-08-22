import 'package:ondam_models/ondam_models.dart';
import 'package:test/test.dart';

void main() {
  group('ImportantDateKind', () {
    test('fromWireValue는 정의된 6개 종류를 왕복 변환한다', () {
      for (final kind in ImportantDateKind.values) {
        expect(ImportantDateKind.fromWireValue(kind.toWireValue()), kind);
      }
    });

    test('fromWireValue는 알 수 없는 값을 조용히 무시하지 않고 예외를 던진다', () {
      expect(
        () => ImportantDateKind.fromWireValue('알수없음'),
        throwsArgumentError,
      );
    });
  });

  group('ImportantDatePriority', () {
    test('fromWireValue는 정의된 3개 우선순위를 왕복 변환한다', () {
      for (final priority in ImportantDatePriority.values) {
        expect(
          ImportantDatePriority.fromWireValue(priority.toWireValue()),
          priority,
        );
      }
    });
  });

  test('priority/needsSourceEvidence를 지정하지 않으면 기본값(medium/false)을 쓴다', () {
    final date = ImportantDate(
      date: DateTime(2026, 8, 25),
      kind: ImportantDateKind.paymentDue,
    );

    expect(date.priority, ImportantDatePriority.medium);
    expect(date.needsSourceEvidence, isFalse);
    expect(date.label, isNull);
  });

  test('label/priority/needsSourceEvidence를 명시하면 그대로 보존된다', () {
    final date = ImportantDate(
      date: DateTime(2026, 8, 25),
      kind: ImportantDateKind.paymentDue,
      label: '전기요금 납부기한',
      priority: ImportantDatePriority.high,
      needsSourceEvidence: true,
    );

    expect(date.label, '전기요금 납부기한');
    expect(date.priority, ImportantDatePriority.high);
    expect(date.needsSourceEvidence, isTrue);
  });
}
