import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../domain/entities/sms_message.dart';
import 'message_risk_result_page.dart';

/// 선택한 문자의 원문 확인 — 분석 요청 전 사용자가 무엇을 분석하는지 한 번
/// 더 확인할 수 있게 한다("문자 선택 → 선택된 문자 확인 → 분석하기").
class SmsMessageDetailPage extends StatelessWidget {
  const SmsMessageDetailPage({super.key, required this.message});

  final SmsMessage message;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: '문자 확인',
      onBack: () => Navigator.of(context).pop(),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppInfoRow(label: '보낸 사람', value: message.sender ?? '알 수 없는 번호'),
          const SizedBox(height: AppSpacing.md),
          Text('문자 내용', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(message.body, style: AppTextStyles.bodyLarge),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: '분석하기',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MessageRiskResultPage(message: message),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
