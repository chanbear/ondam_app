import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../core/easy_mode/easy_mode_provider.dart';
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

    return AppScaffold(
      title: '문자 확인',
      onBack: () => Navigator.of(context).pop(),
      scrollable: false,
      body: permissionAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: '문자 권한을 확인하지 못했어요.',
          onRetry: () => ref.invalidate(smsPermissionProvider),
        ),
        data: (status) {
          return switch (status) {
            SmsPermissionStatus.granted => const SmsRecentListView(),
            SmsPermissionStatus.denied => _PermissionRequestView(
              easyMode: easyMode,
              onRequest: () =>
                  ref.read(smsPermissionProvider.notifier).request(),
            ),
            SmsPermissionStatus.permanentlyDenied =>
              const _PermissionBlockedView(),
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
            '받은 문자를 확인해 위험한 문자인지 알려드리려면\n문자 접근을 허용해주세요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: '문자 권한 허용하기',
            size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
            onPressed: onRequest,
          ),
        ],
      ),
    );
  }
}

class _PermissionBlockedView extends StatelessWidget {
  const _PermissionBlockedView();

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
            '문자 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: '설정 열기', onPressed: openAppSettings),
        ],
      ),
    );
  }
}
