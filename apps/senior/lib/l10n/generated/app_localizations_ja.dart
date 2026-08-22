// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => '온담';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '言語';

  @override
  String get easyModeSectionTitle => 'かんたんモード';

  @override
  String get easyModeTitle => 'かんたんモード';

  @override
  String get easyModeSubtitle => '大きなボタンとシンプルな画面に切り替えます';

  @override
  String get accountSectionTitle => 'アカウント';

  @override
  String get logout => 'ログアウト';

  @override
  String get deleteAccount => '退会';

  @override
  String get deleteAccountConfirmTitle => '本当に退会しますか？';

  @override
  String get deleteAccountConfirmMessage =>
      '退会すると、アカウントと保存されたすべての情報が直ちに削除され、元に戻すことはできません。';

  @override
  String get deleteAccountConfirmLabel => '退会する';

  @override
  String get phoneStartTitle => '電話番号ではじめる';

  @override
  String get phoneStartSubtitle => '電話番号とパスワードを入力してください。';

  @override
  String get phoneNumberLabel => '電話番号';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => 'パスワード';

  @override
  String get pinHint => '4桁の数字';

  @override
  String get startButton => 'はじめる';

  @override
  String get forgotPinLink => 'パスワードをお忘れですか？';

  @override
  String pinWrongWithCount(int count) {
    return 'パスワードが正しくありません。（$count回失敗）';
  }

  @override
  String get pinWrong => 'パスワードが正しくありません。';

  @override
  String pinLockedWithTime(String time) {
    return '失敗回数が多すぎます。$timeに再度お試しください。';
  }

  @override
  String get pinLockedNoTime => '失敗回数が多すぎるため、一時的にロックされました。しばらくしてから再度お試しください。';

  @override
  String get pinNotSet => 'パスワードが設定されていません。';

  @override
  String get pinInvalidFormat => 'パスワードは4桁の数字です。';

  @override
  String get pinUnknownError => '確認中に問題が発生しました。もう一度お試しください。';

  @override
  String get voiceAssistantLabel => '音声アシスタント';

  @override
  String get navInfo => '情報';

  @override
  String get navHome => 'ホーム';

  @override
  String get navRecords => '記録';

  @override
  String get navMore => 'その他';

  @override
  String get profileTitle => 'マイ情報';

  @override
  String get nameLabel => 'お名前';

  @override
  String get ageLabel => '年齢';

  @override
  String get profileSaved => 'プロフィールを保存しました。';

  @override
  String get profileLoadError => '保存された情報を読み込めませんでした。';

  @override
  String get myRegionTitle => 'マイエリア';

  @override
  String get regionLoadError => '地域情報を読み込めませんでした。';

  @override
  String get currentRegionLabel => '現在の地域';

  @override
  String get regionNotSetValue => 'まだ登録されていません';

  @override
  String get enterRegionAction => '地域を入力する';

  @override
  String get saveButton => '保存';

  @override
  String get sidoLabel => '都道府県';

  @override
  String get sidoPlaceholder => 'タップして選択してください';

  @override
  String get sigunguLabel => '市区町村';

  @override
  String get dongLabel => '町・字';

  @override
  String get locatingButton => '現在地を確認しています…';

  @override
  String get useCurrentLocationButton => '現在地で自動入力';

  @override
  String get locationServiceDisabledError => '位置情報サービスをオンにしてから、もう一度お試しください。';

  @override
  String get locationPermissionDeniedError => '端末設定で位置情報の許可をしてから、もう一度お試しください。';

  @override
  String get locationPermissionRequiredError => '現在地を使用するには位置情報の許可が必要です。';

  @override
  String get sidoRequiredError => '都道府県を選択してください。';

  @override
  String get regionSaved => '地域を保存しました。';

  @override
  String get sidoPickerTitle => '都道府県を選択';

  @override
  String get welfareCenterTitle => '高齢者福祉センターを探す';

  @override
  String get welfareCenterRegionLoadError => 'マイエリア情報を読み込めませんでした。';

  @override
  String get welfareCenterEmptyRegionMessage => '高齢者福祉センターを探すには、まず地域を登録してください。';

  @override
  String get searchNearbyButton => '近くの高齢者福祉センターを探す';

  @override
  String get phoneLaunchError => '電話アプリを開けませんでした。';

  @override
  String get welfareCenterSearchError => '検索中に問題が発生しました。';

  @override
  String get welfareCenterNoResults => '近くに高齢者福祉センターが見つかりませんでした。';

  @override
  String get callButtonTooltip => '電話をかける';

  @override
  String get voiceUnavailableError => 'この端末では音声認識を利用できません。';

  @override
  String get voiceInitError => '音声アシスタントを開始できませんでした。';

  @override
  String get voicePreparing => '音声アシスタントを準備しています…';

  @override
  String get voiceProcessing => 'ご要望を確認しています…';

  @override
  String get voiceIdlePrompt => 'マイクを押してお話しください';

  @override
  String get voiceListening => '聞いています…';

  @override
  String get voiceStartSemanticLabel => '話しはじめる';

  @override
  String get voiceUnrecognizedAnswer =>
      'おっしゃったことをうまく聞き取れませんでした。「문서 찍어줘」（書類撮影）、「문자 확인해줘」（メッセージ確認）、「긴급 도움」（緊急ヘルプ）のように話してみてください。';

  @override
  String get voiceRetryButton => 'もう一度お話しください';
}
