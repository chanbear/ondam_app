import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'온담'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @accountSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get accountSectionTitle;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원 탈퇴'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'정말 탈퇴하시겠어요?'**
  String get deleteAccountConfirmTitle;

  /// No description provided for @deleteAccountConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하면 계정과 함께 저장된 모든 정보가 즉시 삭제되고 되돌릴 수 없어요.'**
  String get deleteAccountConfirmMessage;

  /// No description provided for @deleteAccountConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴하기'**
  String get deleteAccountConfirmLabel;

  /// No description provided for @phoneStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호로 시작하기'**
  String get phoneStartTitle;

  /// No description provided for @phoneStartSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호와 비밀번호를 입력해주세요.'**
  String get phoneStartSubtitle;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In ko, this message translates to:
  /// **'휴대폰 번호'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberHint.
  ///
  /// In ko, this message translates to:
  /// **'010-0000-0000'**
  String get phoneNumberHint;

  /// No description provided for @pinLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get pinLabel;

  /// No description provided for @pinHint.
  ///
  /// In ko, this message translates to:
  /// **'4자리 숫자'**
  String get pinHint;

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get startButton;

  /// No description provided for @forgotPinLink.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get forgotPinLink;

  /// No description provided for @pinWrongWithCount.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 올바르지 않아요. ({count}회 실패)'**
  String pinWrongWithCount(int count);

  /// No description provided for @pinWrong.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 올바르지 않아요.'**
  String get pinWrong;

  /// No description provided for @pinLockedWithTime.
  ///
  /// In ko, this message translates to:
  /// **'너무 여러 번 틀렸어요. {time}에 다시 시도해주세요.'**
  String pinLockedWithTime(String time);

  /// No description provided for @pinLockedNoTime.
  ///
  /// In ko, this message translates to:
  /// **'너무 여러 번 틀려서 잠시 잠겼어요. 잠시 후 다시 시도해주세요.'**
  String get pinLockedNoTime;

  /// No description provided for @pinNotSet.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 설정되어 있지 않아요.'**
  String get pinNotSet;

  /// No description provided for @pinInvalidFormat.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 4자리 숫자예요.'**
  String get pinInvalidFormat;

  /// No description provided for @pinUnknownError.
  ///
  /// In ko, this message translates to:
  /// **'확인 중 문제가 발생했어요. 다시 시도해주세요.'**
  String get pinUnknownError;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navNotification.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get navNotification;

  /// No description provided for @navRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get navRecords;

  /// No description provided for @navStatistics.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get navStatistics;

  /// No description provided for @navMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get navMore;

  /// No description provided for @noConnectedEldersMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 어르신이 없습니다.'**
  String get noConnectedEldersMessage;

  /// No description provided for @connectElderAction.
  ///
  /// In ko, this message translates to:
  /// **'어르신 연결하기'**
  String get connectElderAction;

  /// No description provided for @recentActivityTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 활동'**
  String get recentActivityTitle;

  /// No description provided for @upcomingScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'다가오는 일정'**
  String get upcomingScheduleTitle;

  /// No description provided for @noUpcomingSchedule.
  ///
  /// In ko, this message translates to:
  /// **'예정된 일정이 없어요.'**
  String get noUpcomingSchedule;

  /// No description provided for @reassuranceLoadError.
  ///
  /// In ko, this message translates to:
  /// **'안심 상태를 불러오지 못했어요.'**
  String get reassuranceLoadError;

  /// No description provided for @dangerousAlertTitle.
  ///
  /// In ko, this message translates to:
  /// **'확인이 필요한 활동이 있어요'**
  String get dangerousAlertTitle;

  /// No description provided for @alertCheckRecordsDescription.
  ///
  /// In ko, this message translates to:
  /// **'기록 탭에서 자세한 내용을 확인해주세요.'**
  String get alertCheckRecordsDescription;

  /// No description provided for @cautionAlertTitle.
  ///
  /// In ko, this message translates to:
  /// **'주의가 필요한 활동이 있어요'**
  String get cautionAlertTitle;

  /// No description provided for @safeStatusMessage.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 평안하세요.'**
  String get safeStatusMessage;

  /// No description provided for @safeStatusDescription.
  ///
  /// In ko, this message translates to:
  /// **'아직 특별한 알림이 없어요.'**
  String get safeStatusDescription;

  /// No description provided for @recentActivityLoadError.
  ///
  /// In ko, this message translates to:
  /// **'최근 활동을 불러오지 못했어요.'**
  String get recentActivityLoadError;

  /// No description provided for @noActivityRecords.
  ///
  /// In ko, this message translates to:
  /// **'아직 활동 기록이 없어요.'**
  String get noActivityRecords;

  /// No description provided for @recentNotificationsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 알림'**
  String get recentNotificationsTitle;

  /// No description provided for @viewAllAction.
  ///
  /// In ko, this message translates to:
  /// **'전체보기'**
  String get viewAllAction;

  /// No description provided for @noRecentNotifications.
  ///
  /// In ko, this message translates to:
  /// **'아직 받은 알림이 없습니다.'**
  String get noRecentNotifications;

  /// No description provided for @recentNotificationsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'알림을 불러오지 못했어요.'**
  String get recentNotificationsLoadError;

  /// No description provided for @notificationUnreadLabel.
  ///
  /// In ko, this message translates to:
  /// **'새 알림'**
  String get notificationUnreadLabel;

  /// No description provided for @notificationReadLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인함'**
  String get notificationReadLabel;

  /// No description provided for @documentDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 분석 상세'**
  String get documentDetailTitle;

  /// No description provided for @messageDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'문자 확인 상세'**
  String get messageDetailTitle;

  /// No description provided for @detailsToggleTitle.
  ///
  /// In ko, this message translates to:
  /// **'상세정보 보기'**
  String get detailsToggleTitle;

  /// No description provided for @reliabilityLabel.
  ///
  /// In ko, this message translates to:
  /// **'신뢰도'**
  String get reliabilityLabel;

  /// No description provided for @sourceTextLabel.
  ///
  /// In ko, this message translates to:
  /// **'원문'**
  String get sourceTextLabel;

  /// No description provided for @confirmButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료'**
  String get confirmButtonLabel;

  /// No description provided for @confirmedBannerLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료했어요'**
  String get confirmedBannerLabel;

  /// No description provided for @realtimeAlertsTitle.
  ///
  /// In ko, this message translates to:
  /// **'실시간 알림'**
  String get realtimeAlertsTitle;

  /// No description provided for @riskRecordsTitle.
  ///
  /// In ko, this message translates to:
  /// **'위험 기록'**
  String get riskRecordsTitle;

  /// No description provided for @riskRecordsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오지 못했어요.'**
  String get riskRecordsLoadError;

  /// No description provided for @noRiskRecords.
  ///
  /// In ko, this message translates to:
  /// **'아직 위험 기록이 없습니다.'**
  String get noRiskRecords;

  /// No description provided for @riskSafeLabel.
  ///
  /// In ko, this message translates to:
  /// **'안전'**
  String get riskSafeLabel;

  /// No description provided for @riskCautionLabel.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get riskCautionLabel;

  /// No description provided for @riskDangerousLabel.
  ///
  /// In ko, this message translates to:
  /// **'위험 감지'**
  String get riskDangerousLabel;

  /// No description provided for @analysisTypeDocumentLabel.
  ///
  /// In ko, this message translates to:
  /// **'문서 분석'**
  String get analysisTypeDocumentLabel;

  /// No description provided for @analysisTypeMessageLabel.
  ///
  /// In ko, this message translates to:
  /// **'문자 확인'**
  String get analysisTypeMessageLabel;

  /// No description provided for @connectAnotherElderAction.
  ///
  /// In ko, this message translates to:
  /// **'다른 어르신 연결'**
  String get connectAnotherElderAction;

  /// No description provided for @supportTitle.
  ///
  /// In ko, this message translates to:
  /// **'고객 지원'**
  String get supportTitle;

  /// No description provided for @pinForgotTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN 재설정'**
  String get pinForgotTitle;

  /// No description provided for @pinForgotReauthFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'본인 확인에 실패했어요'**
  String get pinForgotReauthFailedTitle;

  /// No description provided for @retryButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retryButtonLabel;

  /// No description provided for @pinForgotNewPinTitle.
  ///
  /// In ko, this message translates to:
  /// **'새로운 PIN 4자리를 정해주세요'**
  String get pinForgotNewPinTitle;

  /// No description provided for @pinKeypadClearLabel.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get pinKeypadClearLabel;

  /// No description provided for @recordsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'분석 기록을 불러오지 못했어요.'**
  String get recordsLoadError;

  /// No description provided for @recordsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 분석 기록이 없습니다.'**
  String get recordsEmptyMessage;

  /// No description provided for @statisticsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'통계를 불러오지 못했어요.'**
  String get statisticsLoadError;

  /// No description provided for @statisticsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 통계로 보여드릴 데이터가 없습니다.'**
  String get statisticsEmptyMessage;

  /// No description provided for @thisMonthCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 분석 건수'**
  String get thisMonthCountLabel;

  /// No description provided for @riskyThisMonthCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'위험 문자 건수'**
  String get riskyThisMonthCountLabel;

  /// No description provided for @countUnitLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String countUnitLabel(int count);

  /// No description provided for @feeStatisticsSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'요금 통계'**
  String get feeStatisticsSectionTitle;

  /// No description provided for @billingInfoSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'고지서 정보'**
  String get billingInfoSectionTitle;

  /// No description provided for @billingInfoUndecidedNotice.
  ///
  /// In ko, this message translates to:
  /// **'고지서 통계 항목은 아직 결정되지 않았어요. 기록에 담긴 원본 정보만 보여드려요.'**
  String get billingInfoUndecidedNotice;

  /// No description provided for @billingInfoEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 고지서 정보가 없습니다.'**
  String get billingInfoEmptyMessage;

  /// No description provided for @trendSameAsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달과 동일해요'**
  String get trendSameAsLastMonth;

  /// No description provided for @trendIncreasedLabel.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 {count}건 늘었어요'**
  String trendIncreasedLabel(int count);

  /// No description provided for @trendDecreasedLabel.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 {count}건 줄었어요'**
  String trendDecreasedLabel(int count);

  /// No description provided for @feeStatisticsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 요금 통계가 없습니다.\n고지서나 요금서를 분석하면 통계가 만들어집니다.'**
  String get feeStatisticsEmptyMessage;

  /// No description provided for @totalFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 요금'**
  String get totalFeeLabel;

  /// No description provided for @averageFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'평균 요금'**
  String get averageFeeLabel;

  /// No description provided for @maxFeeLabel.
  ///
  /// In ko, this message translates to:
  /// **'최고 요금'**
  String get maxFeeLabel;

  /// No description provided for @feeRecordCountLabel.
  ///
  /// In ko, this message translates to:
  /// **'요금 내역'**
  String get feeRecordCountLabel;

  /// No description provided for @monthlyToggleLabel.
  ///
  /// In ko, this message translates to:
  /// **'월별'**
  String get monthlyToggleLabel;

  /// No description provided for @yearlyToggleLabel.
  ///
  /// In ko, this message translates to:
  /// **'연별'**
  String get yearlyToggleLabel;

  /// No description provided for @toggleViewSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'{label} 보기'**
  String toggleViewSemanticLabel(String label);

  /// No description provided for @monthlyTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'월별 요금 추이'**
  String get monthlyTrendTitle;

  /// No description provided for @yearlyTrendTitle.
  ///
  /// In ko, this message translates to:
  /// **'연별 요금 추이'**
  String get yearlyTrendTitle;

  /// No description provided for @noDataInPeriodMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 기간에는 요금 기록이 없습니다.'**
  String get noDataInPeriodMessage;

  /// No description provided for @feeFootnote.
  ///
  /// In ko, this message translates to:
  /// **'분석된 고지서/요금서의 금액을 기준으로 계산합니다. AI가 금액을 추출하지 못한 기록은 제외됩니다.'**
  String get feeFootnote;

  /// No description provided for @feeChartEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 요금 통계가 없습니다.'**
  String get feeChartEmptyMessage;

  /// No description provided for @feeChartSemanticNoData.
  ///
  /// In ko, this message translates to:
  /// **'요금 추이 그래프. 아직 데이터가 없습니다.'**
  String get feeChartSemanticNoData;

  /// No description provided for @feeChartSemanticSummary.
  ///
  /// In ko, this message translates to:
  /// **'요금 추이 그래프. {summary}'**
  String feeChartSemanticSummary(String summary);

  /// No description provided for @monthNumberLabel.
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String monthNumberLabel(int month);

  /// No description provided for @yearNumberLabel.
  ///
  /// In ko, this message translates to:
  /// **'{year}년'**
  String yearNumberLabel(int year);

  /// No description provided for @structuredFieldRiskTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'위험 유형'**
  String get structuredFieldRiskTypeLabel;

  /// No description provided for @riskTypeVoicePhishingLure.
  ///
  /// In ko, this message translates to:
  /// **'보이스피싱 유도'**
  String get riskTypeVoicePhishingLure;

  /// No description provided for @riskTypeSmishing.
  ///
  /// In ko, this message translates to:
  /// **'스미싱(문자 사기)'**
  String get riskTypeSmishing;

  /// No description provided for @riskTypeLoanScam.
  ///
  /// In ko, this message translates to:
  /// **'대출 사기'**
  String get riskTypeLoanScam;

  /// No description provided for @riskTypeImpersonationAuthority.
  ///
  /// In ko, this message translates to:
  /// **'기관 사칭'**
  String get riskTypeImpersonationAuthority;

  /// No description provided for @riskTypeDeliveryScam.
  ///
  /// In ko, this message translates to:
  /// **'배송 사기'**
  String get riskTypeDeliveryScam;

  /// No description provided for @riskTypeInvestmentScam.
  ///
  /// In ko, this message translates to:
  /// **'투자 사기'**
  String get riskTypeInvestmentScam;

  /// No description provided for @riskTypeRomanceScam.
  ///
  /// In ko, this message translates to:
  /// **'로맨스 스캠'**
  String get riskTypeRomanceScam;

  /// No description provided for @riskTypeOtherScam.
  ///
  /// In ko, this message translates to:
  /// **'기타 사기'**
  String get riskTypeOtherScam;

  /// No description provided for @riskTypeNone.
  ///
  /// In ko, this message translates to:
  /// **'해당 없음'**
  String get riskTypeNone;

  /// No description provided for @notificationTypeRiskyDocument.
  ///
  /// In ko, this message translates to:
  /// **'문서에서 위험 신호가 감지됐어요'**
  String get notificationTypeRiskyDocument;

  /// No description provided for @notificationTypeRiskyMessage.
  ///
  /// In ko, this message translates to:
  /// **'문자에서 위험 신호가 감지됐어요'**
  String get notificationTypeRiskyMessage;

  /// No description provided for @guardianConnectionManageTitle.
  ///
  /// In ko, this message translates to:
  /// **'어르신 연결 관리'**
  String get guardianConnectionManageTitle;

  /// No description provided for @connectElderActionLong.
  ///
  /// In ko, this message translates to:
  /// **'어르신 연결하기'**
  String get connectElderActionLong;

  /// No description provided for @connectionListLoadError.
  ///
  /// In ko, this message translates to:
  /// **'연결 목록을 불러오지 못했어요.'**
  String get connectionListLoadError;

  /// No description provided for @connectionListEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 어르신이 없습니다\n어르신 연결하기로 QR을 스캔해주세요'**
  String get connectionListEmptyMessage;

  /// No description provided for @elderPlaceholderName.
  ///
  /// In ko, this message translates to:
  /// **'어르신 ({id})'**
  String elderPlaceholderName(String id);

  /// No description provided for @elderRevokeConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결을 해제할까요?'**
  String get elderRevokeConfirmTitle;

  /// No description provided for @elderRevokeConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'해제하면 이 어르신의 정보를 더 이상 볼 수 없습니다.'**
  String get elderRevokeConfirmMessage;

  /// No description provided for @elderRevokeConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get elderRevokeConfirmLabel;

  /// No description provided for @elderRevokeAction.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get elderRevokeAction;

  /// No description provided for @elderLinkStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'어르신 수락 대기 중'**
  String get elderLinkStatusPending;

  /// No description provided for @elderLinkStatusAccepted.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get elderLinkStatusAccepted;

  /// No description provided for @elderLinkStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'거절됨'**
  String get elderLinkStatusRejected;

  /// No description provided for @elderLinkStatusRevoked.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제됨'**
  String get elderLinkStatusRevoked;

  /// No description provided for @connectionRequestSendingMessage.
  ///
  /// In ko, this message translates to:
  /// **'연결 요청을 보내고 있어요'**
  String get connectionRequestSendingMessage;

  /// No description provided for @qrScanInstructionMessage.
  ///
  /// In ko, this message translates to:
  /// **'어르신 화면에 표시된 QR 코드를 비춰주세요'**
  String get qrScanInstructionMessage;

  /// No description provided for @cameraPermissionRequiredMessage.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 필요해요'**
  String get cameraPermissionRequiredMessage;

  /// No description provided for @openSettingsAction.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get openSettingsAction;

  /// No description provided for @connectionRequestSentTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결 요청을 보냈어요'**
  String get connectionRequestSentTitle;

  /// No description provided for @connectionRequestSentDescription.
  ///
  /// In ko, this message translates to:
  /// **'어르신이 요청을 수락하면 연결이 완료돼요.'**
  String get connectionRequestSentDescription;

  /// No description provided for @okButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get okButtonLabel;

  /// No description provided for @comingSoonMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 기능은 아직 준비 중이에요.'**
  String get comingSoonMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
