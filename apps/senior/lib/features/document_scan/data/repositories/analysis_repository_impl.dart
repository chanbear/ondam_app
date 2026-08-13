import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/captured_photo.dart';
import '../../domain/repositories/analysis_repository.dart';

/// No datasource file exists here on purpose — there is nothing to wrap
/// yet. When the real analysis backend (Supabase Storage upload + Edge
/// Function, per technical-decisions.md §1-7/§1-8) is built in a later
/// Phase, add `data/datasources/analysis_remote_datasource.dart` and change
/// this method to call it. Until then this always returns
/// `Err(UnavailableFailure())` — never a fabricated [AnalysisResult].
class AnalysisRepositoryImpl implements AnalysisRepository {
  const AnalysisRepositoryImpl();

  @override
  Future<Result<AnalysisResult>> analyzeDocument(CapturedPhoto photo) async {
    return const Err(UnavailableFailure('분석 서버가 아직 준비되지 않았어요. 조금만 기다려주세요.'));
  }
}
