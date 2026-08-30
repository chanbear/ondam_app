import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sms_message.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../providers/sms_permission_provider.dart';
import '../widgets/manual_message_input_view.dart';
import '../widgets/sms_recent_list_view.dart';
import 'message_risk_result_page.dart';

/// 문자 확인 진입점 — Phase 7 결정사항: Android는 최근 문자 자동 조회,
/// iOS(및 자동 조회를 지원하지 않는 모든 플랫폼)는 붙여넣기/직접 입력.
/// 두 흐름 모두 이 화면 하나에서 권한 상태(`SmsPermissionStatus`)만으로
/// 분기한다 — 위젯이 `Platform.isAndroid`를 직접 참조하지 않는다(그
/// 판단은 이미 data 계층의 repository factory에서 끝났다).
class MessageCheckEntryPage extends ConsumerWidget {
  const MessageCheckEntryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final permissionAsync = ref.watch(smsPermissionProvider);
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      title: l10n.messageCheckLabel,
      onBack: () => Navigator.of(context).pop(),
      scrollable: false,
      body: permissionAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: l10n.smsPermissionCheckError,
          onRetry: () => ref.invalidate(smsPermissionProvider),
        ),
        data: (status) {
          return switch (status) {
            SmsPermissionStatus.granted => _RecentMessagesView(l10n: l10n),
            SmsPermissionStatus.denied => _PermissionRequestView(
              easyMode: easyMode,
              onRequest: () =>
                  ref.read(smsPermissionProvider.notifier).request(),
            ),
            SmsPermissionStatus.permanentlyDenied => _PermissionBlockedView(
              easyMode: easyMode,
            ),
            SmsPermissionStatus.unsupported => ManualMessageInputView(
              easyMode: easyMode,
              onAnalyze: (text) => _openResult(context, text),
            ),
          };
        },
      ),
    );
  }

  void _openResult(BuildContext context, String body) {
    final message = SmsMessage(
      sender: null,
      body: body,
      receivedAt: DateTime.now(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MessageRiskResultPage(message: message),
      ),
    );
  }
}

/// 문자 목록 진입 — ui-prototype `msg-list`: 목록 위에 2줄 안내문
/// ("최근 문자를 가져왔어요.\n확인하고 싶은 문자를 눌러주세요.")을 먼저
/// 보여준다. 제목("문자 확인")은 이미 표준 [AppHeader]가 담당하므로 여기서
/// 다시 h1을 반복하지 않는다.
class _RecentMessagesView extends StatelessWidget {
  const _RecentMessagesView({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.recentMessagesIntro, style: AppTextStyles.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        const Expanded(child: SmsRecentListView()),
      ],
    );
  }
}

class _PermissionRequestView extends StatelessWidget {
  const _PermissionRequestView({
    required this.easyMode,
    required this.onRequest,
  });

  final bool easyMode;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sms_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.smsPermissionRequestMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.smsPermissionRequestButton,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}

class _PermissionBlockedView extends StatelessWidget {
  const _PermissionBlockedView({required this.easyMode});

  final bool easyMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.block_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.smsPermissionBlockedMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.openSettingsButton,
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: openAppSettings,
          ),
        ],
      ),
    );
  }
}
