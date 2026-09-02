import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';
import 'package:ondam_models/ondam_models.dart';

import '../../../../core/voice_guide/voice_guide_scaffold.dart';
import '../../../../core/easy_mode/easy_mode_outline_card.dart';
import '../../../../core/easy_mode/easy_mode_provider.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../providers/guardian_links_notifier.dart';
import 'connection_qr_page.dart';

/// 화면이 열려 있는 동안의 재조회 주기. 연결 요청/승인은 상대(보호자) 앱에서
/// 이뤄지므로 이 화면은 그 변경을 realtime/push로 통보받을 방법이 없다 —
/// 화면이 떠 있는 동안 짧은 주기로 다시 조회해 "앱을 재실행해야 반영되는"
/// 문제를 없앤다(BUG 1). 새 아키텍처 없이 기존 `ref.invalidate` 패턴만 재사용.
const _guardianLinksRefreshInterval = Duration(seconds: 5);

/// 어르신 측 "연결된 보호자 목록" — ui-screen-spec.md "더보기 — 연결된
/// 보호자 목록" 대응. pending 요청은 수락/거절, accepted 연결은 해제
/// 버튼을 보여준다.
class GuardianListPage extends ConsumerStatefulWidget {
  const GuardianListPage({super.key});

  @override
  ConsumerState<GuardianListPage> createState() => _GuardianListPageState();
}

class _GuardianListPageState extends ConsumerState<GuardianListPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(_guardianLinksRefreshInterval, (_) {
      ref.invalidate(guardianLinksProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linksState = ref.watch(guardianLinksProvider);
    final l10n = AppLocalizations.of(context)!;

    return VoiceGuideScaffold(
      title: l10n.guardianListTitle,
      onBack: () => Navigator.of(context).pop(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ConnectionQrPage())),
        label: Text(l10n.guardianConnectButton),
        icon: const Icon(Icons.qr_code),
      ),
      body: linksState.when(
        loading: () => const AppLoading(),
        error: (error, _) => AppError(
          message: l10n.guardianListLoadError,
          onRetry: () => ref.invalidate(guardianLinksProvider),
        ),
        data: (links) {
          final visible = links
              .where((link) => link.status != GuardianLinkStatus.rejected)
              .toList();
          if (visible.isEmpty) {
            return AppEmptyState(
              message: l10n.guardianListEmptyMessage,
              icon: Icons.family_restroom_outlined,
              actionLabel: l10n.guardianConnectButton,
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
    final l10n = AppLocalizations.of(context)!;
    final easyMode = ref.watch(easyModeProvider);
    final isAccepted = link.status == GuardianLinkStatus.accepted;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // 2026-08-31 — 사용자 제공 레퍼런스 디자인의 원형 아바타에 맞춘다.
            // 실제 이름/관계 정보는 이 화면에서 조회하지 않아(guardianId만
            // 있음) 이니셜 대신 아이콘을 그대로 쓴다 — 없는 데이터를 지어내지
            // 않는다.
            const CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySoft,
              child: Icon(Icons.person_outline, color: AppColors.primary),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                // 이미 연결된 보호자에게 "연결 요청" 문구를 쓰면 의미가
                // 틀리다 — accepted 상태는 별도 문구를 쓴다.
                isAccepted
                    ? l10n.guardianConnectedLabelWithId(
                        _shortId(link.guardianId),
                      )
                    : l10n.guardianRequestLabelWithId(
                        _shortId(link.guardianId),
                      ),
                style: AppTextStyles.bodyLarge,
              ),
            ),
            // ui-prototype `senior.guardian-link`와 맞춤(2026-08-29 사용자
            // 요청) — 연결된 보호자는 정보와 "해제" 액션을 같은 줄에 묶어
            // 카드 하나로 인지되게 한다. 대기중 요청은 기존대로 배지만.
            if (isAccepted)
              TextButton(
                onPressed: () async {
                  final confirmed = await AppConfirmDialog.show(
                    context,
                    title: l10n.guardianRevokeConfirmTitle,
                    message: l10n.guardianRevokeConfirmMessage,
                    confirmLabel: l10n.guardianRevokeConfirmLabel,
                    destructive: true,
                  );
                  if (confirmed) {
                    await ref
                        .read(guardianLinksProvider.notifier)
                        .revoke(link.id);
                  }
                },
                child: Text(
                  l10n.guardianRevokeAction,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              )
            else
              _StatusBadge(status: link.status),
          ],
        ),
        // ui-prototype `S("guardian-link")` — 연결된 날짜 표시.
        if (isAccepted && link.respondedAt != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.guardianConnectedSince(_formatDate(link.respondedAt!)),
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        if (link.status == GuardianLinkStatus.pending) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: l10n.acceptButton,
                  size: easyMode ? AppButtonSize.large : AppButtonSize.standard,
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
                  child: Text(l10n.rejectButton),
                ),
              ),
            ],
          ),
        ],
      ],
    );
    // 2026-08-28 — 쉬운 모드일 때만 `EasyOutlineCard`(굵은 먹색 테두리)로.
    return easyMode ? EasyOutlineCard(child: content) : AppCard(child: content);
  }

  String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

  String _formatDate(DateTime dt) =>
      '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final GuardianLinkStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = switch (status) {
      GuardianLinkStatus.pending => l10n.guardianStatusPending,
      GuardianLinkStatus.accepted => l10n.guardianStatusAccepted,
      GuardianLinkStatus.rejected => l10n.guardianStatusRejected,
      GuardianLinkStatus.revoked => l10n.guardianStatusRevoked,
    };
    return Text(label, style: AppTextStyles.labelSmall);
  }
}
