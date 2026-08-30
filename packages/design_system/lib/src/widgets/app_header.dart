import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// Shared screen header — title + back navigation as a text+arrow link
/// (never a bare icon), per ui-spec.md's existing "← 홈으로" pattern. Placed
/// at the top of `AppScaffold`, not a Flutter `AppBar`.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.backLabel,
    this.actions = const [],
  });

  final String title;
  final VoidCallback? onBack;
  // 2026-08-31 — 실기기(기기 언어 일본어)로 확인된 버그: 이 패키지는
  // Senior/Guardian이 공유하는 순수 위젯 패키지라 자체 l10n을 갖지 않는데,
  // 기본값이 '뒤로' 하드코딩이라 backLabel을 안 넘기는 거의 모든 화면(24개
  // 중 23개)에서 화면 전체가 다른 언어여도 뒤로가기 글자만 한국어로
  // 고정돼 보였다. null이면 텍스트 없이 화살표 아이콘만 그린다 — 실제로
  // 라벨 문구가 필요한 화면(예: document_scan_preview_page.dart의
  // "재촬영")은 각 화면이 자기 l10n으로 명시적으로 넘기면 된다.
  final String? backLabel;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            _BackLink(label: backLabel, onTap: onBack!)
          else
            const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  // null이면 아이콘만(터치 영역은 그대로 44x44 이상 유지) — 시맨틱 라벨은
  // 이 패키지가 자체 l10n을 갖지 않아 완벽한 다국어 대응은 스코프 밖이고,
  // "back"류의 일반적인 영어 키워드로 대체한다(시각적 텍스트 제거가
  // 핵심이고, 접근성 라벨 자체는 이번 수정 대상이 아니다).
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label ?? 'Back',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_back, size: 18),
              if (label != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(label!, style: AppTextStyles.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
