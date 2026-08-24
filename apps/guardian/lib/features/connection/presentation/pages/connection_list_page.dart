import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/my_links_notifier.dart';
import 'connection_scan_page.dart';

/// 화면이 열려 있는 동안의 재조회 주기 — Senior 쪽 `GuardianListPage`와
/// 동일한 이유(BUG 1): 연결 요청/승인은 상대(어르신) 앱에서 이뤄지므로 이
/// 화면은 그 변경을 realtime/push로 통보받을 방법이 없다.
const _myLinksRefreshInterval = Duration(seconds: 5);

/// 보호자 측 "어르신 연결 관리" — ui-screen-spec.md "더보기 — 어르신 연결
/// 관리" 대응. pending 요청은 대기 상태만 보여주고(수락/거절은 어르신
/// 전용), accepted 연결은 해제할 수 있다.
class ConnectionListPage extends ConsumerStatefulWidget {
  const ConnectionListPage({super.key});

  @override
  ConsumerState<ConnectionListPage> createState() => _ConnectionListPageState();
}

class _ConnectionListPageState extends ConsumerState<ConnectionListPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(_myLinksRefreshInterval, (_) {
      ref.invalidate(myLinksProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final linksState = ref.watch(myLinksProvider);

    return AppScaffold(
      title: l10n.guardianConnectionManageTitle,
      onBack: () => Navigator.of(context).pop(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionScanPage())),
        label: Text(l10n.connectElderActionLong),
        icon: const Icon(Icons.qr_code_scanner),
      ),
      body: linksState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: l10n.connectionListLoadError,
          onRetry: () => ref.invalidate(myLinksProvider),
        ),
        data: (links) {
          final visible = links
              .where((link) => link.status != GuardianLinkStatus.rejected)
              .toList();
          if (visible.isEmpty) {
            return AppEmptyState(
              message: l10n.connectionListEmptyMessage,
              icon: Icons.person_add_alt_outlined,
              actionLabel: l10n.connectElderActionLong,
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectionScanPage()),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) => _LinkCard(link: visible[index]),
          );
        },
      ),
    );
  }
}

class _LinkCard extends ConsumerWidget {
  const _LinkCard({required this.link});

  final GuardianLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.elderly_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.elderPlaceholderName(_shortId(link.elderId)),
                  style: AppTextStyles.bodyLarge,
                ),
                Text(
                  _statusLabel(l10n, link.status),
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
          if (link.status == GuardianLinkStatus.accepted)
            TextButton(
              onPressed: () async {
                final confirmed = await AppConfirmDialog.show(
                  context,
                  title: l10n.elderRevokeConfirmTitle,
                  message: l10n.elderRevokeConfirmMessage,
                  confirmLabel: l10n.elderRevokeConfirmLabel,
                  destructive: true,
                );
                if (confirmed) {
                  await ref.read(myLinksProvider.notifier).revoke(link.id);
                }
              },
              child: Text(
                l10n.elderRevokeAction,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _statusLabel(AppLocalizations l10n, GuardianLinkStatus status) =>
      switch (status) {
        GuardianLinkStatus.pending => l10n.elderLinkStatusPending,
        GuardianLinkStatus.accepted => l10n.elderLinkStatusAccepted,
        GuardianLinkStatus.rejected => l10n.elderLinkStatusRejected,
        GuardianLinkStatus.revoked => l10n.elderLinkStatusRevoked,
      };
}
