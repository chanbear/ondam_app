import 'package:ondam_core/ondam_core.dart';

import '../repositories/schedule_repository.dart';

/// 새 일정을 만들기 전에 입력값을 검증한다 — UI가 아니라 여기서 검증하는
/// 이유는 riverpod.md/ui-design.md 둘 다 "계산/검증 로직은 Notifier/UseCase에
/// 있어야 한다"고 명시하기 때문. [isRecurring]이 true일 때만
/// [recurrenceHour]/[recurrenceMinute]를 요구한다(복약처럼 매일 같은 시각
/// 반복하는 단순 케이스만 지원 — 요구사항 범위).
class CreateScheduleUseCase {
  const CreateScheduleUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Result<void>> call({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  }) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return Future.value(const Err(ValidationFailure('일정 제목을 입력해주세요.')));
    }

    if (isRecurring) {
      if (recurrenceHour == null || recurrenceMinute == null) {
        return Future.value(const Err(ValidationFailure('반복할 시각을 선택해주세요.')));
      }
      if (recurrenceHour < 0 ||
          recurrenceHour > 23 ||
          recurrenceMinute < 0 ||
          recurrenceMinute > 59) {
        return Future.value(const Err(ValidationFailure('반복 시각이 올바르지 않아요.')));
      }
    }

    return _repository.createSchedule(
      title: trimmedTitle,
      scheduledAt: scheduledAt,
      isRecurring: isRecurring,
      recurrenceHour: isRecurring ? recurrenceHour : null,
      recurrenceMinute: isRecurring ? recurrenceMinute : null,
    );
  }
}
