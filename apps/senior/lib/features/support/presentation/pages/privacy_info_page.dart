import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 개인정보 보관 안내 — 이 저장소에서 실제로 확정·구현된 정책만 안내한다
/// (technical-decisions.md §1-3-A/§1-8/§2-3). 아직 확정되지 않은 항목(분석
/// 결과 원문 보관 기간, §5 OPEN QUESTIONS 5번)은 있는 그대로 "미확정"으로
/// 안내한다 — 확정된 것처럼 지어내지 않는다.
class PrivacyInfoPage extends StatelessWidget {
  const PrivacyInfoPage({super.key});

  static const _items = [
    (
      Icons.pin_outlined,
      '비밀번호(PIN)',
      'PIN 원문이나 이를 유추할 수 있는 값은 이 기기 어디에도 저장하지 않아요. 서버에서도 암호화된 값만 검증 전용으로 보관하고, 다른 사람이 들여다볼 수 있는 경로가 없어요.',
    ),
    (
      Icons.photo_camera_back_outlined,
      '문서 촬영 사진',
      '문서를 촬영해 분석을 요청하면, 분석이 끝나는 즉시(성공하든 실패하든) 원본 사진은 서버에서 삭제돼요. 분석 결과만 남아요.',
    ),
    (
      Icons.family_restroom_outlined,
      '보호자와 공유되는 정보',
      '분석 결과는 내가 연결을 수락한 보호자만 볼 수 있어요. 연결을 해제하면 더 이상 볼 수 없어요.',
    ),
    (
      Icons.delete_outline,
      '회원 탈퇴',
      '탈퇴하면 계정과 함께 저장된 모든 정보가 즉시 삭제되고 되돌릴 수 없어요.',
    ),
    (
      Icons.help_outline,
      '분석 결과 원문 보관 기간',
      '문자·문서 분석 결과에 남는 요약/원문을 얼마나 오래 보관할지는 아직 정해지지 않았어요. 정해지는 대로 이 화면에 안내할게요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '개인정보 보관 안내',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (icon, title, body) in _items) ...[
            _PrivacyItem(icon: icon, title: title, body: body),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(title, style: AppTextStyles.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(body, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
