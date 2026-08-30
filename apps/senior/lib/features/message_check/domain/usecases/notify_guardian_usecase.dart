import 'package:ondam_core/ondam_core.dart';

import '../repositories/message_risk_repository.dart';

class NotifyGuardianUseCase {
  const NotifyGuardianUseCase(this._repository);

  final MessageRiskRepository _repository;

  Future<Result<void>> call({
    required String targetUserId,
    required String analysisResultId,
  }) => _repository.notifyGuardian(
    targetUserId: targetUserId,
    analysisResultId: analysisResultId,
  );
}
