import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/captured_photo.dart';
import 'document_scan_di_providers.dart';

/// Drives the "분석 요청" step. `state` is `AsyncValue<AnalysisResult>` so
/// the result screen renders loading/error/data uniformly — but note an
/// `UnavailableFailure` (no backend yet) is a normal, expected `AsyncError`
/// case, not a bug; the result screen must render it as "준비 중", not as a
/// retry-suggesting generic error (see `document_scan_result_page.dart`).
class AnalysisNotifier extends AsyncNotifier<AnalysisResult?> {
  @override
  FutureOr<AnalysisResult?> build() => null;

  Future<Result<AnalysisResult>> analyze(CapturedPhoto photo) async {
    state = const AsyncLoading();
    final result = await ref.read(analyzeDocumentUseCaseProvider).call(photo);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }
}

final analysisNotifierProvider =
    AsyncNotifierProvider<AnalysisNotifier, AnalysisResult?>(
      AnalysisNotifier.new,
    );
