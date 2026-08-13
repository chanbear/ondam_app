import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../providers/my_links_notifier.dart';
import 'connection_scan_page.dart';

/// 보호자 측 "어르신 연결 관리" — ui-screen-spec.md "더보기 — 어르신 연결
/// 관리" 대응. pending 요청은 대기 상태만 보여주고(수락/거절은 어르신
/// 전용), accepted 연결은 해제할 수 있다.
class ConnectionListPage extends ConsumerWidget {
  const ConnectionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksState = ref.watch(myLinksProvider);

    return AppScaffold(
      title: '어르신 연결 관리',
      onBack: () => Navigator.of(context).pop(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionScanPage())),
        label: const Text('어르신 연결하기'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
      body: linksState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: '연결 목록을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(myLinksProvider),
        ),
        data: (links) {
          final visible = links
              .where((link) => link.status != GuardianLinkStatus.rejected)
              .toList();
          if (visible.isEmpty) {
            return AppEmptyState(
              message: '아직 연결된 어르신이 없습니다\n어르신 연결하기로 QR을 스캔해주세요',
              icon: Icons.person_add_alt_outlined,
              actionLabel: '어르신 연결하기',
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
                  '어르신 (${_shortId(link.elderId)})',
                  style: AppTextStyles.bodyLarge,
                ),
                Text(
                  _statusLabel(link.status),
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
                  title: '연결을 해제할까요?',
                  message: '해제하면 이 어르신의 정보를 더 이상 볼 수 없습니다.',
                  confirmLabel: '해제',
                  destructive: true,
                );
                if (confirmed) {
                  await ref.read(myLinksProvider.notifier).revoke(link.id);
                }
              },
              child: const Text(
                '연결 해제',
                style: TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _statusLabel(GuardianLinkStatus status) => switch (status) {
    GuardianLinkStatus.pending => '어르신 수락 대기 중',
    GuardianLinkStatus.accepted => '연결됨',
    GuardianLinkStatus.rejected => '거절됨',
    GuardianLinkStatus.revoked => '연결 해제됨',
  };
}
