import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../pages/sms_message_detail_page.dart';
import '../providers/sms_inbox_notifier.dart';
import 'sms_message_tile.dart';

/// Android 권한이 허용된 상태에서 최근 문자 목록을 보여준다. 목록이
/// 비어 있으면(수신함이 실제로 비어 있음) 공용 `AppEmptyState`를 사용한다
/// — 가짜 문자를 만들지 않는다.
class SmsRecentListView extends ConsumerWidget {
  const SmsRecentListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(smsInboxProvider);

    return inboxAsync.when(
      loading: () => const AppLoading(message: '최근 문자를 불러오고 있어요'),
      error: (error, _) {
        final message = error is Failure ? error.message : '문자를 불러오지 못했어요.';
        return AppError(
          message: message,
          onRetry: () => ref.invalidate(smsInboxProvider),
        );
      },
      data: (messages) {
        if (messages.isEmpty) {
          return const AppEmptyState(
            icon: Icons.mark_email_read_outlined,
            message: '최근 받은 문자가 없어요.',
          );
        }
        return ListView.separated(
          itemCount: messages.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final message = messages[index];
            return SmsMessageTile(
              message: message,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SmsMessageDetailPage(message: message),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
