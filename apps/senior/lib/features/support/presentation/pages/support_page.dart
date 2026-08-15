import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import 'privacy_info_page.dart';

/// 고객 지원 — 기존 온담앱의 "고객센터 연결/개인정보 보관 안내" 메뉴를
/// 반영한다. "사용 방법 안내"는 더보기 탭에 이미 별도 항목으로 있어 여기서는
/// 중복시키지 않는다. 고객센터 실제 연락처(전화/이메일)는 이 저장소에 사업
/// 정보가 없어 정직한 준비중 안내로 남긴다 — 가짜 번호를 만들지 않는다.
class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '고객 지원',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(title: '고객센터 연락처'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    '전화·이메일 연락처를 준비하고 있어요. 곧 안내해드릴게요.',
                    style: AppTextStyles.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppSectionHeader(title: '개인정보 보관 안내'),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PrivacyInfoPage())),
            child: Semantics(
              button: true,
              label: '개인정보 보관 안내',
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Text(
                      '내 정보가 어떻게 보관되는지 확인해요',
                      style: AppTextStyles.bodyLarge,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
