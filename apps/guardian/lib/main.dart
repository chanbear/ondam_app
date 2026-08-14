import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  // Session lifecycle (create/refresh/expire/sign out) is fully delegated to
  // the Supabase SDK — the app never manages access/refresh tokens itself.
  // See technical-decisions.md §1-3-A: "Session ≠ PIN Gate".
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    publishableKey: AppConfig.supabaseAnonKey,
  );

  // Push (FCM, technical-decisions.md §1-10). This environment has no real
  // Firebase project registered yet (no google-services.json/
  // GoogleService-Info.plist), so `initializeApp()` is expected to throw
  // here until that native config exists — the rest of the app must keep
  // working without Push in that case (see Phase 8 report), so this is
  // guarded instead of awaited unconditionally.
  if (await _tryInitializeFirebase()) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const ProviderScope(child: App()));
}

Future<bool> _tryInitializeFirebase() async {
  try {
    await Firebase.initializeApp();
    return true;
  } catch (e) {
    debugPrint('Firebase 초기화 실패(네이티브 설정 없음) — Push 기능 비활성화: $e');
    return false;
  }
}

/// Must be a top-level function (FlutterFire requirement — runs on a
/// separate background isolate). FCM messages that carry a `notification`
/// payload are already shown by the OS while the app is backgrounded/
/// terminated, so there is nothing to display here; this exists so
/// `onBackgroundMessage` has a registered handler at all (required for the
/// background isolate to be spawned/for `onMessageOpenedApp`/
/// `getInitialMessage` to see the message once the app resumes).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {}
