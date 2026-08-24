import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../repositories/schedule_repository.dart';

class GetSchedulesForElderUseCase {
  const GetSchedulesForElderUseCase(this._repository);

  final ScheduleRepository _repository;

  Future<Result<List<Schedule>>> call(String elderId) =>
      _repository.getSchedulesForElder(elderId);
}
