import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_state_provider.dart';
import '../../../../core/auth/pin_verified_provider.dart';
import '../../../../core/auth/supabase_client_provider.dart';
import '../providers/notification_di_providers.dart';
import 'notification_navigation.dart';

const _riskAlertChannelId = 'guardian_risk_alerts';
const _riskAlertChannelName = '위험 알림';

/// FCM token lifecycle + Push message handling (technical-decisions.md
/// §1-10). Instantiated once at the app root (see `app.dart`), same pattern
/// as `IdleTimeoutController` — this drives app-wide state (DB token
/// registration, notification tray), not per-screen state.
///
/// Android has a real Firebase project wired up (`google-services.json`,
/// project "ondam-app") and `Firebase.initializeApp()` succeeds there. iOS
/// has no `GoogleService-Info.plist` yet, and widget tests have no native
/// platform channel either, so `Firebase.apps` stays empty in those cases;
/// every FCM call is still guarded so the rest of the app keeps working
/// when Push is unavailable, instead of crashing at startup.
class PushNotificationController {
  PushNotificationController(this._ref) {
    unawaited(_initLocalNotifications());

    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed) {
        // `signup-with-phone`(OTP 제거, v18)의 `setSession(refreshToken)`은
        // accessToken 없이 호출되면 gotrue 내부적으로 `_callRefreshToken`
        // 경로를 타 `signedIn`이 아니라 `tokenRefreshed`만 발생시킨다
        // (`auth.setSession` 문서/구현 확인, gotrue 2.27.1). 이 이벤트를
        // 누락하면 v18 이후의 모든 로그인에서 FCM token이 영영 등록되지
        // 않는다 — Phase 8 실기기 재로그인 검증에서 발견. `registerToken`은
        // upsert라 세션 자동 갱신 때마다 반복 호출돼도 안전하다.
        unawaited(_registerCurrentToken());
      } else if (event == AuthChangeEvent.signedOut) {
        unawaited(_invalidateCurrentToken());
      }
    });

    // PIN 잠금 상태에서 도착한 알림 탭은 notification_navigation.dart의
    // pendingNotificationTargetProvider에 저장돼 있다 — PIN이 실제로 풀리는
    // 시점(false→true)에만 재처리한다. 자세한 근거는 그 파일의 doc 참고.
    _ref.listen<bool>(pinVerifiedProvider, (_, next) {
      if (next) _consumePendingNotificationTarget();
    });

    unawaited(_initFirebaseMessaging());
  }

  final Ref _ref;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onMessageOpenedSub;
  StreamSubscription<String>? _onTokenRefreshSub;
  bool _firebaseReady = false;

  Future<void> _initLocalNotifications() async {
    try {
      await _localNotifications.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: _onLocalNotificationTapped,
      );
    } catch (e) {
      // No platform plugin registered (e.g. widget tests without a
      // platform-channel mock) — foreground local notifications just won't
      // show, the rest of the app must keep working.
      debugPrint('PushNotificationController: 로컬 알림 초기화 실패: $e');
    }
  }

  Future<void> _initFirebaseMessaging() async {
    // `Firebase.initializeApp()` runs once in `main.dart` (before
    // `runApp`) so `FirebaseMessaging.onBackgroundMessage` can be
    // registered as early as possible — calling `initializeApp()` again
    // here for the same (default) app risks a native "duplicate-app"
    // error, so this only checks readiness instead of initializing.
    if (Firebase.apps.isEmpty) {
      debugPrint(
        'PushNotificationController: Firebase가 초기화되지 않았습니다 '
        '(네이티브 설정 없음) — Push 기능은 이번 세션에서 비활성화됩니다.',
      );
      return;
    }
    _firebaseReady = true;

    try {
      await FirebaseMessaging.instance.requestPermission();
    } catch (e) {
      debugPrint('PushNotificationController: 알림 권한 요청 실패: $e');
    }

    _onMessageSub = FirebaseMessaging.onMessage.listen(_showLocalNotification);
    _onMessageOpenedSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _handleRemoteMessageTap,
    );
    _onTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      _registerToken,
    );

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleRemoteMessageTap(initialMessage);
    }

    if (_ref.read(supabaseClientProvider).auth.currentSession != null) {
      await _registerCurrentToken();
    }
  }

  Future<void> _registerCurrentToken() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('PushNotificationController: FCM 토큰 조회 실패: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    final result = await _ref
        .read(registerFcmTokenUseCaseProvider)
        .call(token: token, deviceInfo: _deviceInfo());
    if (result is Err<void>) {
      debugPrint(
        'PushNotificationController: FCM 토큰 등록 실패: ${result.failure.message}',
      );
    }
  }

  /// 현재 인증된 사용자와 연결된 FCM token을 무효화(DB에서 삭제)한다.
  ///
  /// `signedOut` 이벤트 리스너(아래)뿐 아니라 로그아웃 버튼(`SettingsPage`)이
  /// **`signOut()`을 호출하기 전에** 직접 호출하는 공개 API이기도 하다 — 실기기
  /// Phase 8 검증에서 발견된 버그: `signOut()`이 먼저 끝나 Supabase 세션이
  /// 사라진 뒤에야 `signedOut` 이벤트로 토큰 삭제가 실행되면, `fcm_tokens`의
  /// owner-only RLS(`user_id = auth.uid()`)가 인증되지 않은 요청의
  /// `auth.uid() = null`과 매칭되지 않아 DELETE가 조용히 0 row로 끝난다.
  /// 세션이 아직 살아있는 로그아웃 버튼 시점에 먼저 삭제해야 실제로 지워진다.
  ///
  /// 로그아웃 흐름에서 이 메서드가 먼저 성공적으로 삭제한 뒤에도 `signedOut`
  /// 리스너가 같은 로직을 한 번 더 실행하지만, `FcmTokenRepositoryImpl.
  /// invalidateToken`은 이미 없는 토큰(0 row)을 `ValidationFailure`로만
  /// 반환하고 여기서는 `debugPrint`만 하므로 중복 호출은 무해하다 — 별도
  /// 가드를 추가하지 않는다.
  Future<void> invalidateCurrentToken() => _invalidateCurrentToken();

  Future<void> _invalidateCurrentToken() async {
    if (!_firebaseReady) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      final result = await _ref
          .read(invalidateFcmTokenUseCaseProvider)
          .call(token);
      if (result is Err<void>) {
        debugPrint(
          'PushNotificationController: FCM 토큰 무효화 실패: ${result.failure.message}',
        );
      }
    } catch (e) {
      debugPrint('PushNotificationController: FCM 토큰 무효화 중 오류: $e');
    }
  }

  Map<String, dynamic> _deviceInfo() => {
    'platform': Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : 'unknown',
  };

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _riskAlertChannelId,
          _riskAlertChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final data = jsonDecode(payload) as Map<String, dynamic>;
    handleNotificationTapData(_ref, data);
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    handleNotificationTapData(_ref, message.data);
  }

  void _consumePendingNotificationTarget() {
    final pending = _ref.read(pendingNotificationTargetProvider);
    if (pending == null) return;
    _ref.read(pendingNotificationTargetProvider.notifier).clear();
    // 현재 프레임에는 go_router의 redirect가 아직 `/home`으로 리빌드 중일 수
    // 있다 — 같은 프레임에 push하면 그 리빌드에 그대로 씻겨나간다
    // (notification_navigation.dart doc 참고). 한 프레임 뒤로 미뤄 router가
    // `/home`에 정착한 다음에 push되도록 한다. 임의의 Duration을 건 지연이
    // 아니라 "이번 빌드가 끝난 다음"이라는 결정적 시점이다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(resolveAndNavigateToAnalysisDetail(_ref, pending));
    });
  }

  void dispose() {
    unawaited(_onMessageSub?.cancel());
    unawaited(_onMessageOpenedSub?.cancel());
    unawaited(_onTokenRefreshSub?.cancel());
  }
}

final pushNotificationControllerProvider = Provider<PushNotificationController>(
  (ref) {
    final controller = PushNotificationController(ref);
    ref.onDispose(controller.dispose);
    return controller;
  },
);
