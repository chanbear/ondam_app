import 'package:flutter/material.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

/// 사용 방법 안내 — "더보기" 메뉴에서 언제든 다시 볼 수 있는 실제 기능
/// 튜토리얼. 이전에는 계정 설정용 [OnboardingFlowPage](최초 1회, 이름/
/// 성별/나이/지역 입력 + 보호자 QR 발급)를 그대로 재사용했는데, 이미 쓰고
/// 있는 사용자에게 "정보를 다시 입력하라"는 화면을 보여주는 게 말이 안 돼
/// 별도 화면으로 분리했다. 여기는 순수 안내용 — 아무 값도 저장하지 않는다.
/// l10n 키가 없는 신규 문구라 이 화면 전용 한글 문자열로 둔다(`profile_page.dart`
/// 와 같은 관례).
class HowToUsePage extends StatefulWidget {
  const HowToUsePage({super.key});

  @override
  State<HowToUsePage> createState() => _HowToUsePageState();
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

// 실제 홈 화면(home_tab_page.dart)에 있는 기능만 소개한다 — 없는 기능을
// 지어내지 않는다.
const _steps = [
  _TutorialStep(
    icon: Icons.document_scanner_outlined,
    title: '문서 읽기로 사기 확인하기',
    description: '고지서나 계약서를 사진으로 찍으면 AI가 위험한 내용이 있는지 확인해드려요.',
  ),
  _TutorialStep(
    icon: Icons.sms_outlined,
    title: '문자 확인하기',
    description: '수상한 문자를 받으면 붙여넣기만 하세요. 사기 문자인지 바로 알려드려요.',
  ),
  _TutorialStep(
    icon: Icons.mic,
    title: '말로 물어보기',
    description: '화면 아래 마이크 버튼을 누르고 말씀하시면 원하는 기능으로 바로 이동해요.',
  ),
  _TutorialStep(
    icon: Icons.phone_in_talk,
    title: '긴급 도움 요청하기',
    description: '위급한 상황엔 긴급 도움 버튼을 눌러 보호자에게 바로 알릴 수 있어요.',
  ),
  _TutorialStep(
    icon: Icons.card_giftcard,
    title: '맞춤 정보 확인하기',
    description: '정보 탭에서 내 나이와 지역에 맞는 혜택 정보를 확인하세요.',
  ),
  _TutorialStep(
    icon: Icons.place_outlined,
    title: '공공시설 찾기',
    description: '가까운 경로당이나 행정복지센터 위치와 연락처를 찾아드려요.',
  ),
  _TutorialStep(
    icon: Icons.history,
    title: '내 기록 확인하기',
    description: '지금까지 확인한 문서와 문자 기록을 기록 탭에서 다시 볼 수 있어요.',
  ),
];

class _HowToUsePageState extends State<HowToUsePage> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _steps.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _previous() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _steps.length - 1;
    return AppScaffold(
      title: '사용 방법 안내',
      onBack: () => Navigator.of(context).pop(),
      scrollable: false,
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (page) => setState(() => _page = page),
              children: [for (final step in _steps) _StepView(step: step)],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < _steps.length; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _page ? AppColors.primary : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                if (_page > 0) ...[
                  Expanded(
                    child: AppButton(
                      label: '이전',
                      variant: AppButtonVariant.secondary,
                      size: AppButtonSize.large,
                      onPressed: _previous,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: AppButton(
                    label: isLast ? '확인' : '다음',
                    size: AppButtonSize.large,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _StepView extends StatelessWidget {
  const _StepView({required this.step});

  final _TutorialStep step;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.primarySoft,
            child: Icon(step.icon, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            step.title,
            style: AppTextStyles.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            step.description,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
