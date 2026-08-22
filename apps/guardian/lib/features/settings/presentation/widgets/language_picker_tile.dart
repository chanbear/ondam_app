import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/locale/locale_provider.dart';

/// 언어 선택 — 각 언어는 번역하지 않고 그 언어 자신의 표기로 보여준다
/// (언어 선택 UI의 일반적인 관례: 한국어 로케일에서도 "English"는 "English").
/// `Locale`은 `==`를 오버라이드해 const map key로 쓸 수 없어 languageCode
/// 문자열로 키를 둔다.
const _languageNames = {'ko': '한국어', 'en': 'English', 'zh': '中文', 'ja': '日本語'};

class LanguagePickerTile extends ConsumerWidget {
  const LanguagePickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeControllerProvider);
    return RadioGroup<Locale>(
      groupValue: current,
      onChanged: (value) {
        if (value != null) {
          ref.read(localeControllerProvider.notifier).setLocale(value);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final locale in supportedAppLocales)
            RadioListTile<Locale>(
              contentPadding: EdgeInsets.zero,
              title: Text(_languageNames[locale.languageCode]!),
              value: locale,
            ),
        ],
      ),
    );
  }
}
