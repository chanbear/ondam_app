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

  /// No description provided for @socialLoginDivider.
  ///
  /// In ko, this message translates to:
  /// **'또는'**
  String get socialLoginDivider;

  /// No description provided for @googleLoginButton.
  ///
  /// In ko, this message translates to:
  /// **'구글 로그인'**
  String get googleLoginButton;

  /// No description provided for @naverLoginButton.
  ///
  /// In ko, this message translates to:
  /// **'네이버 로그인'**
  String get naverLoginButton;

  /// No description provided for @kakaoLoginButton.
  ///
  /// In ko, this message translates to:
  /// **'카카오 로그인'**
  String get kakaoLoginButton;

  /// No description provided for @guestSignInButton.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 없이 사용하기'**
  String get guestSignInButton;

  /// No description provided for @socialLoginComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중인 기능이에요'**
  String get socialLoginComingSoon;

  /// No description provided for @oauthPinSetupTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 새로 설정해주세요'**
  String get oauthPinSetupTitle;

  /// No description provided for @oauthPinSetupSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'다음부터는 이 PIN으로 로그인해요.'**
  String get oauthPinSetupSubtitle;

  /// No description provided for @oauthPinEntryTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 입력해주세요'**
  String get oauthPinEntryTitle;

  /// No description provided for @oauthPinEntrySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'설정하신 4자리 PIN을 입력해주세요.'**
  String get oauthPinEntrySubtitle;

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

  /// No description provided for @genderSectionLabel.
  ///
  /// In ko, this message translates to:
  /// **'성별'**
  String get genderSectionLabel;

  /// No description provided for @genderMaleLabel.
  ///
  /// In ko, this message translates to:
  /// **'남성'**
  String get genderMaleLabel;

  /// No description provided for @genderFemaleLabel.
  ///
  /// In ko, this message translates to:
  /// **'여성'**
  String get genderFemaleLabel;

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

  /// No description provided for @publicFacilitySearchLabel.
  ///
  /// In ko, this message translates to:
  /// **'공공시설 찾기'**
  String get publicFacilitySearchLabel;

  /// No description provided for @publicFacilitySearchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'주변 공공시설을 찾아보세요'**
  String get publicFacilitySearchSubtitle;

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

  /// No description provided for @welfareCenterResultsSummary.
  ///
  /// In ko, this message translates to:
  /// **'{region} 근처 경로당 {count}곳'**
  String welfareCenterResultsSummary(String region, int count);

  /// No description provided for @callButtonTooltip.
  ///
  /// In ko, this message translates to:
  /// **'전화 걸기'**
  String get callButtonTooltip;

  /// No description provided for @directionsButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'길 찾기'**
  String get directionsButtonLabel;

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

  /// No description provided for @analysisResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과'**
  String get analysisResultTitle;

  /// No description provided for @shareButton.
  ///
  /// In ko, this message translates to:
  /// **'공유'**
  String get shareButton;

  /// No description provided for @pinEntryPrompt.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 입력해주세요'**
  String get pinEntryPrompt;

  /// No description provided for @pinForgotLink.
  ///
  /// In ko, this message translates to:
  /// **'PIN을 잊으셨나요?'**
  String get pinForgotLink;

  /// No description provided for @pinResetTitle.
  ///
  /// In ko, this message translates to:
  /// **'PIN 재설정'**
  String get pinResetTitle;

  /// No description provided for @identityVerifyFailedTitle.
  ///
  /// In ko, this message translates to:
  /// **'본인 확인에 실패했어요'**
  String get identityVerifyFailedTitle;

  /// No description provided for @retryButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retryButton;

  /// No description provided for @pinNewSetupPrompt.
  ///
  /// In ko, this message translates to:
  /// **'새로운 PIN 4자리를 정해주세요'**
  String get pinNewSetupPrompt;

  /// No description provided for @pinMismatchError.
  ///
  /// In ko, this message translates to:
  /// **'PIN이 일치하지 않아요. 처음부터 다시 입력해주세요.'**
  String get pinMismatchError;

  /// No description provided for @pinConfirmPrompt.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 입력해주세요'**
  String get pinConfirmPrompt;

  /// No description provided for @pinSetupPrompt.
  ///
  /// In ko, this message translates to:
  /// **'사용하실 PIN 4자리를 정해주세요'**
  String get pinSetupPrompt;

  /// No description provided for @pinSetupDescription.
  ///
  /// In ko, this message translates to:
  /// **'다음부터 앱을 열 때 이 PIN으로 확인해요.'**
  String get pinSetupDescription;

  /// No description provided for @roleSelectTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 분으로 이용하실까요?'**
  String get roleSelectTitle;

  /// No description provided for @roleSelectSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이용 목적에 맞게 화면을 준비해드릴게요.'**
  String get roleSelectSubtitle;

  /// No description provided for @roleAlreadyRegisteredNotice.
  ///
  /// In ko, this message translates to:
  /// **'이 번호는 이미 다른 역할로 등록되어 있어요. 계속 진행하면 이 역할도 함께 등록돼요.'**
  String get roleAlreadyRegisteredNotice;

  /// No description provided for @roleElderButton.
  ///
  /// In ko, this message translates to:
  /// **'저는 어르신이에요'**
  String get roleElderButton;

  /// No description provided for @roleGuardianButton.
  ///
  /// In ko, this message translates to:
  /// **'저는 가족(보호자)이에요'**
  String get roleGuardianButton;

  /// No description provided for @pinKeypadClearLabel.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get pinKeypadClearLabel;

  /// No description provided for @guardianConnectTitle.
  ///
  /// In ko, this message translates to:
  /// **'보호자 연결'**
  String get guardianConnectTitle;

  /// No description provided for @qrGeneratingMessage.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드를 만들고 있어요'**
  String get qrGeneratingMessage;

  /// No description provided for @qrGenerateError.
  ///
  /// In ko, this message translates to:
  /// **'QR 코드를 만들지 못했어요. 다시 시도해주세요.'**
  String get qrGenerateError;

  /// No description provided for @qrShowGuardianPrompt.
  ///
  /// In ko, this message translates to:
  /// **'보호자에게 이 QR을 보여주세요'**
  String get qrShowGuardianPrompt;

  /// No description provided for @qrScanExplanation.
  ///
  /// In ko, this message translates to:
  /// **'보호자가 이 QR을 스캔하면 연결 요청이 도착합니다.'**
  String get qrScanExplanation;

  /// No description provided for @qrExpiredMessage.
  ///
  /// In ko, this message translates to:
  /// **'QR이 만료되었어요.'**
  String get qrExpiredMessage;

  /// No description provided for @qrRegenerateButton.
  ///
  /// In ko, this message translates to:
  /// **'QR 다시 만들기'**
  String get qrRegenerateButton;

  /// No description provided for @guardianListTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결된 보호자 목록'**
  String get guardianListTitle;

  /// No description provided for @guardianConnectButton.
  ///
  /// In ko, this message translates to:
  /// **'보호자 연결하기'**
  String get guardianConnectButton;

  /// No description provided for @guardianListLoadError.
  ///
  /// In ko, this message translates to:
  /// **'보호자 목록을 불러오지 못했어요.'**
  String get guardianListLoadError;

  /// No description provided for @guardianListEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 보호자가 없습니다\n보호자 연결하기로 QR을 보여주세요'**
  String get guardianListEmptyMessage;

  /// No description provided for @guardianRequestLabelWithId.
  ///
  /// In ko, this message translates to:
  /// **'보호자 연결 요청 ({id})'**
  String guardianRequestLabelWithId(String id);

  /// No description provided for @guardianConnectedLabelWithId.
  ///
  /// In ko, this message translates to:
  /// **'연결된 보호자 ({id})'**
  String guardianConnectedLabelWithId(String id);

  /// No description provided for @guardianConnectedSince.
  ///
  /// In ko, this message translates to:
  /// **'연결됨 · {date}'**
  String guardianConnectedSince(String date);

  /// No description provided for @acceptButton.
  ///
  /// In ko, this message translates to:
  /// **'수락'**
  String get acceptButton;

  /// No description provided for @rejectButton.
  ///
  /// In ko, this message translates to:
  /// **'거절'**
  String get rejectButton;

  /// No description provided for @guardianRevokeConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'연결을 해제할까요?'**
  String get guardianRevokeConfirmTitle;

  /// No description provided for @guardianRevokeConfirmMessage.
  ///
  /// In ko, this message translates to:
  /// **'해제하면 이 보호자는 더 이상 회원님의 정보를 볼 수 없습니다.'**
  String get guardianRevokeConfirmMessage;

  /// No description provided for @guardianRevokeConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'해제'**
  String get guardianRevokeConfirmLabel;

  /// No description provided for @guardianRevokeAction.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제'**
  String get guardianRevokeAction;

  /// No description provided for @guardianStatusPending.
  ///
  /// In ko, this message translates to:
  /// **'요청 대기 중'**
  String get guardianStatusPending;

  /// No description provided for @guardianStatusAccepted.
  ///
  /// In ko, this message translates to:
  /// **'연결됨'**
  String get guardianStatusAccepted;

  /// No description provided for @guardianStatusRejected.
  ///
  /// In ko, this message translates to:
  /// **'거절함'**
  String get guardianStatusRejected;

  /// No description provided for @guardianStatusRevoked.
  ///
  /// In ko, this message translates to:
  /// **'연결 해제됨'**
  String get guardianStatusRevoked;

  /// No description provided for @documentScanTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 촬영'**
  String get documentScanTitle;

  /// No description provided for @documentScanStartTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 분석'**
  String get documentScanStartTitle;

  /// No description provided for @documentScanStartTakePhotoButton.
  ///
  /// In ko, this message translates to:
  /// **'사진 촬영하기'**
  String get documentScanStartTakePhotoButton;

  /// No description provided for @documentScanStartPickPhotoButton.
  ///
  /// In ko, this message translates to:
  /// **'사진 불러오기'**
  String get documentScanStartPickPhotoButton;

  /// No description provided for @documentScanStartTipTitle.
  ///
  /// In ko, this message translates to:
  /// **'꼭 확인해 주세요!'**
  String get documentScanStartTipTitle;

  /// No description provided for @documentScanStartTipLine1.
  ///
  /// In ko, this message translates to:
  /// **'문서의 글자가 선명하게 보이도록 촬영해 주세요'**
  String get documentScanStartTipLine1;

  /// No description provided for @documentScanStartTipLine2.
  ///
  /// In ko, this message translates to:
  /// **'빛 반사가 적은 밝은 곳에서 촬영하면 더 정확해요'**
  String get documentScanStartTipLine2;

  /// No description provided for @photoLibraryUnavailableError.
  ///
  /// In ko, this message translates to:
  /// **'사진을 불러올 수 없어요.'**
  String get photoLibraryUnavailableError;

  /// No description provided for @cameraPermissionCheckError.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한을 확인하지 못했어요.'**
  String get cameraPermissionCheckError;

  /// No description provided for @cameraPermissionRequestMessage.
  ///
  /// In ko, this message translates to:
  /// **'문서와 문자를 촬영해 분석하려면\n카메라 접근을 허용해주세요.'**
  String get cameraPermissionRequestMessage;

  /// No description provided for @cameraPermissionRequestButton.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한 허용하기'**
  String get cameraPermissionRequestButton;

  /// No description provided for @cameraPermissionBlockedMessage.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.'**
  String get cameraPermissionBlockedMessage;

  /// No description provided for @openSettingsButton.
  ///
  /// In ko, this message translates to:
  /// **'설정 열기'**
  String get openSettingsButton;

  /// No description provided for @scanPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'촬영 결과 확인'**
  String get scanPreviewTitle;

  /// No description provided for @retakeLabel.
  ///
  /// In ko, this message translates to:
  /// **'재촬영'**
  String get retakeLabel;

  /// No description provided for @scannedDocumentsCount.
  ///
  /// In ko, this message translates to:
  /// **'{count}장 촬영했어요'**
  String scannedDocumentsCount(int count);

  /// No description provided for @photoCountBadge.
  ///
  /// In ko, this message translates to:
  /// **'{count}장'**
  String photoCountBadge(int count);

  /// No description provided for @addAnotherPhotoButton.
  ///
  /// In ko, this message translates to:
  /// **'추가 촬영'**
  String get addAnotherPhotoButton;

  /// No description provided for @analyzeButton.
  ///
  /// In ko, this message translates to:
  /// **'분석하기'**
  String get analyzeButton;

  /// No description provided for @documentIndexLabel.
  ///
  /// In ko, this message translates to:
  /// **'문서 {index}'**
  String documentIndexLabel(int index);

  /// No description provided for @deletePhotoAtIndexLabel.
  ///
  /// In ko, this message translates to:
  /// **'{index}번째 사진 삭제'**
  String deletePhotoAtIndexLabel(int index);

  /// No description provided for @documentAnalyzingProgress.
  ///
  /// In ko, this message translates to:
  /// **'{current}/{total} 문서 분석 중'**
  String documentAnalyzingProgress(int current, int total);

  /// No description provided for @documentsAnalyzedCount.
  ///
  /// In ko, this message translates to:
  /// **'문서 {count}건을 분석했어요'**
  String documentsAnalyzedCount(int count);

  /// No description provided for @noCameraAvailableError.
  ///
  /// In ko, this message translates to:
  /// **'사용 가능한 카메라가 없어요.'**
  String get noCameraAvailableError;

  /// No description provided for @cameraStartError.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 시작하지 못했어요.'**
  String get cameraStartError;

  /// No description provided for @flashUnavailableError.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 플래시를 사용할 수 없어요.'**
  String get flashUnavailableError;

  /// No description provided for @flashOffLabel.
  ///
  /// In ko, this message translates to:
  /// **'플래시 꺼짐'**
  String get flashOffLabel;

  /// No description provided for @flashOnLabel.
  ///
  /// In ko, this message translates to:
  /// **'플래시 켜짐'**
  String get flashOnLabel;

  /// No description provided for @flashAutoLabel.
  ///
  /// In ko, this message translates to:
  /// **'플래시 자동'**
  String get flashAutoLabel;

  /// No description provided for @captureFailedError.
  ///
  /// In ko, this message translates to:
  /// **'촬영에 실패했어요. 다시 시도해주세요.'**
  String get captureFailedError;

  /// No description provided for @cameraPreparingMessage.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 준비하고 있어요'**
  String get cameraPreparingMessage;

  /// No description provided for @documentFrameGuideMessage.
  ///
  /// In ko, this message translates to:
  /// **'문서를 화면 안에 맞춰주세요'**
  String get documentFrameGuideMessage;

  /// No description provided for @captureButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'촬영하기'**
  String get captureButtonLabel;

  /// No description provided for @closeCameraButtonLabel.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get closeCameraButtonLabel;

  /// No description provided for @noGuardianConnectedError.
  ///
  /// In ko, this message translates to:
  /// **'아직 연결된 보호자가 없어요.'**
  String get noGuardianConnectedError;

  /// No description provided for @emergencyHelpTitle.
  ///
  /// In ko, this message translates to:
  /// **'도움이 필요하신가요?'**
  String get emergencyHelpTitle;

  /// No description provided for @emergency119Label.
  ///
  /// In ko, this message translates to:
  /// **'119 신고하기 (소방·구급)'**
  String get emergency119Label;

  /// No description provided for @emergency112Label.
  ///
  /// In ko, this message translates to:
  /// **'112 신고하기 (경찰)'**
  String get emergency112Label;

  /// No description provided for @govComplaintLabel.
  ///
  /// In ko, this message translates to:
  /// **'110 상담하기 (정부민원안내)'**
  String get govComplaintLabel;

  /// No description provided for @dasanCallCenterLabel.
  ///
  /// In ko, this message translates to:
  /// **'120 상담하기 (다산콜센터)'**
  String get dasanCallCenterLabel;

  /// No description provided for @cancelButton.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancelButton;

  /// No description provided for @myRecordsTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 기록'**
  String get myRecordsTitle;

  /// No description provided for @documentReadLabel.
  ///
  /// In ko, this message translates to:
  /// **'문서 읽기'**
  String get documentReadLabel;

  /// No description provided for @documentReadSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진으로 문서를 읽어드려요'**
  String get documentReadSubtitle;

  /// No description provided for @messageCheckLabel.
  ///
  /// In ko, this message translates to:
  /// **'문자 확인'**
  String get messageCheckLabel;

  /// No description provided for @messageCheckSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'문자를 읽어주고 쉽게 알려드려요'**
  String get messageCheckSubtitle;

  /// No description provided for @recentMessagesIntro.
  ///
  /// In ko, this message translates to:
  /// **'최근 문자를 가져왔어요.\n확인하고 싶은 문자를 눌러주세요.'**
  String get recentMessagesIntro;

  /// No description provided for @infoTabTitle.
  ///
  /// In ko, this message translates to:
  /// **'정보'**
  String get infoTabTitle;

  /// No description provided for @infoTabEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 준비된 정보가 없어요. 곧 맞춤 정보를 보여드릴게요.'**
  String get infoTabEmptyMessage;

  /// No description provided for @statisticsLabel.
  ///
  /// In ko, this message translates to:
  /// **'통계'**
  String get statisticsLabel;

  /// No description provided for @usefulInfoLabel.
  ///
  /// In ko, this message translates to:
  /// **'알아두면 좋은 정보'**
  String get usefulInfoLabel;

  /// No description provided for @howToUseLabel.
  ///
  /// In ko, this message translates to:
  /// **'사용 방법 안내'**
  String get howToUseLabel;

  /// No description provided for @supportTitle.
  ///
  /// In ko, this message translates to:
  /// **'고객 지원'**
  String get supportTitle;

  /// No description provided for @moreTitle.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get moreTitle;

  /// No description provided for @recordsLoadingMessage.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오고 있어요'**
  String get recordsLoadingMessage;

  /// No description provided for @recordsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'기록을 불러오는 중 문제가 발생했어요.'**
  String get recordsLoadError;

  /// No description provided for @recordsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'아직 분석한 기록이 없습니다.\n문서 찍기나 문자 보기를 이용해보세요.'**
  String get recordsEmptyMessage;

  /// No description provided for @helpRequestLabel.
  ///
  /// In ko, this message translates to:
  /// **'도움 요청'**
  String get helpRequestLabel;

  /// No description provided for @easyModeOnState.
  ///
  /// In ko, this message translates to:
  /// **'켜짐'**
  String get easyModeOnState;

  /// No description provided for @easyModeOffState.
  ///
  /// In ko, this message translates to:
  /// **'꺼짐'**
  String get easyModeOffState;

  /// No description provided for @easyModeToggleSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'쉬운 모드, 현재 {state}'**
  String easyModeToggleSemanticLabel(String state);

  /// No description provided for @easyModeDescription.
  ///
  /// In ko, this message translates to:
  /// **'더 크고 단순한 화면으로 보기'**
  String get easyModeDescription;

  /// No description provided for @recentRecordsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 기록'**
  String get recentRecordsTitle;

  /// No description provided for @todayScheduleTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 일정'**
  String get todayScheduleTitle;

  /// No description provided for @emergencyHelpRequestLabel.
  ///
  /// In ko, this message translates to:
  /// **'긴급 도움 (SOS)'**
  String get emergencyHelpRequestLabel;

  /// No description provided for @emergencyHelpRequestSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'위급할 때 빠르게 도움을 요청해요'**
  String get emergencyHelpRequestSubtitle;

  /// No description provided for @homeGreetingWithName.
  ///
  /// In ko, this message translates to:
  /// **'{name}님, 안녕하세요!'**
  String homeGreetingWithName(String name);

  /// No description provided for @homeGreetingSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘도 편안하고 안전한 하루 되세요'**
  String get homeGreetingSubtitle;

  /// No description provided for @easyHomeHeadline.
  ///
  /// In ko, this message translates to:
  /// **'무엇을 도와드릴까요?'**
  String get easyHomeHeadline;

  /// No description provided for @infoGreetingWithName.
  ///
  /// In ko, this message translates to:
  /// **'{name}님을 위한 맞춤 정보예요'**
  String infoGreetingWithName(String name);

  /// No description provided for @recordsFilterAllLabel.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get recordsFilterAllLabel;

  /// No description provided for @recordsFilterEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'해당하는 기록이 없어요.\n다른 필터를 선택해보세요.'**
  String get recordsFilterEmptyMessage;

  /// No description provided for @moreAccountSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'계정'**
  String get moreAccountSectionTitle;

  /// No description provided for @moreUsageInfoSectionTitle.
  ///
  /// In ko, this message translates to:
  /// **'이용 정보'**
  String get moreUsageInfoSectionTitle;

  /// No description provided for @smsPermissionCheckError.
  ///
  /// In ko, this message translates to:
  /// **'문자 권한을 확인하지 못했어요.'**
  String get smsPermissionCheckError;

  /// No description provided for @smsPermissionRequestMessage.
  ///
  /// In ko, this message translates to:
  /// **'받은 문자를 확인해 위험한 문자인지 알려드리려면\n문자 접근을 허용해주세요.'**
  String get smsPermissionRequestMessage;

  /// No description provided for @smsPermissionRequestButton.
  ///
  /// In ko, this message translates to:
  /// **'문자 권한 허용하기'**
  String get smsPermissionRequestButton;

  /// No description provided for @smsPermissionBlockedMessage.
  ///
  /// In ko, this message translates to:
  /// **'문자 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.'**
  String get smsPermissionBlockedMessage;

  /// No description provided for @analysisGenericError.
  ///
  /// In ko, this message translates to:
  /// **'분석 중 문제가 발생했어요.'**
  String get analysisGenericError;

  /// No description provided for @unknownSenderLabel.
  ///
  /// In ko, this message translates to:
  /// **'알 수 없는 번호'**
  String get unknownSenderLabel;

  /// No description provided for @manualMessageInputPrompt.
  ///
  /// In ko, this message translates to:
  /// **'의심스러운 문자를 복사해서 붙여넣거나\n직접 입력해주세요.'**
  String get manualMessageInputPrompt;

  /// No description provided for @pasteFromClipboardButton.
  ///
  /// In ko, this message translates to:
  /// **'클립보드에서 붙여넣기'**
  String get pasteFromClipboardButton;

  /// No description provided for @messageContentLabel.
  ///
  /// In ko, this message translates to:
  /// **'문자 내용'**
  String get messageContentLabel;

  /// No description provided for @messageContentHint.
  ///
  /// In ko, this message translates to:
  /// **'문자 내용을 입력해주세요'**
  String get messageContentHint;

  /// No description provided for @recentSmsLoadingMessage.
  ///
  /// In ko, this message translates to:
  /// **'최근 문자를 불러오고 있어요'**
  String get recentSmsLoadingMessage;

  /// No description provided for @smsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'문자를 불러오지 못했어요.'**
  String get smsLoadError;

  /// No description provided for @recentSmsEmptyMessage.
  ///
  /// In ko, this message translates to:
  /// **'최근 받은 문자가 없어요.'**
  String get recentSmsEmptyMessage;

  /// No description provided for @accessibilitySettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'접근성 설정'**
  String get accessibilitySettingsTitle;

  /// No description provided for @guardianRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'보호자 등록'**
  String get guardianRegisterTitle;

  /// No description provided for @onboardingAccessibilityHeadline.
  ///
  /// In ko, this message translates to:
  /// **'몇 가지만 정해주세요'**
  String get onboardingAccessibilityHeadline;

  /// No description provided for @onboardingAccessibilityIntro.
  ///
  /// In ko, this message translates to:
  /// **'편하게 사용하실 수 있도록 먼저 설정할게요.'**
  String get onboardingAccessibilityIntro;

  /// No description provided for @nextButton.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get nextButton;

  /// No description provided for @onboardingProfileIntro.
  ///
  /// In ko, this message translates to:
  /// **'알려주시면 더 도움이 되는 정보를 보여드릴 수 있어요. (선택 입력)'**
  String get onboardingProfileIntro;

  /// No description provided for @regionLabel.
  ///
  /// In ko, this message translates to:
  /// **'지역'**
  String get regionLabel;

  /// No description provided for @skipButton.
  ///
  /// In ko, this message translates to:
  /// **'건너뛰기'**
  String get skipButton;

  /// No description provided for @guardianConnectComingSoonMessage.
  ///
  /// In ko, this message translates to:
  /// **'보호자 연결은 곧 제공될 예정이에요. 준비되면 더보기 메뉴에서 언제든 연결하실 수 있어요.'**
  String get guardianConnectComingSoonMessage;

  /// No description provided for @saveAndStartButton.
  ///
  /// In ko, this message translates to:
  /// **'저장하고 시작하기'**
  String get saveAndStartButton;

  /// No description provided for @textSizeTitle.
  ///
  /// In ko, this message translates to:
  /// **'글자 크기'**
  String get textSizeTitle;

  /// No description provided for @textScaleNormalLabel.
  ///
  /// In ko, this message translates to:
  /// **'보통'**
  String get textScaleNormalLabel;

  /// No description provided for @textScaleLargeLabel.
  ///
  /// In ko, this message translates to:
  /// **'크게'**
  String get textScaleLargeLabel;

  /// No description provided for @textScaleExtraLargeLabel.
  ///
  /// In ko, this message translates to:
  /// **'아주 크게'**
  String get textScaleExtraLargeLabel;

  /// No description provided for @voiceGuideTitle.
  ///
  /// In ko, this message translates to:
  /// **'음성 안내'**
  String get voiceGuideTitle;

  /// No description provided for @voiceGuideDescription.
  ///
  /// In ko, this message translates to:
  /// **'화면 내용을 음성으로도 안내해드려요'**
  String get voiceGuideDescription;

  /// No description provided for @voiceRateTitle.
  ///
  /// In ko, this message translates to:
  /// **'음성 안내 속도'**
  String get voiceRateTitle;

  /// No description provided for @voiceRateNormalLabel.
  ///
  /// In ko, this message translates to:
  /// **'1배'**
  String get voiceRateNormalLabel;

  /// No description provided for @voiceRateFastLabel.
  ///
  /// In ko, this message translates to:
  /// **'1.2배'**
  String get voiceRateFastLabel;

  /// No description provided for @voiceRateFasterLabel.
  ///
  /// In ko, this message translates to:
  /// **'1.5배'**
  String get voiceRateFasterLabel;

  /// No description provided for @voiceRateFastestLabel.
  ///
  /// In ko, this message translates to:
  /// **'2배'**
  String get voiceRateFastestLabel;

  /// No description provided for @homeVoiceGuideEasy.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면이에요. 문서 읽기, 문자 확인, 경로당 찾기, 내 기록 중에서 골라주세요.'**
  String get homeVoiceGuideEasy;

  /// No description provided for @homeVoiceGuideNormal.
  ///
  /// In ko, this message translates to:
  /// **'홈 화면이에요. 문서 읽기, 문자 확인, 경로당 찾기, 긴급 도움 요청 중에서 골라주세요.'**
  String get homeVoiceGuideNormal;

  /// No description provided for @easyResultVoiceGuidePrefix.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과를 알려드릴게요.'**
  String get easyResultVoiceGuidePrefix;

  /// No description provided for @feeStatisticsTitle.
  ///
  /// In ko, this message translates to:
  /// **'요금 통계'**
  String get feeStatisticsTitle;

  /// No description provided for @feeStatisticsLoadingMessage.
  ///
  /// In ko, this message translates to:
  /// **'요금 통계를 불러오고 있어요'**
  String get feeStatisticsLoadingMessage;

  /// No description provided for @feeStatisticsLoadError.
  ///
  /// In ko, this message translates to:
  /// **'요금 통계를 불러오는 중 문제가 발생했어요.'**
  String get feeStatisticsLoadError;

  /// No description provided for @privacyPinTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호(PIN)'**
  String get privacyPinTitle;

  /// No description provided for @privacyPinBody.
  ///
  /// In ko, this message translates to:
  /// **'PIN 원문이나 이를 유추할 수 있는 값은 이 기기 어디에도 저장하지 않아요. 서버에서도 암호화된 값만 검증 전용으로 보관하고, 다른 사람이 들여다볼 수 있는 경로가 없어요.'**
  String get privacyPinBody;

  /// No description provided for @privacyPhotoTitle.
  ///
  /// In ko, this message translates to:
  /// **'문서 촬영 사진'**
  String get privacyPhotoTitle;

  /// No description provided for @privacyPhotoBody.
  ///
  /// In ko, this message translates to:
  /// **'문서를 촬영해 분석을 요청하면, 분석이 끝나는 즉시(성공하든 실패하든) 원본 사진은 서버에서 삭제돼요. 분석 결과만 남아요.'**
  String get privacyPhotoBody;

  /// No description provided for @privacySharedInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'보호자와 공유되는 정보'**
  String get privacySharedInfoTitle;

  /// No description provided for @privacySharedInfoBody.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과는 내가 연결을 수락한 보호자만 볼 수 있어요. 연결을 해제하면 더 이상 볼 수 없어요.'**
  String get privacySharedInfoBody;

  /// No description provided for @privacyRetentionTitle.
  ///
  /// In ko, this message translates to:
  /// **'분석 결과 원문 보관 기간'**
  String get privacyRetentionTitle;

  /// No description provided for @privacyRetentionBody.
  ///
  /// In ko, this message translates to:
  /// **'문자·문서 분석 결과에 남는 요약/원문을 얼마나 오래 보관할지는 아직 정해지지 않았어요. 정해지는 대로 이 화면에 안내할게요.'**
  String get privacyRetentionBody;

  /// No description provided for @privacyInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 보관 안내'**
  String get privacyInfoTitle;

  /// No description provided for @supportContactTitle.
  ///
  /// In ko, this message translates to:
  /// **'고객센터 연락처'**
  String get supportContactTitle;

  /// No description provided for @supportContactComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'전화·이메일 연락처를 준비하고 있어요. 곧 안내해드릴게요.'**
  String get supportContactComingSoon;

  /// No description provided for @privacyInfoDescription.
  ///
  /// In ko, this message translates to:
  /// **'내 정보가 어떻게 보관되는지 확인해요'**
  String get privacyInfoDescription;

  /// No description provided for @micPermissionCheckError.
  ///
  /// In ko, this message translates to:
  /// **'마이크 권한을 확인하지 못했어요.'**
  String get micPermissionCheckError;

  /// No description provided for @micPermissionRequestMessage.
  ///
  /// In ko, this message translates to:
  /// **'음성 비서를 사용하려면\n마이크 접근을 허용해주세요.'**
  String get micPermissionRequestMessage;

  /// No description provided for @micPermissionRequestButton.
  ///
  /// In ko, this message translates to:
  /// **'마이크 권한 허용하기'**
  String get micPermissionRequestButton;

  /// No description provided for @micPermissionBlockedMessage.
  ///
  /// In ko, this message translates to:
  /// **'마이크 권한이 차단되어 있어요.\n기기 설정에서 직접 허용해주셔야 해요.'**
  String get micPermissionBlockedMessage;

  /// No description provided for @actionChecklistTitle.
  ///
  /// In ko, this message translates to:
  /// **'해야 할 일'**
  String get actionChecklistTitle;

  /// No description provided for @clarifyingQuestionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'궁금한 점이 있나요?'**
  String get clarifyingQuestionsTitle;

  /// No description provided for @askByVoiceButton.
  ///
  /// In ko, this message translates to:
  /// **'음성으로 물어보기'**
  String get askByVoiceButton;

  /// No description provided for @dateKindPaymentDue.
  ///
  /// In ko, this message translates to:
  /// **'납부 기한'**
  String get dateKindPaymentDue;

  /// No description provided for @dateKindVisit.
  ///
  /// In ko, this message translates to:
  /// **'방문 날짜'**
  String get dateKindVisit;

  /// No description provided for @dateKindApplicationPeriod.
  ///
  /// In ko, this message translates to:
  /// **'신청 기간'**
  String get dateKindApplicationPeriod;

  /// No description provided for @dateKindExpiration.
  ///
  /// In ko, this message translates to:
  /// **'만료일'**
  String get dateKindExpiration;

  /// No description provided for @dateKindReservation.
  ///
  /// In ko, this message translates to:
  /// **'예약 날짜'**
  String get dateKindReservation;

  /// No description provided for @dateKindOther.
  ///
  /// In ko, this message translates to:
  /// **'기타 중요한 날짜'**
  String get dateKindOther;

  /// No description provided for @importantDatesTitle.
  ///
  /// In ko, this message translates to:
  /// **'중요한 날짜'**
  String get importantDatesTitle;

  /// No description provided for @monthDayFormat.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 {day}일'**
  String monthDayFormat(int month, int day);

  /// No description provided for @keyPointsTitle.
  ///
  /// In ko, this message translates to:
  /// **'주요 내용'**
  String get keyPointsTitle;

  /// No description provided for @analysisProgressSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'분석 진행률 {percent}퍼센트, {label}'**
  String analysisProgressSemanticLabel(int percent, String label);

  /// No description provided for @progressPreparing.
  ///
  /// In ko, this message translates to:
  /// **'분석을 준비하고 있어요'**
  String get progressPreparing;

  /// No description provided for @progressSending.
  ///
  /// In ko, this message translates to:
  /// **'자료를 보내고 있어요'**
  String get progressSending;

  /// No description provided for @progressAnalyzing.
  ///
  /// In ko, this message translates to:
  /// **'AI가 확인하고 있어요'**
  String get progressAnalyzing;

  /// No description provided for @progressFinishing.
  ///
  /// In ko, this message translates to:
  /// **'결과를 정리하고 있어요'**
  String get progressFinishing;

  /// No description provided for @detailsViewTitle.
  ///
  /// In ko, this message translates to:
  /// **'상세정보 보기'**
  String get detailsViewTitle;

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

  /// No description provided for @easyResultAiSummaryLabel.
  ///
  /// In ko, this message translates to:
  /// **'AI 요약'**
  String get easyResultAiSummaryLabel;

  /// No description provided for @easyResultTypeLabel.
  ///
  /// In ko, this message translates to:
  /// **'종류'**
  String get easyResultTypeLabel;

  /// No description provided for @easyResultReplayLabel.
  ///
  /// In ko, this message translates to:
  /// **'다시 듣기'**
  String get easyResultReplayLabel;

  /// No description provided for @askAboutThisButton.
  ///
  /// In ko, this message translates to:
  /// **'이 내용 물어보기'**
  String get askAboutThisButton;

  /// No description provided for @confirmedDoneSemanticLabel.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료로 표시했어요'**
  String get confirmedDoneSemanticLabel;

  /// No description provided for @confirmedDoneMessage.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료했어요'**
  String get confirmedDoneMessage;

  /// No description provided for @confirmDoneButton.
  ///
  /// In ko, this message translates to:
  /// **'확인 완료'**
  String get confirmDoneButton;

  /// No description provided for @featureComingSoonMessage.
  ///
  /// In ko, this message translates to:
  /// **'이 기능은 아직 준비 중이에요.'**
  String get featureComingSoonMessage;

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

  /// No description provided for @feeHeroTitle.
  ///
  /// In ko, this message translates to:
  /// **'{month}월 요금'**
  String feeHeroTitle(int month);

  /// No description provided for @feeHeroLessThanLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 {amount} 적어요'**
  String feeHeroLessThanLastMonth(String amount);

  /// No description provided for @feeHeroMoreThanLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달보다 {amount} 많아요'**
  String feeHeroMoreThanLastMonth(String amount);

  /// No description provided for @feeHeroSameAsLastMonth.
  ///
  /// In ko, this message translates to:
  /// **'지난달과 같아요'**
  String get feeHeroSameAsLastMonth;

  /// No description provided for @recentBillsTitle.
  ///
  /// In ko, this message translates to:
  /// **'최근 고지서'**
  String get recentBillsTitle;

  /// No description provided for @countUnitLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}건'**
  String countUnitLabel(int count);

  /// No description provided for @notifSettingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notifSettingsTitle;

  /// No description provided for @dangerAlertLabel.
  ///
  /// In ko, this message translates to:
  /// **'위험 알림'**
  String get dangerAlertLabel;

  /// No description provided for @alwaysOnCaption.
  ///
  /// In ko, this message translates to:
  /// **'항상 켜짐'**
  String get alwaysOnCaption;

  /// No description provided for @guardianNotifyLabel.
  ///
  /// In ko, this message translates to:
  /// **'보호자 알림'**
  String get guardianNotifyLabel;

  /// No description provided for @messageGuardianNoticeTitle.
  ///
  /// In ko, this message translates to:
  /// **'보호자에게 알렸어요'**
  String get messageGuardianNoticeTitle;

  /// No description provided for @messageGuardianNoticeBody.
  ///
  /// In ko, this message translates to:
  /// **'문자 내용을 전달했어요'**
  String get messageGuardianNoticeBody;

  /// No description provided for @goHomeButton.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get goHomeButton;
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
