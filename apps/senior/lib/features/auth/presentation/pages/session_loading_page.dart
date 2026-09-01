import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:ondam_design_system/ondam_design_system.dart';

import '../../../../core/auth/supabase_client_provider.dart';
import '../providers/login_notifier.dart';

/// Neutral placeholder shown while the router waits for `hasPinProvider`
/// (or role state) to resolve after a session is established. Never a
/// terminal destination — the router's `redirect` moves away from this
/// the instant the underlying provider settles.
///
/// 소셜 로그인(구글)이나 게스트 세션이 남아있는 상태로 앱이 새로 열리면,
/// 라우터가 `PhoneInputPage`를 거치지 않고 곧장 이 화면으로 보낼 수 있다
/// (역할이 비어있으면 `decideAuthRedirect`가 바로 `sessionLoading`을
/// 반환한다) — 그러면 역할 자동 부여를 트리거하는 코드가
/// `PhoneInputPage.build()`에만 있었을 때는 전혀 실행되지 않아 이 화면에
/// 영원히 멈춰 있었다(2026-08-30 실기기에서 재현된 버그). 이 화면도 같은
/// 트리거를 직접 갖는다.
class SessionLoadingPage extends ConsumerStatefulWidget {
  const SessionLoadingPage({super.key});

  @override
  ConsumerState<SessionLoadingPage> createState() => _SessionLoadingPageState();
}

class _SessionLoadingPageState extends ConsumerState<SessionLoadingPage> {
  bool _triggered = false;

  void _maybeCompleteSocialLogin() {
    if (_triggered) return;
    final currentUser = ref
        .read(supabaseClientProvider)
        .auth
        .currentSession
        ?.user;
    if (currentUser == null) return;
    // 2026-08-31 — 게스트도 소셜 로그인과 동일하게 PIN 게이트를 건너뛴다
    // (phone_input_page.dart의 `skipsPinGate`와 같은 신호) — 이전에는
    // 익명 세션을 제외해서, 역할이 비어있는 게스트가 이 화면에 갇히는
    // 같은 종류의 버그가 여기에도 있었다.
    final skipsPinGate =
        currentUser.phone == null || currentUser.phone!.isEmpty;
    if (!skipsPinGate) return;
    _triggered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loginNotifierProvider.notifier).completeSocialLoginSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeCompleteSocialLogin();
    final loginState = ref.watch(loginNotifierProvider);
    final failure = loginState.hasError ? loginState.error as Failure : null;
    if (failure != null) {
      return Scaffold(
        body: AppError(
          message: failure.message,
          onRetry: () => ref
              .read(loginNotifierProvider.notifier)
              .completeSocialLoginSession(),
        ),
      );
    }
    return const Scaffold(body: AppLoading());
  }
}
