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

  /// No description provided for @easyModeSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'쉬운 모드'**
  String get easyModeSectionTitle;

  /// No description provided for @easyModeTitle.
  ///
  /// In ko, this message translates to:
  /// **'쉬운 모드'**
  String get easyModeTitle;

  /// No description provided for @easyModeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'큰 버튼과 단순한 화면으로 바꿔드려요'**
  String get easyModeSubtitle;

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

  /// No description provided for @voiceAssistantLabel.
  ///
  /// In ko, this message translates to:
  /// **'음성 비서'**
  String get voiceAssistantLabel;

  /// No description provided for @navInfo.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get navInfo;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navRecords.
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get navRecords;

  /// No description provided for @navMore.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get navMore;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get profileTitle;

  /// No description provided for @nameLabel.
  ///
  /// In ko, this message translates to:
  /// **'이름'**
  String get nameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In ko, this message translates to:
  /// **'나이'**
  String get ageLabel;

  /// No description provided for @profileSaved.
  ///
  /// In ko, this message translates to:
  /// **'프로필이 저장되었어요.'**
  String get profileSaved;

  /// No description provided for @profileLoadError.
  ///
  /// In ko, this message translates to:
  /// **'저장된 정보를 불러오지 못했어요.'**
  String get profileLoadError;

  /// No description provided for @myRegionTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 지역'**
  String get myRegionTitle;

  /// No description provided for @regionLoadError.
  ///
  /// In ko, this message translates to:
  /// **'지역 정보를 불러오지 못했어요.'**
  String get regionLoadError;

  /// No description provided for @currentRegionLabel.
  ///
  /// In ko, this message translates to:
  /// **'현재 지역'**
  String get currentRegionLabel;

  /// No description provided for @regionNotSetValue.
  ///
  /// In ko, this message translates to:
  /// **'아직 등록하지 않았어요'**
  String get regionNotSetValue;

  /// No description provided for @enterRegionAction.
  ///
  /// In ko, this message translates to:
  /// **'내 지역 입력하기'**
  String get enterRegionAction;

  /// No description provided for @saveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get saveButton;

  /// No description provided for @sidoLabel.
  ///
  /// In ko, this message translates to:
  /// **'시/도'**
  String get sidoLabel;

  /// No description provided for @sidoPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 선택해주세요'**
  String get sidoPlaceholder;

  /// No description provided for @sigunguLabel.
  ///
  /// In ko, this message translates to:
  /// **'시/군/구'**
  String get sigunguLabel;

  /// No description provided for @dongLabel.
  ///
  /// In ko, this message translates to:
  /// **'읍/면/동'**
  String get dongLabel;

  /// No description provided for @locatingButton.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치 확인 중이에요'**
  String get locatingButton;

  /// No description provided for @useCurrentLocationButton.
  ///
  /// In ko, this message translates to:
  /// **'현재 위치로 자동 입력'**
  String get useCurrentLocationButton;

  /// No description provided for @locationServiceDisabledError.
  ///
  /// In ko, this message translates to:
  /// **'위치 서비스를 켜신 뒤 다시 시도해주세요.'**
  String get locationServiceDisabledError;

  /// No description provided for @locationPermissionDeniedError.
  ///
  /// In ko, this message translates to:
  /// **'기기 설정에서 위치 권한을 허용한 뒤 다시 시도해주세요.'**
  String get locationPermissionDeniedError;

  /// No description provided for @locationPermissionRequiredError.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한을 허용해야 현재 위치를 사용할 수 있어요.'**
  String get locationPermissionRequiredError;

  /// No description provided for @sidoRequiredError.
  ///
  /// In ko, this message translates to:
  /// **'시/도를 선택해주세요.'**
  String get sidoRequiredError;

  /// No description provided for @regionSaved.
  ///
  /// In ko, this message translates to:
  /// **'내 지역이 저장되었어요.'**
  String get regionSaved;

  /// No description provided for @sidoPickerTitle.
  ///
  /// In ko, this message translates to:
  /// **'시/도 선택'**
  String get sidoPickerTitle;

  /// No description provided for @welfareCenterTitle.
  ///
  /// In ko, this message translates to:
  /// **'경로당 찾기'**
  String get welfareCenterTitle;

  /// No description provided for @welfareCenterRegionLoadError.
  ///
  /// In ko, this message translates to:
  /// **'내 지역 정보를 불러오지 못했어요.'**
  String get welfareCenterRegionLoadError;

  /// No description provided for @welfareCenterEmptyRegionMessage.
  ///
  /// In ko, this message translates to:
  /// **'경로당을 찾으려면 먼저 내 지역을 등록해주세요.'**
  String get welfareCenterEmptyRegionMessage;

  /// No description provided for @searchNearbyButton.
  ///
  /// In ko, this message translates to:
  /// **'내 주변 경로당 찾기'**
  String get searchNearbyButton;

  /// No description provided for @phoneLaunchError.
  ///
  /// In ko, this message translates to:
  /// **'전화 앱을 열 수 없어요.'**
  String get phoneLaunchError;

  /// No description provided for @welfareCenterSearchError.
  ///
  /// In ko, this message translates to:
  /// **'경로당 검색 중 문제가 발생했어요.'**
  String get welfareCenterSearchError;

  /// No description provided for @welfareCenterNoResults.
  ///
  /// In ko, this message translates to:
  /// **'근처에서 경로당을 찾지 못했어요.'**
  String get welfareCenterNoResults;

  /// No description provided for @callButtonTooltip.
  ///
  /// In ko, this message translates to:
  /// **'전화 걸기'**
  String get callButtonTooltip;

  /// No description provided for @voiceUnavailableError.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 음성 인식을 사용할 수 없어요.'**
  String get voiceUnavailableError;

  /// No description provided for @voiceInitError.
  ///
  /// In ko, this message translates to:
  /// **'음성 비서를 시작하지 못했어요.'**
  String get voiceInitError;

  /// No description provided for @voicePreparing.
  ///
  /// In ko, this message translates to:
  /// **'음성 비서를 준비하고 있어요'**
  String get voicePreparing;

  /// No description provided for @voiceProcessing.
  ///
  /// In ko, this message translates to:
  /// **'요청하신 내용을 확인하고 있어요'**
  String get voiceProcessing;

  /// No description provided for @voiceIdlePrompt.
  ///
  /// In ko, this message translates to:
  /// **'마이크를 눌러 말씀해주세요'**
  String get voiceIdlePrompt;

  /// No description provided for @voiceListening.
  ///
  /// In ko, this message translates to:
  /// **'듣고 있어요'**
  String get voiceListening;

  /// No description provided for @voiceStartSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'말하기 시작'**
  String get voiceStartSemanticLabel;

  /// No description provided for @voiceUnrecognizedAnswer.
  ///
  /// In ko, this message translates to:
  /// **'무슨 말씀인지 잘 이해하지 못했어요. \"문서 찍어줘\", \"문자 확인해줘\", \"긴급 도움\"처럼 말씀해주세요.'**
  String get voiceUnrecognizedAnswer;

  /// No description provided for @voiceRetryButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 말씀해주세요'**
  String get voiceRetryButton;
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
