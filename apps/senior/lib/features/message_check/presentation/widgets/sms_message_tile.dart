import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/sms_message.dart';

/// One row in the recent-SMS list — 보낸 사람 → 내용 일부 → 날짜/시간 우선순위
/// (Phase 45-B §5, HTML prototype `messageList()`의 sender+date 상단 행과
/// 동일한 구조).
/// 2026-08-31 — ui-prototype `.msg-list-cards`(사용자 요청)와 맞춰 흰
/// `AppCard` 대신 아이콘 배지와 같은 톤(`AppColors.primarySoft`)의 색 카드로
/// 바꾼다 — `AppCard`는 다른 화면 여러 곳이 공유하는 흰 배경 카드라 이
/// 화면만 바꾸려고 그 위젯 자체를 고치지 않고, `more_tab_page.dart`의
/// `_EasyMoreTile`과 같은 패턴(Material+InkWell 직접 구성)을 그대로 쓴다.
class SmsMessageTile extends StatelessWidget {
  const SmsMessageTile({super.key, required this.message, this.onTap});

  final SmsMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bodyPreview = message.body.trim();
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카드 배경이 이제 primarySoft라 배지도 같은 톤이면 안 보이게
              // 겹친다 — solid 원(more_tab_page.dart `_EasyMoreTile`과 동일
              // 패턴)으로 바꿔 구분되게 한다.
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.sms_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            message.sender ??
                                AppLocalizations.of(
                                  context,
                                )!.unknownSenderLabel,
                            style: AppTextStyles.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatDate(message.receivedAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      bodyPreview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
}
