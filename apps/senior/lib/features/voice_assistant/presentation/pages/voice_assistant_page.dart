import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:permission_handler/permission_handler.dart'
    show openAppSettings;

import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../document_scan/presentation/pages/document_scan_camera_page.dart';
import '../../../emergency_help/presentation/widgets/emergency_help_sheet.dart';
import '../../../message_check/presentation/pages/message_check_entry_page.dart';
import '../../../welfare_center/presentation/pages/welfare_center_list_page.dart';
import '../../domain/entities/mic_permission_status.dart';
import '../../domain/entities/voice_intent.dart';
import '../providers/mic_permission_provider.dart';
import '../widgets/voice_interaction_view.dart';

/// 음성 비서 진입점 — 권한 상태별로 명확히 다른 화면을 보여준다(허용/거부/
/// 영구거부/제한), `document_scan`의 `DocumentScanCameraPage`와 동일한 구조.
/// 허용 상태에서만 실제 STT/TTS 상호작용(`VoiceInteractionView`)을 그린다.
///
/// 실제 Navigation은 이 페이지가 전담한다(`VoiceIntent` → 화면) — 새
/// 목적지를 추가할 때는 [VoiceIntent]에 값을 추가하고 이 switch에 한 줄만
/// 더하면 된다.
class VoiceAssistantPage extends ConsumerWidget {
  const VoiceAssistantPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final easyMode = ref.watch(easyModeProvider);
    final permissionAsync = ref.watch(micPermissionProvider);
    final l10n = AppLocalizations.of(context)!;

    return VoiceGuideScaffold(
      title: l10n.voiceAssistantLabel,
      onBack: () => Navigator.of(context).pop(),
      body: permissionAsync.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: l10n.micPermissionCheckError,
          onRetry: () => ref.invalidate(micPermissionProvider),
        ),
        data: (status) {
          return switch (status) {
            MicPermissionStatus.granted => VoiceInteractionView(
              easyMode: easyMode,
              onNavigate: (intent) => _navigate(context, intent),
            ),
            MicPermissionStatus.denied => _PermissionRequestView(
              easyMode: easyMode,
              onRequest: () =>
                  ref.read(micPermissionProvider.notifier).request(),
            ),
            MicPermissionStatus.permanentlyDenied ||
            MicPermissionStatus.restricted => const _PermissionBlockedView(),
          };
        },
      ),
    );
  }

  void _navigate(BuildContext context, VoiceIntent intent) {
    switch (intent) {
      case VoiceIntent.documentScan:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DocumentScanCameraPage()),
        );
      case VoiceIntent.messageCheck:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MessageCheckEntryPage()),
        );
      case VoiceIntent.emergencyHelp:
        EmergencyHelpSheet.show(context);
      case VoiceIntent.welfareCenter:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const WelfareCenterListPage()),
        );
      case VoiceIntent.unrecognized:
        break; // hasImmediateDestination이 false라 여기 도달하지 않는다.
    }
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
          const Icon(Icons.mic_none_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.micPermissionRequestMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.micPermissionRequestButton,
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
          const Icon(Icons.mic_off_outlined, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            AppLocalizations.of(context)!.micPermissionBlockedMessage,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: AppLocalizations.of(context)!.openSettingsButton,
            onPressed: openAppSettings,
          ),
        ],
      ),
    );
  }
}
