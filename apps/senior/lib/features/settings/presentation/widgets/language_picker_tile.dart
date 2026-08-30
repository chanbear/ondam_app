import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/locale/locale_provider.dart';

/// 언어 선택 — 각 언어는 번역하지 않고 그 언어 자신의 표기로 보여준다
/// (언어 선택 UI의 일반적인 관례: 한국어 로케일에서도 "English"는 "English").
/// `Locale`은 `==`를 오버라이드해 const map key로 쓸 수 없어 languageCode
/// 문자열로 키를 둔다.
const _languageNames = {'ko': '한국어', 'en': 'English', 'zh': '中文', 'ja': '日本語'};

/// ui-prototype `onboard-settings`의 언어 설정(전체너비 큰 칩 스택,
/// min-height 64px)과 같은 시각 패턴 — 기본 RadioListTile(작은 원형
/// 라디오)은 어르신 대상 터치 타겟으로 작아 교체.
class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    final notifier = ref.read(localeControllerProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final locale in supportedAppLocales)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SizedBox(
              width: double.infinity,
              child: AppCard(
                variant: locale == current
                    ? AppCardVariant.selected
                    : AppCardVariant.normal,
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.lg,
                ),
                onTap: () => notifier.setLocale(locale),
                child: Center(
                  child: Text(
                    _languageNames[locale.languageCode]!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: locale == current
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
