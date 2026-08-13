import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// Generic placeholder for menu destinations whose feature doesn't have a
/// domain/data layer yet (notification/analysis/schedule/connection/support
/// 등 — Phase 5~6+ 예정). Shows a genuine "not built yet" state, not
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
      body: const AppEmptyState(
        icon: Icons.construction_outlined,
        message: '이 기능은 아직 준비 중이에요.',
      ),
    );
  }
}
