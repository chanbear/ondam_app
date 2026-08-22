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
  String get phoneStartSubtitle => 'お名前と電話番号を入力してください。';

  @override
  String get nameLabel => 'お名前';

  @override
  String get phoneNumberLabel => '電話番号';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get startButton => 'はじめる';

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
}
