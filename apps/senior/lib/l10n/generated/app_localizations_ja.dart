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
  String get appTagline => '高齢者のための文書・メッセージ確認アシスタント';

  @override
  String get splashTagline => '高齢者のための安心生活アシスタント';

  @override
  String get splashStartButton => 'オンダムを始める';

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
  String get startButton => '設定へ進む';

  @override
  String get socialLoginDivider => 'または';

  @override
  String get googleLoginButton => 'Googleでログイン';

  @override
  String get guestSignInButton => '会員登録なしで利用する';

  @override
  String get oauthPinSetupTitle => 'PINを設定してください';

  @override
  String get oauthPinSetupSubtitle => '次回からこのPINでログインします。';

  @override
  String get oauthPinEntryTitle => 'PINを入力してください';

  @override
  String get oauthPinEntrySubtitle => '設定した4桁のPINを入力してください。';

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
  String get ageDecreaseAction => '年齢を減らす';

  @override
  String get ageIncreaseAction => '年齢を増やす';

  @override
  String get genderSectionLabel => '性別';

  @override
  String get genderMaleLabel => '男性';

  @override
  String get genderFemaleLabel => '女性';

  @override
  String get genderRequiredError => '性別を選択してください。カスタム情報検索に必要です。';

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
  String get publicFacilitySearchLabel => '公共施設を探す';

  @override
  String get publicFacilitySearchSubtitle => '近くの公共施設を探してみましょう';

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
  String welfareCenterResultsSummary(String region, int count) {
    return '$region周辺の高齢者福祉センター$count件';
  }

  @override
  String get callButtonTooltip => '電話をかける';

  @override
  String get directionsButtonLabel => '経路を調べる';

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

  @override
  String get riskSafeLabel => '安全';

  @override
  String get riskCautionLabel => '注意';

  @override
  String get riskDangerousLabel => '危険を検知';

  @override
  String get analysisTypeDocumentLabel => '書類分析';

  @override
  String get analysisTypeMessageLabel => 'メッセージ確認';

  @override
  String get analysisResultTitle => '分析結果';

  @override
  String get shareButton => '共有';

  @override
  String get pinEntryPrompt => 'PINを入力してください';

  @override
  String get pinForgotLink => 'PINをお忘れですか？';

  @override
  String get pinResetTitle => 'PIN再設定';

  @override
  String get identityVerifyFailedTitle => '本人確認に失敗しました';

  @override
  String get retryButton => 'もう一度試す';

  @override
  String get pinNewSetupPrompt => '新しい4桁のPINを設定してください';

  @override
  String get pinMismatchError => 'PINが一致しません。最初からもう一度入力してください。';

  @override
  String get pinConfirmPrompt => 'もう一度入力してください';

  @override
  String get pinSetupPrompt => '使用する4桁のPINを設定してください';

  @override
  String get pinSetupDescription => '次回からアプリを開くときにこのPINで確認します。';

  @override
  String get roleSelectTitle => 'どちらとしてご利用になりますか？';

  @override
  String get roleSelectSubtitle => 'ご利用目的に合わせて画面をご用意します。';

  @override
  String get roleAlreadyRegisteredNotice =>
      'この番号はすでに別の役割で登録されています。続行するとこの役割も追加登録されます。';

  @override
  String get roleElderButton => '私は高齢者です';

  @override
  String get roleGuardianButton => '私は家族（保護者）です';

  @override
  String get pinKeypadClearLabel => '消去';

  @override
  String get guardianConnectTitle => '保護者連携';

  @override
  String get qrGeneratingMessage => 'QRコードを作成しています';

  @override
  String get qrGenerateError => 'QRコードを作成できませんでした。もう一度お試しください。';

  @override
  String get qrShowGuardianPrompt => 'この QR コードを保護者に見せてください';

  @override
  String get qrScanExplanation => '保護者がこのQRコードをスキャンすると連携リクエストが届きます。';

  @override
  String get qrExpiredMessage => 'QRコードの有効期限が切れました。';

  @override
  String get qrRegenerateButton => 'QRコードを再作成';

  @override
  String get guardianListTitle => '連携中の保護者一覧';

  @override
  String get guardianConnectButton => '保護者と連携する';

  @override
  String get guardianListLoadError => '保護者一覧を読み込めませんでした。';

  @override
  String get guardianListEmptyMessage =>
      'まだ連携している保護者がいません\n「保護者と連携する」でQRコードを表示してください';

  @override
  String guardianRequestLabelWithId(String id) {
    return '保護者連携リクエスト（$id）';
  }

  @override
  String guardianConnectedLabelWithId(String id) {
    return '連携済みの保護者（$id）';
  }

  @override
  String guardianConnectedSince(String date) {
    return '連携済み・$date';
  }

  @override
  String get acceptButton => '承認';

  @override
  String get rejectButton => '拒否';

  @override
  String get guardianRevokeConfirmTitle => '連携を解除しますか？';

  @override
  String get guardianRevokeConfirmMessage => '解除すると、この保護者はお客様の情報を閲覧できなくなります。';

  @override
  String get guardianRevokeConfirmLabel => '解除';

  @override
  String get guardianRevokeAction => '連携解除';

  @override
  String get guardianStatusPending => 'リクエスト待ち';

  @override
  String get guardianStatusAccepted => '連携済み';

  @override
  String get guardianStatusRejected => '拒否済み';

  @override
  String get guardianStatusRevoked => '連携解除済み';

  @override
  String get documentScanTitle => '書類撮影';

  @override
  String get documentScanStartTitle => '書類分析';

  @override
  String get documentScanStartTakePhotoButton => '写真を撮る';

  @override
  String get documentScanStartPickPhotoButton => '写真を選ぶ';

  @override
  String get documentScanStartTipTitle => 'ご確認ください！';

  @override
  String get documentScanStartTipLine1 => '文字がはっきり見えるように撮影してください';

  @override
  String get documentScanStartTipLine2 => '光の反射が少ない明るい場所で撮影するとより正確です';

  @override
  String get photoLibraryUnavailableError => '写真を読み込めませんでした。';

  @override
  String get cameraPermissionCheckError => 'カメラの権限を確認できませんでした。';

  @override
  String get cameraPermissionRequestMessage =>
      '書類やメッセージを撮影して分析するには\nカメラへのアクセスを許可してください。';

  @override
  String get cameraPermissionRequestButton => 'カメラの権限を許可する';

  @override
  String get cameraPermissionBlockedMessage =>
      'カメラの権限がブロックされています。\n端末の設定から直接許可してください。';

  @override
  String get openSettingsButton => '設定を開く';

  @override
  String get scanPreviewTitle => '撮影結果の確認';

  @override
  String get retakeLabel => '撮り直し';

  @override
  String scannedDocumentsCount(int count) {
    return '$count枚撮影しました';
  }

  @override
  String photoCountBadge(int count) {
    return '$count枚';
  }

  @override
  String get addAnotherPhotoButton => '追加撮影';

  @override
  String get analyzeButton => '分析する';

  @override
  String documentIndexLabel(int index) {
    return '書類 $index';
  }

  @override
  String deletePhotoAtIndexLabel(int index) {
    return '$index枚目の写真を削除';
  }

  @override
  String documentAnalyzingProgress(int current, int total) {
    return '書類分析中 $current/$total';
  }

  @override
  String documentsAnalyzedCount(int count) {
    return '$count件の書類を分析しました';
  }

  @override
  String get noCameraAvailableError => '利用可能なカメラがありません。';

  @override
  String get cameraStartError => 'カメラを起動できませんでした。';

  @override
  String get flashUnavailableError => 'この端末ではフラッシュを使用できません。';

  @override
  String get flashOffLabel => 'フラッシュオフ';

  @override
  String get flashOnLabel => 'フラッシュオン';

  @override
  String get flashAutoLabel => 'フラッシュ自動';

  @override
  String get captureFailedError => '撮影に失敗しました。もう一度お試しください。';

  @override
  String get cameraPreparingMessage => 'カメラを準備しています';

  @override
  String get documentFrameGuideMessage => '書類を画面内に収めてください';

  @override
  String get captureButtonLabel => '撮影する';

  @override
  String get closeCameraButtonLabel => '閉じる';

  @override
  String get noGuardianConnectedError => 'まだ連携している保護者がいません。';

  @override
  String get emergencyHelpTitle => 'お困りですか？';

  @override
  String get emergency119Label => '119通報（消防・救急）';

  @override
  String get emergency112Label => '112通報（警察）';

  @override
  String get govComplaintLabel => '110相談（政府苦情案内）';

  @override
  String get dasanCallCenterLabel => '120相談（ダサンコールセンター）';

  @override
  String get cancelButton => 'キャンセル';

  @override
  String get myRecordsTitle => 'マイ記録';

  @override
  String get documentReadLabel => '書類を読む';

  @override
  String get documentReadSubtitle => '写真で書類を読み上げます';

  @override
  String get messageCheckLabel => 'メッセージ確認';

  @override
  String get messageCheckSubtitle => 'メッセージを読んでわかりやすくお伝えします';

  @override
  String get recentMessagesIntro => '最近のメッセージを読み込みました。\n確認したいメッセージをタップしてください。';

  @override
  String get infoTabTitle => '情報';

  @override
  String get infoTabEmptyMessage => 'まだ準備された情報がありません。まもなくおすすめ情報をお届けします。';

  @override
  String get statisticsLabel => '統計';

  @override
  String get usefulInfoLabel => '知っておくと便利な情報';

  @override
  String get howToUseLabel => '使い方案内';

  @override
  String get supportTitle => 'カスタマーサポート';

  @override
  String get moreTitle => 'その他';

  @override
  String get recordsLoadingMessage => '記録を読み込んでいます';

  @override
  String get recordsLoadError => '記録の読み込み中に問題が発生しました。';

  @override
  String get recordsEmptyMessage => 'まだ分析した記録がありません。\n書類撮影やメッセージ確認をご利用ください。';

  @override
  String get helpRequestLabel => '助けを求める';

  @override
  String get easyModeOnState => 'オン';

  @override
  String get easyModeOffState => 'オフ';

  @override
  String easyModeToggleSemanticLabel(String state) {
    return 'かんたんモード、現在$state';
  }

  @override
  String get easyModeDescription => '大きくシンプルな画面で見る';

  @override
  String get recentRecordsTitle => '最近の記録';

  @override
  String get todayScheduleTitle => '今日の予定';

  @override
  String get emergencyHelpRequestLabel => '緊急ヘルプ（SOS）';

  @override
  String get emergencyHelpRequestSubtitle => '緊急時にすぐ助けを呼べます';

  @override
  String homeGreetingWithName(String name) {
    return '$name様、こんにちは！';
  }

  @override
  String get homeGreetingSubtitle => '今日も安全で快適な一日をお過ごしください';

  @override
  String get easyHomeHeadline => '何をお手伝いしましょうか？';

  @override
  String infoGreetingWithName(String name) {
    return '$name様のためのおすすめ情報です';
  }

  @override
  String get recordsFilterAllLabel => 'すべて';

  @override
  String get recordsFilterEmptyMessage => '該当する記録がありません。\n別のフィルターを選んでみてください。';

  @override
  String get moreAccountSectionTitle => 'アカウント';

  @override
  String get moreUsageInfoSectionTitle => '利用情報';

  @override
  String get smsPermissionCheckError => 'メッセージの権限を確認できませんでした。';

  @override
  String get smsPermissionRequestMessage =>
      '受信メッセージを確認して危険なメッセージかお知らせするために\nメッセージへのアクセスを許可してください。';

  @override
  String get smsPermissionRequestButton => 'メッセージの権限を許可する';

  @override
  String get smsPermissionBlockedMessage =>
      'メッセージの権限がブロックされています。\n端末の設定から直接許可してください。';

  @override
  String get analysisGenericError => '分析中に問題が発生しました。';

  @override
  String get unknownSenderLabel => '不明な番号';

  @override
  String get manualMessageInputPrompt => '不審なメッセージをコピー＆ペーストするか\n直接入力してください。';

  @override
  String get pasteFromClipboardButton => 'クリップボードから貼り付け';

  @override
  String get messageContentLabel => 'メッセージ内容';

  @override
  String get messageContentHint => 'メッセージ内容を入力してください';

  @override
  String get recentSmsLoadingMessage => '最近のメッセージを読み込んでいます';

  @override
  String get smsLoadError => 'メッセージを読み込めませんでした。';

  @override
  String get recentSmsEmptyMessage => '最近受信したメッセージがありません。';

  @override
  String get accessibilitySettingsTitle => 'アクセシビリティ設定';

  @override
  String get guardianRegisterTitle => '保護者登録';

  @override
  String get onboardingAccessibilityHeadline => 'いくつか設定しましょう';

  @override
  String get onboardingAccessibilityIntro => '快適にご利用いただけるよう、まず設定を行います。';

  @override
  String get nextButton => '次へ';

  @override
  String get onboardingProfileIntro => '教えていただくと、より役立つ情報をお届けできます。（任意入力）';

  @override
  String get regionLabel => '地域';

  @override
  String get skipButton => 'スキップ';

  @override
  String get profileNextButton => '保護者登録に進む';

  @override
  String get onboardingCompleteTitle => '設定完了！';

  @override
  String get onboardingCompleteSubtitle => 'オンダムを使う準備ができました';

  @override
  String get textSizeTitle => '文字サイズ';

  @override
  String get textScaleNormalLabel => '普通';

  @override
  String get textScaleLargeLabel => '大きく';

  @override
  String get textScaleExtraLargeLabel => 'とても大きく';

  @override
  String get textScaleNormalDesc => '最も多く選ばれています。';

  @override
  String get textScaleLargeDesc => 'もっと大きく見られます。';

  @override
  String get textScaleExtraLargeDesc => '一番大きく表示します。';

  @override
  String get voiceGuideTitle => '音声案内';

  @override
  String get voiceGuideDescription => '画面の内容を音声でもご案内します';

  @override
  String get voiceRateTitle => '音声案内の速度';

  @override
  String get voiceRateNormalLabel => '1倍';

  @override
  String get voiceRateFastLabel => '1.2倍';

  @override
  String get voiceRateFasterLabel => '1.5倍';

  @override
  String get voiceRateFastestLabel => '2倍';

  @override
  String get homeVoiceGuideEasy =>
      'ホーム画面です。書類を読む、メッセージ確認、高齢者福祉センターを探す、マイ記録からお選びください。';

  @override
  String get homeVoiceGuideNormal =>
      'ホーム画面です。書類を読む、メッセージ確認、高齢者福祉センターを探す、緊急ヘルプ要請からお選びください。';

  @override
  String get easyResultVoiceGuidePrefix => '分析結果をお知らせします。';

  @override
  String get feeStatisticsTitle => '料金統計';

  @override
  String get feeStatisticsLoadingMessage => '料金統計を読み込んでいます';

  @override
  String get feeStatisticsLoadError => '料金統計の読み込み中に問題が発生しました。';

  @override
  String get privacyPinTitle => 'パスワード（PIN）';

  @override
  String get privacyPinBody =>
      'PINの原文やそれを推測できる値は、この端末のどこにも保存されません。サーバー上でも暗号化された値のみを検証専用に保管しており、他人が閲覧できる経路はありません。';

  @override
  String get privacyPhotoTitle => '書類撮影写真';

  @override
  String get privacyPhotoBody =>
      '書類を撮影して分析を依頼すると、分析が終わり次第（成功・失敗を問わず）元の写真はサーバーから削除されます。分析結果のみが残ります。';

  @override
  String get privacySharedInfoTitle => '保護者と共有される情報';

  @override
  String get privacySharedInfoBody =>
      '分析結果は、連携を承認した保護者のみが閲覧できます。連携を解除すると、それ以降は閲覧できなくなります。';

  @override
  String get privacyRetentionTitle => '分析結果原文の保管期間';

  @override
  String get privacyRetentionBody =>
      'メッセージ・書類の分析結果に残る要約／原文をどのくらい保管するかはまだ決まっていません。決まり次第、この画面でご案内します。';

  @override
  String get privacyInfoTitle => '個人情報保管について';

  @override
  String get supportContactTitle => 'サポート連絡先';

  @override
  String get supportContactComingSoon => '電話・メールの連絡先を準備しています。まもなくご案内します。';

  @override
  String get privacyInfoDescription => '自分の情報がどのように保管されているか確認する';

  @override
  String get micPermissionCheckError => 'マイクの権限を確認できませんでした。';

  @override
  String get micPermissionRequestMessage =>
      '音声アシスタントを使用するには\nマイクへのアクセスを許可してください。';

  @override
  String get micPermissionRequestButton => 'マイクの権限を許可する';

  @override
  String get micPermissionBlockedMessage =>
      'マイクの権限がブロックされています。\n端末の設定から直接許可してください。';

  @override
  String get actionChecklistTitle => 'やるべきこと';

  @override
  String get clarifyingQuestionsTitle => '気になることはありますか？';

  @override
  String get askByVoiceButton => '音声で質問する';

  @override
  String get dateKindPaymentDue => '支払期限';

  @override
  String get dateKindVisit => '訪問日';

  @override
  String get dateKindApplicationPeriod => '申請期間';

  @override
  String get dateKindExpiration => '有効期限';

  @override
  String get dateKindReservation => '予約日';

  @override
  String get dateKindOther => 'その他の重要な日付';

  @override
  String get importantDatesTitle => '重要な日付';

  @override
  String monthDayFormat(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get keyPointsTitle => '主な内容';

  @override
  String analysisProgressSemanticLabel(int percent, String label) {
    return '分析進捗$percentパーセント、$label';
  }

  @override
  String get progressPreparing => '分析を準備しています';

  @override
  String get progressSending => 'データを送信しています';

  @override
  String get progressAnalyzing => 'AIが確認しています';

  @override
  String get progressFinishing => '結果をまとめています';

  @override
  String get detailsViewTitle => '詳細を見る';

  @override
  String get reliabilityLabel => '信頼度';

  @override
  String get sourceTextLabel => '原文';

  @override
  String get structuredFieldRiskTypeLabel => 'リスク種別';

  @override
  String get riskTypeVoicePhishingLure => '振り込め詐欺の誘導';

  @override
  String get riskTypeSmishing => 'スミッシング(迷惑メッセージ)';

  @override
  String get riskTypeLoanScam => '融資詐欺';

  @override
  String get riskTypeImpersonationAuthority => '機関なりすまし';

  @override
  String get riskTypeDeliveryScam => '配送詐欺';

  @override
  String get riskTypeInvestmentScam => '投資詐欺';

  @override
  String get riskTypeRomanceScam => 'ロマンス詐欺';

  @override
  String get riskTypeOtherScam => 'その他の詐欺';

  @override
  String get riskTypeNone => 'なし';

  @override
  String get easyResultAiSummaryLabel => 'AI要約';

  @override
  String get easyResultTypeLabel => '種類';

  @override
  String get easyResultReplayLabel => 'もう一度聞く';

  @override
  String get askAboutThisButton => 'この内容について質問する';

  @override
  String get confirmedDoneSemanticLabel => '確認完了としてマークしました';

  @override
  String get confirmedDoneMessage => '確認完了しました';

  @override
  String get confirmDoneButton => '確認完了';

  @override
  String get featureComingSoonMessage => 'この機能はまだ準備中です。';

  @override
  String get feeStatisticsEmptyMessage =>
      'まだ料金統計がありません。\n請求書や料金明細を分析すると統計が作成されます。';

  @override
  String get totalFeeLabel => '総額';

  @override
  String get averageFeeLabel => '平均額';

  @override
  String get maxFeeLabel => '最高額';

  @override
  String get feeRecordCountLabel => '料金内訳件数';

  @override
  String get monthlyToggleLabel => '月別';

  @override
  String get yearlyToggleLabel => '年別';

  @override
  String toggleViewSemanticLabel(String label) {
    return '$labelを見る';
  }

  @override
  String get monthlyTrendTitle => '月別料金推移';

  @override
  String get yearlyTrendTitle => '年別料金推移';

  @override
  String get noDataInPeriodMessage => 'この期間には料金記録がありません。';

  @override
  String get feeFootnote =>
      '分析された請求書・料金明細の金額をもとに計算します。AIが金額を抽出できなかった記録は除外されます。';

  @override
  String get feeChartEmptyMessage => 'まだ料金統計がありません。';

  @override
  String get feeChartSemanticNoData => '料金推移グラフ。まだデータがありません。';

  @override
  String feeChartSemanticSummary(String summary) {
    return '料金推移グラフ。$summary';
  }

  @override
  String monthNumberLabel(int month) {
    return '$month月';
  }

  @override
  String yearNumberLabel(int year) {
    return '$year年';
  }

  @override
  String feeHeroTitle(int month) {
    return '$month月の料金';
  }

  @override
  String feeHeroLessThanLastMonth(String amount) {
    return '先月より$amount少ないです';
  }

  @override
  String feeHeroMoreThanLastMonth(String amount) {
    return '先月より$amount多いです';
  }

  @override
  String get feeHeroSameAsLastMonth => '先月と同じです';

  @override
  String get recentBillsTitle => '最近の請求書';

  @override
  String countUnitLabel(int count) {
    return '$count件';
  }

  @override
  String get notifSettingsTitle => '通知設定';

  @override
  String get dangerAlertLabel => '危険通知';

  @override
  String get alwaysOnCaption => '常にオン';

  @override
  String get guardianNotifyLabel => '保護者に通知';

  @override
  String get messageGuardianNoticeTitle => '保護者にお知らせしました';

  @override
  String get messageGuardianNoticeBody => 'メッセージの内容を保護者に伝えました';

  @override
  String get goHomeButton => 'ホームへ';
}
