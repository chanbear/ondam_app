import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 로그인/역할선택 등 첫 진입 화면에서 쓰는 작은 브랜드 마크(원형 배지 +
/// 아이콘). Modern Care 리디자인(2026-08-26, 사용자 승인)에서 텍스트만
/// 있던 첫인상 화면에 최소한의 시각 정체성을 더하기 위해 추가 — 아직
/// `assets/*`가 pubspec에 등록되지 않아(CLAUDE.md) 이미지 로고 대신
/// 아이콘으로 구성한다.
class AppMark extends StatelessWidget {
  const AppMark({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.primarySoft,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.health_and_safety_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}
