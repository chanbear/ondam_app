import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../l10n/generated/app_localizations.dart';

/// Generic placeholder for menu destinations whose feature doesn't have a
/// domain/data layer yet (welfare_center, analysis, schedule, connection,
/// support 등 — Phase 4~6+ 예정). Shows a genuine "not built yet" state, not
/// fabricated data — REMOVE-1(`feature-spec.md`)의 "Mock 데이터 프리뷰 금지"
/// 원칙과 같은 이유로, 실제로 없는 기능을 있는 것처럼 보여주지 않는다.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: title,
      onBack: () => Navigator.of(context).pop(),
      body: AppEmptyState(
        icon: Icons.construction_outlined,
        message: AppLocalizations.of(context)!.featureComingSoonMessage,
      ),
    );
  }
}
