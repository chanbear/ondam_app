import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 쉬운 모드 카드 — ui-prototype에서 쓰던 "굵은 먹색 테두리" Easy Mode
/// 비주얼은 2026-08-29 ui-prototype에서 사용자 요청으로 삭제되어, 이제
/// [AppCard]와 동일한 1px 테두리로 그린다. Settings/Profile/Connection 3개
/// feature가 실제로 공유해서 architecture.md의 core 승격 기준을 충족하므로
/// 위젯 자체는 유지하고(호출부 8곳을 개별 수정하지 않기 위해) 내부 렌더링만
/// [AppCard]와 맞춘다.
class EasyOutlineCard extends StatelessWidget {
  const EasyOutlineCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
