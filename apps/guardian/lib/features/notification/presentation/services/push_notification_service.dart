import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ondam_core/ondam_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/auth/auth_state_provider.dart';
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
/// This environment has no real Firebase project wired up yet (no
/// `google-services.json`/`GoogleService-Info.plist` — see Phase 8 report).
/// `Firebase.initializeApp()` is expected to throw here until that native
/// config exists; every FCM call is guarded so the rest of the app keeps
/// working when Push is unavailable, instead of crashing at startup.
class PushNotificationController {
  PushNotificationController(this._ref) {
    unawaited(_initLocalNotifications());

    _ref.listen<AsyncValue<AuthState>>(authStateChangesProvider, (_, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession) {
        unawaited(_registerCurrentToken());
      } else if (event == AuthChangeEvent.signedOut) {
        unawaited(_invalidateCurrentToken());
      }
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
    unawaited(resolveAndNavigateToAnalysisDetail(_ref, data));
  }

  void _handleRemoteMessageTap(RemoteMessage message) {
    unawaited(resolveAndNavigateToAnalysisDetail(_ref, message.data));
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
