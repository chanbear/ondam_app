import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';

import '../../domain/entities/sms_message.dart';
import 'message_check_di_providers.dart';

/// Recent-inbox list — only meaningfully invoked once permission is
/// `granted` (see `message_check_entry_page.dart`).
class SmsInboxNotifier extends AsyncNotifier<List<SmsMessage>> {
  @override
  Future<List<SmsMessage>> build() async {
    final result = await ref.read(fetchRecentSmsUseCaseProvider).call();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }
}

final smsInboxProvider =
    AsyncNotifierProvider<SmsInboxNotifier, List<SmsMessage>>(
      SmsInboxNotifier.new,
    );
