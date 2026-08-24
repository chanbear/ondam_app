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
  String get phoneStartSubtitle => '请输入手机号码和密码。';

  @override
  String get phoneNumberLabel => '手机号码';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => '密码';

  @override
  String get pinHint => '4位数字';

  @override
  String get startButton => '开始';

  @override
  String get forgotPinLink => '忘记密码了吗？';

  @override
  String pinWrongWithCount(int count) {
    return '密码不正确。（已失败$count次）';
  }

  @override
  String get pinWrong => '密码不正确。';

  @override
  String pinLockedWithTime(String time) {
    return '尝试次数过多。请在$time后重试。';
  }

  @override
  String get pinLockedNoTime => '尝试次数过多，账户已暂时锁定。请稍后重试。';

  @override
  String get pinNotSet => '尚未设置密码。';

  @override
  String get pinInvalidFormat => '密码必须是4位数字。';

  @override
  String get pinUnknownError => '确认时出现问题。请重试。';

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

  @override
  String get recentNotificationsTitle => '最近通知';

  @override
  String get viewAllAction => '查看全部';

  @override
  String get noRecentNotifications => '尚未收到通知。';

  @override
  String get recentNotificationsLoadError => '无法加载通知。';

  @override
  String get notificationUnreadLabel => '新通知';

  @override
  String get notificationReadLabel => '已查看';

  @override
  String get documentDetailTitle => '文档分析详情';

  @override
  String get messageDetailTitle => '短信核查详情';

  @override
  String get detailsToggleTitle => '查看详情';

  @override
  String get reliabilityLabel => '可信度';

  @override
  String get sourceTextLabel => '原文';

  @override
  String get confirmButtonLabel => '确认完成';

  @override
  String get confirmedBannerLabel => '已确认完成';

  @override
  String get realtimeAlertsTitle => '实时通知';

  @override
  String get riskRecordsTitle => '风险记录';

  @override
  String get riskRecordsLoadError => '无法加载记录。';

  @override
  String get noRiskRecords => '尚无风险记录。';

  @override
  String get riskSafeLabel => '安全';

  @override
  String get riskCautionLabel => '注意';

  @override
  String get riskDangerousLabel => '检测到危险';

  @override
  String get analysisTypeDocumentLabel => '文件分析';

  @override
  String get analysisTypeMessageLabel => '短信核查';

  @override
  String get connectAnotherElderAction => '连接其他老人';

  @override
  String get supportTitle => '客服支持';

  @override
  String get pinForgotTitle => '重置PIN';

  @override
  String get pinForgotReauthFailedTitle => '身份验证失败';

  @override
  String get retryButtonLabel => '重试';

  @override
  String get pinForgotNewPinTitle => '请设置新的4位PIN码';

  @override
  String get pinKeypadClearLabel => '清除';

  @override
  String get recordsLoadError => '无法加载分析记录。';

  @override
  String get recordsEmptyMessage => '尚无分析记录。';

  @override
  String get statisticsLoadError => '无法加载统计数据。';

  @override
  String get statisticsEmptyMessage => '尚无可显示的统计数据。';

  @override
  String get thisMonthCountLabel => '本月分析次数';

  @override
  String get riskyThisMonthCountLabel => '本月风险短信数';

  @override
  String countUnitLabel(int count) {
    return '$count件';
  }

  @override
  String get feeStatisticsSectionTitle => '费用统计';

  @override
  String get billingInfoSectionTitle => '账单信息';

  @override
  String get billingInfoUndecidedNotice => '账单统计项目尚未确定，仅显示记录中的原始信息。';

  @override
  String get billingInfoEmptyMessage => '尚无账单信息。';

  @override
  String get trendSameAsLastMonth => '与上月持平';

  @override
  String trendIncreasedLabel(int count) {
    return '比上月增加$count件';
  }

  @override
  String trendDecreasedLabel(int count) {
    return '比上月减少$count件';
  }

  @override
  String get feeStatisticsEmptyMessage => '尚无费用统计。\n分析账单或缴费通知单后将生成统计数据。';

  @override
  String get totalFeeLabel => '总费用';

  @override
  String get averageFeeLabel => '平均费用';

  @override
  String get maxFeeLabel => '最高费用';

  @override
  String get feeRecordCountLabel => '账单记录数';

  @override
  String get monthlyToggleLabel => '按月';

  @override
  String get yearlyToggleLabel => '按年';

  @override
  String toggleViewSemanticLabel(String label) {
    return '查看$label';
  }

  @override
  String get monthlyTrendTitle => '月度费用趋势';

  @override
  String get yearlyTrendTitle => '年度费用趋势';

  @override
  String get noDataInPeriodMessage => '该时间段内没有费用记录。';

  @override
  String get feeFootnote => '根据已分析账单/缴费通知单中的金额计算。AI未能提取金额的记录将被排除。';

  @override
  String get feeChartEmptyMessage => '尚无费用统计。';

  @override
  String get feeChartSemanticNoData => '费用趋势图。尚无数据。';

  @override
  String feeChartSemanticSummary(String summary) {
    return '费用趋势图。$summary';
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
  String get structuredFieldRiskTypeLabel => '风险类型';

  @override
  String get riskTypeVoicePhishingLure => '电话诈骗诱导';

  @override
  String get riskTypeSmishing => '短信诈骗';

  @override
  String get riskTypeLoanScam => '贷款诈骗';

  @override
  String get riskTypeImpersonationAuthority => '机构冒充';

  @override
  String get riskTypeDeliveryScam => '快递诈骗';

  @override
  String get riskTypeInvestmentScam => '投资诈骗';

  @override
  String get riskTypeRomanceScam => '恋爱诈骗';

  @override
  String get riskTypeOtherScam => '其他诈骗';

  @override
  String get riskTypeNone => '无';

  @override
  String get notificationTypeRiskyDocument => '文件中检测到风险信号';

  @override
  String get notificationTypeRiskyMessage => '短信中检测到风险信号';

  @override
  String get guardianConnectionManageTitle => '老人连接管理';

  @override
  String get connectElderActionLong => '连接老人';

  @override
  String get connectionListLoadError => '无法加载连接列表。';

  @override
  String get connectionListEmptyMessage => '尚未连接任何老人\n请点击\"连接老人\"扫描二维码';

  @override
  String elderPlaceholderName(String id) {
    return '老人（$id）';
  }

  @override
  String get elderRevokeConfirmTitle => '确定要解除连接吗？';

  @override
  String get elderRevokeConfirmMessage => '解除后将无法再查看该老人的信息。';

  @override
  String get elderRevokeConfirmLabel => '解除';

  @override
  String get elderRevokeAction => '解除连接';

  @override
  String get elderLinkStatusPending => '等待老人接受中';

  @override
  String get elderLinkStatusAccepted => '已连接';

  @override
  String get elderLinkStatusRejected => '已拒绝';

  @override
  String get elderLinkStatusRevoked => '已解除连接';

  @override
  String get connectionRequestSendingMessage => '正在发送连接请求';

  @override
  String get qrScanInstructionMessage => '请将摄像头对准老人屏幕上显示的二维码';

  @override
  String get cameraPermissionRequiredMessage => '需要相机权限';

  @override
  String get openSettingsAction => '前往设置';

  @override
  String get connectionRequestSentTitle => '已发送连接请求';

  @override
  String get connectionRequestSentDescription => '老人接受请求后即可完成连接。';

  @override
  String get okButtonLabel => '确定';

  @override
  String get comingSoonMessage => '此功能仍在开发中。';
}
