import 'package:flutter/widgets.dart';

/// 앱 locale → TTS 엔진 locale 태그. `voice_interaction_view.dart`가 쓰던
/// 매핑을 그대로 옮겨 여기 하나로 공유한다(중복 방지).
String ttsLocaleTag(Locale locale) => switch (locale.languageCode) {
  'en' => 'en-US',
  'zh' => 'zh-CN',
  'ja' => 'ja-JP',
  _ => 'ko-KR',
};
