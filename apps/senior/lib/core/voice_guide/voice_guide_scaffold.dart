import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../features/onboarding/presentation/providers/accessibility_prefs_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import 'voice_guide_provider.dart';
import 'voice_guide_service.dart';

/// `AppScaffold`를 감싸 화면 진입/이탈에 맞춰 음성 안내를 자동으로
/// 시작·정지한다(사용자 요청 — 음성 안내 범위를 홈/Easy 분석결과 2곳에서
/// 전체 화면으로 확대). 화면에 들어오면 [guideText](없으면 [title] 기반
/// 기본 문구)를 읽고, 이 위젯이 dispose되면(다른 화면으로 이동/뒤로가기)
/// 그 발화를 멈춘다 — 다음 화면의 `VoiceGuideScaffold`가 자기 안내를 새로
/// 시작하므로 "이전 화면 안내 중지 + 새 화면 안내 시작"이 화면 전환마다
/// 자연스럽게 이어진다.
///
/// [announceOnEnter]를 false로 두면 진입 시 자동 안내를 하지 않는다 —
/// `document_scan_result_page.dart`/`message_risk_result_page.dart`처럼
/// body 안에서 이미 더 구체적인 안내(분석 결과 요약 등)를 직접 읽어주는
/// 화면에 쓴다. 이 경우에도 dispose 시 정지는 그대로 적용된다.
///
/// 홈 탭(`home_tab_page.dart`)은 여기 포함하지 않는다 — 탭 전환은
/// 화면(Route) 이동이 아니라서 이 위젯의 진입/이탈 생명주기와 맞지 않고,
/// 이미 자체적으로 토글 on 시점을 감지해 안내하는 로직이 있다.
class VoiceGuideScaffold extends ConsumerStatefulWidget {
  const VoiceGuideScaffold({
    super.key,
    this.title,
    this.guideText,
    this.announceOnEnter = true,
    this.onBack,
    this.backLabel,
    this.headerActions = const [],
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.scrollable = false,
  });

  final String? title;
  final String? guideText;
  final bool announceOnEnter;
  final VoidCallback? onBack;
  final String? backLabel;
  final List<Widget> headerActions;
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  ConsumerState<VoiceGuideScaffold> createState() => _VoiceGuideScaffoldState();
}

class _VoiceGuideScaffoldState extends ConsumerState<VoiceGuideScaffold> {
  bool _spokenOnEnter = false;
  bool _wasEnabled = false;
  // dispose()에서는 ref.read()를 쓸 수 없다(위젯이 이미 unmount 중이라
  // Riverpod가 예외를 던진다) — initState에서 미리 읽어 필드에 담아둔다.
  late final VoiceGuideService _service;

  @override
  void initState() {
    super.initState();
    _wasEnabled = ref.read(accessibilityPrefsProvider).voiceGuideEnabled;
    _service = ref.read(voiceGuideServiceProvider);
  }

  @override
  void dispose() {
    _service.stop();
    super.dispose();
  }

  // `AppLocalizations.of(context)`는 delegate가 등록돼 있지 않으면(l10n을
  // 쓰지 않는 화면의 기존 위젯 테스트 다수가 이렇다) null을 돌려준다 —
  // 안내 문구가 실제로 필요할 때만 조회하고, 없으면 조용히 건너뛴다.
  String? _resolveGuideText(BuildContext context) {
    final custom = widget.guideText;
    if (custom != null) return custom;
    final title = widget.title;
    if (title == null || title.isEmpty) return null;
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return null;
    return l10n.voiceGuideDefaultScreenText(title);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(
      accessibilityPrefsProvider.select((prefs) => prefs.voiceGuideEnabled),
    );
    // 최초 진입 시(설정이 이미 켜져 있던 경우) 한 번, 그리고 이 화면에
    // 머무는 동안 토글이 꺼짐→켜짐으로 바뀔 때 한 번 더 읽는다.
    final justTurnedOn = enabled && !_wasEnabled;
    _wasEnabled = enabled;
    if (widget.announceOnEnter &&
        enabled &&
        (!_spokenOnEnter || justTurnedOn)) {
      _spokenOnEnter = true;
      final text = _resolveGuideText(context);
      if (text != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          speakScreenGuide(ref, text);
        });
      }
    }

    return AppScaffold(
      title: widget.title,
      onBack: widget.onBack,
      backLabel: widget.backLabel,
      headerActions: widget.headerActions,
      floatingActionButton: widget.floatingActionButton,
      bottomNavigationBar: widget.bottomNavigationBar,
      padding: widget.padding,
      scrollable: widget.scrollable,
      body: widget.body,
    );
  }
}
