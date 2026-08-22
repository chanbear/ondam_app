// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '온담';

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsLanguage => '语言';

  @override
  String get accountSectionTitle => '账户';

  @override
  String get logout => '退出登录';

  @override
  String get deleteAccount => '注销账户';

  @override
  String get deleteAccountConfirmTitle => '确定要注销账户吗？';

  @override
  String get deleteAccountConfirmMessage => '注销后，账户及保存的所有信息将立即删除，且无法恢复。';

  @override
  String get deleteAccountConfirmLabel => '注销';

  @override
  String get phoneStartTitle => '使用手机号码开始';

  @override
  String get phoneStartSubtitle => '请输入姓名和手机号码。';

  @override
  String get nameLabel => '姓名';

  @override
  String get phoneNumberLabel => '手机号码';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get startButton => '开始';

  @override
  String get navHome => '首页';

  @override
  String get navNotification => '通知';

  @override
  String get navRecords => '记录';

  @override
  String get navStatistics => '统计';

  @override
  String get navMore => '更多';

  @override
  String get noConnectedEldersMessage => '尚未连接任何老人。';

  @override
  String get connectElderAction => '连接老人';

  @override
  String get recentActivityTitle => '最近活动';

  @override
  String get upcomingScheduleTitle => '即将到来的日程';

  @override
  String get noUpcomingSchedule => '没有安排的日程。';

  @override
  String get reassuranceLoadError => '无法加载安心状态。';

  @override
  String get dangerousAlertTitle => '有需要确认的活动';

  @override
  String get alertCheckRecordsDescription => '请在记录标签中查看详细信息。';

  @override
  String get cautionAlertTitle => '有需要留意的活动';

  @override
  String get safeStatusMessage => '祝您今天平安。';

  @override
  String get safeStatusDescription => '目前没有特别通知。';

  @override
  String get recentActivityLoadError => '无法加载最近活动。';

  @override
  String get noActivityRecords => '尚无活动记录。';
}
