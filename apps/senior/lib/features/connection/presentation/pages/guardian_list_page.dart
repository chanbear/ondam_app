import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../providers/guardian_links_notifier.dart';
import 'connection_qr_page.dart';

/// 어르신 측 "연결된 보호자 목록" — ui-screen-spec.md "더보기 — 연결된
/// 보호자 목록" 대응. pending 요청은 수락/거절, accepted 연결은 해제
/// 버튼을 보여준다.
class GuardianListPage extends ConsumerWidget {
  const GuardianListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksState = ref.watch(guardianLinksProvider);

    return AppScaffold(
      title: '연결된 보호자 목록',
      onBack: () => Navigator.of(context).pop(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionQrPage())),
        label: const Text('보호자 연결하기'),
        icon: const Icon(Icons.qr_code),
      ),
      body: linksState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: '보호자 목록을 불러오지 못했어요.',
          onRetry: () => ref.invalidate(guardianLinksProvider),
        ),
        data: (links) {
          final visible = links
              .where((link) => link.status != GuardianLinkStatus.rejected)
              .toList();
          if (visible.isEmpty) {
            return AppEmptyState(
              message: '아직 연결된 보호자가 없습니다\n보호자 연결하기로 QR을 보여주세요',
              icon: Icons.family_restroom_outlined,
              actionLabel: '보호자 연결하기',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConnectionQrPage()),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) =>
                _GuardianLinkCard(link: visible[index]),
          );
        },
      ),
    );
  }
}

class _GuardianLinkCard extends ConsumerWidget {
  const _GuardianLinkCard({required this.link});

  final GuardianLink link;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '보호자 연결 요청 (${_shortId(link.guardianId)})',
                  style: AppTextStyles.bodyLarge,
                ),
              ),
              _StatusBadge(status: link.status),
            ],
          ),
          if (link.status == GuardianLinkStatus.pending) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '수락',
                    onPressed: () => ref
                        .read(guardianLinksProvider.notifier)
                        .respond(linkId: link.id, accept: true),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => ref
                        .read(guardianLinksProvider.notifier)
                        .respond(linkId: link.id, accept: false),
                    child: const Text('거절'),
                  ),
                ),
              ],
            ),
          ] else if (link.status == GuardianLinkStatus.accepted) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final confirmed = await AppConfirmDialog.show(
                    context,
                    title: '연결을 해제할까요?',
                    message: '해제하면 이 보호자는 더 이상 회원님의 정보를 볼 수 없습니다.',
                    confirmLabel: '해제',
                    destructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(guardianLinksProvider.notifier)
                        .revoke(link.id);
                  }
                },
                child: Text(
                  '연결 해제',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final GuardianLinkStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      GuardianLinkStatus.pending => '요청 대기 중',
      GuardianLinkStatus.accepted => '연결됨',
      GuardianLinkStatus.rejected => '거절함',
      GuardianLinkStatus.revoked => '연결 해제됨',
    };
    return Text(label, style: AppTextStyles.labelSmall);
  }
}
