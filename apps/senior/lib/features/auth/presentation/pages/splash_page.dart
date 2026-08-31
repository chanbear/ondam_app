import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../app/router/auth_routes.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// 앱의 첫 진입 화면(`AuthRoutes.splash`, `initialLocation`) — 로고 +
/// 앱 이름 + 태그라인을 보여주고 "온담 시작하기"를 누르면 로그인 화면으로
/// 넘어간다. 세션이 없을 때만 도달하는 일회성 첫인상 화면이라(로그아웃 후
/// 재진입 등은 곧장 로그인 화면으로) 별도 상태 저장은 필요 없다
/// (`auth_redirect.dart`의 `onSplash` 예외 참고).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const _SplashMark(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.appTitle,
                style: AppTextStyles.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.splashTagline,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              AppButton(
                label: l10n.splashStartButton,
                size: AppButtonSize.large,
                onPressed: () => context.go(AuthRoutes.phoneInput),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 레퍼런스 이미지의 문서+AI+체크리스트 로고 — `assets/*`가 아직
/// pubspec에 등록되지 않아(CLAUDE.md) 이미지 대신 아이콘을 겹쳐 구성한다.
class _SplashMark extends StatelessWidget {
  const _SplashMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(
            Icons.description_outlined,
            color: AppColors.primary,
            size: 48,
          ),
          Positioned(
            right: 14,
            bottom: 22,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
