import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../domain/entities/sms_message.dart';

/// One row in the recent-SMS list — sender + a short body preview + relative
/// time, in a large enough touch target for Senior UX (`AppCard` already
/// gives a full-width tappable area).
class SmsMessageTile extends StatelessWidget {
  const SmsMessageTile({super.key, required this.message, this.onTap});

  final SmsMessage message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bodyPreview = message.body.trim();
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.sms_outlined, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.sender ?? '알 수 없는 번호',
                  style: AppTextStyles.titleMedium,
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
    );
  }
}
