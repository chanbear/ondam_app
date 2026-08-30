// `dart:io` isn't a valid import target on web — conditional export picks
// the real `Platform.isAndroid` check where `dart:io` exists, and a
// hardcoded `false` (web) where it doesn't.
export 'android_platform_stub.dart'
    if (dart.library.io) 'android_platform_io.dart';
