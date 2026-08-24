import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import 'schedule_di_providers.dart';

/// 다가오는 순서(soonest first)로 정렬된 본인 일정 목록. AsyncNotifier라서
/// `ScheduleTabView`가 `.when(...)`으로 그린다(riverpod.md).
///
/// toggleCompleted/delete는 검증할 비즈니스 로직이 없는 단순 CRUD라
/// UseCase 없이 Repository를 직접 호출한다(architecture.md: "usecase가
/// 단순 CRUD 하나뿐이면 repository를 provider에서 직접 호출해도 된다") —
/// 유효성 검증이 실제로 있는 create만 `CreateScheduleUseCase`를 거친다.
class ScheduleNotifier extends AsyncNotifier<List<Schedule>> {
  @override
  Future<List<Schedule>> build() async {
    final result = await ref.read(getMySchedulesUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// 확인 완료가 성공하면 목록도 함께 다시 조회한다 — `AnalysisRecordsNotifier.confirm`와
  /// 동일한 invalidateSelf+재조회 패턴(riverpod.md).
  Future<Result<void>> create({
    required String title,
    required DateTime scheduledAt,
    required bool isRecurring,
    int? recurrenceHour,
    int? recurrenceMinute,
  }) async {
    final result = await ref
        .read(createScheduleUseCaseProvider)
        .call(
          title: title,
          scheduledAt: scheduledAt,
          isRecurring: isRecurring,
          recurrenceHour: recurrenceHour,
          recurrenceMinute: recurrenceMinute,
        );
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  Future<Result<void>> toggleCompleted(String id, bool completed) async {
    final result = await ref
        .read(scheduleRepositoryProvider)
        .toggleCompleted(id, completed);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }

  Future<Result<void>> delete(String id) async {
    final result = await ref
        .read(scheduleRepositoryProvider)
        .deleteSchedule(id);
    if (result case Ok()) {
      ref.invalidateSelf();
      await future;
    }
    return result;
  }
}

final scheduleListProvider =
    AsyncNotifierProvider<ScheduleNotifier, List<Schedule>>(
      ScheduleNotifier.new,
    );
