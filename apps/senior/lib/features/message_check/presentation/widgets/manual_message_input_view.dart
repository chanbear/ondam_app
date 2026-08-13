import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:ondam_design_system/ondam_design_system.dart';

/// iOS(및 자동 조회를 지원하지 않는 모든 플랫폼)용 문자 확인 입력 — 자동
/// SMS 접근 대신 붙여넣기/직접 입력으로 문자 원문을 받는다. `TextEditingController`는
/// 로컬 UI 상태라 StatefulWidget을 사용한다(flutter.md).
///
/// 클립보드가 비어 있어도 오류로 처리하지 않는다 — 사용자가 직접 입력할 수
/// 있으면 충분하다(Phase 7 결정사항 C).
class ManualMessageInputView extends StatefulWidget {
  const ManualMessageInputView({
    super.key,
    required this.onAnalyze,
    this.easyMode = false,
  });

  final ValueChanged<String> onAnalyze;
  final bool easyMode;

  @override
  State<ManualMessageInputView> createState() => _ManualMessageInputViewState();
}

class _ManualMessageInputViewState extends State<ManualMessageInputView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    _controller.text = text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final buttonSize = widget.easyMode
        ? AppButtonSize.large
        : AppButtonSize.standard;

    return ListView(
      children: [
        Text(
          '의심스러운 문자를 복사해서 붙여넣거나\n직접 입력해주세요.',
          style: AppTextStyles.bodyLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: '클립보드에서 붙여넣기',
          size: buttonSize,
          onPressed: _pasteFromClipboard,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('문자 내용', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _controller,
          minLines: 6,
          maxLines: 12,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: '문자 내용을 입력해주세요'),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: '분석하기',
          size: buttonSize,
          onPressed: _controller.text.trim().isEmpty
              ? null
              : () => widget.onAnalyze(_controller.text.trim()),
        ),
      ],
    );
  }
}
