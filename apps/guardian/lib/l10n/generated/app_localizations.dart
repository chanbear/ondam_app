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
  /// **'이름과 휴대폰 번호를 입력해주세요.'**
  String get phoneStartSubtitle;

  /// No description provided for @nameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get nameLabel;

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

  /// No description provided for @startButton.
  ///
  /// In ko, this message translates to:
  /// **'시작하기'**
  String get startButton;

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
