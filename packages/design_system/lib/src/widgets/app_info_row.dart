import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_spacing.dart';
import '../tokens/app_text_styles.dart';

/// One key-value or checklist line — profile fields, bill line items,
/// "확인할 일" checklists all repeat this layout (ui-component-spec.md
/// AppInfoRow). Pass [checked]/[onCheckedChanged] for the checklist variant,
/// [value] for the key-value variant — not both at once.
class AppInfoRow extends StatelessWidget {
  const AppInfoRow({
    super.key,
    required this.label,
    this.value,
    this.checked,
    this.onCheckedChanged,
  });

  final String label;
  final String? value;
  final bool? checked;
  final ValueChanged<bool?>? onCheckedChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (checked != null)
            Checkbox(value: checked, onChanged: onCheckedChanged),
          Expanded(child: Text(label, style: AppTextStyles.bodyLarge)),
          if (value != null) ...[
            const SizedBox(width: AppSpacing.sm),
            // 실기기 확인: value(주소/신청방법처럼 AI가 생성한 긴 문자열)가
            // label처럼 감싸이지 않은 순수 Text였을 때, 값이 길면 줄바꿈되지
            // 않고 Row 오른쪽 밖으로 그대로 넘쳐서(overflow) 화면에 노란/
            // 검정 경고 줄무늬가 그대로 노출됐다. Flexible로 감싸 필요한
            // 만큼만 차지하고, 다 안 들어가면 여러 줄로 줄바꿈되게 한다.
            Flexible(
              child: Text(
                value!,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
