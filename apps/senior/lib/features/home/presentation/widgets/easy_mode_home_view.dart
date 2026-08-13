import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import 'home_feature_card.dart';

/// Easy Mode home content — Easy Mode is the app's core UX, not a settings
/// toggle (ui-principles.md Senior 8): fewer items (핵심 5개 이하), each a
/// full-width large button, no secondary info cards. 음성 비서와 긴급 도움은
/// 홈에서 동등하게 눈에 띄는 위치에 둔다(ui-spec.md 기존 결정).
class EasyModeHomeView extends StatelessWidget {
  const EasyModeHomeView({
    super.key,
    required this.features,
    required this.onEmergencyTap,
  });

  final List<HomeFeatureItem> features;
  final VoidCallback onEmergencyTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        for (final item in features) ...[
          HomeFeatureLargeButton(item: item),
          const SizedBox(height: AppSpacing.md),
        ],
        Semantics(
          button: true,
          label: '긴급 도움',
          child: Material(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: onEmergencyTap,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Container(
                constraints: const BoxConstraints(minHeight: 76),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.emergency, color: Colors.white, size: 28),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '긴급 도움',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
