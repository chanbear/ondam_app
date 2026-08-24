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
  String get navHome => 'ホーム';

  @override
  String get navNotification => '通知';

  @override
  String get navRecords => '記録';

  @override
  String get navStatistics => '統計';

  @override
  String get navMore => 'その他';

  @override
  String get noConnectedEldersMessage => 'まだ連携している高齢者がいません。';

  @override
  String get connectElderAction => '高齢者と連携する';

  @override
  String get recentActivityTitle => '最近のアクティビティ';

  @override
  String get upcomingScheduleTitle => '今後の予定';

  @override
  String get noUpcomingSchedule => '予定はありません。';

  @override
  String get reassuranceLoadError => '安心ステータスを読み込めませんでした。';

  @override
  String get dangerousAlertTitle => '確認が必要な活動があります';

  @override
  String get alertCheckRecordsDescription => '記録タブで詳細をご確認ください。';

  @override
  String get cautionAlertTitle => '注意が必要な活動があります';

  @override
  String get safeStatusMessage => '今日も穏やかにお過ごしください。';

  @override
  String get safeStatusDescription => 'まだ特別な通知はありません。';

  @override
  String get recentActivityLoadError => '最近のアクティビティを読み込めませんでした。';

  @override
  String get noActivityRecords => 'まだ活動記録がありません。';

  @override
  String get recentNotificationsTitle => '最近の通知';

  @override
  String get viewAllAction => 'すべて見る';

  @override
  String get noRecentNotifications => 'まだ通知がありません。';

  @override
  String get recentNotificationsLoadError => '通知を読み込めませんでした。';

  @override
  String get notificationUnreadLabel => '新着';

  @override
  String get notificationReadLabel => '確認済み';

  @override
  String get documentDetailTitle => '書類分析の詳細';

  @override
  String get messageDetailTitle => 'メッセージ確認の詳細';

  @override
  String get detailsToggleTitle => '詳細を見る';

  @override
  String get reliabilityLabel => '信頼度';

  @override
  String get sourceTextLabel => '原文';

  @override
  String get confirmButtonLabel => '確認完了';

  @override
  String get confirmedBannerLabel => '確認完了しました';

  @override
  String get realtimeAlertsTitle => 'リアルタイム通知';

  @override
  String get riskRecordsTitle => 'リスク記録';

  @override
  String get riskRecordsLoadError => '記録を読み込めませんでした。';

  @override
  String get noRiskRecords => 'まだリスク記録がありません。';

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
  String get connectAnotherElderAction => '他の高齢者と連携';

  @override
  String get supportTitle => 'カスタマーサポート';

  @override
  String get pinForgotTitle => 'PIN再設定';

  @override
  String get pinForgotReauthFailedTitle => '本人確認に失敗しました';

  @override
  String get retryButtonLabel => 'もう一度お試しください';

  @override
  String get pinForgotNewPinTitle => '新しい4桁のPINを設定してください';

  @override
  String get pinKeypadClearLabel => '消去';

  @override
  String get recordsLoadError => '分析記録を読み込めませんでした。';

  @override
  String get recordsEmptyMessage => 'まだ分析記録がありません。';

  @override
  String get statisticsLoadError => '統計を読み込めませんでした。';

  @override
  String get statisticsEmptyMessage => 'まだ統計として表示できるデータがありません。';

  @override
  String get thisMonthCountLabel => '今月の分析件数';

  @override
  String get riskyThisMonthCountLabel => '今月の危険メッセージ件数';

  @override
  String countUnitLabel(int count) {
    return '$count件';
  }

  @override
  String get feeStatisticsSectionTitle => '料金統計';

  @override
  String get billingInfoSectionTitle => '請求書情報';

  @override
  String get billingInfoUndecidedNotice =>
      '請求書統計の項目はまだ決まっていません。記録に含まれる元の情報のみ表示します。';

  @override
  String get billingInfoEmptyMessage => 'まだ請求書情報がありません。';

  @override
  String get trendSameAsLastMonth => '先月と同じです';

  @override
  String trendIncreasedLabel(int count) {
    return '先月より$count件増えました';
  }

  @override
  String trendDecreasedLabel(int count) {
    return '先月より$count件減りました';
  }

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
  String get notificationTypeRiskyDocument => '書類でリスクが検知されました';

  @override
  String get notificationTypeRiskyMessage => 'メッセージでリスクが検知されました';

  @override
  String get guardianConnectionManageTitle => '高齢者連携管理';

  @override
  String get connectElderActionLong => '高齢者と連携する';

  @override
  String get connectionListLoadError => '連携リストを読み込めませんでした。';

  @override
  String get connectionListEmptyMessage =>
      'まだ連携している高齢者がいません\n「高齢者と連携する」からQRコードをスキャンしてください';

  @override
  String elderPlaceholderName(String id) {
    return '高齢者（$id）';
  }

  @override
  String get elderRevokeConfirmTitle => '連携を解除しますか？';

  @override
  String get elderRevokeConfirmMessage => '解除すると、この高齢者の情報を確認できなくなります。';

  @override
  String get elderRevokeConfirmLabel => '解除';

  @override
  String get elderRevokeAction => '連携解除';

  @override
  String get elderLinkStatusPending => '高齢者の承認待ち';

  @override
  String get elderLinkStatusAccepted => '連携済み';

  @override
  String get elderLinkStatusRejected => '拒否されました';

  @override
  String get elderLinkStatusRevoked => '連携解除済み';

  @override
  String get connectionRequestSendingMessage => '連携リクエストを送信しています';

  @override
  String get qrScanInstructionMessage => '高齢者の画面に表示されたQRコードを映してください';

  @override
  String get cameraPermissionRequiredMessage => 'カメラの権限が必要です';

  @override
  String get openSettingsAction => '設定へ移動';

  @override
  String get connectionRequestSentTitle => '連携リクエストを送信しました';

  @override
  String get connectionRequestSentDescription => '高齢者がリクエストを承認すると連携が完了します。';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get comingSoonMessage => 'この機能は現在準備中です。';
}
