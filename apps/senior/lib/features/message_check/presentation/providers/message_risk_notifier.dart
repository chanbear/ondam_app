import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../domain/entities/sms_message.dart';
import 'message_check_di_providers.dart';

/// Drives the "분석 요청" step — mirrors `document_scan`'s
/// `AnalysisNotifier`. `state` is `AsyncValue<AnalysisResult>` so the result
/// screen renders loading/error/data uniformly; an `UnavailableFailure` (no
/// backend yet) is a normal, expected `AsyncError`, not a bug.
class MessageRiskNotifier extends AsyncNotifier<AnalysisResult?> {
  @override
  FutureOr<AnalysisResult?> build() => null;

  Future<Result<AnalysisResult>> analyze(SmsMessage message) async {
    state = const AsyncLoading();
    final result = await ref
        .read(checkMessageRiskUseCaseProvider)
        .call(message);
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    return result;
  }
}

final messageRiskNotifierProvider =
    AsyncNotifierProvider<MessageRiskNotifier, AnalysisResult?>(
      MessageRiskNotifier.new,
    );
