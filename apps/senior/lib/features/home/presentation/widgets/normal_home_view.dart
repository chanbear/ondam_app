import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import 'home_feature_card.dart';

/// Normal Mode home content — full card grid + "오늘 해야 할 일" summary.
/// `schedule` feature has no domain layer yet, so the summary is a genuine
/// empty state, not fabricated data (feature-spec.md REMOVE-1 principle).
class NormalHomeView extends StatelessWidget {
  const NormalHomeView({super.key, required this.features});

  final List<HomeFeatureItem> features;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        AppSectionHeader(title: '핵심 기능'),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.1,
          children: [for (final item in features) HomeFeatureCard(item: item)],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(title: '오늘 해야 할 일'),
        const AppEmptyState(message: '오늘은 예정된 일정이 없어요.'),
      ],
    );
  }
}
