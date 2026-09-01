// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ondam';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get accountSectionTitle => 'Account';

  @override
  String get logout => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmTitle => 'Delete your account?';

  @override
  String get deleteAccountConfirmMessage =>
      'Deleting your account permanently removes it and all saved information right away. This cannot be undone.';

  @override
  String get deleteAccountConfirmLabel => 'Delete';

  @override
  String get phoneStartTitle => 'Get started with your phone number';

  @override
  String get phoneStartSubtitle => 'Enter your phone number and password.';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberHint => '010-0000-0000';

  @override
  String get pinLabel => 'Password';

  @override
  String get pinHint => '4-digit number';

  @override
  String get startButton => 'Get started';

  @override
  String get forgotPinLink => 'Forgot your password?';

  @override
  String pinWrongWithCount(int count) {
    return 'Incorrect password. ($count failed attempts)';
  }

  @override
  String get pinWrong => 'Incorrect password.';

  @override
  String pinLockedWithTime(String time) {
    return 'Too many attempts. Please try again at $time.';
  }

  @override
  String get pinLockedNoTime =>
      'Too many attempts. Your account is temporarily locked — please try again shortly.';

  @override
  String get pinNotSet => 'No password has been set.';

  @override
  String get pinInvalidFormat => 'Your password must be a 4-digit number.';

  @override
  String get pinUnknownError => 'Something went wrong. Please try again.';

  @override
  String get navHome => 'Home';

  @override
  String get navNotification => 'Alerts';

  @override
  String get navRecords => 'History';

  @override
  String get navStatistics => 'Stats';

  @override
  String get navMore => 'More';

  @override
  String get noConnectedEldersMessage => 'No elders connected yet.';

  @override
  String get connectElderAction => 'Connect with an elder';

  @override
  String get recentActivityTitle => 'Recent activity';

  @override
  String get recentActivityEyebrow => 'Latest updates';

  @override
  String get upcomingScheduleTitle => 'Upcoming schedule';

  @override
  String get upcomingScheduleEyebrow => 'So nothing slips';

  @override
  String get noUpcomingSchedule => 'No upcoming schedule.';

  @override
  String get reassuranceLoadError => 'We couldn\'t load the status.';

  @override
  String get dangerousAlertTitle =>
      'There\'s activity that needs your attention';

  @override
  String get alertCheckRecordsDescription =>
      'Check the History tab for details.';

  @override
  String get cautionAlertTitle => 'There\'s activity that needs some caution';

  @override
  String get safeStatusMessage => 'Everything looks fine today.';

  @override
  String get safeStatusDescription => 'No special alerts yet.';

  @override
  String get recentActivityLoadError => 'We couldn\'t load recent activity.';

  @override
  String get noActivityRecords => 'No activity records yet.';

  @override
  String get recentNotificationsTitle => 'Recent alerts';

  @override
  String get recentNotificationsEyebrow => 'Please check now';

  @override
  String get viewAllAction => 'View all';

  @override
  String get noRecentNotifications => 'No alerts yet.';

  @override
  String get recentNotificationsLoadError => 'We couldn\'t load alerts.';

  @override
  String get notificationUnreadLabel => 'New';

  @override
  String get notificationReadLabel => 'Checked';

  @override
  String get documentDetailTitle => 'Document analysis details';

  @override
  String get messageDetailTitle => 'Message check details';

  @override
  String get detailsToggleTitle => 'View details';

  @override
  String get reliabilityLabel => 'Reliability';

  @override
  String get sourceTextLabel => 'Original text';

  @override
  String get confirmButtonLabel => 'Confirm';

  @override
  String get confirmedBannerLabel => 'Marked as confirmed';

  @override
  String get realtimeAlertsTitle => 'Live alerts';

  @override
  String get unreadNotificationsCountLabel => 'Unread alerts';

  @override
  String get unreadNotificationsSummaryDescription =>
      'Alerts that need attention from your parent\'s checked documents and messages show up here.';

  @override
  String get riskRecordsTitle => 'Risk records';

  @override
  String get riskRecordsLoadError => 'We couldn\'t load records.';

  @override
  String get noRiskRecords => 'No risk records yet.';

  @override
  String get riskSafeLabel => 'Safe';

  @override
  String get riskCautionLabel => 'Caution';

  @override
  String get riskDangerousLabel => 'Danger detected';

  @override
  String get analysisTypeDocumentLabel => 'Document analysis';

  @override
  String get analysisTypeMessageLabel => 'Message check';

  @override
  String get connectAnotherElderAction => 'Connect another elder';

  @override
  String get connectAnotherElderSubtitle => 'Link a new elder to your account';

  @override
  String get settingsSubtitle => 'Manage language and account';

  @override
  String get supportTitle => 'Support';

  @override
  String get supportSubtitle => 'Reach out if you need help';

  @override
  String get supportFaqSectionTitle => 'Frequently asked questions';

  @override
  String get supportFaqConnectQuestion => 'How do I connect an elder?';

  @override
  String get supportFaqConnectAnswer =>
      'Tap \'Connect another elder\' in More, then point your camera at the QR code shown on the elder\'s ONDAM app screen to connect instantly.';

  @override
  String get supportFaqAlertQuestion => 'When do risk alerts arrive?';

  @override
  String get supportFaqAlertAnswer =>
      'You\'ll get a real-time alert whenever a document or message the elder checked is flagged as caution or dangerous. Safe items aren\'t reported separately.';

  @override
  String get supportFaqMultipleEldersQuestion =>
      'Can I connect more than one elder?';

  @override
  String get supportFaqMultipleEldersAnswer =>
      'Yes — keep adding elders from \'Connect another elder\' in More, and switch between them at the top of the Home screen.';

  @override
  String get supportFaqDisconnectQuestion => 'What happens if I disconnect?';

  @override
  String get supportFaqDisconnectAnswer =>
      'Disconnecting removes that elder\'s alerts and records from your view, and it also disappears from their connection list.';

  @override
  String get supportPrivacySectionTitle => 'Privacy';

  @override
  String get supportPrivacyNote =>
      'Sensitive information like the elder\'s password, PIN, or display settings is never shared with guardians. ONDAM only shows alerts and records that need your attention.';

  @override
  String get guardianLoginEyebrow => 'Family peace of mind';

  @override
  String get pinForgotTitle => 'Reset PIN';

  @override
  String get pinForgotReauthFailedTitle => 'We couldn\'t verify your identity';

  @override
  String get retryButtonLabel => 'Try again';

  @override
  String get pinForgotNewPinTitle => 'Please set a new 4-digit PIN';

  @override
  String get pinKeypadClearLabel => 'Clear';

  @override
  String get recordsLoadError => 'We couldn\'t load the analysis records.';

  @override
  String get recordsEmptyMessage => 'No analysis records yet.';

  @override
  String get filterAllLabel => 'All';

  @override
  String get filterDangerLabel => 'Risky';

  @override
  String get filterDocumentLabel => 'Documents';

  @override
  String get filterMessageLabel => 'Messages';

  @override
  String get statisticsLoadError => 'We couldn\'t load the statistics.';

  @override
  String get statisticsEmptyMessage => 'No data to show statistics for yet.';

  @override
  String get thisMonthCountLabel => 'Analyses this month';

  @override
  String get riskyThisMonthCountLabel => 'Risky messages this month';

  @override
  String get completedScheduleCountLabel => 'Completed schedules';

  @override
  String get pendingScheduleCountLabel => 'Remaining schedules';

  @override
  String get recentWeeksActivityTitle => 'Last 4 weeks';

  @override
  String get recentWeeksActivitySubtitle => 'Analyses';

  @override
  String get fourWeeksAgoLabel => '4 wks ago';

  @override
  String get thisWeekLabel => 'This week';

  @override
  String countUnitLabel(int count) {
    return '$count';
  }

  @override
  String get guardianSummaryTitle => 'Care Summary';

  @override
  String guardianSummaryRiskyCount(int count) {
    return '$count risky item(s) need your attention';
  }

  @override
  String guardianSummaryPendingSchedule(int count) {
    return '$count schedule(s) still pending';
  }

  @override
  String get guardianSummaryAllClear =>
      'No risky items or pending schedules right now';

  @override
  String get feeStatisticsSectionTitle => 'Fee Statistics';

  @override
  String get billingInfoSectionTitle => 'Bill Information';

  @override
  String get billingInfoUndecidedNotice =>
      'We haven\'t finalized which bill fields to summarize yet — showing the raw info from each record.';

  @override
  String get billingInfoEmptyMessage => 'No bill information yet.';

  @override
  String get trendSameAsLastMonth => 'Same as last month';

  @override
  String trendIncreasedLabel(int count) {
    return '$count more than last month';
  }

  @override
  String trendDecreasedLabel(int count) {
    return '$count fewer than last month';
  }

  @override
  String get feeStatisticsEmptyMessage =>
      'No fee statistics yet.\nAnalyze a bill or invoice to build your statistics.';

  @override
  String get totalFeeLabel => 'Total fee';

  @override
  String get averageFeeLabel => 'Average fee';

  @override
  String get maxFeeLabel => 'Highest fee';

  @override
  String get feeRecordCountLabel => 'Bill records';

  @override
  String get monthlyToggleLabel => 'Monthly';

  @override
  String get yearlyToggleLabel => 'Yearly';

  @override
  String toggleViewSemanticLabel(String label) {
    return 'View $label';
  }

  @override
  String get monthlyTrendTitle => 'Monthly fee trend';

  @override
  String get yearlyTrendTitle => 'Yearly fee trend';

  @override
  String get noDataInPeriodMessage => 'No fee records for this period.';

  @override
  String get feeFootnote =>
      'Calculated from the amounts on analyzed bills and invoices. Records where AI couldn\'t extract an amount are excluded.';

  @override
  String get feeChartEmptyMessage => 'No fee statistics yet.';

  @override
  String get feeChartSemanticNoData => 'Fee trend chart. No data yet.';

  @override
  String feeChartSemanticSummary(String summary) {
    return 'Fee trend chart. $summary';
  }

  @override
  String monthNumberLabel(int month) {
    return '$month';
  }

  @override
  String yearNumberLabel(int year) {
    return '$year';
  }

  @override
  String get structuredFieldRiskTypeLabel => 'Risk type';

  @override
  String get riskTypeVoicePhishingLure => 'Voice phishing lure';

  @override
  String get riskTypeSmishing => 'Smishing (text scam)';

  @override
  String get riskTypeLoanScam => 'Loan scam';

  @override
  String get riskTypeImpersonationAuthority => 'Authority impersonation';

  @override
  String get riskTypeDeliveryScam => 'Delivery scam';

  @override
  String get riskTypeInvestmentScam => 'Investment scam';

  @override
  String get riskTypeRomanceScam => 'Romance scam';

  @override
  String get riskTypeOtherScam => 'Other scam';

  @override
  String get riskTypeNone => 'None';

  @override
  String get notificationTypeRiskyDocument => 'Risk detected in a document';

  @override
  String get notificationTypeRiskyMessage => 'Risk detected in a message';

  @override
  String get guardianConnectionManageTitle => 'Manage Elder Connections';

  @override
  String get connectElderActionLong => 'Connect with an elder';

  @override
  String get connectionListLoadError =>
      'We couldn\'t load the connection list.';

  @override
  String get connectionListEmptyMessage =>
      'No elders connected yet\nTap Connect with an elder to scan a QR code';

  @override
  String elderPlaceholderName(String id) {
    return 'Elder ($id)';
  }

  @override
  String get elderRevokeConfirmTitle => 'Disconnect this elder?';

  @override
  String get elderRevokeConfirmMessage =>
      'Once disconnected, you\'ll no longer be able to see this elder\'s information.';

  @override
  String get elderRevokeConfirmLabel => 'Disconnect';

  @override
  String get elderRevokeAction => 'Disconnect';

  @override
  String get elderLinkStatusPending => 'Waiting for the elder to accept';

  @override
  String get elderLinkStatusAccepted => 'Connected';

  @override
  String get elderLinkStatusRejected => 'Declined';

  @override
  String get elderLinkStatusRevoked => 'Disconnected';

  @override
  String get connectionRequestSendingMessage =>
      'Sending the connection request';

  @override
  String get qrScanInstructionMessage =>
      'Point your camera at the QR code on the elder\'s screen';

  @override
  String get cameraPermissionRequiredMessage => 'Camera permission is required';

  @override
  String get openSettingsAction => 'Go to settings';

  @override
  String get connectionRequestSentTitle => 'Connection request sent';

  @override
  String get connectionRequestSentDescription =>
      'The connection will complete once the elder accepts the request.';

  @override
  String get okButtonLabel => 'OK';

  @override
  String get comingSoonMessage => 'This feature is still being built.';

  @override
  String demoUsageBadgeLabel(int months, int count) {
    return 'Demo · used for $months months · $count analyses';
  }
}
